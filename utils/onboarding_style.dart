import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingColorScheme {
  final List<Color> background;
  final List<Color> ring;
  final Color title;
  final Color body;

  const OnboardingColorScheme({
    required this.background,
    required this.ring,
    required this.title,
    this.body = const Color(0xFF564B66),
  });
}

class OnboardingStyle {
  static const babyPink = Color(0xFFFFF0F5);

  static const roseCombo = OnboardingColorScheme(
    background: [Color(0xFFFFE3EF), Color(0xFFFFF6FA)],
    ring: [Color(0xFFEC1E8C), Color(0xFF9C0057)],
    title: Color(0xFFE0357A),
  );

  static const skyCombo = OnboardingColorScheme(
    background: [Color(0xFFD8EFFE), Color(0xFFF0FAFF)],
    ring: [Color(0xFF1DC8D8), Color(0xFF00695C)],
    title: Color(0xFF00697A),
  );

  static const violetCombo = OnboardingColorScheme(
    background: [Color(0xFFE6D9F8), Color(0xFFF6EEFC)],
    ring: [Color.fromARGB(255, 160, 79, 183), Color.fromARGB(255, 129, 2, 146)],
    title: Color.fromARGB(255, 99, 4, 146),
  );

  static const amberCombo = OnboardingColorScheme(
    background: [
      Color.fromRGBO(250, 255, 184, 1),
      Color.fromARGB(255, 255, 255, 211)
    ],
    ring: [
      Color.fromARGB(255, 255, 240, 106),
      Color.fromARGB(255, 212, 203, 30)
    ],
    title: Color.fromARGB(255, 255, 217, 0),
  );

  static const emeraldCombo = OnboardingColorScheme(
    background: [Color.fromARGB(255, 209, 255, 217), Color(0xFFEDFBF2)],
    ring: [Color.fromARGB(255, 34, 222, 116), Color.fromARGB(255, 14, 90, 31)],
    title: Color(0xFF1B7A3D),
  );

  static const List<OnboardingColorScheme> pageSchemes = [
    roseCombo,
    skyCombo,
    violetCombo,
    amberCombo,
    emeraldCombo,
  ];

  static Widget pageBackground({
    required OnboardingColorScheme scheme,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: scheme.background,
        ),
      ),
      child: child,
    );
  }

  static Widget roundedImage(
    String path, {
    required List<Color> ringColors,
    double size = 210,
  }) {
    final imageSize = size * 0.6;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: ringColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: ringColors.last.withValues(alpha: 0.32),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.05),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Center(
          child: Image.asset(
            path,
            width: imageSize,
            height: imageSize,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  static Widget underline(List<Color> colors) {
    return Container(
      width: 44,
      height: 4,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  static Widget gradientButton({
    required String label,
    required VoidCallback onPressed,
    required List<Color> colors,
  }) {
    return _OnboardingGradientButton(
      label: label,
      onPressed: onPressed,
      gradientColors: colors,
    );
  }
}

class _OnboardingGradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final List<Color> gradientColors;

  const _OnboardingGradientButton({
    required this.label,
    required this.onPressed,
    required this.gradientColors,
  });

  @override
  State<_OnboardingGradientButton> createState() =>
      _OnboardingGradientButtonState();
}

class _OnboardingGradientButtonState extends State<_OnboardingGradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.97 : 1.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scaleByDouble(scale, scale, 1.0, 1.0),
        transformAlignment: Alignment.center,
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.gradientColors.last
                  .withValues(alpha: _pressed ? 0.30 : 0.40),
              blurRadius: _pressed ? 16 : 22,
              offset: const Offset(0, 8),
              spreadRadius: 0.5,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: GoogleFonts.poppins(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
