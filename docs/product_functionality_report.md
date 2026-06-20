# Product Functionality Report: Smart Ankle-Foot Orthosis (AFO)

This section outlines the functional capabilities of the Smart AFO system, detailing how physical hardware sensors, embedded edge processing, and the mobile client application coordinate to provide real-time biomechanical analysis and microclimate safety monitoring.

---

## 1. Hardware Architecture & Functionality

The physical system utilizes a **Dual-Brain Architecture** consisting of a dedicated real-time microprocessing unit (MCU) and a co-located Linux gateway.

### A. Microcontroller Unit (MCU) Core (Arduino UNO Q Core)
*   **Asynchronous Sensor Polling:** Implements a non-blocking asynchronous event loop (utilizing `millis()` instead of locking delays) to poll physical sensors at distinct, optimal frequencies.
*   **Inter-Processor Communication (RPC Bridge):** Uses the `Arduino_RouterBridge` library to transmit binary telemetry packets directly to the Linux processor over a high-speed UART serial interface.
*   **Heartbeat Indicator:** Drives a physical LED (`LED_BUILTIN`) blinking at 1Hz to confirm system health and active processor loop status.

### B. Physical Sensors & Signal Acquisition
*   **Plantar Force Sensing (2x FSR406):**
    *   **Placement:** Located at critical pressure points: Medial (Anterior/Front foot sole) and Lateral (Posterior/Heel sole).
    *   **Polling Frequency:** 50Hz (every 20ms) to capture dynamic foot-strike transients during walking.
*   **Gait Analysis & Acceleration (MPU6050 6-Axis IMU):**
    *   **Bus Interface:** Connected via Fast Mode I2C (400kHz).
    *   **Function:** Measures linear acceleration forces along 3 dimensions ($A_x, A_y, A_z$).
    *   **Embedded Step Detection:** Implements a peak-magnitude threshold check ($>1.30\text{ Gs}$) with a 350ms software debounce to count cumulative steps and calculate real-time walking cadence (steps per minute).
*   **Microclimate Sensing (DHT11):**
    *   **Placement:** Located inside the orthosis shell.
    *   **Polling Frequency:** 0.5Hz (every 2 seconds).
    *   **Function:** Measures relative humidity (0–100%) and temperature (0–50°C) to monitor moisture accumulation and heat friction.

---

## 2. Software Architecture & Functionality

The software layer consists of the Linux Edge Processor service and the Flutter Mobile Companion App.

### A. Linux Edge Processor (`afo_edge_processor.py`)
*   **Background Telemetry Daemon:** Runs as an autostart systemd service (`smart-afo.service`) with crash-recovery policies.
*   **Data Ingestion & DBus BLE Server:**
    *   Listens for UART RPC callbacks from the MCU.
    *   Hosts a native BlueZ BLE GATT server.
    *   Broadcasts raw, unbuffered high-frequency telemetry notifications at 5Hz to connected mobile devices.
*   **Edge Data Persistence:** Logs telemetry packets locally to a SQLite database (`afo_telemetry.db`) downsampled to 5Hz to balance data density with write-cycles.

### B. Flutter Mobile Application (`smart_afo_app`)
The companion app translates telemetry data into real-time visual analytics, user controls, and active safety alerts.

#### i. Real-Time Telemetry Visualization (Dashboard)
*   **Live Center of Pressure (COP) Graph:** Draws a continuous line graph showing the dynamic shift of weight between the front foot and heel. Updates every 500ms using raw BLE telemetry.
*   **Adaptive Chart Scaling:** The graph's X-axis horizon scales dynamically from 5 to 30 seconds as the countdown timer progresses.
*   **Inline Step Goal Editing:** Users can tap the step target card to edit their daily goal. Progress percentages and dials adjust instantly.
*   **Dual-Tab Countdown Timer:** Displays a synced 30-second cycle countdown at the top of both the Dashboard and Analytics screens.

#### ii. Low-Frequency Analytics (30-Second Refresh Cycle)
To prevent cognitive overload from constantly shifting visuals, advanced analytics are buffered and updated only when the 30-second countdown resets:
*   **Force Comparison Bar Chart:** Displays the averaged loading ratio between FSR1 (Medial) and FSR2 (Lateral) computed over the 30-second cycle.
*   **Foot Sole Heatmap Visualizer:** Projects a 2D foot-sole graphic with a dynamic indicator showing the physical center of pressure location based on the cycle's average.
*   **Balance Shift Slider:** Displays an anterior-posterior slider representing the deviation from optimal balance.

#### iii. Warning & Alert Notification System
*   **Pulsing Status Button:** Replaces intrusive banners with a header-located icon. Safe state is a green bell. Active warnings switch the icon to a pulsing red shield.
*   **Dropdown Warnings List:** Tapping the warning shield displays a list of active safety violations:
    *   *Plantar Force Imbalance:* Triggered if the calculated COP exceeds safety limits.
    *   *Elevated Skin Temperature:* Triggered if temperature exceeds 32°C (prevents burns/friction).
    *   *High Moisture Level:* Triggered if humidity exceeds 70% (maceration risk).
*   **Haptic Alerts:** Sends a single physical vibration to the user's phone the moment a new warning state is entered.

#### iv. Intelligent Gait Insights (AI Integration)
*   **User-Facing Source Selector:** A toggle allows users to choose between:
    *   *Local LLM Mode:* Uses rule-based local simulation to generate insights offline.
    *   *Deepseek AI Mode:* Connects to the Deepseek V4Pro cloud API to generate biomechanical comments.
*   **Password-Locked Developer Console:** Locked behind password **`0000`**. Contains the secure, local **Deepseek API Key panel** (obscured from sight and saved locally using `SharedPreferences`) and options to revoke consent.

---

## 3. Functionality Mapping Matrix

| Functional Area | Hardware Component | Software Component | Refresh / Polling Rate |
| :--- | :--- | :--- | :--- |
| **Medial/Lateral Force** | FSR406 Resistors (A0, A1) | Flutter Line Graph / Bar Chart | 50Hz Polling / 5Hz BLE |
| **Walk Cadence & Steps** | MPU6050 Accelerometer (I2C) | Step Tracker / Progress Dial | 50Hz Polling / 5Hz BLE |
| **Shell Temperature** | DHT11 Sensor (Pin 4) | Microclimate Stacked Cards | 0.5Hz Polling / 5Hz BLE |
| **Shell Humidity** | DHT11 Sensor (Pin 4) | Microclimate Stacked Cards | 0.5Hz Polling / 5Hz BLE |
| **BLE GATT Advertising** | Built-in Wireless (Linux) | BlueZ DBus GATT Service | Continuous Broadcast |
| **Local Logging** | MicroSD/Onboard Flash | SQLite Daemon (`afo_telemetry.db`) | 5Hz (200ms write interval) |
| **Live COP Plotting** | *Calculated* | Flutter Custom Graph Painter | 500ms Real-Time |
| **Gait Heatmap** | *Calculated* | Flutter 2D Sole Visualizer | 30s Averaged Cycle |
| **Safety Alarms** | *Triggered by parameters* | Flutter Notification Hub & Haptics | Immediate upon threshold breach |
| **Insights Generation** | *Calculated* | Deepseek V4Pro API / Local Rules Engine| On-Demand (User triggered) |
