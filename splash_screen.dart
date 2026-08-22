import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/connectivity_service.dart';
import '../services/auth_service.dart';
import '../widgets/no_internet_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _loadingController;

  late Animation<double> _fadeAnim;
  late Animation<double> _loadingAnim;

  bool _hasError = false;

  final String mainQuote = 'Every new beginning\nis filled with love!';
  final String subQuote = "Let's walk this beautiful journey\ntogether";

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(
        const AssetImage('assets/images/splash_bg.jpg'),
        context,
      );
    });

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    );

    _loadingAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    _startSequence();
  }

  void _startSequence() async {
    _fadeController.forward();
    _loadingController.forward();

    await Future.delayed(const Duration(milliseconds: 6000));

    if (mounted) {
      _navigate();
    }
  }

  Future<void> _navigate() async {
    final connectivity = ConnectivityService();
    final hasInternet = await connectivity.isConnected();

    if (!mounted) return;

    if (!hasInternet) {
      setState(() => _hasError = true);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;

    if (!mounted) return;

    if (isFirstTime) {
      Navigator.pushReplacementNamed(context, '/onboarding');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      await user.reload();
      await AuthService().syncEmailAfterVerification();
      if (!mounted) return;

      final freshUser = FirebaseAuth.instance.currentUser;

      if (freshUser == null || !freshUser.emailVerified) {
        Navigator.pushReplacementNamed(context, '/verify_email');
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(freshUser.uid)
          .get();

      if (!mounted) return;

      if (doc.exists && (doc.data()?['blocked'] == true)) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final role = doc.exists ? (doc.data()?['role'] ?? 'mother') : 'mother';

      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return NoInternetScreen(
        onRetry: () {
          setState(() => _hasError = false);
          _navigate();
        },
      );
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFDE8EF),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/splash_bg.jpg',
            fit: BoxFit.cover,
            width: size.width,
            height: size.height,
            errorBuilder: (_, __, ___) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFDE8EF),
                      Color(0xFFF9C8D8),
                      Color(0xFFF5B8CC),
                    ],
                  ),
                ),
              );
            },
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xEEFDE8EF),
                  Color(0xAAF9C8D8),
                  Color(0x44F5B8CC),
                ],
              ),
            ),
          ),
          // Responsive, overflow-safe content — same pattern used on
          // Home/Onboarding: LayoutBuilder + SingleChildScrollView +
          // ConstrainedBox(minHeight) lets the content center itself
          // on tall/large screens, and scroll (instead of overflowing)
          // on short/small ones.
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Mom N Baby SmartCare',
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFE91E8C),
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 35),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 28),
                                child: Column(
                                  children: [
                                    Text(
                                      mainQuote,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w800,
                                        color: const Color.fromARGB(
                                            255, 134, 2, 75),
                                        height: 1.1,
                                        shadows: [
                                          Shadow(
                                            color: Colors.white
                                                .withValues(alpha: 0.8),
                                            blurRadius: 8,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            subQuote,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w400,
                                              color: const Color(0xFF5C3040),
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          '❤️',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 35),
                              Text(
                                'loading...',
                                style: GoogleFonts.dancingScript(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFD81B6A)
                                      .withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 90),
                                child: AnimatedBuilder(
                                  animation: _loadingAnim,
                                  builder: (_, __) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: _loadingAnim.value,
                                        backgroundColor: Colors.pink.shade100
                                            .withValues(alpha: 0.6),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                          Color(0xFFE91E8C),
                                        ),
                                        minHeight: 3,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
