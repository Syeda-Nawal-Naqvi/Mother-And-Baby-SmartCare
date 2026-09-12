import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/email_share_service.dart';
import '../../services/firebase_service.dart';
import '../../services/pdf_report_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/app_widgets.dart';

class ShareMotherRecordScreen extends StatefulWidget {
  const ShareMotherRecordScreen({super.key});

  @override
  State<ShareMotherRecordScreen> createState() =>
      _ShareMotherRecordScreenState();
}

class _ShareMotherRecordScreenState extends State<ShareMotherRecordScreen> {
  static const Color _accent = Color(0xFFE91E8C);

  bool _useDifferentEmail = false;
  final TextEditingController _emailController = TextEditingController();
  bool _isSending = false;

  String get _verifiedEmail => FirebaseAuth.instance.currentUser?.email ?? '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? get _resolvedRecipient {
    if (!_useDifferentEmail) return _verifiedEmail;
    final typed = _emailController.text.trim();
    return typed.isEmpty ? null : typed;
  }

  bool get _isRecipientValid {
    final email = _resolvedRecipient;
    return email != null && EmailValidator.validate(email);
  }

  Future<void> _handleSend() async {
    if (!_isRecipientValid) return;

    if (!FirestoreService.isOnline.value) {
      _showNoInternetDialog();
      return;
    }

    setState(() => _isSending = true);
    try {
      final pdfBytes = await PdfReportService.generateMotherReport();
      await EmailShareService.sendReportEmail(
        recipientEmail: _resolvedRecipient!,
        subject: 'Mother Health Report — Mother And Baby SmartCare',
        bodyText: "Sharing the mother's health report from Mother And Baby "
            'SmartCare. The detailed PDF report is attached for your '
            'reference.',
        pdfBytes: pdfBytes,
        fileName: 'Mother_Health_Report.pdf',
      );
      if (!mounted) return;

      _showResultDialog(
        success: true,
        title: 'Mail App Opened',
        message: 'Your email app has opened with the report attached and '
            'addressed to $_resolvedRecipient. Review it and tap Send '
            'to deliver it.',
      );
    } on NoInternetException {
      if (!mounted) return;
      _showNoInternetDialog();
    } on NoEmailAppException catch (e) {
      if (!mounted) return;
      _showResultDialog(
        success: false,
        title: 'No Email App Found',
        message: '${e.message} Please set up a mail account (e.g. Gmail) '
            'on this device and try again.',
      );
    } catch (e) {
      if (!mounted) return;

      _showResultDialog(
        success: false,
        title: 'Send Failed',
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.wifi_off_rounded, color: _accent, size: 34),
        title: Text('No Internet Connection',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Sharing a PDF report requires an active internet connection. '
          'Please check your connection and try again.',
          style: GoogleFonts.poppins(fontSize: 13.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('OK', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showResultDialog({
    required bool success,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: Icon(
          success ? Icons.mark_email_read_rounded : Icons.error_outline_rounded,
          color: success ? Colors.green : Colors.red,
          size: 34,
        ),
        title: Text(title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(message, style: GoogleFonts.poppins(fontSize: 13.5)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('OK', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ThemeAware(
      builder: (context, theme) {
        return Scaffold(
          backgroundColor: theme.bg,
          appBar: AppBar(
            backgroundColor: theme.surface,
            elevation: 0,
            iconTheme: const IconThemeData(color: _accent),
            title: Text(
              'Share Mother Record',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, color: theme.textPrimary),
            ),
          ),
          body: Column(
            children: [
              const OfflineBanner(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SummaryCard(
                        color: _accent,
                        title: "Mother's Complete Health Record",
                        description:
                            'Includes Weight, Blood Pressure, Glucose Level '
                            'and Medical History, compiled into a single PDF.',
                        theme: theme,
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Send to',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: theme.textPrimary),
                      ),
                      const SizedBox(height: 10),
                      _RecipientPanel(
                        accent: _accent,
                        theme: theme,
                        verifiedEmail: _verifiedEmail,
                        useDifferentEmail: _useDifferentEmail,
                        emailController: _emailController,
                        onToggle: (v) => setState(() => _useDifferentEmail = v),
                        onChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 16, color: theme.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tapping "Send" opens your email app with the '
                                'report already attached — review it and tap '
                                'Send inside that app to deliver it.',
                                style: GoogleFonts.poppins(
                                    fontSize: 11.5, color: theme.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: (_isRecipientValid && !_isSending)
                              ? _handleSend
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            disabledBackgroundColor:
                                _accent.withValues(alpha: 0.35),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isSending
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.4, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.send_rounded,
                                        color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text('Send PDF',
                                        style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white)),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Color color;
  final String title;
  final String description;
  final AppThemeColors theme;

  const _SummaryCard({
    required this.color,
    required this.title,
    required this.description,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: theme.isDark ? 0.28 : 0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.picture_as_pdf_rounded, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary)),
                const SizedBox(height: 4),
                Text(description,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: theme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipientPanel extends StatelessWidget {
  final Color accent;
  final AppThemeColors theme;
  final String verifiedEmail;
  final bool useDifferentEmail;
  final TextEditingController emailController;
  final ValueChanged<bool> onToggle;
  final VoidCallback onChanged;

  const _RecipientPanel({
    required this.accent,
    required this.theme,
    required this.verifiedEmail,
    required this.useDifferentEmail,
    required this.emailController,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioGroup<bool>(
      groupValue: useDifferentEmail,
      onChanged: (v) => onToggle(v ?? false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onToggle(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: !useDifferentEmail
                    ? accent.withValues(alpha: theme.isDark ? 0.18 : 0.08)
                    : theme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: !useDifferentEmail ? accent : theme.border,
                  width: !useDifferentEmail ? 1.6 : 1,
                ),
              ),
              child: Row(
                children: [
                  Radio<bool>(
                    value: false,
                    activeColor: accent,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Your registered email',
                                style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textSecondary)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_rounded,
                                      size: 12, color: Colors.green),
                                  const SizedBox(width: 3),
                                  Text('Verified',
                                      style: GoogleFonts.poppins(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.green)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          verifiedEmail.isEmpty
                              ? 'No email found'
                              : verifiedEmail,
                          style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: theme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onToggle(true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: useDifferentEmail
                    ? accent.withValues(alpha: theme.isDark ? 0.18 : 0.08)
                    : theme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: useDifferentEmail ? accent : theme.border,
                  width: useDifferentEmail ? 1.6 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        activeColor: accent,
                      ),
                      Text('Send to a different email',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (useDifferentEmail)
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 12, right: 6, bottom: 4),
                      child: TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => onChanged(),
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'e.g. doctor@example.com',
                          hintStyle: GoogleFonts.poppins(
                              fontSize: 13, color: theme.textSecondary),
                          filled: true,
                          fillColor: theme.surfaceAlt,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: accent, width: 1.5),
                          ),
                          errorText: emailController.text.isEmpty ||
                                  EmailValidator.validate(
                                      emailController.text.trim())
                              ? null
                              : 'Enter a valid email address',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
