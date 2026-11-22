import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'login_page.dart';

import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

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
          child: Padding(
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
                  width: 295, // naikkan ke 300–310 jika masih kurang lebar
                  child: PrimaryButton(
                    text: 'Continue with Google',
                    imagePath: 'assets/images/google.png',
                    onPressed: () {},
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