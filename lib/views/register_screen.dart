import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../controllers/auth_controller.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'seller_dashboard.dart';

// ---------------------------------------------------------------------------
// RegisterScreen — Dual-Role Sign-Up
// Supports two roles: "General User" (→ HomeScreen) and "Art Seller"
// (→ SellerDashboard). Creates a Firebase Auth account and writes a
// Firestore document: { name, email, role, createdAt }.
// Errors are displayed as SnackBar alerts.
// ---------------------------------------------------------------------------

class RegisterScreen extends StatefulWidget {
  final bool defaultToSeller;
  const RegisterScreen({super.key, this.defaultToSeller = false});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  // ── Form state ─────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl    = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _passwordCtrl    = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscurePassword        = true;
  bool _obscureConfirmPassword = true;

  // ── Role selection — "General User" or "Art Seller" ────────────────────────
  late bool _isSeller;

  // ── Profile Picture ────────────────────────────────────────────────────────
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // ── Entrance animation ──────────────────────────────────────────────────
  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _isSeller = widget.defaultToSeller;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // ── Registration handler ──────────────────────────────────────────────────

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final authCtrl = context.read<AuthController>();

    final success = await authCtrl.register(
      email:    _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      fullName: _fullNameCtrl.text.trim(),
      role:     _isSeller ? 'seller' : 'user',
      profileImageBytes: _selectedImage != null ? _selectedImage!.readAsBytesSync() : null,
    );

    if (!mounted) return;

