import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/home_chat_view.dart';
import '../widgets/custom_button_nav.dart';
import 'collaboration_page.dart';
import 'history_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            HomeChatView(
              currentTabIndex: _currentIndex,
              onTabChanged: _onTabChanged,
            ),
            CollaborationPage(
              onBackToHome: () => _onTabChanged(0),
            ),
            HistoryPage(
              isTabMode: true,
              onBackToHome: () => _onTabChanged(0),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _currentIndex == 0
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: CustomBottomNav(
                  currentIndex: _currentIndex,
                  onTap: _onTabChanged,
                ),
              ),
            ),
    );
  }
}