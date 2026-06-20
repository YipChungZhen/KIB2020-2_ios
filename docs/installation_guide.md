# Installation Guide: Smart AFO System

This document provides step-by-step instructions for assembling, wiring, and mounting the physical hardware components of the Smart AFO, as well as installing and deploying the software components across the microcontroller, edge gateway, and mobile device.

---

## 1. Hardware Installation & Assembly

### A. Sensor Mounting and Placement
*   **Plantar Force Sensors (FSR406):**
    *   **FSR1 (Anterior/Medial):** Secure to the front-inner region of the orthosis footplate (under the metatarsals/forefoot).
    *   **FSR2 (Posterior/Lateral):** Secure to the back-outer region of the footplate (under the heel cup).
    *   **Mounting Instruction:** Clean the plastic footplate surface. Apply thin, double-sided adhesive tape to the back of the FSR pads. Avoid applying tape or adhesive directly to the active sensing grid areas to prevent constant pressure offset.
    *   **Routing:** Run the flexible tail ribbons along the outer borders of the foot sole. Use protective heat-shrink tubing or cable wrap along the vertical ankle strut to secure the wires and protect them from shear stress.
*   **6-Axis IMU (MPU6050):**
    *   **Placement:** Mount the breakout board flat and rigid on the vertical strut of the AFO frame (near the ankle hinge).
    *   **Orientation:** Mount it facing forward ($X$-axis pointing forward, $Y$-axis pointing vertically upward, and $Z$-axis pointing outward). The board must be rigidly fixed (using screws or heavy-duty mounting tape) so structural vibration is captured accurately.
*   **Microclimate Sensor (DHT11):**
    *   **Placement:** Mount inside the upper calf portion of the plastic shell.
    *   **Instruction:** Ensure the sensor's blue ventilation grid is exposed to the microclimate space between the user's leg and the plastic brace (do not cover it with foam padding).

### B. Controller Enclosure
*   Mount the Arduino UNO Q/Linux dual-processor board assembly inside a custom 3D-printed ventilated enclosure.
*   Secure the enclosure to the upper calf strap of the AFO using mounting slots or heavy-duty hook-and-loop straps.

### C. Wiring Diagram & Pin Connections
Ensure all physical connections match the following terminal mapping:

```
[MPU6050 IMU]      [Arduino UNO Q]
  VCC       ─────>   5V
  GND       ─────>   GND
  SDA       ─────>   Analog Pin A4 (with 4.7k Pull-up Resistor)
  SCL       ─────>   Analog Pin A5 (with 4.7k Pull-up Resistor)

[DHT11 Sensor]     [Arduino UNO Q]
  VCC       ─────>   5V
  GND       ─────>   GND
  DATA      ─────>   Digital Pin D4

[FSR1 (Medial)]    [Arduino UNO Q]
  Pin 1     ─────>   5V
  Pin 2     ─────>   Analog Pin A0  <───> [10k Pull-down Resistor] <───> GND

[FSR2 (Lateral)]   [Arduino UNO Q]
  Pin 1     ─────>   5V
  Pin 2     ─────>   Analog Pin A1  <───> [10k Pull-down Resistor] <───> GND
```

---

## 2. Software Installation & Deployment

The software setup is divided into Firmware Flashing, Edge Service Configuration, and Mobile Application Sideloading.

### A. MCU Firmware Installation (Arduino UNO Q)
1.  **Install Toolchain:** Download and install the [Arduino IDE](https://www.arduino.cc/en/software).
2.  **Install Dependency Libraries:** Open the Arduino Library Manager (`Ctrl+Shift+I`) and install:
    *   `DHT sensor library` (by Adafruit)
    *   `Adafruit Unified Sensor`
    *   `Arduino_RouterBridge` (packaged with the Uno Q Core platform files)
3.  **Compile & Flash:**
    *   Connect the Arduino UNO board to your computer via USB.
    *   Open the firmware file: [SmartAFO_UNO_Q.ino](file:///c:/Users/User/.gemini/antigravity-ide/scratch/SmartAFO_MCU/SmartAFO_UNO_Q/SmartAFO_UNO_Q.ino).
    *   Select **Tools > Board > Arduino Uno**.
    *   Select **Tools > Port** and choose your active COM port.
    *   Press the **Upload** ($\rightarrow$) button.
    *   *Verification:* Verify the onboard LED (pin 13) blinks at 1Hz, indicating the main event loop is running successfully.

### B. Linux Edge Processor Installation
1.  **Transfer Script files:** Copy `afo_edge_processor.py` and `smart-afo.service` to the onboard Linux filesystem (via SCP or SFTP):
    *   `afo_edge_processor.py` $\rightarrow$ `/home/arduino/afo_edge_processor.py`
    *   `smart-afo.service` $\rightarrow$ `/etc/systemd/system/smart-afo.service`
2.  **Install Linux Python Dependencies:** Access the Linux shell terminal via SSH and install the required Python system packages:
    ```bash
    sudo apt-get update
    sudo apt-get install python3-dbus python3-gi python3-numpy python3-serial
    ```
3.  **Enable and Start Systemd Daemon Service:**
    ```bash
    # Reload systemd configuration
    sudo systemctl daemon-reload
    
    # Enable autostart on system boot
    sudo systemctl enable smart-afo
    
    # Start the daemon process
    sudo systemctl start smart-afo
    ```
4.  **Confirm Execution:** Verify the service status:
    ```bash
    systemctl status smart-afo
    ```

### C. Mobile Application Installation (Companion App)

#### For Android Devices (Sideloading):
1.  Download the compiled release package file to your Android phone:
    *   **Download:** [app-release.apk](file:///C:/Users/User/.gemini/antigravity-ide/brain/93f24edd-0bc5-41d3-b9a6-525c69f5a6f7/app-release.apk)
2.  Open your Android File Manager app and tap on the downloaded `.apk` file.
3.  If prompted, enable the system setting **"Allow installation of apps from unknown sources"**.
4.  Follow the prompts to complete installation and launch **Smart AFO Link**.

#### For iOS Devices (Sideloading):
1.  Download **Sideloadly** (Windows/macOS) or **AltStore** onto your computer.
2.  Connect your iPhone to the computer via USB.
3.  Launch the sideloading tool, drag the compiled **`Runner.ipa`** file into the tool window, and sign it using your Apple ID.
4.  Click install to load the app onto your phone.
5.  On the iPhone, open **Settings > General > VPN & Device Management**, find your Apple ID under Developer App, and tap **Trust**.
6.  *(iOS 16+)* Go to **Settings > Privacy & Security > Developer Mode**, toggle it **ON**, and reboot your iPhone.
