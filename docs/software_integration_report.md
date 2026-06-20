# Software Integration Report

This document details the software integration architecture of the Smart AFO system, explaining the firmware layer, the edge gateway services, and the mobile application communication protocols.

---

## 1. High-Level Software Architecture

The software architecture is divided into three distinct operational layers. Communication between these layers is handled via structured RPC (Remote Procedure Call) bridges and BLE (Bluetooth Low Energy) GATT specifications.

```
┌──────────────────────────────────────────────────────────┐
│             Bare-Metal C++ (Arduino Uno Q)               │
│  - Sensor polling (FSRs at 50Hz, DHT11 at 0.5Hz)         │
│  - Acceleration magnitude step detection & cadence calculation │
└───────────────────────────┬──────────────────────────────┘
                            │
              RouterBridge RPC call (UART Serial)
                            │
                            ▼
┌──────────────────────────────────────────────────────────┐
│              Linux Edge Service (Python)                 │
│  - Spawns UART RPC listener daemon                       │
│  - Manages SQLite database writer worker (5Hz logging)   │
│  - Hosts BlueZ BLE GATT Server (custom Service/Chrc)    │
└───────────────────────────┬──────────────────────────────┘
                            │
             BLE GATT Notification (Binary payload)
                            │
                            ▼
┌──────────────────────────────────────────────────────────┐
│                Flutter App (Mobile Client)               │
│  - Unpacks 24-byte binary structure (Little Endian)     │
│  - Drives real-time COP Line Graph (500ms updates)       │
│  - Buffers 30s cycle averages for heatmaps & bar charts  │
│  - Integrates Deepseek AI Gait Insights & password gate  │
└──────────────────────────────────────────────────────────┘
```

---

## 2. Firmware Integration (C++ on Arduino Core)

The firmware runs on an ATMega328P microcontroller core and performs real-time sampling and calculations.

### A. Non-Blocking Event Timing
The code avoids using the blocking `delay()` function to maintain a steady sensor acquisition frequency:
```cpp
const unsigned long FSR_INTERVAL = 20;     // 50Hz FSR and IMU polling (20ms)
const unsigned long DHT_INTERVAL = 2000;   // 0.5Hz DHT11 polling (2000ms)
```

### B. Gait Calculations
*   **Step Detection:** Acceleration magnitude is calculated using:
    $$\text{Magnitude} = \sqrt{a_x^2 + a_y^2 + a_z^2}$$
    If $\text{Magnitude} > 1.30\text{ Gs}$ and the elapsed time since the last step exceeds $350\text{ms}$ (debounce), a step is registered.
*   **Cadence Calculation:** Keeps a sliding window of the last 4 step intervals (`stepIntervals`) to calculate walking cadence in Steps Per Minute (SPM).

### C. Data Transmission
Once data is updated, it calls the RPC bridge method registered on the Linux router:
```cpp
Bridge.call("update_telemetry", fsr1Value, fsr2Value, (float)temperatureValue, (float)humidityValue, (float)cop, (float)walkingCadence, (uint32_t)stepCount);
```

---

## 3. Edge Gateway Integration (Python on OpenWRT Linux)

The edge gateway mediates communication between the serial port and the mobile client, while persisting data locally.

### A. Threading Architecture
The Python gateway script (`afo_edge_processor.py`) utilizes three concurrent execution threads:
1.  **Main/Bridge Thread:** Initializes the `arduino.app_utils.Bridge` RPC handler, registers the `update_telemetry` callback, and runs the main loop.
2.  **DBus BLE Thread:** Spawns a background GLib Main Loop thread (`gi.repository.GLib`) to process Bluetooth connections and write requests.
3.  **Database Logger Thread:** Operates a thread-safe Queue-based consumer thread (`db_logger_worker`) that writes sensor frames into SQLite downsampled to 5Hz to avoid wearing out the system's flash storage.

### B. BLE GATT Structural Packaging
When new data arrives from the Arduino, the edge processor encodes the telemetry parameters into a **24-byte binary packet** using Python's `struct` module before dispatching it to connected BLE clients:
```python
# Format: < (Little Endian), HH (2x uint16), ffffI (4x float, 1x uint32)
payload = struct.pack('<HHffffI', fsr1, fsr2, temp, humidity, cop, cadence, step_count)
```

---

## 4. Mobile Client Integration (Flutter & Dart)

The Flutter mobile application connects, parses, visualizes, and processes the telemetry.

### A. Binary Payload Parsing
In `ble_service.dart`, the incoming 24-byte packet is read as `List<int>`, converted to a byte array, and parsed in Little Endian format:
```dart
final bytes = Uint8List.fromList(rawBytes);
final byteData = ByteData.sublistView(bytes);

int fsr1 = byteData.getUint16(0, Endian.little);         // Bytes 0-1
int fsr2 = byteData.getUint16(2, Endian.little);         // Bytes 2-3
double temp = byteData.getFloat32(4, Endian.little);     // Bytes 4-7
double humidity = byteData.getFloat32(8, Endian.little); // Bytes 8-11
double cop = byteData.getFloat32(12, Endian.little);     // Bytes 12-15
double cadence = byteData.getFloat32(16, Endian.little); // Bytes 16-19
int stepCount = byteData.getUint32(20, Endian.little);   // Bytes 20-23
```

### B. Dynamic Force Calibration & COP Calculation
Before plotting or evaluating warnings, raw FSR voltage dividers (0 to 1023) are converted to Newtons based on the sensor's physical conductivity curve:
```dart
double _calculateForceNewton(int adc) {
  if (adc >= 1022) return 0.0;
  int normalizedAdc = adc <= 1 ? 1 : adc;
  const double rSeries = 10000.0; // 10k Resistor
  final double rFsr = rSeries * normalizedAdc / (1023.0 - normalizedAdc);
  if (rFsr <= 0) return 0.0;
  final double conductance = 1000000.0 / rFsr;
  return conductance <= 1000.0 ? conductance / 80.0 : (conductance - 1000.0) / 30.0;
}
```
Using the calibrated forces $F_{\text{medial}}$ and $F_{\text{lateral}}$, the Center of Pressure is computed dynamically:
$$\text{COP} = \frac{F_{\text{lateral}} - F_{\text{medial}}}{F_{\text{lateral}} + F_{\text{medial}}}$$

### C. Frequency-Separated Rendering Engine
To create a clean user experience, visual controls are split into two refresh frequencies:
*   **High-Frequency Thread (500ms):** Telemetry listeners directly trigger updates on the dynamic **COP History Line Graph**, rendering immediate movements.
*   **Low-Frequency Buffer (30s Cycle):** Values are collected into buffers (`_cycleFsr1Buffer`, `_cycleFsr2Buffer`, and `_cycleCopBuffer`) during the 30-second countdown. When the timer hits `0`, the average values are calculated and rendered on the **Bar Charts**, **Foot Sole Heatmap**, and **Balance Slider**.

### D. Security & API Gates
*   **Developer Settings Password:** Gatekeeps access with a simple password check:
    ```dart
    if (_devPasswordController.text == "0000") {
      setState(() => _isDeveloperModeUnlocked = true);
    }
    ```
*   **Encrypted Preferences Storage:** The Deepseek API key is written to `SharedPreferences` locally and loaded on boot, keeping the key out of code repositories.
