import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/onboarding_style.dart';

class OnboardingPage2 extends StatelessWidget {
  const OnboardingPage2({super.key});

  static const _scheme = OnboardingStyle.skyCombo;

  @override
  Widget build(BuildContext context) {
    return OnboardingStyle.pageBackground(
      scheme: _scheme,
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OnboardingStyle.roundedImage(
                            'assets/icons/onboarding2.png',
                            ringColors: _scheme.ring,
                            size: 200,
                          ),
                          const SizedBox(height: 30),
                          OnboardingStyle.underline(_scheme.ring),
                          const SizedBox(height: 18),
                          Text(
                            'Baby Health Tracking',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _scheme.title,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Manage multiple baby profiles with allergy information, weight tracking, milestone records, and complete medical history to support healthy growth.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              height: 1.55,
                              color: _scheme.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
