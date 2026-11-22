import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final bool isRecording;
  final bool isTTSMode; 
  final VoidCallback onHomeTap;
  final VoidCallback onMicTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onCollaborationTap;
  final VoidCallback onSwipeFeature; 

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.isRecording,
    required this.isTTSMode, 
    required this.onHomeTap,
    required this.onMicTap,
    required this.onHistoryTap,
    required this.onCollaborationTap,
    required this.onSwipeFeature, 
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // BACKGROUND NAVBAR
          Container(
            height: 70,
            margin: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(35),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _navItem(
                        index: 0,
                        icon: Icons.home_outlined,
                        label: 'Home',
                        isActive: currentIndex == 0,
                        onTap: onHomeTap,
                      ),
                      _navItem(
                        index: 3,
                        icon: Icons.people_alt_outlined,
                        label: 'Collaboration',
                        isActive: currentIndex == 3,
                        onTap: onCollaborationTap,
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: SizedBox(),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _navItem(
                        index: 2,
                        icon: Icons.history,
                        label: 'History',
                        isActive: currentIndex == 2,
                        onTap: onHistoryTap,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // TOMBOL MIC & SWIPE DETECTOR
          Positioned(
            top: 0,
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! < -100 || details.primaryVelocity! > 100) {
                  onSwipeFeature(); 
                }
              },
              onTap: onMicTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isRecording ? 76 : 64,
                height: isRecording ? 76 : 64,
                decoration: BoxDecoration(
                  color: isRecording 
                      ? Colors.red 
                      : (isTTSMode ? Colors.green : AppColors.navy), 
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isRecording ? Colors.red : (isTTSMode ? Colors.green : AppColors.navy))
                          .withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isTTSMode 
                      ? Icons.volume_up 
                      : (isRecording ? Icons.stop : Icons.mic), 
                  color: AppColors.white,
                  size: isRecording ? 32 : 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 👇 MENU ITEM DENGAN ANIMASI
  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80, 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animasi pada Ikon
            AnimatedScale(
              scale: isActive ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                color: isActive ? AppColors.navy : AppColors.textGray,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            // Animasi pada Teks
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                color: isActive ? AppColors.navy : AppColors.textGray,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}