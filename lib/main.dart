import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize BLE service singleton
  await BleService.instance.init();
  
  runApp(const SmartAfoApp());
}

class SmartAfoApp extends StatelessWidget {
  const SmartAfoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AFO SmartLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F111E),
        primaryColor: const Color(0xFF00E5FF),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF8B5CF6),
          surface: Color(0xFF1E2135),
          error: Color(0xFFEF4444),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final BleService _ble = BleService.instance;
  
  // Alert Snooze Timestamp
  DateTime? _snoozeAlertsUntil;
  bool _dismissedThisAlertCycle = false;
  String? _lastAlertMsg;

  double _calculateForceNewton(int adc) {
    if (adc >= 1022) return 0.0; // no force applied
    int normalizedAdc = adc <= 1 ? 1 : adc;
    
    const double rSeries = 10000.0; // 10k ohm resistor
    final double rFsr = rSeries * normalizedAdc / (1023.0 - normalizedAdc);
    if (rFsr <= 0) return 0.0;
    
    final double conductance = 1000000.0 / rFsr;
    double force;
    if (conductance <= 1000.0) {
      force = conductance / 80.0;
    } else {
      force = (conductance - 1000.0) / 30.0;
    }
    return force > 100.0 ? 100.0 : force;
  }

  @override
  void initState() {
    super.initState();
    // Listener to check thresholds and trigger visual warning changes
    _ble.telemetry.addListener(_checkThresholds);
  }

  @override
  void dispose() {
    _ble.telemetry.removeListener(_checkThresholds);
    super.dispose();
  }

  void _checkThresholds() {
    final data = _ble.telemetry.value;
    if (data == null) return;

    // Threshold logic:
    // Asymmetry is defined when weight is shifted significantly to one side (|COP| > 0.40)
    bool isUnbalanced = data.cop.abs() > 0.40;
    // Temp > 35.0°C indicates skin risk
    bool isHot = data.temperature > 35.0;
    // Humidity > 75.0% indicates sweating / maceration risk
    bool isHumid = data.humidity > 75.0;

    String? newAlert;
    if (isUnbalanced) {
      newAlert = "Force Imbalance! Leaning heavily to the ${data.cop > 0 ? 'Lateral' : 'Medial'} side.";
    } else if (isHot) {
      newAlert = "High Orthosis Temp (${data.temperature.toStringAsFixed(1)}°C)! Risk of skin maceration.";
    } else if (isHumid) {
      newAlert = "Moisture Warning (${data.humidity.toStringAsFixed(1)}%)! Risk of sweat buildup.";
    }

    if (newAlert != _lastAlertMsg) {
      setState(() {
        _lastAlertMsg = newAlert;
        _dismissedThisAlertCycle = false; // Reset dismiss flag for new alert messages
      });
    }
  }

  bool get _isSnoozed {
    if (_snoozeAlertsUntil == null) return false;
    return DateTime.now().isBefore(_snoozeAlertsUntil!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0D18), Color(0xFF13172E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ValueListenableBuilder<AfoConnectionState>(
            valueListenable: _ble.connectionState,
            builder: (context, connState, _) {
              final isConnected = connState == AfoConnectionState.connected;
              
              return CustomScrollView(
                slivers: [
                  _buildHeader(connState),
                  
                  if (!isConnected) ...[
                    _buildScannerPrompt(connState),
                    _buildDeviceList(),
                  ] else ...[
                    _buildActiveAlertBanner(),
                    _buildMetricsSection(),
                  ]
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // --- UI Components ---

  /// Header App Bar
  Widget _buildHeader(AfoConnectionState connState) {
    String statusText = "Disconnected";
    Color statusColor = Colors.grey;
    bool isScanning = connState == AfoConnectionState.scanning;

    if (connState == AfoConnectionState.connected) {
      statusText = "Connected";
      statusColor = const Color(0xFF00FFC2);
    } else if (connState == AfoConnectionState.scanning) {
      statusText = "Scanning...";
      statusColor = const Color(0xFFFBBF24);
    } else if (connState == AfoConnectionState.connecting) {
      statusText = "Connecting...";
      statusColor = const Color(0xFF38BDF8);
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "AFO SmartLink",
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (connState == AfoConnectionState.connected)
              Flexible(
                child: OutlinedButton(
                  onPressed: () => _ble.disconnect(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bluetooth_disabled, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          "Disconnect",
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (!isScanning)
              Flexible(
                child: ElevatedButton(
                  onPressed: () => _ble.startScan(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          "Scan Devices",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: TextButton(
                  onPressed: () => _ble.stopScan(),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Stop Scan",
                          style: const TextStyle(color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Scanner Prompt when not connected
  Widget _buildScannerPrompt(AfoConnectionState connState) {
    bool isScanning = connState == AfoConnectionState.scanning;

    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            children: [
              Icon(
                isScanning ? Icons.bluetooth_searching : Icons.bluetooth,
                size: 80,
                color: isScanning ? const Color(0xFF00E5FF) : Colors.white24,
              ),
              const SizedBox(height: 16),
              Text(
                isScanning ? "Looking for Smart AFO..." : "Connect Orthosis Device",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isScanning 
                    ? "Ensure the orthosis microprocessor core is powered on and within range."
                    : "Scan to locate and bind the Bluetooth Low Energy telemetry server.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Device Scan Results List
  Widget _buildDeviceList() {
    return ValueListenableBuilder<List<ScanResult>>(
      valueListenable: _ble.scanResults,
      builder: (context, results, _) {
        if (results.isEmpty) {
          return const SliverToBoxAdapter(
            child: SizedBox.shrink(),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final result = results[index];
                final deviceName = result.device.platformName.isNotEmpty 
                    ? result.device.platformName 
                    : "Unknown Device";
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: const Color(0xFF1E2137),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.white10, width: 1.0),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.2),
                      child: const Icon(Icons.developer_board, color: Color(0xFF8B5CF6)),
                    ),
                    title: Text(
                      deviceName,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    subtitle: Text(
                      result.device.remoteId.str,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _ble.connectToDevice(result.device),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Connect", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              },
              childCount: results.length,
            ),
          ),
        );
      },
    );
  }

  /// Active warning alert banner at the top of the dashboard
  Widget _buildActiveAlertBanner() {
    if (_lastAlertMsg == null || _dismissedThisAlertCycle || _isSnoozed) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Safety System Warning",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _lastAlertMsg!,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _dismissedThisAlertCycle = true;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text("Dismiss", style: TextStyle(fontSize: 12, decoration: TextDecoration.underline)),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _snoozeAlertsUntil = DateTime.now().add(const Duration(minutes: 5));
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text("Snooze (5m)", style: TextStyle(fontSize: 12, decoration: TextDecoration.underline)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dashboard Metrics Section
  Widget _buildMetricsSection() {
    return ValueListenableBuilder<AfoTelemetry?>(
      valueListenable: _ble.telemetry,
      builder: (context, data, _) {
        if (data == null) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00E5FF)),
                  SizedBox(height: 16),
                  Text("Waiting for initial data stream...", style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildMicroclimateSection(data),
              const SizedBox(height: 20),
              _buildBalanceAnalyticsSection(data),
              const SizedBox(height: 20),
              _buildForceGraphSection(data),
              const SizedBox(height: 30),
            ]),
          ),
        );
      },
    );
  }

  /// Microclimate Section (Temp & Humidity Cards)
  Widget _buildMicroclimateSection(AfoTelemetry data) {
    bool tempWarning = data.temperature > 35.0;
    bool humidWarning = data.humidity > 75.0;

    return Row(
      children: [
        Expanded(
          child: _buildGlassCard(
            title: "Microclimate Temp",
            value: "${data.temperature.toStringAsFixed(1)}°C",
            icon: Icons.thermostat_outlined,
            indicatorText: tempWarning ? "Maceration Risk" : "Safe Climate",
            indicatorColor: tempWarning ? const Color(0xFFEF4444) : const Color(0xFF10B981),
            iconColor: const Color(0xFFF87171),
            glowingBorder: tempWarning,
            gradient: const LinearGradient(
              colors: [Color(0xFF2E1A22), Color(0xFF1E2135)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildGlassCard(
            title: "Foot Humidity",
            value: "${data.humidity.toStringAsFixed(1)}%",
            icon: Icons.water_drop_outlined,
            indicatorText: humidWarning ? "Sweat Warning" : "Optimal dryness",
            indicatorColor: humidWarning ? const Color(0xFFFBBF24) : const Color(0xFF10B981),
            iconColor: const Color(0xFF60A5FA),
            glowingBorder: humidWarning,
            gradient: const LinearGradient(
              colors: [Color(0xFF1D2840), Color(0xFF1E2135)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ],
    );
  }

  /// Balance and COP Analytics Card
  Widget _buildBalanceAnalyticsSection(AfoTelemetry data) {
    // Determine pointer offset for COP visualization
    // data.cop goes from -1.0 (Medial) to +1.0 (Lateral)
    double alignmentVal = (data.cop + 1.0) / 2.0; // Normalized to 0.0 - 1.0
    alignmentVal = alignmentVal.clamp(0.0, 1.0);

    bool copWarning = data.cop.abs() > 0.40;
    Color copGlowColor = copWarning ? const Color(0xFFEF4444) : const Color(0xFF00FFC2);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2135),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: copWarning ? const Color(0xFFEF4444).withOpacity(0.5) : Colors.white10, 
          width: 1.2
        ),
        boxShadow: [
          if (copWarning)
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              blurRadius: 12,
              spreadRadius: 2,
            )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Center of Pressure (COP) Balance",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: copGlowColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    copWarning ? "UNBALANCED" : "STABLE",
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: copGlowColor,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Foot Heatmap Graphic & Sliding COP Track
          Row(
            children: [
              // 1. Dynamic Foot Sole Visualizer
              _buildFootSoleVisualizer(data),
              const SizedBox(width: 24),
              
              // 2. Sliding Center of Pressure indicator scale
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Lateral Shift Monitor",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.cop == 0 
                          ? "Perfect Alignment" 
                          : "${(data.cop.abs() * 100).toStringAsFixed(0)}% Shifted ${data.cop > 0 ? 'Lateral' : 'Medial'}",
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    
                    // COP slider line
                    Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // Background track line
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        // Safe middle zone indicator
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 60,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        // Slider indicator knob
                        AnimatedAlign(
                          duration: const Duration(milliseconds: 100),
                          alignment: Alignment(data.cop, 0),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: copGlowColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: copGlowColor.withOpacity(0.6),
                                  blurRadius: 8,
                                  spreadRadius: 3,
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Medial", 
                            style: const TextStyle(fontSize: 9, color: Colors.white38),
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Center", 
                            style: const TextStyle(fontSize: 9, color: Colors.white38),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Lateral", 
                            style: const TextStyle(fontSize: 9, color: Colors.white38),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Foot Sole pressure illustration
  Widget _buildFootSoleVisualizer(AfoTelemetry data) {
    final double force1 = _calculateForceNewton(data.fsr1);
    final double force2 = _calculateForceNewton(data.fsr2);

    // Scale size of sensors according to force in Newtons (0 - 100)
    double fsr1Size = 25 + (force1 / 100.0) * 35;
    double fsr2Size = 25 + (force2 / 100.0) * 35;

    // Color based on force level (calibrated in Newtons)
    Color getForceColor(double force) {
      if (force < 5.0) return const Color(0xFF00FFC2).withOpacity(0.3); // Safe/low pressure
      if (force < 45.0) return const Color(0xFF8B5CF6); // Moderate pressure
      return const Color(0xFFEF4444); // High/danger pressure
    }

    return Container(
      width: 100,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white10, width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Foot outline graphic overlay
          Opacity(
            opacity: 0.15,
            child: Icon(Icons.accessibility_new, size: 80, color: Colors.white),
          ),
          
          // Medial FSR1 Zone (Left position on display representing medial side of foot sole)
          Positioned(
            left: 15,
            top: 40,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: fsr1Size,
              height: fsr1Size,
              decoration: BoxDecoration(
                color: getForceColor(force1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: getForceColor(force1).withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Center(
                child: Text(
                  "${force1.toStringAsFixed(0)}",
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
          
          // Lateral FSR2 Zone (Right position on display representing lateral side of foot sole)
          Positioned(
            right: 15,
            top: 40,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: fsr2Size,
              height: fsr2Size,
              decoration: BoxDecoration(
                color: getForceColor(force2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: getForceColor(force2).withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Center(
                child: Text(
                  "${force2.toStringAsFixed(0)}",
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
          
          // Dynamic COP Pointer showing calculated balance on foot sole itself
          Positioned(
            top: 45,
            left: 50 + (data.cop * 20) - 6,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 4, spreadRadius: 1)
                ],
              ),
            ),
          ),
          
          Positioned(
            bottom: 12,
            child: Text(
              "Plantar Sole",
              style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w500),
            ),
          )
        ],
      ),
    );
  }

  /// Live Bar Chart Section
  Widget _buildForceGraphSection(AfoTelemetry data) {
    final double force1 = _calculateForceNewton(data.fsr1);
    final double force2 = _calculateForceNewton(data.fsr2);

    return Container(
      height: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2135),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Plantar Sensors Force Comparison",
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        double forceNewton = value == 0 ? force1 : force2;
                        String name = value == 0 
                            ? "FSR 1 (Medial)\n${forceNewton.toStringAsFixed(1)} N" 
                            : "FSR 2 (Lateral)\n${forceNewton.toStringAsFixed(1)} N";
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value % 25 == 0) {
                          return Text(
                            "${value.toInt()} N",
                            style: const TextStyle(color: Colors.white30, fontSize: 10),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.white12, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: force1,
                        width: 50,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF00FFC2)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: force2,
                        width: 50,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF00E5FF)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Glassmorphic Stat Card template helper
  Widget _buildGlassCard({
    required String title,
    required String value,
    required IconData icon,
    required String indicatorText,
    required Color indicatorColor,
    required Color iconColor,
    required bool glowingBorder,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: glowingBorder ? indicatorColor.withOpacity(0.5) : Colors.white10,
          width: glowingBorder ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (glowingBorder)
            BoxShadow(
              color: indicatorColor.withOpacity(0.08),
              blurRadius: 10,
              spreadRadius: 1,
            )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 4),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: indicatorColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    indicatorText.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 8,
                      color: indicatorColor,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
