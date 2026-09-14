import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/app_notification_service.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../utils/countries.dart';
import '../../widgets/country_picker.dart';
import '../auth/forgot_password_screen.dart';
import 'admin_notifications_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _name = '';
  String _email = '';
  String _country = '';
  bool _isLoading = false;
  bool _isProfileLoading = true;
  bool _isSavingName = false;
  bool _isSavingCountry = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final enabled = await AppNotificationService().isNotificationsEnabled();
      if (!mounted) return;
      setState(() => _notificationsEnabled = enabled);
    } catch (_) {
      if (!mounted) return;
      setState(() => _notificationsEnabled = true);
    }
  }

  Future<void> _setNotificationsEnabled(bool val) async {
    setState(() => _notificationsEnabled = val);
    await AppNotificationService().setNotificationsEnabled(val);
  }

  Future<void> _loadProfile() async {
    try {
      final uid = _auth.currentUser?.uid;
      _email = _auth.currentUser?.email ?? '';
      if (uid == null) {
        if (mounted) setState(() => _isProfileLoading = false);
        return;
      }
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!mounted) return;
      setState(() {
        _name = (doc.data()?['name'] ?? 'Admin').toString();
        _country = (doc.data()?['country'] ?? '').toString();
        _isProfileLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _name = _auth.currentUser?.displayName ?? 'Admin';
          _isProfileLoading = false;
        });
      }
    }
  }

  void _showToast(String message, {required bool isSuccess}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style:
                      GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: isSuccess ? ThemeService.success : ThemeService.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _dialogField({
    required TextEditingController ctrl,
    required String hint,
    bool isPassword = false,
    bool isDark = false,
    int maxLength = 0,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword,
      maxLength: maxLength > 0 ? maxLength : null,
      style: GoogleFonts.poppins(
          fontSize: 14, color: ThemeService.textPrimary(isDark)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
        counterStyle: GoogleFonts.poppins(
            fontSize: 11, color: ThemeService.textSecondary(isDark)),
        filled: true,
        fillColor: ThemeService.surfaceAlt(isDark),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ThemeService.border(isDark)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ThemeService.border(isDark)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: ThemeService.activeAccent(isDark), width: 1.5),
        ),
      ),
    );
  }

  Future<void> _showNameDialog(bool isDark) async {
    final ctrl = TextEditingController(text: _name);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeService.surface(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Update Name',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: ThemeService.textPrimary(isDark))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Maximum 30 characters allowed.',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: ThemeService.textSecondary(isDark))),
            const SizedBox(height: 12),
            _dialogField(
                ctrl: ctrl,
                hint: 'Enter your full name',
                isDark: isDark,
                maxLength: 30),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    color: isDark ? Colors.grey.shade400 : Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = ctrl.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(ctx);
              await _saveName(value);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeService.activeAccent(isDark),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child:
                Text('Save', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveName(String value) async {
    setState(() => _isSavingName = true);
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      await _firestore
          .collection('users')
          .doc(uid)
          .set({'name': value}, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {
        _name = value;
        _isSavingName = false;
      });
      _showToast('Name updated successfully!', isSuccess: true);
    } catch (_) {
      if (mounted) {
        setState(() => _isSavingName = false);
        _showToast('Failed to update name.', isSuccess: false);
      }
    }
  }

  Future<void> _changePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        final isDark = context.read<ThemeNotifier>().isDarkMode;
        return AlertDialog(
          backgroundColor: ThemeService.surface(isDark),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Change Password',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: ThemeService.textPrimary(isDark),
              )),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(
                    ctrl: currentCtrl,
                    hint: 'Current password',
                    isPassword: true,
                    isDark: isDark),
                const SizedBox(height: 12),
                _dialogField(
                    ctrl: newCtrl,
                    hint: 'New password',
                    isPassword: true,
                    isDark: isDark),
                const SizedBox(height: 12),
                _dialogField(
                    ctrl: confirmCtrl,
                    hint: 'Confirm new password',
                    isPassword: true,
                    isDark: isDark),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen()));
                    },
                    child: Text('Forgot your password?',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ThemeService.activeAccent(isDark))),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(
                      color: isDark ? Colors.grey.shade400 : Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newCtrl.text != confirmCtrl.text) {
                  _showToast('Passwords do not match', isSuccess: false);
                  return;
                }
                if (newCtrl.text.length < 6) {
                  _showToast('Minimum 6 characters required', isSuccess: false);
                  return;
                }
                final error = await _authService.changePassword(
                  oldPassword: currentCtrl.text,
                  newPassword: newCtrl.text,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (error == null) {
                  _showToast('Password updated successfully!', isSuccess: true);
                } else {
                  _showToast(error, isSuccess: false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeService.activeAccent(isDark),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Update',
                  style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeEmail() async {
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        final isDark = context.read<ThemeNotifier>().isDarkMode;
        return AlertDialog(
          backgroundColor: ThemeService.surface(isDark),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Change Email',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: ThemeService.textPrimary(isDark))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'A verification link will be sent to your new email. Your email updates only after you click that link.',
                  style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
                const SizedBox(height: 14),
                _dialogField(
                    ctrl: emailCtrl, hint: 'New email address', isDark: isDark),
                const SizedBox(height: 12),
                _dialogField(
                    ctrl: passwordCtrl,
                    hint: 'Current password',
                    isPassword: true,
                    isDark: isDark),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(
                      color: isDark ? Colors.grey.shade400 : Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailCtrl.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  _showToast('Enter a valid email', isSuccess: false);
                  return;
                }
                if (passwordCtrl.text.isEmpty) {
                  _showToast('Enter your current password', isSuccess: false);
                  return;
                }
                final error = await _authService.requestEmailChange(
                    email, passwordCtrl.text);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (error == null) {
                  _showToast(
                      'Verification link sent to $email. Click it to confirm.',
                      isSuccess: true);
                } else {
                  _showToast(error, isSuccess: false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeService.activeAccent(isDark),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Send Link',
                  style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickCountry() async {
    final picked = await showCountryPicker(
      context,
      currentValue: _country.isEmpty ? null : _country,
      title: 'Select your country',
    );
    if (picked == null || picked == _country || !mounted) return;
    setState(() => _isSavingCountry = true);
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      await _firestore
          .collection('users')
          .doc(uid)
          .set({'country': picked}, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {
        _country = picked;
        _isSavingCountry = false;
      });
      _showToast('Country updated successfully!', isSuccess: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingCountry = false);
      _showToast('Failed to update country.', isSuccess: false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = context.read<ThemeNotifier>().isDarkMode;
        return AlertDialog(
          backgroundColor: ThemeService.surface(isDark),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Sign out?',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: ThemeService.textPrimary(isDark))),
          content: Text(
            'You will need to log in again to access the admin panel.',
            style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(
                      color: isDark ? Colors.grey.shade400 : Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeService.activeAccent(isDark),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Sign out',
                  style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> _deleteAccount() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final passwordCtrl = TextEditingController();
    bool obscurePassword = true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = context.read<ThemeNotifier>().isDarkMode;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: ThemeService.surface(isDark),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text('Delete Account',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, color: Colors.red.shade600)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'This is permanent and cannot be undone. Your admin profile '
                    'and login will be removed.',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: obscurePassword,
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: ThemeService.textPrimary(isDark)),
                    decoration: InputDecoration(
                      hintText: 'Enter password to confirm',
                      hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade400),
                      filled: true,
                      fillColor: ThemeService.surfaceAlt(isDark),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: ThemeService.border(isDark)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: ThemeService.border(isDark)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: ThemeService.activeAccent(isDark)),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          size: 20,
                        ),
                        onPressed: () => setDialogState(
                            () => obscurePassword = !obscurePassword),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Cancel',
                      style: GoogleFonts.poppins(
                          color: isDark ? Colors.grey.shade400 : Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade500,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Delete',
                      style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm != true || !mounted) return;

    try {
      setState(() => _isLoading = true);
      final user = _auth.currentUser!;
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: passwordCtrl.text,
      );
      await user.reauthenticateWithCredential(cred);
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showToast('Incorrect password. Try again.', isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    final isDark = themeNotifier.isDarkMode;

    final bgColor = ThemeService.bg(isDark);
    final cardColor = ThemeService.surface(isDark);
    final titleColor = ThemeService.textPrimary(isDark);
    final subtitleColor = ThemeService.textSecondary(isDark);
    final dividerColor = ThemeService.border(isDark);
    final sectionLabelColor =
        isDark ? ThemeService.activeAccent(isDark) : Colors.grey.shade500;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: ThemeService.activeAccent(isDark), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Account & Settings',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w600, color: titleColor)),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: ThemeService.activeAccent(isDark)))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  ThemeService.activeAccent(isDark),
                                  ThemeService.activeAccentLight(isDark)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: ThemeService.activeAccent(isDark)
                                      .withValues(alpha: 0.30),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isProfileLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      _name.isNotEmpty
                                          ? _name[0].toUpperCase()
                                          : 'A',
                                      style: GoogleFonts.poppins(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isProfileLoading
                                    ? 'Loading...'
                                    : (_name.isNotEmpty ? _name : 'Admin'),
                                style: GoogleFonts.poppins(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: titleColor),
                              ),
                              const SizedBox(width: 8),
                              _isSavingName
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: subtitleColor),
                                    )
                                  : GestureDetector(
                                      onTap: () => _showNameDialog(isDark),
                                      child: Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color:
                                              ThemeService.activeAccent(isDark)
                                                  .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(Icons.edit_rounded,
                                            size: 14,
                                            color: ThemeService.activeAccent(
                                                isDark)),
                                      ),
                                    ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(_email,
                              style: GoogleFonts.poppins(
                                  fontSize: 12.5, color: subtitleColor)),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFF8B5CF6)
                                      .withValues(alpha: 0.30)),
                            ),
                            child: Text('Administrator',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF8B5CF6))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildSectionLabel('Account', color: sectionLabelColor),
                    const SizedBox(height: 12),
                    _buildSettingsTile(
                      icon: Icons.mail_outline_rounded,
                      iconBg: isDark
                          ? const Color(0xFF1A2A4A)
                          : const Color(0xFFDBEAFE),
                      iconColor: const Color(0xFF3B82F6),
                      label: 'Change Email',
                      subtitle: 'Verify a new email address',
                      onTap: _changeEmail,
                      cardColor: cardColor,
                      titleColor: titleColor,
                      subtitleColor: subtitleColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildSettingsTile(
                      icon: Icons.lock_outline_rounded,
                      iconBg: isDark
                          ? const Color(0xFF2A2010)
                          : const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFF59E0B),
                      label: 'Change Password',
                      subtitle: 'Update or reset your password',
                      onTap: _changePassword,
                      cardColor: cardColor,
                      titleColor: titleColor,
                      subtitleColor: subtitleColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _isSavingCountry ? null : _pickCountry,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: isDark
                              ? Border.all(
                                  color: ThemeService.border(isDark), width: 1)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: ThemeService.activeAccent(isDark)
                                  .withValues(alpha: isDark ? 0.22 : 0.14),
                              blurRadius: 16,
                              spreadRadius: 0.3,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: isDark ? 0.18 : 0.10),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  _country.isEmpty
                                      ? '🏳️'
                                      : (countryByName(_country).flag.isEmpty
                                          ? '🏳️'
                                          : countryByName(_country).flag),
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Country',
                                      style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: titleColor)),
                                  Text(
                                      _country.isNotEmpty
                                          ? _country
                                          : 'Not set',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12, color: subtitleColor)),
                                ],
                              ),
                            ),
                            _isSavingCountry
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color:
                                            ThemeService.activeAccent(isDark)),
                                  )
                                : Icon(Icons.chevron_right_rounded,
                                    color: isDark
                                        ? ThemeService.textSecondary(isDark)
                                        : Colors.grey.shade300,
                                    size: 22),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildSectionLabel('Notifications',
                        color: sectionLabelColor),
                    const SizedBox(height: 12),
                    _buildSettingsTile(
                      icon: Icons.notifications_none_rounded,
                      iconBg: ThemeService.activeAccent(isDark)
                          .withValues(alpha: isDark ? 0.15 : 0.10),
                      iconColor: ThemeService.activeAccent(isDark),
                      label: 'View Notifications',
                      subtitle: 'Feedback replies & system alerts',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const AdminNotificationsScreen())),
                      cardColor: cardColor,
                      titleColor: titleColor,
                      subtitleColor: subtitleColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 28),
                    _buildSectionLabel('Preferences', color: sectionLabelColor),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: isDark
                            ? Border.all(
                                color: ThemeService.border(isDark), width: 1)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: ThemeService.activeAccent(isDark)
                                .withValues(alpha: isDark ? 0.22 : 0.14),
                            blurRadius: 16,
                            spreadRadius: 0.3,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Notifications',
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: titleColor)),
                            subtitle: Text('Admin alerts and feedback pings',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: subtitleColor)),
                            secondary: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: ThemeService.activeAccent(isDark)
                                    .withValues(alpha: isDark ? 0.15 : 0.10),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.notifications_outlined,
                                  color: ThemeService.activeAccent(isDark),
                                  size: 20),
                            ),
                            value: _notificationsEnabled,
                            activeThumbColor: ThemeService.activeAccent(isDark),
                            inactiveThumbColor: isDark
                                ? ThemeService.textSecondary(isDark)
                                : Colors.grey.shade400,
                            inactiveTrackColor: isDark
                                ? ThemeService.surfaceAlt(isDark)
                                : Colors.grey.shade200,
                            onChanged: _setNotificationsEnabled,
                          ),
                          Divider(color: dividerColor),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Dark Mode',
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: titleColor)),
                            subtitle: Text('Switch app theme',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: subtitleColor)),
                            secondary: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6)
                                    .withValues(alpha: isDark ? 0.20 : 0.10),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isDark
                                    ? Icons.dark_mode
                                    : Icons.dark_mode_outlined,
                                color: isDark
                                    ? const Color(0xFFB39DDB)
                                    : const Color(0xFF3B82F6),
                                size: 20,
                              ),
                            ),
                            value: isDark,
                            activeThumbColor: ThemeService.activeAccent(isDark),
                            inactiveThumbColor: Colors.grey.shade400,
                            inactiveTrackColor: Colors.grey.shade200,
                            onChanged: (val) => themeNotifier.toggleTheme(val),
                          ),
                        ],
                      ),
                    ),
                    if (isDark) ...[
                      const SizedBox(height: 28),
                      _buildSectionLabel('Appearance',
                          color: sectionLabelColor),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: dividerColor, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: ThemeService.activeAccent(isDark)
                                  .withValues(alpha: 0.22),
                              blurRadius: 16,
                              spreadRadius: 0.3,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dark Mode Colors',
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: titleColor)),
                            const SizedBox(height: 2),
                            Text('Pick the color scheme used in dark mode',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: subtitleColor)),
                            const SizedBox(height: 14),
                            ...ThemeService.availableDarkPalettes.map((p) {
                              final selected = themeNotifier.darkPalette == p;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildPaletteOption(
                                  palette: p,
                                  selected: selected,
                                  titleColor: titleColor,
                                  subtitleColor: subtitleColor,
                                  accent: ThemeService.activeAccent(isDark),
                                  dividerColor: dividerColor,
                                  onTap: () => themeNotifier.setDarkPalette(p),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    _buildSectionLabel('Danger Zone', color: sectionLabelColor),
                    const SizedBox(height: 12),
                    _buildSettingsTile(
                      icon: Icons.logout_rounded,
                      iconBg: isDark
                          ? const Color(0xFF2A2010)
                          : const Color(0xFFFEF3C7),
                      iconColor: Colors.orange.shade600,
                      label: 'Logout',
                      subtitle: 'Sign out of the admin panel',
                      onTap: _logout,
                      cardColor: cardColor,
                      titleColor: titleColor,
                      subtitleColor: subtitleColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildSettingsTile(
                      icon: Icons.delete_outline_rounded,
                      iconBg: isDark
                          ? const Color(0xFF2A0A0A)
                          : const Color(0xFFFFEBEE),
                      iconColor: Colors.red.shade400,
                      label: 'Delete Account',
                      subtitle: 'Requires promoting another admin first',
                      onTap: _deleteAccount,
                      labelColor: Colors.red.shade500,
                      cardColor: cardColor,
                      titleColor: titleColor,
                      subtitleColor: subtitleColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),
                    Divider(color: dividerColor),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Mother & Baby SmartCare — Admin  ·  v1.0.0',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isDark
                                ? ThemeService.textSecondary(isDark)
                                : Colors.grey.shade400),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPaletteOption({
    required AppDarkPalette palette,
    required bool selected,
    required Color titleColor,
    required Color subtitleColor,
    required Color accent,
    required Color dividerColor,
    required VoidCallback onTap,
  }) {
    final swatchBg = ThemeService.previewBgOf(palette);
    final swatchAccent = ThemeService.previewColorOf(palette);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent : dividerColor,
            width: selected ? 1.5 : 1,
          ),
          color: selected ? accent.withValues(alpha: 0.08) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: swatchBg,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: dividerColor),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: swatchAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ThemeService.labelOf(palette),
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: titleColor)),
                  Text(ThemeService.descriptionOf(palette),
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: subtitleColor)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? accent : dividerColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, {required Color color}) {
    return Text(label.toUpperCase(),
        style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 1.0));
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required Color cardColor,
    required Color titleColor,
    required Color subtitleColor,
    required bool isDark,
    Color? labelColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isDark
              ? Border.all(color: ThemeService.border(isDark), width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: ThemeService.activeAccent(isDark)
                  .withValues(alpha: isDark ? 0.22 : 0.14),
              blurRadius: 16,
              spreadRadius: 0.3,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: labelColor ?? titleColor)),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: subtitleColor)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: isDark
                    ? ThemeService.textSecondary(isDark)
                    : Colors.grey.shade300,
                size: 22),
          ],
        ),
      ),
    );
  }
}
