import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

              // Judul "Sign in"
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
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w300,
                      color: AppColors.white,
                      fontSize: 12,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // TODO: pindah ke halaman register
                      Navigator.pop(context);
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
                  onTap: () {
                    // TODO: lupa password
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontFamily: 'Inter',
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
                text: 'Login',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DashboardPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              Row(
                children: const [
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
                text: 'Continue with Google',
                imagePath: 'assets/images/google.png',
                onPressed: () {
                  // TODO: login google
                },
              ),
              const SizedBox(height: 16),

              PrimaryButton(
                text: 'Continue with Email',
                icon: FontAwesomeIcons.envelope,
                onPressed: () {
                  // TODO: login email (dari halaman ini)
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