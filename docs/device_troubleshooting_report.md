# Device Troubleshooting and Testing Report

This report summarizes the troubleshooting protocols, diagnostic workflows, and verification tests used to resolve hardware and software integration issues in the Smart AFO system.

---

## 1. Hardware & I2C Sensor Troubleshooting (MPU6050 IMU)

During system integration, the MPU6050 Inertial Measurement Unit (IMU) occasionally failed to register steps or return acceleration telemetry. Running a standard I2C scanner sketch returned the error: **"Scanning... No I2C devices found"**. 

The following structured diagnostic guide was established to isolate and resolve this physical connection failure:

### A. Pin Mapping & Wire Verification
Ensure the hardware jumper wires are mapped to the correct pins on the Arduino UNO board:
*   **SDA (Serial Data Line):** Must connect to **Analog Pin A4**.
*   **SCL (Serial Clock Line):** Must connect to **Analog Pin A5**.
*   *Note:* Using other analog pins or digital pins (unless using the dedicated SDA/SCL pins near AREF on R3 boards, which are internally bridged to A4/A5) will cause I2C initialization to fail.

### B. Power & Ground Checks
*   **Voltage Supply (VCC):** Connect to the Arduino's **5V** pin (Gy-521 and similar standard MPU6050 breakout boards have an onboard LDO regulator that regulates 5V down to 3.3V safely).
*   **Common Ground (GND):** Connect to one of the Arduino's **GND** pins.
*   **Visual Check:** Verify if the physical LED indicator on the MPU6050 module is glowing. If dark, the chip is not receiving power.

### C. Electrical Contact Integrity
*   **Cold Solder Joints:** Breakout board pins must be **soldered** to the MPU6050 PCB header. Simply inserting the pins into the header pinholes without solder results in intermittent contact, causing capacitive noise on the I2C bus and leading to connection drops.
*   **Jumper Integrity:** Replace single-core breadboard wires if they have internal fractures.

### D. I2C Addressing & Threshold Calibration
*   **Address Verification:** By default, the MPU6050 address is **`0x68`** (with the `AD0` pin pulled low or left floating). If the `AD0` pin is connected to `VCC`, the address shifts to **`0x69`**.
    *   If the scanner finds the device at `0x69`, the microcontroller code's address definition must be updated:
        ```cpp
        const int MPU_ADDR = 0x69;
        ```
*   **Step Detection Sensitivity:** If the hardware works but steps are not counting, the vertical acceleration threshold can be adjusted in the Arduino code (default `1.30` Gs, can be reduced to `1.15` Gs for lighter stepping or gait conditions).

---

## 2. Telemetry Pipeline Diagnostics (App Shows No Data)

When the mobile app connects but displays no data (or zeros), the failure lies in the multi-stage serial/BLE telemetry pipeline. The troubleshooting path follows this sequence:

```
[Sensors] ──(Physical)──> [Arduino Uno] ──(UART Serial)──> [Linux Edge] ──(BLE GATT)──> [Flutter App]
```

### Diagnostics Step 1: Arduino Heartbeat Check
*   **Action:** Check the onboard Arduino LED (pin 13).
*   **Explanation:** The sketch toggles the LED status every 500ms. If the LED is **solid ON** or **completely OFF** and is not flashing, the microcontroller has crashed.
*   **Common Cause:** The standard Arduino `Wire.h` library will block indefinitely (hang) if SCL/SDA lines are shorted or experiencing noise. Reset the board and verify the I2C pull-up resistors or connections.

### Diagnostics Step 2: Serial/RPC Bridge Check (Linux Side)
*   **Action:** Connect to the Linux processor via SSH and query the status of the Python background daemon:
    ```bash
    systemctl status smart-afo
    ```
*   **Action:** Monitor live logs to check if telemetry packages are arriving from the Arduino over the serial UART bridge:
    ```bash
    journalctl -u smart-afo -f -n 50
    ```
    *   *Normal log:* `[Bridge Telemetry] FSR1: ... FSR2: ...`
    *   *Error log (No data):* Displays serial timeouts or BlueZ DBus GATT server warnings.
*   **Action:** If stopped or locked up, restart the service:
    ```bash
    sudo systemctl restart smart-afo
    ```

### Diagnostics Step 3: BLE Connection Verification (Mobile App Side)
*   **Observation:** Verify the BLE status indicator on the app header.
*   **Status: "Scanning..."** or **"Disconnected":** The phone cannot locate the Linux board. Verify Bluetooth is enabled on the phone and check that the Edge Python process is actively advertising.
*   **Status: "Connected" but data is static/empty:** The BLE connection is active, but the Python daemon is not receiving serial packets from the Arduino (refer back to Steps 1 and 2).

---

## 3. Software Build & Compilation Testing

Before generating release packages, software testing was performed to verify code health:

### A. Static Code Analysis
Run static analysis on the Flutter workspace to check for type issues, missing imports, or layout syntax bugs:
```bash
flutter analyze
```
*   **Result:** `No issues found! (ran in 6.7s)`

### B. Release Package Compilation
Compile the application to a release APK to verify build configuration, asset mapping, and tree-shaking optimizations:
```bash
flutter build apk --release
```
*   **Result:** `Built build\app\outputs\flutter-apk\app-release.apk (53.8MB)`
*   **Action:** The resulting APK was successfully loaded and sideloaded onto the test hardware for final integration validation.
