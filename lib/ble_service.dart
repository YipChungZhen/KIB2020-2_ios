import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Telemetry data model representing the decoded AFO metrics.
class AfoTelemetry {
  final int fsr1;           // Medial force sensor (0 - 1023)
  final int fsr2;           // Lateral force sensor (0 - 1023)
  final double temperature; // Under-foot temperature in Celsius
  final double humidity;    // Under-foot relative humidity in %
  final double cop;         // Calculated Center of Pressure (-1.0 to +1.0)
  final DateTime timestamp;

  AfoTelemetry({
    required this.fsr1,
    required this.fsr2,
    required this.temperature,
    required this.humidity,
    required this.cop,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'AFO Data: FSR1=$fsr1, FSR2=$fsr2, Temp=${temperature.toStringAsFixed(1)}°C, '
           'Humid=${humidity.toStringAsFixed(1)}%, COP=${cop.toStringAsFixed(2)}';
  }
}

/// BLE Connection State Enum
enum AfoConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
}

/// BLE Handling Service (Singleton)
class BleService {
  // UUIDs matching the Linux BLE GATT Server
  static const String serviceUuidStr = "af00c200-7d5f-4ff0-91f0-dffc27d5fff0";
  static const String charUuidStr = "af00c201-7d5f-4ff0-91f0-dffc27d5fff0";

  final Guid _serviceUuid = Guid(serviceUuidStr);
  final Guid _charUuid = Guid(charUuidStr);

  // Private constructor
  BleService._internal();
  static final BleService instance = BleService._internal();

  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSub;
  StreamSubscription<List<int>>? _valueNotificationSub;

  // Notifiers for UI binding
  final ValueNotifier<AfoConnectionState> connectionState = 
      ValueNotifier<AfoConnectionState>(AfoConnectionState.disconnected);
  
  final ValueNotifier<AfoTelemetry?> telemetry = 
      ValueNotifier<AfoTelemetry?>(null);

  final ValueNotifier<List<ScanResult>> scanResults = 
      ValueNotifier<List<ScanResult>>([]);

  StreamSubscription<List<ScanResult>>? _scanResultsSub;

