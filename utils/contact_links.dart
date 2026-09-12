import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactLinks {
  ContactLinks._();

  static const String instagramUsername = 'mother_and_baby_smartcare';
  static const String supportEmail = 'motherandbabysmartcare@gmail.com';

  static Future<void> openInstagram(BuildContext context) async {
    final appUri = Uri.parse('instagram://user?username=$instagramUsername');
    final webUri = Uri.parse('https://instagram.com/$instagramUsername');
    bool opened = false;
    try {
      opened = await launchUrl(appUri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (opened) return;
    if (!context.mounted) return;

    try {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!context.mounted) return;
      _showError(context, 'Could not open Instagram.');
    }
  }

  static Future<void> openGmail(
    BuildContext context, {
    String subject = 'Hello, Mother And Baby SmartCare',
  }) async {
    final mailUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {'subject': subject},
    );
    bool opened = false;
    try {
      opened = await launchUrl(mailUri);
    } catch (_) {
      opened = false;
    }
    if (!context.mounted) return;
    if (!opened) _showError(context, 'No email app found on this device.');
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message, style: GoogleFonts.poppins(fontSize: 13))),
    );
  }
}