    if (success) {
      if (_isSeller) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SellerDashboard()),
              (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
        );
      }
    } else {
      final error = authCtrl.errorMessage ?? 'Registration failed. Please try again.';
      _showErrorSnackBar(error);
      authCtrl.clearError();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFB71C1C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authCtrl = context.watch<AuthController>();
    final size     = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      resizeToAvoidBottomInset: true, // Keyboard එක එද්දී Resize වෙන කෑල්ල
      body: Stack(
        children: [
        // ── Decorative background accent ──────────────────────────────────
        Positioned(
        top: -80,
        right: -80,
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppTheme.primaryAccent.withValues(alpha: 0.10),
                AppTheme.primaryAccent.withValues(alpha: 0.00),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: -60,
        left: -60,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF8D6E63).withValues(alpha: 0.12),
                const Color(0xFF8D6E63).withValues(alpha: 0.00),
              ],
            ),
          ),
        ),
      ),

      // ── Main scrollable form ──────────────────────────────────────────
      SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: size.height * 0.03,
          ),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Form(
                key: _formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    const SizedBox(height: 16),

                // ── Profile Picture Avatar ───────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                        border: Border.all(
                          color: AppTheme.primaryAccent.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _selectedImage == null
                          ? Icon(
                              Icons.add_a_photo_outlined,
                              color: AppTheme.primaryAccent,
                              size: 32,
                            )
                          : null,
                    ),
                  ),
                ),
          const SizedBox(height: 28),

          // ── Headline ─────────────────────────────────────
          Text(
            'Create Account',
            style: GoogleFonts.outfit(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
              letterSpacing: -1.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Join ArtSpace Preview — choose your account type below',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // ── Aesthetic Seller Toggle ───────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _isSeller = !_isSeller),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _isSeller
                    ? AppTheme.primaryAccent.withOpacity(0.05)
                    : AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isSeller
                      ? AppTheme.primaryAccent.withOpacity(0.5)
                      : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isSeller ? AppTheme.primaryAccent : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.storefront_rounded,
                      size: 20,
                      color: _isSeller ? Colors.white : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _isSeller ? 'Register as an Art Seller' : 'Register as a User',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isSeller,
                    onChanged: (val) => setState(() => _isSeller = val),
                    activeColor: AppTheme.primaryAccent,
                    activeTrackColor: AppTheme.primaryAccent.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          _SectionLabel(label: 'Personal Details'),
          const SizedBox(height: 12),

          _FormField(
            controller: _fullNameCtrl,
            hintText: 'Full Name',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter your full name';
              }
              if (v.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          _FormField(
            controller: _emailCtrl,
            hintText: 'Email Address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter your email';
              }
              final emailRegex = RegExp(
                  r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
              if (!emailRegex.hasMatch(v.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          _SectionLabel(label: 'Security'),
          const SizedBox(height: 12),

          _FormField(
            controller: _passwordCtrl,
            hintText: 'Password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            suffixIcon: _EyeToggle(
              obscure: _obscurePassword,
              onToggle: () => setState(
                      () => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Please enter a password';
              }
              if (v.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          _FormField(
            controller: _confirmPassCtrl,
            hintText: 'Confirm Password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleRegister(),
            suffixIcon: _EyeToggle(
              obscure: _obscureConfirmPassword,
              onToggle: () => setState(
                    () => _obscureConfirmPassword =
                !_obscureConfirmPassword,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Please confirm your password';
              }
              if (v != _passwordCtrl.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),

          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'Minimum 6 characters',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 36),

          _RegisterButton(
            isLoading: authCtrl.isLoading,
            onTap: authCtrl.isLoading ? null : _handleRegister,
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: authCtrl.isLoading
                ? null
                : () {
              authCtrl.clearError();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const LoginScreen()),
              );
            },
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: 'Already have an account? ',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                ),
                children: [
                  TextSpan(
                    text: 'Log In',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppTheme.primaryAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'By creating an account you agree to our\nTerms of Service and Privacy Policy.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppTheme.textMuted.withValues(alpha: 0.7),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          ],
        ),
      ),
    ),
    ),
    ),
    ),

    // ── Loading overlay ───────────────────────────────────────────────
    if (authCtrl.isLoading)
    Container(
    color: AppTheme.backgroundBeige.withValues(alpha: 0.80),
    child: Center(
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
    color: AppTheme.surfaceWhite,
    borderRadius: BorderRadius.circular(20),
    boxShadow: AppTheme.premiumShadow,
    ),
    child: Center(
    child: CircularProgressIndicator(
    color: AppTheme.primaryAccent,
    strokeWidth: 3,
    ),
    ),
    ),
    const SizedBox(height: 18),
    Text(
    'Creating your account…',
    style: GoogleFonts.outfit(
    fontSize: 14,
    color: AppTheme.textMuted,
    fontWeight: FontWeight.w500,
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

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: AppTheme.textMuted.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const _FormField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: AppTheme.smallRadius,
        boxShadow: AppTheme.premiumShadow,
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        validator: validator,
        style: GoogleFonts.outfit(
          color: AppTheme.textDark,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.outfit(
            color: AppTheme.textMuted,
            fontSize: 15,
          ),
          prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: AppTheme.smallRadius,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppTheme.smallRadius,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppTheme.smallRadius,
            borderSide: BorderSide(
              color: AppTheme.primaryAccent.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppTheme.smallRadius,
            borderSide: const BorderSide(
              color: Color(0xFFD32F2F),
              width: 1.2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppTheme.smallRadius,
            borderSide: const BorderSide(
              color: Color(0xFFD32F2F),
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: AppTheme.surfaceWhite,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          errorStyle: GoogleFonts.outfit(
            fontSize: 12,
            color: const Color(0xFFD32F2F),
          ),
        ),
      ),
    );
  }
}

class _EyeToggle extends StatelessWidget {
  final bool obscure;
  final VoidCallback onToggle;
  const _EyeToggle({required this.obscure, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppTheme.textMuted,
        size: 20,
      ),
      onPressed: onToggle,
      splashRadius: 20,
    );
  }
}

class _RegisterButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;
  const _RegisterButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        boxShadow: onTap == null
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF4A3424).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A3424),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          disabledBackgroundColor: const Color(0xFF4A3424).withOpacity(0.6),
          disabledForegroundColor: Colors.white.withOpacity(0.8),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final String label;
  final String description;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      lowerBound: 0.0,
      upperBound: 0.04,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
          decoration: BoxDecoration(
            color: selected
                ? widget.accentColor.withValues(alpha: 0.10)
                : AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? widget.accentColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: selected ? widget.accentColor : Colors.grey),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(widget.description, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}