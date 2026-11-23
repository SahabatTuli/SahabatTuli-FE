import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import 'dashboard_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Email dan password wajib diisi');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (!mounted) return;
      final user = result['user'] != null
          ? AuthResponse.from(result['user'])
          : null;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardPage(initialUser: user),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);

    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    final tokenController = TextEditingController();
    final newPasswordController = TextEditingController();

    bool isSubmitting = false;
    bool isResetStep = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 28),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isResetStep ? 'Setel Password Baru' : 'Reset Password',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isResetStep
                          ? 'Masukkan token dari link email dan password baru Anda (minimal 8 karakter).'
                          : 'Masukkan email akun Anda untuk menerima tautan reset password.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (!isResetStep) ...[
                      TextField(
                        controller: resetEmailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isSubmitting,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textDark,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Email Address',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13.5,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFEAEAEA),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: tokenController,
                        enabled: !isSubmitting,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textDark,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Token Reset Password',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13.5,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFEAEAEA),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: newPasswordController,
                        obscureText: true,
                        enabled: !isSubmitting,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textDark,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Password Baru (min. 8 karakter)',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13.5,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFEAEAEA),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (!isResetStep) {
                                  final email =
                                      resetEmailController.text.trim();
                                  if (email.isEmpty) {
                                    _showSnackBar('Email wajib diisi');
                                    return;
                                  }

                                  setDialogState(() => isSubmitting = true);
                                  try {
                                    await _authService.requestPasswordReset(
                                      email: email,
                                    );
                                    if (!mounted) return;
                                    setDialogState(() {
                                      isSubmitting = false;
                                      isResetStep = true;
                                    });
                                    _showSnackBar(
                                      'Permintaan reset password terkirim! Cek email Anda.',
                                      isSuccess: true,
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    setDialogState(() => isSubmitting = false);
                                    _showSnackBar(
                                      e
                                          .toString()
                                          .replaceFirst('Exception: ', ''),
                                    );
                                  }
                                } else {
                                  final token = tokenController.text.trim();
                                  final newPass = newPasswordController.text;

                                  if (token.isEmpty || newPass.length < 8) {
                                    _showSnackBar(
                                      'Isi token dan password baru minimal 8 karakter',
                                    );
                                    return;
                                  }

                                  setDialogState(() => isSubmitting = true);
                                  try {
                                    await _authService.resetPassword(
                                      newPassword: newPass,
                                      token: token,
                                    );
                                    if (!mounted) return;
                                    Navigator.pop(dialogContext);
                                    _showSnackBar(
                                      'Password berhasil diubah! Silakan login kembali.',
                                      isSuccess: true,
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    setDialogState(() => isSubmitting = false);
                                    _showSnackBar(
                                      e
                                          .toString()
                                          .replaceFirst('Exception: ', ''),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isResetStep
                                    ? 'Simpan Password Baru'
                                    : 'Kirim Link Reset',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: isSubmitting
                          ? null
                          : () {
                              setDialogState(() {
                                isResetStep = !isResetStep;
                              });
                            },
                      child: Text(
                        isResetStep
                            ? 'Kembali kirim ulang email'
                            : 'Sudah punya token? Masukkan di sini',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green.shade600 : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Sign in',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text(
                    "Don't have an account yet? ",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w300,
                      color: AppColors.white,
                      fontSize: 12,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Sign up',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildInput(
                controller: _emailController,
                focusNode: _emailFocusNode,
                hint: 'Email Address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildInput(
                controller: _passwordController,
                hint: 'Password',
                obscure: _obscurePassword,
                onToggleVisibility: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: _showForgotPasswordDialog,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w300,
                      color: AppColors.white,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: _isLoading ? 'Signing in...' : 'Login',
                onPressed: _isLoading ? () {} : _handleLogin,
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(
                    child: Divider(color: AppColors.white, thickness: 1),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Or',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: AppColors.white, thickness: 1),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: _isGoogleLoading
                    ? 'Redirecting to Google...'
                    : 'Continue with Google',
                imagePath: 'assets/images/google.png',
                onPressed: _isGoogleLoading ? () {} : _handleGoogleSignIn,
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Continue with Email',
                icon: FontAwesomeIcons.envelope,
                onPressed: () {
                  _emailFocusNode.requestFocus();
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String hint,
    bool obscure = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 18,
          ),
          suffixIcon: onToggleVisibility != null
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF9E9E9E),
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
        ),
      ),
    );
  }
}