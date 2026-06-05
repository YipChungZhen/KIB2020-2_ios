# Update Log - Smart AFO Mobile App
**Date:** June 5, 2026

This log documents the updates made to the Smart AFO Flutter application, including launcher icon integration, sensor calibration mathematics, and deployment/CI configuration.

---

## 1. Custom App Icon Integration
* **Asset Added:** Integrated the user's custom medical/orthosis graphic as the official app launcher icon ([app_icon.jpg](file:///c:/Users/User/.gemini/antigravity-ide/scratch/smart_afo_app/assets/app_icon.jpg)).
* **Configured Builder:** Added the `flutter_launcher_icons` dependency to `pubspec.yaml` and set it up to generate native platform launcher icons for both platforms.
* **Outputs Generated:** Successfully compiled and generated all launcher formats:
  * **Android:** Native launcher icon mipmap sizes (`mipmap-hdpi`, `mipmap-mdpi`, `mipmap-xhdpi`, `mipmap-xxhdpi`, `mipmap-xxxhdpi`).
  * **iOS:** Native `AppIcon.appiconset` folder formats within `Assets.xcassets`.

---

## 2. Plantar Sensors Force Calibration (FSR406)
Replaced the initial linear force mapping with the standard non-linear calibration curve for the FSR406 sensors to improve accuracy.
* **Math Formulas Implemented:**
  1. **Sensor Resistance ($R_{FSR}$):** 
     $$R_{FSR} = 10\,000.0 \times \left( \frac{1023.0 - \text{adc}}{\text{adc}} \right)$$
  2. **Sensor Conductance ($G$ in microSiemens):** 
     $$G = \frac{1\,000\,000.0}{R_{FSR}}$$
  3. **Force ($F$ in Newtons):** 
     $$F = \begin{cases} \frac{G}{80.0} & \text{if } G \le 1000.0 \\ \frac{G - 1000.0}{30.0} & \text{if } G > 1000.0 \end{cases}$$
* **UI Adjustments (Force Graph):**
  * **Range:** Expanded the chart display maximum (`maxY`) to `100 N` (clamping values above `100 N` to prevent spikes from breaking UI layout).
  * **Labels:** Set clean gridline increments and Y-axis labels at intervals of `25 N` (`0 N`, `25 N`, `50 N`, `75 N`, `100 N`).

---

## 3. Platform Configuration & Deployment
* **iOS Permissions:** Added the required Bluetooth Low Energy permissions (`NSBluetoothAlwaysUsageDescription` and `NSBluetoothPeripheralUsageDescription`) to `ios/Runner/Info.plist` to prevent runtime iOS device crashes.
* **Codemagic YAML Integration:** Created a custom [codemagic.yaml](file:///c:/Users/User/.gemini/antigravity-ide/scratch/smart_afo_app/codemagic.yaml) file to compile the unsigned `.app` package and package it manually into an `.ipa` archive, bypassing GUI scheme check bugs.
* **Builds Completed:**
  * **Android APK:** Generated the release APK at `build\app\outputs\flutter-apk\app-release.apk` (45.5 MB).
  * **iOS IPA:** Compiled `Runner.ipa` via Codemagic cloud build.