  /// Setup listeners for adapter state and permissions
  Future<void> init() async {
    // Monitor system Bluetooth Adapter state (On/Off)
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      debugPrint('BLE: Adapter state is $state');
      if (state == BluetoothAdapterState.off) {
        _handleDisconnect();
      }
    });

    // Setup scan results subscription (filtering for AFO device by name)
    _scanResultsSub = FlutterBluePlus.scanResults.listen((results) {
      scanResults.value = results.where((r) {
        final name = r.device.platformName.toLowerCase();
        return name.contains("smart-afo") || name.contains("orthosis") || r.advertisementData.localName.toLowerCase().contains("smart-afo");
      }).toList();
    });
  }

  /// Start scanning for devices advertising the AFO Service
  Future<void> startScan() async {
    if (connectionState.value == AfoConnectionState.scanning || 
        connectionState.value == AfoConnectionState.connected) {
      return;
    }

    connectionState.value = AfoConnectionState.scanning;
    scanResults.value = [];

    try {
      // Check if Bluetooth is turned on
      if (await FlutterBluePlus.isSupported == false) {
        debugPrint("BLE: Bluetooth not supported on this device.");
        connectionState.value = AfoConnectionState.disconnected;
        return;
      }

      // Turn on Bluetooth if off (Android only)
      if (defaultTargetPlatform == TargetPlatform.android) {
        await FlutterBluePlus.turnOn();
      }

      // Scan for all nearby Bluetooth devices (filtering by name in the results listener)
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
      );

      // Automatically set state back to disconnected once scan finishes
      FlutterBluePlus.isScanning.listen((isScanning) {
        if (!isScanning && connectionState.value == AfoConnectionState.scanning) {
          connectionState.value = AfoConnectionState.disconnected;
        }
      });
    } catch (e) {
      debugPrint("BLE: Scan Error: $e");
      connectionState.value = AfoConnectionState.disconnected;
    }
  }

  /// Stop active BLE scans
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    if (connectionState.value == AfoConnectionState.scanning) {
      connectionState.value = AfoConnectionState.disconnected;
    }
  }

  /// Connect to the selected Bluetooth Device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    await stopScan();
    connectionState.value = AfoConnectionState.connecting;
    _connectedDevice = device;

    try {
      // Connect to peripheral (complying with the nonprofit license terms)
      await device.connect(license: License.nonprofit, autoConnect: false, timeout: const Duration(seconds: 8));

      // Listen to connection state updates
      _connectionStateSub = device.connectionState.listen((BluetoothConnectionState state) {
        debugPrint('BLE: Device Connection State: $state');
        if (state == BluetoothConnectionState.connected) {
          connectionState.value = AfoConnectionState.connected;
          _discoverAfoServices(device);
        } else if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnect();
        }
      });

      return true;
    } catch (e) {
      debugPrint("BLE: Connection Failed: $e");
      _handleDisconnect();
      return false;
    }
  }

  /// Discover GATT Services and Subscribe to telemetry characteristic notifications
  Future<void> _discoverAfoServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      BluetoothCharacteristic? telemetryChar;

      for (var service in services) {
        if (service.uuid == _serviceUuid) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid == _charUuid) {
              telemetryChar = characteristic;
              break;
            }
          }
        }
      }

      if (telemetryChar != null) {
        debugPrint("BLE: Found AFO Service and Characteristic. Subscribing...");
        
        // Enable notifications on the server
        await telemetryChar.setNotifyValue(true);
        
        // Listen for data streams
        _valueNotificationSub = telemetryChar.onValueReceived.listen((value) {
          _parseBinaryPayload(value);
        });
      } else {
        debugPrint("BLE: AFO Characteristic not found. Disconnecting...");
        disconnect();
      }
    } catch (e) {
      debugPrint("BLE: Error during service discovery: $e");
      disconnect();
    }
  }

  /// Unpack binary structure: struct.pack('<HHfff', fsr1, fsr2, temp, humidity, cop)
  /// Byte index offsets:
  /// [0-1]  : fsr1 (uint16, 2 bytes)
  /// [2-3]  : fsr2 (uint16, 2 bytes)
  /// [4-7]  : temperature (float32, 4 bytes)
  /// [8-11] : humidity (float32, 4 bytes)
  /// [12-15]: center of pressure (float32, 4 bytes)
  void _parseBinaryPayload(List<int> rawBytes) {
    if (rawBytes.length < 16) {
      debugPrint("BLE: Ignored invalid packet, length: ${rawBytes.length}");
      return;
    }

    try {
      final bytes = Uint8List.fromList(rawBytes);
      final byteData = ByteData.sublistView(bytes);

      // Read Little Endian bytes
      int fsr1 = byteData.getUint16(0, Endian.little);
      int fsr2 = byteData.getUint16(2, Endian.little);
      double temp = byteData.getFloat32(4, Endian.little);
      double humidity = byteData.getFloat32(8, Endian.little);
      double cop = byteData.getFloat32(12, Endian.little);

      // Create new telemetry snapshot and publish to listeners
      telemetry.value = AfoTelemetry(
        fsr1: fsr1,
        fsr2: fsr2,
        temperature: temp,
        humidity: humidity,
        cop: cop,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint("BLE: Payload parsing exception: $e");
    }
  }

  /// Disconnect current BLE device
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        debugPrint("BLE: Error during disconnect call: $e");
      }
    }
    _handleDisconnect();
  }

  /// Reset internal variables on disconnect
  void _handleDisconnect() {
    _connectionStateSub?.cancel();
    _valueNotificationSub?.cancel();
    _connectionStateSub = null;
    _valueNotificationSub = null;
    _connectedDevice = null;
    telemetry.value = null;
    connectionState.value = AfoConnectionState.disconnected;
    debugPrint("BLE: Disconnected & Telemetry Reset.");
  }

  /// Clean up variables on application destruction
  void dispose() {
    disconnect();
    _scanResultsSub?.cancel();
  }
}
