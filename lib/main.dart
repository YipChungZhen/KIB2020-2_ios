import 'dart:async';
import 'dart:ui';
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
    _videoController = VideoPlayerController.asset('assets/splash_branding.mp4')
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1D0B2E), // Deep purple fade
              Color(0xFF0A1024), // Deep blue fade
              Colors.black,      // Solid black
              Colors.black,
            ],
            stops: [0.0, 0.4, 0.75, 1.0],
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
                      const SizedBox(height: 2),
                      _videoController.value.isInitialized
                          ? SizedBox(
                              width: 200,
                              child: AspectRatio(
                                aspectRatio: _videoController.value.aspectRatio,
                                child: VideoPlayer(_videoController),
                              ),
                            )
                          : const SizedBox(
                              width: 200,
                              height: 40,
                              child: Center(
                                child: Text(
                                  "Loading…",
                                  style: TextStyle(color: Colors.white24, fontSize: 12),
                                ),
                              ),
                            ),
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
  
  int _selectedIndex = 0;

  // Alert Snooze Timestamp
  DateTime? _snoozeAlertsUntil;
  bool _dismissedThisAlertCycle = false;
  String? _lastAlertMsg;

  // 30s Refresh Countdown State
  int _countdownSeconds = 30;
  Timer? _countdownTimer;


  // COP 30s Countdown History State
  int _stepGoal = 5000;
  TextEditingController? _stepGoalController;
  final List<FlSpot> _currentCopWindow = [];
  List<FlSpot> _lastCopWindow = [];
  DateTime? _cycleStartTime;

  // Status dot pulse animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // AI Settings State
  bool _isAiConsented = false;
  String _deepSeekApiKey = "sk-352248d215c5440b84e7f7263cfede53";
  bool _isSimulationMode = true;
  bool _developerSettingsExpanded = false;
  bool _isWifiPermissionGranted = false;
  
  // AI Generation State
  String? _aiResponseText;
  bool _isAiLoading = false;
  String? _aiError;

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

  double _getCop(AfoTelemetry data) {
    final double f1 = _calculateForceNewton(data.fsr1);
    final double f2 = _calculateForceNewton(data.fsr2);
    if ((f1 + f2) <= 0) return 0.0;
    return (f2 - f1) / (f2 + f1);
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

    _stepGoalController = TextEditingController(text: "5000");
    _cycleStartTime = DateTime.now();
    _lastCopWindow = [
      const FlSpot(0.0, -0.1),
      const FlSpot(5.0, 0.05),
      const FlSpot(10.0, -0.08),
      const FlSpot(15.0, 0.12),
      const FlSpot(20.0, -0.02),
      const FlSpot(25.0, 0.08),
      const FlSpot(30.0, 0.0),
    ];

    // Load persisted AI preferences
    _loadPrefs();
  }

  @override
  void dispose() {
    _ble.telemetry.removeListener(_checkThresholds);
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _stepGoalController?.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAiConsented = prefs.getBool('isAiConsented') ?? false;
      _deepSeekApiKey = "sk-352248d215c5440b84e7f7263cfede53";
      _isSimulationMode = prefs.getBool('isSimulationMode') ?? true;
      _isWifiPermissionGranted = prefs.getBool('isWifiPermissionGranted') ?? false;
      _stepGoal = prefs.getInt('stepGoal') ?? 5000;
      _stepGoalController?.text = _stepGoal.toString();
    });
  }
  Future<void> _saveConsent(bool consented) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAiConsented', consented);
    setState(() {
      _isAiConsented = consented;
    });
  }

  Future<void> _saveWifiPermission(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isWifiPermissionGranted', granted);
    setState(() {
      _isWifiPermissionGranted = granted;
    });
  }
  Future<void> _saveStepGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('stepGoal', goal);
    setState(() {
      _stepGoal = goal;
    });
  }

  void _showWifiPermissionDialog({VoidCallback? onAllowed, VoidCallback? onDenied}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2135),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "WiFi & Network Consent",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: Text(
            "AFO SmartLink needs your permission to use WiFi or Mobile Data connection on your device to transmit anonymized gait metrics to the DeepSeek cloud service. Do you allow this network usage?",
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveWifiPermission(false);
                if (onDenied != null) onDenied();
              },
              child: const Text(
                "Decline",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveWifiPermission(true);
                if (onAllowed != null) onAllowed();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                "Allow",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveSimulationMode(bool isSim) async {
    if (!isSim && _isAiConsented && !_isWifiPermissionGranted) {
      _showWifiPermissionDialog(
        onAllowed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isSimulationMode', false);
          setState(() {
            _isSimulationMode = false;
          });
        },
        onDenied: () {
          // Revert or stay in simulation mode
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("WiFi permission declined. Reverting to Local LLM mode."),
              backgroundColor: Color(0xFF1E2135),
            ),
          );
        },
      );
      return;
    }

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
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveConsent(true);
                // Check if they also need to consent to WiFi since default is Deepseek AI (online mode)
                if (!_isSimulationMode && !_isWifiPermissionGranted) {
                  _showWifiPermissionDialog(
                    onDenied: () {
                      _saveSimulationMode(true); // fall back to Local LLM if network denied
                    },
                  );
                }
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
      final double calculatedCop = _getCop(data);
      
      String result;
      if (_isSimulationMode) {
        result = await AiService.simulateAnalysis(
          fsr1Newtons: fsr1N,
          fsr2Newtons: fsr2N,
          temp: data.temperature,
          humidity: data.humidity,
          cop: calculatedCop,
          cadence: data.cadence,
          stepCount: data.stepCount,
        );
      } else {
        result = await AiService.analyzeGait(
          apiKey: _deepSeekApiKey,
          fsr1Newtons: fsr1N,
          fsr2Newtons: fsr2N,
          temp: data.temperature,
          humidity: data.humidity,
          cop: calculatedCop,
          cadence: data.cadence,
          stepCount: data.stepCount,
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
            _lastCopWindow = List.from(_currentCopWindow);
            _currentCopWindow.clear();
            _cycleStartTime = DateTime.now();
          }
        });
      }
    });
  }

  void _checkThresholds() {
    final data = _ble.telemetry.value;
    if (data == null) return;

    final double liveCop = _getCop(data);



    // Capture COP data point in the current 30s cycle
    _cycleStartTime ??= DateTime.now();
    final elapsed = DateTime.now().difference(_cycleStartTime!).inMilliseconds / 1000.0;
    if (elapsed <= 30.0) {
      if (_currentCopWindow.isEmpty || (elapsed - _currentCopWindow.last.x) >= 0.1) {
        _currentCopWindow.add(FlSpot(elapsed, liveCop));
      }
    }

    // Threshold logic:
    // Asymmetry is defined when weight is shifted significantly to one side (|COP| > 0.40)
    bool isUnbalanced = liveCop.abs() > 0.40;
    // Temp > 35.0°C indicates skin risk
    bool isHot = data.temperature > 35.0;
    // Humidity > 75.0% indicates sweating / maceration risk
    bool isHumid = data.humidity > 75.0;

    String? newAlert;
    if (isUnbalanced) {
      newAlert = "Force Imbalance! Leaning heavily to the ${liveCop > 0 ? 'Lateral' : 'Medial'} side.";
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
      // Trigger short vibration alert haptic feedback for new warnings
      if (newAlert != null) {
        HapticFeedback.vibrate();
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
      backgroundColor: const Color(0xFF0F111E),
      bottomNavigationBar: ValueListenableBuilder<AfoConnectionState>(
        valueListenable: _ble.connectionState,
        builder: (context, connState, _) {
          if (connState != AfoConnectionState.connected) return const SizedBox.shrink();
          return NavigationBar(
            backgroundColor: const Color(0xFF13172E),
            indicatorColor: const Color(0xFF00E5FF).withValues(alpha: 0.2),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (idx) {
              setState(() => _selectedIndex = idx);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined), 
                selectedIcon: Icon(Icons.dashboard, color: Color(0xFF00E5FF)), 
                label: 'Dashboard'
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined), 
                selectedIcon: Icon(Icons.analytics, color: Color(0xFF00E5FF)), 
                label: 'Analytics'
              ),
              NavigationDestination(
                icon: Icon(Icons.psychology_outlined), 
                selectedIcon: Icon(Icons.psychology, color: Color(0xFF00E5FF)), 
                label: 'Insights'
              ),
            ],
          );
        },
      ),
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
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Divider(color: Colors.white10, height: 1, thickness: 1),
                      ),
                    ),
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
              Tooltip(
                message: "Disconnect",
                child: IconButton(
                  onPressed: () => _ble.disconnect(),
                  icon: const Icon(Icons.bluetooth_disabled, color: Colors.redAccent, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            else if (!isScanning)
              Tooltip(
                message: "Scan Devices",
                child: IconButton(
                  onPressed: () => _ble.startScan(),
                  icon: const Icon(Icons.bluetooth_searching, color: Color(0xFF8B5CF6), size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            else
              Tooltip(
                message: "Stop Scan",
                child: IconButton(
                  onPressed: () => _ble.stopScan(),
                  icon: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.bluetooth_searching, color: Color(0xFFFBBF24), size: 22),
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFFBBF24)),
                      ),
                    ],
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFBBF24).withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    bool isConnecting = connState == AfoConnectionState.connecting;

    Widget stateIcon;
    String stateTitle;
    String stateDesc;

    if (isConnecting) {
      stateIcon = const Icon(Icons.bluetooth_connected, size: 80, color: Color(0xFF38BDF8));
      stateTitle = "Pairing with Device...";
      stateDesc = "Connecting to the telemetry server.";
    } else if (isScanning) {
      stateIcon = const Icon(Icons.bluetooth_searching, size: 80, color: Color(0xFF00E5FF));
      stateTitle = "Looking for Smart AFO...";
      stateDesc = "Ensure the orthosis microprocessor core is powered on and within range.";
    } else {
      stateIcon = const Icon(Icons.bluetooth_disabled, size: 80, color: Colors.grey);
      stateTitle = "Connect Orthosis Device";
      stateDesc = "Scan to locate and bind the Bluetooth Low Energy telemetry server.";
    }

    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            children: [
              stateIcon,
              const SizedBox(height: 16),
              Text(
                stateTitle,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                stateDesc,
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
    final bool isUrgent = _countdownSeconds <= 5;
    final Color timerColor = isUrgent ? const Color(0xFFFBBF24) : const Color(0xFF00E5FF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2135),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: timerColor.withValues(alpha: 0.25),
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
                  valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                ),
                if (isUrgent)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.sync_rounded,
                      key: ValueKey("urgent_$_countdownSeconds"),
                      color: timerColor,
                      size: 14,
                    ),
                  )
                else
                  Icon(
                    Icons.sync_rounded,
                    color: timerColor,
                    size: 14,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isUrgent ? "Refreshing soon… 00:$secondsStr" : "Data refreshes at 00:$secondsStr",
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: timerColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Dashboard Metrics Section (Tabs Content)
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
              if (_selectedIndex == 0) ...[
                // Dashboard Tab
                _buildCountdownTimerSection(),
                const SizedBox(height: 20),
                _buildActivitySection(data),
                const SizedBox(height: 20),
                _buildMicroclimateSection(data),
              ] else if (_selectedIndex == 1) ...[
                // Analytics Tab
                _buildCountdownTimerSection(),
                const SizedBox(height: 20),
                _buildForceGraphSection(data),
                const SizedBox(height: 20),
                _buildBalanceAnalyticsSection(data),
                const SizedBox(height: 20),
                _buildCopHistorySection(),
              ] else if (_selectedIndex == 2) ...[
                // AI Insights Tab
                _buildAiAnalysisSection(data),
              ],
              const SizedBox(height: 30),
            ]),
          ),
        );
      },
    );
  }


  Widget _buildActivitySection(AfoTelemetry data) {
    return Column(
      children: [
        _buildStepGoalCard(data),
        const SizedBox(height: 16),
        _buildCadenceGaugeCard(data),
      ],
    );
  }

  /// Step Goal progress ring card widget
  Widget _buildStepGoalCard(AfoTelemetry data) {
    double percent = (data.stepCount / _stepGoal).clamp(0.0, 1.0);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF102830), Color(0xFF1E2135)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              // Progress Ring
              SizedBox(
                width: 70,
                height: 70,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: percent,
                      strokeWidth: 5.0,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00FFC2)),
                    ),
                    const Center(
                      child: Icon(
                        Icons.directions_walk_rounded,
                        color: Color(0xFF00FFC2),
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Step texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "DAILY STEP PROGRESS",
                      style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      textBaseline: TextBaseline.alphabetic,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      children: [
                        Text(
                          "${data.stepCount}",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "/",
                          style: GoogleFonts.outfit(
                            color: Colors.white38,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _stepGoalController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF00FFC2),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF00FFC2)),
                              ),
                            ),
                            onChanged: (val) {
                              final newGoal = int.tryParse(val) ?? 5000;
                              if (newGoal > 0) {
                                _saveStepGoal(newGoal);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Goal Progress: ${(percent * 100).toStringAsFixed(0)}%",
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF00FFC2),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
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

  /// Cadence Gauge progress ring card widget
  Widget _buildCadenceGaugeCard(AfoTelemetry data) {
    bool isWalking = data.cadence > 0;
    // Cadence ranges from 0 to 140 SPM
    double percent = (data.cadence / 140.0).clamp(0.0, 1.0);
    Color cadenceColor = data.cadence > 110 
        ? const Color(0xFFEF4444) // Fast
        : data.cadence > 80 
            ? const Color(0xFF8B5CF6) // Target
            : const Color(0xFFFBBF24); // Slow
            
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF201A3A), Color(0xFF1E2135)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isWalking ? cadenceColor.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.05),
              width: isWalking ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isWalking ? cadenceColor.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.2),
                blurRadius: isWalking ? 12 : 8,
                spreadRadius: isWalking ? 2 : 0,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              // Cadence Gauge Ring
              SizedBox(
                width: 70,
                height: 70,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: percent,
                      strokeWidth: 5.0,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(isWalking ? cadenceColor : Colors.white30),
                    ),
                    Center(
                      child: Icon(
                        Icons.speed_rounded,
                        color: isWalking ? cadenceColor : Colors.white30,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Cadence texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "WALKING CADENCE",
                      style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${data.cadence.toStringAsFixed(0)} SPM",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isWalking ? (data.cadence > 110 ? "FAST CADENCE" : data.cadence > 80 ? "TARGET CADENCE" : "SLOW CADENCE") : "STATIONARY",
                      style: GoogleFonts.outfit(
                        color: isWalking ? cadenceColor : Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildCopHistorySection() {
    final double elapsed = _cycleStartTime != null
        ? (DateTime.now().difference(_cycleStartTime!).inMilliseconds / 1000.0).clamp(0.0, 30.0)
        : 30.0;
    final double dynamicMaxX = elapsed < 5.0 ? 5.0 : elapsed;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          height: 310,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2135).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Center of Pressure Real-Time Trend (30s Window)",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: dynamicMaxX,
                    minY: -1.2,
                    maxY: 1.2,
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => const Color(0xFF2A2D40),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            String dir = spot.y == 0
                                ? "Centered"
                                : spot.y > 0 ? "Posterior" : "Anterior";
                            return LineTooltipItem(
                              '${spot.y.toStringAsFixed(2)} ($dir)\nTime: ${spot.x.toStringAsFixed(1)}s',
                              const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 12),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: 5,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              "${value.toInt()}s",
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value == -1.0) {
                              return const Text("Ant", style: TextStyle(color: Colors.white30, fontSize: 10));
                            } else if (value == 0.0) {
                              return const Text("Ctr", style: TextStyle(color: Colors.white30, fontSize: 10));
                            } else if (value == 1.0) {
                              return const Text("Post", style: TextStyle(color: Colors.white30, fontSize: 10));
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
                      drawVerticalLine: true,
                      horizontalInterval: 0.5,
                      verticalInterval: 5.0,
                      getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1, dashArray: [5, 5]),
                      getDrawingVerticalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1, dashArray: [5, 5]),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _currentCopWindow.isEmpty
                            ? [const FlSpot(0, 0)]
                            : _currentCopWindow,
                        isCurved: true,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                              const Color(0xFF00E5FF).withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF00E5FF)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showLastCycleChartDialog,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF00E5FF),
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    "Show Last Cycle Graph",
                    style: TextStyle(
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLastCycleChartDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2135),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Last 30s Cycle COP Graph",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: SizedBox(
            height: 250,
            width: double.maxFinite,
            child: _lastCopWindow.isEmpty
                ? Center(
                    child: Text(
                      "No data available for the last cycle.\nWait for the first 30s countdown to complete.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: 30,
                      minY: -1.2,
                      maxY: 1.2,
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => const Color(0xFF2A2D40),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              String dir = spot.y == 0
                                  ? "Centered"
                                  : spot.y > 0 ? "Posterior" : "Anterior";
                              return LineTooltipItem(
                                '${spot.y.toStringAsFixed(2)} ($dir)\nTime: ${spot.x.toStringAsFixed(1)}s',
                                const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 12),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: 5,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                "${value.toInt()}s",
                                style: const TextStyle(color: Colors.white38, fontSize: 10),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              if (value == -1.0) {
                                return const Text("Ant", style: TextStyle(color: Colors.white30, fontSize: 10));
                              } else if (value == 0.0) {
                                return const Text("Ctr", style: TextStyle(color: Colors.white30, fontSize: 10));
                              } else if (value == 1.0) {
                                return const Text("Post", style: TextStyle(color: Colors.white30, fontSize: 10));
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
                        drawVerticalLine: true,
                        horizontalInterval: 0.5,
                        verticalInterval: 5.0,
                        getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1, dashArray: [5, 5]),
                        getDrawingVerticalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1, dashArray: [5, 5]),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _lastCopWindow,
                          isCurved: true,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF00E5FF).withValues(alpha: 0.3),
                                const Color(0xFF8B5CF6).withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF8B5CF6)],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Close", style: GoogleFonts.outfit(color: const Color(0xFF00E5FF))),
            ),
          ],
        );
      },
    );
  }

  /// Microclimate Section (Temp & Humidity Cards)
  Widget _buildMicroclimateSection(AfoTelemetry data) {
    bool tempWarning = data.temperature > 35.0;
    bool humidWarning = data.humidity > 75.0;

    return Column(
      children: [
        _buildGlassCard(
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
        const SizedBox(height: 16),
        _buildGlassCard(
          title: "Foot Humidity",
          value: "${data.humidity.toStringAsFixed(1)}%",
          icon: Icons.water_drop_outlined,
          indicatorText: humidWarning ? "Sweat Warning" : "Optimal Dryness",
          indicatorColor: humidWarning ? const Color(0xFFFBBF24) : const Color(0xFF10B981),
          iconColor: const Color(0xFF60A5FA),
          glowingBorder: humidWarning,
          gradient: const LinearGradient(
            colors: [Color(0xFF1D2840), Color(0xFF1E2135)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ],
    );
  }

  /// Balance and COP Analytics Card
  Widget _buildBalanceAnalyticsSection(AfoTelemetry data) {
    final double liveCop = _getCop(data);
    // Determine pointer offset for COP visualization
    // liveCop goes from -1.0 (Medial) to +1.0 (Lateral)
    double alignmentVal = (liveCop + 1.0) / 2.0; // Normalized to 0.0 - 1.0
    alignmentVal = alignmentVal.clamp(0.0, 1.0);

    bool copWarning = liveCop.abs() > 0.40;
    Color copGlowColor = copWarning ? const Color(0xFFEF4444) : const Color(0xFF00FFC2);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2135).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: copWarning ? const Color(0xFFEF4444).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05), 
              width: 1.2
            ),
            boxShadow: [
              BoxShadow(
                color: copWarning ? const Color(0xFFEF4444).withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.2),
                blurRadius: copWarning ? 12 : 8,
                spreadRadius: copWarning ? 2 : 0,
                offset: const Offset(0, 4),
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
                    fontSize: 18,
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      "Anterior–Posterior Balance",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      liveCop == 0 
                          ? "Perfect Alignment" 
                          : "${(liveCop.abs() * 100).toStringAsFixed(0)}% Shifted ${liveCop > 0 ? 'Anterior' : 'Posterior'}",
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
                          alignment: Alignment(liveCop, 0),
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
                            "Anterior", 
                            style: const TextStyle(fontSize: 11, color: Colors.white38),
                            textAlign: TextAlign.left,
                            softWrap: true,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Center", 
                            style: const TextStyle(fontSize: 11, color: Colors.white38),
                            textAlign: TextAlign.center,
                            softWrap: true,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Posterior", 
                            style: const TextStyle(fontSize: 11, color: Colors.white38),
                            textAlign: TextAlign.right,
                            softWrap: true,
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
    ),
  ),
);
  }

  /// Foot Sole pressure illustration
  Widget _buildFootSoleVisualizer(AfoTelemetry data) {
    final double force1 = _calculateForceNewton(data.fsr1);
    final double force2 = _calculateForceNewton(data.fsr2);
    final double liveCop = _getCop(data);

    // Scale size of sensors according to force in Newtons (0 - 100)
    double fsr1Size = 25 + (force1 / 100.0) * 35;
    double fsr2Size = 25 + (force2 / 100.0) * 35;

    // Color based on force level (calibrated in Newtons)
    Color getForceColor(double force) {
      if (force < 5.0) return const Color(0xFF00FFC2).withValues(alpha: 0.3); // Safe/low pressure
      if (force < 45.0) return const Color(0xFF8B5CF6); // Moderate pressure
      return const Color(0xFFEF4444); // High/danger pressure
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Anterior label — outside the foot graphic
        Text(
          "Anterior",
          style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Container(
          width: 100,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.white10, width: 1.5),
          ),
          clipBehavior: Clip.hardEdge,
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
              
              // Dynamic COP Pointer — clamped within the foot outline
              AnimatedPositioned(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                top: 68, // vertical center between anterior & posterior bubbles
                left: (50 + (liveCop * 20) - 6).clamp(10.0, 78.0),
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
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Posterior label — outside the foot graphic
        Text(
          "Posterior",
          style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// Live Bar Chart Section
  Widget _buildForceGraphSection(AfoTelemetry data) {
    final double force1 = _calculateForceNewton(data.fsr1);
    final double force2 = _calculateForceNewton(data.fsr2);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          height: 260,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2135).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Plantar Sensors Force Comparison",
            style: GoogleFonts.outfit(
              fontSize: 18,
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
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1, dashArray: [5, 5]),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: force1,
                        width: 50,
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 100,
                          color: Colors.white.withValues(alpha: 0.03),
                        ),
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
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 100,
                          color: Colors.white.withValues(alpha: 0.03),
                        ),
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
    ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: glowingBorder ? indicatorColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05),
              width: glowingBorder ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: glowingBorder 
                    ? indicatorColor.withValues(alpha: 0.15) 
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: glowingBorder ? 12 : 8,
                spreadRadius: glowingBorder ? 2 : 0,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 28),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      indicatorText,
                      style: GoogleFonts.outfit(
                        color: indicatorColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
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
  Widget _buildAiAnalysisSection(AfoTelemetry data) {
    if (!_isAiConsented) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2135).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF00E5FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: const Icon(Icons.psychology_outlined, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  "AI Gait Insights",
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Get dynamic biomechanical analysis and foot microclimate safety warnings using DeepSeek V4Pro AI.",
              style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: 3,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showConsentDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              child: const Text("Unlock AI Analysis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    ),
  );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2135).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _aiError != null 
                  ? const Color(0xFFEF4444).withValues(alpha: 0.4) 
                  : Colors.white.withValues(alpha: 0.05), 
              width: 1.0
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (_isSimulationMode 
                            ? const Color(0xFF00E5FF) 
                            : const Color(0xFF8B5CF6)).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: _isSimulationMode
                          ? const Icon(Icons.memory, color: Color(0xFF00E5FF), size: 24)
                          : ClipOval(
                              child: Image.asset(
                                'assets/deepseek_logo.png',
                                width: 24,
                                height: 24,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "AI Gait Analysis Service",
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_isSimulationMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "LOCAL LLM",
                    style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFFFBBF24), fontWeight: FontWeight.bold),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "DEEPSEEK AI",
                    style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF8B5CF6), fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (_isAiLoading)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              builder: (context, value, child) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00E5FF).withValues(alpha: 0.05 + value * 0.05),
                        const Color(0xFF8B5CF6).withValues(alpha: 0.05 + value * 0.05),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF00E5FF).withValues(alpha: 0.6 + value * 0.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isSimulationMode ? "Generating local LLM analysis..." : "Consulting DeepSeek V4Pro AI...",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5 + value * 0.4),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
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
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                      const Color(0xFF00E5FF).withValues(alpha: 0.15),
                    ],
                  ),
                ),
                child: const Icon(Icons.tune, color: Color(0xFF8B5CF6), size: 18),
              ),
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
                      Text(
                        "AI Analysis Source",
                        style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _saveSimulationMode(true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isSimulationMode ? const Color(0xFF8B5CF6) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "Local LLM",
                                    style: TextStyle(
                                      color: _isSimulationMode ? Colors.white : Colors.white54,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _saveSimulationMode(false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !_isSimulationMode ? const Color(0xFF00E5FF) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "Deepseek AI",
                                    style: TextStyle(
                                      color: !_isSimulationMode ? Colors.black : Colors.white54,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Revoke Consent Option
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            _saveConsent(false);
                            _saveWifiPermission(false);
                            _saveSimulationMode(true);
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
    ),
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
