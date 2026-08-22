import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/onboarding_style.dart';

class OnboardingPage5 extends StatelessWidget {
  const OnboardingPage5({super.key});

  static const _scheme = OnboardingStyle.emeraldCombo;

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
                            'assets/icons/onboarding5.png',
                            ringColors: _scheme.ring,
                            size: 210,
                          ),
                          const SizedBox(height: 30),
                          OnboardingStyle.underline(_scheme.ring),
                          const SizedBox(height: 18),
                          Text(
                            'Cloud Sync & Security',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _scheme.title,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Keep your health records securely stored and synchronized through the cloud. Access your data safely across devices anytime while ensuring full protection of your information.',
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
