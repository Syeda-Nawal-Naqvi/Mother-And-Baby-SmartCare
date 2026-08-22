import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'verify_email_screen.dart';
import 'set_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  static const List<Color> _brandGradient = [
    Color(0xFF7A2790),
    Color(0xFFD44FC2),
    Color(0xFFE91E8C),
  ];
  static const Color _accent = Color(0xFFE91E8C);
  static const Color _accentDeep = Color(0xFF7A2790);
  static const Color _headingColor = Color(0xFF6A1B9A);
  static const Color _labelColor = Color(0xFF9C27B0);
  static const Color _inputTextColor = Color(0xFF3D1259);

  static const String _noSpaceHelper =
      'Use letters, numbers, and symbols (- _ !) — no spaces.';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showToast(String message, {required bool isSuccess}) {
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
              child: Text(
                message,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor:
            isSuccess ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateByRole(String role) {
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin_dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await _authService.login(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _errorMessage = error;
        _isLoading = false;
      });
      return;
    }

    final isVerified = await _authService.checkEmailVerified();
    if (!mounted) return;

    if (!isVerified) {
      setState(() => _isLoading = false);
      _showToast('Please verify your email first.', isSuccess: false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
      );
      return;
    }

    final role = await _authService.getUserRole(_authService.currentUser!.uid);
    if (!mounted) return;

    setState(() => _isLoading = false);
    _showToast('Login successful! Welcome back 👋', isSuccess: true);
    _navigateByRole(role);
  }

  Future<void> _googleLogin() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });
    _showToast('Opening Google Sign-In…', isSuccess: true);

    final result = await _authService.signInWithGoogle();
    if (!mounted) return;

    if (result['error'] != null) {
      setState(() {
        _errorMessage = result['error'];
        _isGoogleLoading = false;
      });
      return;
    }

    setState(() => _isGoogleLoading = false);

    if (result['isNewUser'] == true) {
      _showToast('Welcome! Account created with Google 🎉', isSuccess: true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SetPasswordScreen(role: result['role']),
        ),
      );
      return;
    }

    if (result['securityNotice'] == true) {
      _showToast(
        'For your security we sent a password reset link to your email — '
        'any old password on this account no longer works.',
        isSuccess: true,
      );
    } else {
      _showToast('Google login successful! 🎉', isSuccess: true);
    }
    _navigateByRole(result['role']);
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? icon,
    String? iconAsset,
    Widget? suffix,
    String? helperText,
  }) {
    final Widget prefix = iconAsset != null
        ? Padding(
            padding: const EdgeInsets.all(12),
            child: Image.asset(
              iconAsset,
              color: _accent,
              errorBuilder: (_, __, ___) => Icon(
                  icon ?? Icons.mail_outline_rounded,
                  color: _accent,
                  size: 20),
            ),
          )
        : Icon(icon ?? Icons.circle_outlined, color: _accent, size: 20);

    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade400),
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      helperText: helperText,
      helperMaxLines: 2,
      helperStyle: GoogleFonts.poppins(
          fontSize: 10.5, color: _labelColor.withValues(alpha: 0.75)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _accent.withValues(alpha: 0.22))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accent, width: 1.8)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade300)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5)),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: GoogleFonts.poppins(
            fontSize: 12.5, fontWeight: FontWeight.w600, color: _labelColor));
  }

  Widget _fieldShadowWrap(Widget child) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight -
                      MediaQuery.of(context).padding.top -
                      32,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              const _AuthLogoMark(
                                assetPath: 'assets/icons/app_logo.png',
                                gradientColors: _brandGradient,
                                size: 92,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Welcome Back!',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _headingColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sign in to your account',
                                style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    color:
                                        _headingColor.withValues(alpha: 0.55)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline_rounded,
                                    color: Colors.red.shade400, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        color: Colors.red.shade700),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _errorMessage = null),
                                  child: Icon(Icons.close,
                                      color: Colors.red.shade300, size: 18),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _buildLabel('Email Address'),
                        const SizedBox(height: 6),
                        _fieldShadowWrap(
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                            ],
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: _inputTextColor,
                                fontWeight: FontWeight.w500),
                            decoration: _inputDecoration(
                                hint: 'Enter your email',
                                iconAsset: 'assets/icons/message.png',
                                icon: Icons.mail_outline_rounded),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(v.trim())) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Password'),
                        const SizedBox(height: 6),
                        _fieldShadowWrap(
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                            ],
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: _inputTextColor,
                                fontWeight: FontWeight.w500),
                            decoration: _inputDecoration(
                              hint: 'Enter your password',
                              icon: Icons.lock_outline_rounded,
                              helperText: _noSpaceHelper,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: _accent.withValues(alpha: 0.7),
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Password is required';
                              }
                              if (v.contains(' ')) {
                                return "Spaces aren't allowed. Use letters, numbers, or symbols like - _ instead.";
                              }
                              if (v.length < 6) {
                                return 'Minimum 6 characters required';
                              }
                              return null;
                            },
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 32),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen()),
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  color: _accentDeep,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _AuthGradientButton(
                          label: 'Sign In',
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _login,
                          gradientColors: _brandGradient,
                          glowColor: _accent,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color: _accent.withValues(alpha: 0.18))),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('OR',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color:
                                          _accentDeep.withValues(alpha: 0.55),
                                      fontWeight: FontWeight.w600)),
                            ),
                            Expanded(
                                child: Divider(
                                    color: _accent.withValues(alpha: 0.18))),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _AuthOutlineButton(
                          accent: _accent,
                          onPressed: _isGoogleLoading ? null : _googleLogin,
                          child: _isGoogleLoading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: _accent, strokeWidth: 2.5),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset('assets/icons/google.png',
                                        width: 20, height: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Continue with Google',
                                      style: GoogleFonts.poppins(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                          color: _headingColor),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 26),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don't have an account? ",
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: _headingColor.withValues(
                                          alpha: 0.6))),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const RegisterScreen()),
                                ),
                                child: Text(
                                  'Sign Up',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _accent),
                                ),
                              ),
                            ],
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
    );
  }
}

