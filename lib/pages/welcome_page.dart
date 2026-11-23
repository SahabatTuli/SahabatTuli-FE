import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import 'dashboard_page.dart';
import 'login_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final AuthService _authService = AuthService();

  bool _isCheckingSession = true;
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    try {
      final session = await _authService.getSession();
      if (!mounted) return;

      if (session != null && session['user'] != null) {
        final user = AuthResponse.from(session['user']);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(initialUser: user),
          ),
        );
        return;
      }
    } catch (_) {
      // Abaikan error dan tampilkan halaman Welcome seperti biasa
    }

    if (mounted) {
      setState(() => _isCheckingSession = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);

    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
      ),
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: SafeArea(
          child: _isCheckingSession
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image(
                        image: AssetImage('assets/images/LogoAPP.webp'),
                        width: 200,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 24),
                      CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2.5,
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Expanded(
                        child: Center(
                          child: Image(
                            image: AssetImage('assets/images/LogoAPP.webp'),
                            width: 220,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      SizedBox(
                        width: 295,
                        child: PrimaryButton(
                          text: _isGoogleLoading
                              ? 'Redirecting to Google...'
                              : 'Continue with Google',
                          imagePath: 'assets/images/google.png',
                          onPressed:
                              _isGoogleLoading ? () {} : _handleGoogleSignIn,
                        ),
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: 295,
                        child: PrimaryButton(
                          text: 'Continue with Email',
                          icon: FontAwesomeIcons.envelope,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 18),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Sign in',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}