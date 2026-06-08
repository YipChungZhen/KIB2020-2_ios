import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ble_service.dart';
import 'ai_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize BLE service singleton
  await BleService.instance.init();
  
  runApp(const SmartAfoApp());
}

class SmartAfoApp extends StatelessWidget {
  const SmartAfoApp({super.key});

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
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _brandOpacity;
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    _brandOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    // Initialize Video Player Controller
    _videoController = VideoPlayerController.asset('assets/antigravity_logo.webm')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
        }
      });
    _videoController.setVolume(0.0); // Keep muted by default
    _videoController.setLooping(false); // Do not loop

    _controller.forward();

    // Delay video playback to synchronize with the fade-in of the branding section
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _videoController.play();
      }
    });

    // Navigate to Dashboard after 3.8 seconds to give the video enough time to play
    Timer(const Duration(milliseconds: 3800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _videoController.dispose();
    super.dispose();
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
        child: Stack(
          children: [
            // Center Content (Logo and Title)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with fade & scale animation
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/app_icon.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // App Title and Subtitle with fade animation
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _textOpacity.value,
                        child: child,
                      );
                    },
                    child: Column(
                      children: [
                        Text(
                          "AFO SmartLink",
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Intelligent Plantar Biometrics",
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: const Color(0xFF00E5FF),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bottom "powered by [Video]" branding tag
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30.0),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _brandOpacity.value,
                      child: child,
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "powered by",
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white38,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _videoController.value.isInitialized
                          ? SizedBox(
                              width: 200,
                              child: AspectRatio(
                                aspectRatio: _videoController.value.aspectRatio,
                                child: VideoPlayer(_videoController),
                              ),
                            )
                          : const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final BleService _ble = BleService.instance;
  
  // Alert Snooze Timestamp
  DateTime? _snoozeAlertsUntil;
  bool _dismissedThisAlertCycle = false;
  String? _lastAlertMsg;

  // 30s Refresh Countdown State
  int _countdownSeconds = 30;
  Timer? _countdownTimer;
  int? _lastFsr1;
  int? _lastFsr2;
  double? _lastCop;

  // Status dot pulse animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // AI Settings State
  bool _isAiConsented = false;
  String _deepSeekApiKey = "";
  bool _isSimulationMode = true;
  bool _developerSettingsExpanded = false;
  
  // AI Generation State
  String? _aiResponseText;
  bool _isAiLoading = false;
  String? _aiError;
  
  final TextEditingController _apiKeyController = TextEditingController();
  bool _showApiKeyText = false;

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
    // Pulse animation for status dot
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
    
    // Listener to check thresholds and trigger visual warning changes
    _ble.telemetry.addListener(_checkThresholds);
    _startCountdownTimer();

    // Load persisted AI preferences
    _loadPrefs();
  }

  @override
  void dispose() {
    _ble.telemetry.removeListener(_checkThresholds);
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAiConsented = prefs.getBool('isAiConsented') ?? false;
      _deepSeekApiKey = prefs.getString('deepSeekApiKey') ?? "";
      _isSimulationMode = prefs.getBool('isSimulationMode') ?? true;
      _apiKeyController.text = _deepSeekApiKey;
    });
  }

  Future<void> _saveConsent(bool consented) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAiConsented', consented);
    setState(() {
      _isAiConsented = consented;
    });
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deepSeekApiKey', key);
    setState(() {
      _deepSeekApiKey = key;
    });
  }

  Future<void> _saveSimulationMode(bool isSim) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSimulationMode', isSim);
    setState(() {
      _isSimulationMode = isSim;
    });
  }

  void _showConsentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2135),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "AI Gait Insights Consent",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.5),
                    children: const [
                      TextSpan(
                        text: "To generate personalized insights about your gait and foot microclimate, this app uses an artificial intelligence (AI) assistant.\n\n"
                            "By clicking \"I Agree,\" you consent to securely sending your current, anonymized sensor readings (plantar pressure distribution, temperature, and humidity) to a cloud-based AI service for processing. No personally identifiable information (such as your name or location) is transmitted.\n\n",
                      ),
                      TextSpan(
                        text: "Important Medical Disclaimer:\n",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      TextSpan(
                        text: "The AI Analysis feature provides informational summaries only. It is not a diagnostic tool, and its outputs do not constitute medical advice. AI systems can make mistakes. Always consult your biomedical engineer, physical therapist, or physician before making changes to your orthosis, walking habits, or medical treatment.",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveConsent(false);
              },
              child: const Text(
                "Decline & Continue Offline",
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveConsent(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                "I Agree",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _runAiAnalysis(AfoTelemetry data) async {
    setState(() {
      _isAiLoading = true;
      _aiResponseText = null;
      _aiError = null;
    });

    try {
      final double fsr1N = _calculateForceNewton(data.fsr1);
      final double fsr2N = _calculateForceNewton(data.fsr2);
      
      String result;
      if (_isSimulationMode) {
        result = await AiService.simulateAnalysis(
          fsr1Newtons: fsr1N,
          fsr2Newtons: fsr2N,
          temp: data.temperature,
          humidity: data.humidity,
          cop: data.cop,
        );
      } else {
        result = await AiService.analyzeGait(
          apiKey: _deepSeekApiKey,
          fsr1Newtons: fsr1N,
          fsr2Newtons: fsr2N,
          temp: data.temperature,
          humidity: data.humidity,
          cop: data.cop,
        );
      }

      setState(() {
        _aiResponseText = result;
        _isAiLoading = false;
      });
    } catch (e) {
      setState(() {
        _aiError = e.toString().replaceFirst("Exception: ", "");
        _isAiLoading = false;
      });
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdownSeconds > 0) {
            _countdownSeconds--;
          } else {
            _countdownSeconds = 30;
          }
        });
      }
    });
  }

  void _checkThresholds() {
    final data = _ble.telemetry.value;
    if (data == null) return;

    // Self-synchronization logic:
    // If fsr1, fsr2, or cop has changed from the last cached package, it means
    // the 30-second window has refreshed on the board.
    if (_lastFsr1 != data.fsr1 || _lastFsr2 != data.fsr2 || _lastCop != data.cop) {
      _lastFsr1 = data.fsr1;
      _lastFsr2 = data.fsr2;
      _lastCop = data.cop;
      setState(() {
        _countdownSeconds = 30;
      });
    }

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
      // Trigger haptic feedback for new alerts
      if (newAlert != null) {
        HapticFeedback.heavyImpact();
      }
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
                    if (_isSnoozed) _buildSnoozeBanner(),
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
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          final bool isActive = connState == AfoConnectionState.scanning || 
                                                 connState == AfoConnectionState.connecting;
                          final double scale = isActive ? _pulseAnimation.value : 1.0;
                          final double glowOpacity = isActive ? _pulseAnimation.value * 0.6 : 0.5;
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: statusColor.withValues(alpha: glowOpacity),
                                    blurRadius: 8,
                                    spreadRadius: 3,
                                  )
                                ],
                              ),
                            ),
                          );
                        },
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
          final isScanning = _ble.connectionState.value == AfoConnectionState.scanning;
          // Show empty state only if a scan has already run (not scanning anymore)
          if (!isScanning && _ble.connectionState.value == AfoConnectionState.disconnected) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.device_unknown_rounded, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                      const SizedBox(height: 12),
                      Text(
                        "No Smart AFO devices found",
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.white38,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Ensure the orthosis is powered on and nearby",
                        style: TextStyle(fontSize: 12, color: Colors.white24),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
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
                final rssi = result.rssi;
                final signalStrength = rssi > -60 ? "Strong" : rssi > -80 ? "Fair" : "Weak";
                final signalColor = rssi > -60 ? const Color(0xFF10B981) : rssi > -80 ? const Color(0xFFFBBF24) : const Color(0xFFEF4444);
                
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
                      backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                      child: const Icon(Icons.developer_board, color: Color(0xFF8B5CF6)),
                    ),
                    title: Text(
                      deviceName,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(Icons.signal_cellular_alt_rounded, size: 12, color: signalColor),
                        const SizedBox(width: 4),
                        Text(
                          "$signalStrength ($rssi dBm)",
                          style: TextStyle(color: signalColor.withValues(alpha: 0.8), fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            result.device.remoteId.str,
                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
    final bool showBanner = _lastAlertMsg != null && !_dismissedThisAlertCycle && !_isSnoozed;

    return SliverToBoxAdapter(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.15),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: showBanner
              ? Padding(
                  key: const ValueKey('alert_banner'),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.05),
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
                                      HapticFeedback.mediumImpact();
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
                                      HapticFeedback.heavyImpact();
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
                )
              : const SizedBox(
                  key: ValueKey('alert_empty'),
                  width: double.infinity,
                  height: 0,
                ),
        ),
      ),
    );
  }

  /// Snooze indicator banner
  Widget _buildSnoozeBanner() {
    final remaining = _snoozeAlertsUntil?.difference(DateTime.now());
    final minutesLeft = remaining?.inMinutes ?? 0;
    final secondsLeft = remaining?.inSeconds.remainder(60) ?? 0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.3), width: 1.0),
          ),
          child: Row(
            children: [
              const Icon(Icons.snooze_rounded, color: Color(0xFFFBBF24), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Alerts snoozed · Resume in ${minutesLeft}m ${secondsLeft.toString().padLeft(2, '0')}s",
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFFFBBF24),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _snoozeAlertsUntil = null;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFBBF24),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text("Resume", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownTimerSection() {
    final String secondsStr = _countdownSeconds.toString().padLeft(2, '0');
    final double progress = _countdownSeconds / 30.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2135),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2.5,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                ),
                Center(
                  child: Icon(
                    Icons.sync_rounded,
                    color: const Color(0xFF00E5FF),
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "Data refreshes at 00:$secondsStr",
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF00E5FF),
              letterSpacing: 0.2,
            ),
          ),
        ],
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
              _buildCountdownTimerSection(),
              const SizedBox(height: 20),
              _buildMicroclimateSection(data),
              const SizedBox(height: 20),
              _buildBalanceAnalyticsSection(data),
              const SizedBox(height: 20),
              _buildForceGraphSection(data),
              const SizedBox(height: 20),
              _buildAiAnalysisSection(data),
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
          color: copWarning ? const Color(0xFFEF4444).withValues(alpha: 0.5) : Colors.white10, 
          width: 1.2
        ),
        boxShadow: [
          if (copWarning)
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
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
                    color: copGlowColor.withValues(alpha: 0.15),
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
                              color: const Color(0xFF10B981).withValues(alpha: 0.3),
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
                                  color: copGlowColor.withValues(alpha: 0.6),
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
                            style: const TextStyle(fontSize: 11, color: Colors.white38),
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Center", 
                            style: const TextStyle(fontSize: 11, color: Colors.white38),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Lateral", 
                            style: const TextStyle(fontSize: 11, color: Colors.white38),
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
      if (force < 5.0) return const Color(0xFF00FFC2).withValues(alpha: 0.3); // Safe/low pressure
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
          CustomPaint(
            size: const Size(100, 150),
            painter: _FootSoleOutlinePainter(),
          ),
          
          // FSR1 Anterior Zone (Top — tarsals / forefoot)
          Positioned(
            left: 0,
            right: 0,
            top: 12,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: fsr1Size,
                height: fsr1Size,
                decoration: BoxDecoration(
                  color: getForceColor(force1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: getForceColor(force1).withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    force1.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          
          // FSR2 Posterior Zone (Bottom — heel)
          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: fsr2Size,
                height: fsr2Size,
                decoration: BoxDecoration(
                  color: getForceColor(force2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: getForceColor(force2).withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    force2.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
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
              "Posterior (Heel)",
              style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.w500),
            ),
          ),
          
          Positioned(
            top: 4,
            child: Text(
              "Anterior (Tarsals)",
              style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.w500),
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
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF2A2D40),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(1)} N',
                        const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 13),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        double forceNewton = value == 0 ? force1 : force2;
                        String name = value == 0 
                            ? "FSR 1 (Anterior)\n${forceNewton.toStringAsFixed(1)} N" 
                            : "FSR 2 (Posterior)\n${forceNewton.toStringAsFixed(1)} N";
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
                            style: const TextStyle(color: Colors.white30, fontSize: 11),
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
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
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
          color: glowingBorder ? indicatorColor.withValues(alpha: 0.5) : Colors.white10,
          width: glowingBorder ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (glowingBorder)
            BoxShadow(
              color: indicatorColor.withValues(alpha: 0.08),
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
                    color: indicatorColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    indicatorText.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 10,
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

  Widget _buildAiAnalysisSection(AfoTelemetry data) {
    if (!_isAiConsented) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2135),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10, width: 1.0),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.psychology_outlined, color: Color(0xFF00E5FF), size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  "AI Gait Insights",
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Get dynamic biomechanical analysis and foot microclimate safety warnings using DeepSeek V4Pro AI.",
              style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showConsentDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text("Unlock AI Analysis", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2135),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _aiError != null 
              ? const Color(0xFFEF4444).withValues(alpha: 0.4) 
              : Colors.white10, 
          width: 1.0
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.psychology_outlined, color: Color(0xFF00E5FF), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "AI Gait Analysis Service",
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              if (_isSimulationMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "SIMULATION MODE",
                    style: GoogleFonts.outfit(fontSize: 9, color: const Color(0xFFFBBF24), fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (_isAiLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF00E5FF)),
                    const SizedBox(height: 16),
                    Text(
                      _isSimulationMode ? "Generating simulation analysis..." : "Consulting DeepSeek V4Pro AI...",
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            if (_aiResponseText != null) ...[
              // Disclaimer Box at Top of response
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3), width: 1.0),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFEF4444), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "This is an informational Output but not official medical advice under Malaysian Medical Device Act 2012. AI can make mistakes.",
                        style: GoogleFonts.outfit(color: const Color(0xFFFCA5A5), fontSize: 11, height: 1.4, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Response Content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10, width: 1.0),
                ),
                child: Text(
                  _aiResponseText!,
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            if (_aiError != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4), width: 1.0),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _aiError!,
                        style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _runAiAnalysis(data),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _aiResponseText == null ? "Analyze Gait Data" : "Re-Analyze Gait Data",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),
          
          // Collapsible Developer Settings
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                "Developer Settings",
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.white54, fontWeight: FontWeight.bold),
              ),
              trailing: Icon(
                _developerSettingsExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.white38,
                size: 18,
              ),
              onExpansionChanged: (expanded) {
                setState(() {
                  _developerSettingsExpanded = expanded;
                });
              },
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mode Selector Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Simulated Demo Mode",
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          Switch(
                            value: _isSimulationMode,
                            activeThumbColor: const Color(0xFF00E5FF),
                            onChanged: (val) {
                              _saveSimulationMode(val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // API Key Field (Only active/visible if simulation mode is off)
                      if (!_isSimulationMode) ...[
                        Text(
                          "DeepSeek V4Pro API Key",
                          style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _apiKeyController,
                                obscureText: !_showApiKeyText,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.black26,
                                  hintText: "sk-...",
                                  hintStyle: const TextStyle(color: Colors.white24),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.white10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showApiKeyText ? Icons.visibility : Icons.visibility_off,
                                      color: Colors.white38,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showApiKeyText = !_showApiKeyText;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                _saveApiKey(_apiKeyController.text);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("DeepSeek API Key saved locally."),
                                    backgroundColor: Color(0xFF1E2135),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B5CF6),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Your key is encrypted and stored locally. Get a free API key by visiting DeepSeek's console.",
                          style: TextStyle(color: Colors.white24, fontSize: 10, height: 1.3),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Revoke Consent Option
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            _saveConsent(false);
                          },
                          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                          child: const Text("Revoke AI Consent", style: TextStyle(fontSize: 12, decoration: TextDecoration.underline)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for a subtle foot sole outline
class _FootSoleOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Draw a simplified foot sole outline
    // Heel area
    path.moveTo(w * 0.35, h * 0.88);
    path.quadraticBezierTo(w * 0.3, h * 0.92, w * 0.35, h * 0.95);
    path.quadraticBezierTo(w * 0.5, h * 0.97, w * 0.65, h * 0.95);
    path.quadraticBezierTo(w * 0.7, h * 0.92, w * 0.65, h * 0.88);
    // Arch
    path.quadraticBezierTo(w * 0.55, h * 0.7, w * 0.5, h * 0.55);
    // Forefoot
    path.quadraticBezierTo(w * 0.55, h * 0.35, w * 0.72, h * 0.2);
    // Toe area
    path.quadraticBezierTo(w * 0.78, h * 0.12, w * 0.65, h * 0.1);
    path.quadraticBezierTo(w * 0.45, h * 0.08, w * 0.28, h * 0.2);
    path.quadraticBezierTo(w * 0.22, h * 0.35, w * 0.3, h * 0.55);
    path.close();

    canvas.drawPath(path, paint);

    // Draw center line for visual reference
    final centerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(w * 0.5, h * 0.1),
      Offset(w * 0.5, h * 0.95),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