class _AuthLogoMark extends StatelessWidget {
  final String assetPath;
  final List<Color> gradientColors;
  final double size;

  const _AuthLogoMark({
    required this.assetPath,
    required this.gradientColors,
    this.size = 92,
  });

  @override
  Widget build(BuildContext context) {
    final borderWidth = size * 0.045;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        padding: EdgeInsets.all(size * 0.16),
        child: ClipOval(
          child: Image.asset(assetPath, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _AuthGradientButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final List<Color> gradientColors;
  final Color glowColor;

  const _AuthGradientButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
    required this.gradientColors,
    required this.glowColor,
  });

  @override
  State<_AuthGradientButton> createState() => _AuthGradientButtonState();
}

class _AuthGradientButtonState extends State<_AuthGradientButton> {
  bool _hover = false;
  bool _pressed = false;

  bool get _active => _hover || _pressed;
  bool get _disabled => widget.onPressed == null;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.97 : (_hover ? 1.02 : 1.0);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: _disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: _disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: _disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: _disabled ? null : () => setState(() => _pressed = false),
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
              colors: _disabled
                  ? widget.gradientColors
                      .map((c) => c.withValues(alpha: 0.45))
                      .toList()
                  : widget.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _disabled
                ? []
                : [
                    BoxShadow(
                      color: widget.glowColor
                          .withValues(alpha: _active ? 0.55 : 0.35),
                      blurRadius: _active ? 26 : 18,
                      offset: const Offset(0, 8),
                      spreadRadius: _active ? 1.5 : 0.5,
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
        ),
      ),
    );
  }
}

class _AuthOutlineButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color accent;

  const _AuthOutlineButton({
    required this.child,
    required this.onPressed,
    required this.accent,
  });

  @override
  State<_AuthOutlineButton> createState() => _AuthOutlineButtonState();
}

class _AuthOutlineButtonState extends State<_AuthOutlineButton> {
  bool _hover = false;
  bool _pressed = false;

  bool get _active => _hover || _pressed;
  bool get _disabled => widget.onPressed == null;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.97 : (_hover ? 1.015 : 1.0);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: _disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: _disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: _disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: _disabled ? null : () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scaleByDouble(scale, scale, 1.0, 1.0),
          transformAlignment: Alignment.center,
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.accent.withValues(alpha: _active ? 0.55 : 0.28),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withValues(alpha: _active ? 0.22 : 0.10),
                blurRadius: _active ? 20 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}
