import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../Homepage/dashboard.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage>
    with TickerProviderStateMixin {
  late final LocalAuthentication auth;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  bool _supportState = false;
  bool _isAuthenticating = false;
  String _authStatus = 'Ready to authenticate';
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    auth = LocalAuthentication();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _initializeAuth();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    bool isSupported = await auth.isDeviceSupported();
    List<BiometricType> availableBiometrics = await _getAvailableBiometrics();

    setState(() {
      _supportState = isSupported;
      _availableBiometrics = availableBiometrics;
    });

    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _darkTheme(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A0A0A),
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: 40),

                    // Main Header
                    _buildHeader(),

                    const SizedBox(height: 50),

                    // Biometric Status Circle
                    _buildStatusCircle(),

                    const SizedBox(height: 40),

                    // Status Text
                    _buildStatusText(),

                    const SizedBox(height: 40),

                    // Available Biometrics
                    if (_supportState) _buildBiometricsList(),

                    const SizedBox(height: 40),

                    // Authentication Button
                    if (_supportState) _buildAuthButton(),

                    const SizedBox(height: 40),

                    // Security Info
                    _buildSecurityInfo(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      primaryColor: const Color(0xFF00D4AA),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00D4AA),
        secondary: Color(0xFF7C4DFF),
        surface: Color(0xFF1E1E1E),
        background: Color(0xFF0A0A0A),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: const Color(0xFF00D4AA).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Text(
            'SECURE ACCESS',
            style: TextStyle(
              color: Color(0xFF00D4AA),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Biometric\nAuthentication',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: Colors.white,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCircle() {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            if (_isAuthenticating)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00D4AA).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Main circle
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _getStatusColor().withOpacity(0.2),
                    _getStatusColor().withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
                border: Border.all(
                  color: _getStatusColor(),
                  width: 2,
                ),
              ),
              child: Icon(
                _getMainIcon(),
                size: 80,
                color: _getStatusColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusText() {
    return Column(
      children: [
        Text(
          _supportState ? 'Device Supported' : 'Not Supported',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _supportState ? const Color(0xFF00D4AA) : Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _getStatusColor().withOpacity(0.1),
            border: Border.all(
              color: _getStatusColor().withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            _authStatus,
            style: TextStyle(
              fontSize: 14,
              color: _getStatusColor(),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricsList() {
    if (_availableBiometrics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF1E1E1E).withOpacity(0.5),
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: const Text(
          'No biometric methods available',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Methods',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 16),
        ...(_availableBiometrics.map((biometric) => _buildBiometricItem(biometric))),
      ],
    );
  }

  Widget _buildBiometricItem(BiometricType biometric) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF1E1E1E).withOpacity(0.7),
        border: Border.all(
          color: const Color(0xFF00D4AA).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF00D4AA).withOpacity(0.1),
            ),
            child: Icon(
              _getBiometricIcon(biometric),
              color: const Color(0xFF00D4AA),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _getBiometricName(biometric),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.green.withOpacity(0.2),
            ),
            child: const Text(
              'ACTIVE',
              style: TextStyle(
                fontSize: 10,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: _isAuthenticating
            ? null
            : const LinearGradient(
          colors: [Color(0xFF00D4AA), Color(0xFF7C4DFF)],
        ),
        color: _isAuthenticating ? Colors.grey[800] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isAuthenticating ? null : _authenticate,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: _isAuthenticating
                ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  'Authenticating...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            )
                : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.fingerprint_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Authenticate Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1E1E1E).withOpacity(0.3),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.security_rounded,
                color: Color(0xFF00D4AA),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Security Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSecurityItem('End-to-End Encryption', 'Your biometric data never leaves your device'),
          _buildSecurityItem('Zero Storage Policy', 'No biometric templates are stored on servers'),
          _buildSecurityItem('Hardware Security', 'Uses secure hardware elements for authentication'),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF00D4AA),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getBiometricIcon(BiometricType biometric) {
    switch (biometric) {
      case BiometricType.face:
        return Icons.face_rounded;
      case BiometricType.fingerprint:
        return Icons.fingerprint_rounded;
      case BiometricType.iris:
        return Icons.remove_red_eye_rounded;
      case BiometricType.strong:
        return Icons.security_rounded;
      case BiometricType.weak:
        return Icons.lock_outline_rounded;
      default:
        return Icons.security_rounded;
    }
  }

  String _getBiometricName(BiometricType biometric) {
    switch (biometric) {
      case BiometricType.face:
        return 'Face Recognition';
      case BiometricType.fingerprint:
        return 'Fingerprint Scanner';
      case BiometricType.iris:
        return 'Iris Recognition';
      case BiometricType.strong:
        return 'Strong Authentication';
      case BiometricType.weak:
        return 'Pattern/PIN Authentication';
      default:
        return 'Biometric Authentication';
    }
  }

  Color _getStatusColor() {
    if (_authStatus.contains('successful') || _authStatus.contains('✓')) {
      return const Color(0xFF00D4AA);
    }
    if (_authStatus.contains('failed') || _authStatus.contains('error')) {
      return Colors.red;
    }
    if (_authStatus.contains('cancelled')) {
      return Colors.orange;
    }
    if (_authStatus.contains('Authenticating')) {
      return const Color(0xFF7C4DFF);
    }
    return const Color(0xFF00D4AA);
  }

  IconData _getMainIcon() {
    if (_authStatus.contains('successful') || _authStatus.contains('✓')) {
      return Icons.check_circle_rounded;
    }
    if (_authStatus.contains('failed') || _authStatus.contains('error')) {
      return Icons.error_rounded;
    }
    if (_authStatus.contains('cancelled')) {
      return Icons.cancel_rounded;
    }
    if (_isAuthenticating) {
      return Icons.fingerprint_rounded;
    }
    if (!_supportState) {
      return Icons.block_rounded;
    }
    return Icons.fingerprint_rounded;
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _authStatus = 'Authenticating...';
    });

    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to access secure content',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (authenticated) {
        setState(() {
          _isAuthenticating = false;
          _authStatus = 'Authentication successful ✓';
        });

        // Show a full-screen loader
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withOpacity(0.4),
          builder: (context) => Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- UI Change Start ---
                    ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        backgroundColor: Colors.grey,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
                      ),
                    ),
                    // --- UI Change End ---
                  ],
                ),
              ),
            ),
          ),
        );

        await Future.delayed(const Duration(seconds: 2)); // Optional wait

        if (mounted) {
          Navigator.of(context).pop(); // Close the loader
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardPage()),
          );
        }
      }
      else {
        setState(() {
          _isAuthenticating = false;
          _authStatus = 'Authentication failed';
        });
      }

      print("Authenticated: $authenticated");
    } on PlatformException catch (e) {
      setState(() {
        _isAuthenticating = false;
        _authStatus = 'Authentication error: ${e.message ?? 'Unknown error'}';
      });
      print(e);
    }
  }

  Future<List<BiometricType>> _getAvailableBiometrics() async {
    try {
      List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();
      print("List of availableBiometrics: $availableBiometrics");
      return availableBiometrics;
    } catch (e) {
      print("Error getting available biometrics: $e");
      return [];
    }
  }
}