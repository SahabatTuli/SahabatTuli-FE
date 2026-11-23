import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button_nav.dart';
import '../widgets/home_chat_view.dart';
import 'collaboration_page.dart';
import 'history_page.dart';
import 'welcome_page.dart';

class DashboardPage extends StatefulWidget {
  final AuthResponse? initialUser;

  const DashboardPage({super.key, this.initialUser});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _authService = AuthService();

  int _currentIndex = 0;
  late bool _isCheckingSession;
  AuthResponse? _currentUser;

  @override
  void initState() {
    super.initState();
    if (widget.initialUser != null) {
      _currentUser = widget.initialUser;
      _isCheckingSession = false;
    } else {
      _isCheckingSession = true;
      _verifySession();
    }
  }

  Future<void> _verifySession() async {
    final sessionData = await _authService.getSession();

    if (!mounted) return;

    if (sessionData == null || sessionData['user'] == null) {
      await ApiClient.clearCookie();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
      );
      return;
    }

    setState(() {
      _currentUser = AuthResponse.from(sessionData['user']);
      _isCheckingSession = false;
    });
  }

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return const Scaffold(
        backgroundColor: AppColors.navy,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.white),
        ),
      );
    }

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