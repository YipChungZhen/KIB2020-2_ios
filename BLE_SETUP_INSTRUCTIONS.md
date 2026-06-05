# Bluetooth Low Energy (BLE) Platform Configuration

To run the Smart AFO App on iOS and Android devices, you must add the necessary Bluetooth and Location permissions to the native configurations.

---

## 1. Android Configuration

Open `android/app/src/main/AndroidManifest.xml` and add the following permission tags inside the `<manifest>` tag, above the `<application>` tag:

```xml
    <!-- Bluetooth Permissions for API 31+ (Android 12+) -->
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" 
                     android:usesPermissionFlags="neverForLocation" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    
    <!-- Legacy Bluetooth Permissions for API 30 and below (Android 11 and older) -->
    <uses-permission android:name="android.permission.BLUETOOTH" 
                     android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" 
                     android:maxSdkVersion="30" />

    <!-- Location Permission (required for BLE scanning on older Android versions) -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    
    <!-- Optional: Declare that the app uses Bluetooth Low Energy features -->
    <uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
```

*Note: Since Android 12, adding `neverForLocation` to `BLUETOOTH_SCAN` tells Android that your app does not use BLE to determine physical location. If your app does not need location, this is the recommended setting. If you need fine location, remove the flag.*

---

## 2. iOS Configuration

Open `ios/Runner/Info.plist` and add the following keys to declare Bluetooth usage (inside the main `<dict>` block):

```xml
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>This app requires Bluetooth access to connect to the smart orthosis sensors and read real-time plantar force and microclimate data.</string>
    
    <key>NSBluetoothPeripheralUsageDescription</key>
    <string>This app requires Bluetooth access to connect to the smart orthosis sensors and read real-time plantar force and microclimate data.</string>
```

---

## 3. Flutter Bluetooth SDK Behavior

The `flutter_blue_plus` package will:
- Automatically check and prompt for these permissions when you initiate a scan (`FlutterBluePlus.startScan()`).
- Direct the user to system settings if permissions are denied or Bluetooth is turned off.
- Monitor adapter state (on, off, turning_on, unauthorized).
