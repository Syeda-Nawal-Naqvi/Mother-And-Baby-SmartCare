import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_page1.dart';
import 'onboarding_page2.dart';
import 'onboarding_page3.dart';
import 'onboarding_page4.dart';
import 'onboarding_page5.dart';
import '../../utils/onboarding_style.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Widget> _pages = const [
    OnboardingPage1(),
    OnboardingPage2(),
    OnboardingPage3(),
    OnboardingPage4(),
    OnboardingPage5(),
  ];

  OnboardingColorScheme get _scheme =>
      OnboardingStyle.pageSchemes[_currentPage];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _onNextPressed() {
    if (_isLastPage) {
      _finishOnboarding();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnboardingStyle.babyPink,
      body: SafeArea(
        // Column, NOT a full-screen Stack: the bottom panel reserves its
        // own height and the PageView only ever gets what's left via
        // Expanded, so the panel can never overlap the page content on
        // any device size.
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  PageView(
                    controller: _controller,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    children: _pages,
                  ),
                  Positioned(
                    top: 8,
                    right: 16,
                    child: AnimatedOpacity(
                      opacity: _isLastPage ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: TextButton(
                        onPressed: _finishOnboarding,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.85),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: GoogleFonts.poppins(
                            color: _scheme.title,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                          child: const Text('Skip'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom panel: dots + gradient CTA button, echoing the
            // card + gradient-button language of the login screen.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(26, 18, 26, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: _currentPage == index
                              ? LinearGradient(colors: _scheme.ring)
                              : null,
                          color: _currentPage == index
                              ? null
                              : _scheme.ring[0].withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OnboardingStyle.gradientButton(
                    label: _isLastPage ? 'Get Started' : 'Next',
                    onPressed: _onNextPressed,
                    colors: _scheme.ring,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
