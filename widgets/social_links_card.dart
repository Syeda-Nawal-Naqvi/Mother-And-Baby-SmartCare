import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/contact_links.dart';

class SocialLinksCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;
  final Color accent;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;

  const SocialLinksCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.accent,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: accent.withValues(alpha: isDark ? 0.20 : 0.12)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.14 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: textPrimary)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 11.5, color: textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _iconButton(
            onTap: () => ContactLinks.openInstagram(context),
            assetPath: 'assets/icons/instagram.png',
            fallbackIcon: Icons.camera_alt_rounded,
          ),
          const SizedBox(width: 10),
          _iconButton(
            onTap: () => ContactLinks.openGmail(context),
            assetPath: 'assets/icons/gmail.png',
            fallbackIcon: Icons.mail_rounded,
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required VoidCallback onTap,
    required String assetPath,
    required IconData fallbackIcon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(10),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              Icon(fallbackIcon, color: accent, size: 20),
        ),
      ),
    );
  }
}
