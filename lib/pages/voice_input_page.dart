import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class VoiceInputPage extends StatelessWidget {
  const VoiceInputPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: const Text(
          'Voice Input',
          style: TextStyle(color: AppColors.white),
        ),
      ),
      body: const Center(
        child: Text(
          'Voice Input Page\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: AppColors.white),
        ),
      ),
    );
  }
}
