import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'welcome_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();

  String _email = '';
  String _originalUsername = '';
  bool _isLoading = true;
  bool _isEditingUsername = false;
  bool _isSavingUsername = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final session = await _authService.getSession();
      if (!mounted) return;

      final user = session?['user'] is Map
          ? Map.from(session!['user'] as Map)
          : {};

      final name = user['name']?.toString() ?? 'User';
      final email = user['email']?.toString() ?? '-';

      setState(() {
        _originalUsername = name;
        _usernameController.text = name;
        _email = email;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _startEditingUsername() {
    setState(() {
      _isEditingUsername = true;
    });
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _usernameFocusNode.requestFocus();
      }
    });
  }

  Future<void> _saveUsername() async {
    final newName = _usernameController.text.trim();

    if (newName.isEmpty) {
      _showSnackBar('Username tidak boleh kosong', isError: true);
      return;
    }

    if (newName == _originalUsername) {
      _usernameFocusNode.unfocus();
      setState(() => _isEditingUsername = false);
      return;
    }

    setState(() => _isSavingUsername = true);
    try {
      await _authService.updateUserName(newName);
      if (!mounted) return;

      _usernameFocusNode.unfocus();
      setState(() {
        _originalUsername = newName;
        _usernameController.text = newName;
        _isEditingUsername = false;
        _isSavingUsername = false;
      });
      _showSnackBar('Username berhasil diperbarui');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingUsername = false);
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);
    try {
      await _authService.signOut();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.navy),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    const CircleAvatar(
                      radius: 55,
                      backgroundColor: AppColors.navy,
                      child: Icon(
                        Icons.person,
                        color: AppColors.white,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildEditableUsernameField(),
                          const SizedBox(height: 20),
                          _buildReadOnlyField(
                            label: 'Email',
                            value: _email,
                            icon: Icons.email_outlined,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoggingOut ? null : _handleLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red.shade600,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: _isLoggingOut
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.red.shade600,
                                ),
                              )
                            : const Text(
                                'Keluar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEditableUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Username',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: _isEditingUsername
                ? Colors.white
                : const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(12),
            border: _isEditingUsername
                ? Border.all(color: AppColors.navy, width: 1.3)
                : null,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.person_outline,
                color: AppColors.textGray,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _usernameController,
                  focusNode: _usernameFocusNode,
                  readOnly: !_isEditingUsername,
                  enabled: !_isSavingUsername,
                  onSubmitted: (_) => _saveUsername(),
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              if (_isSavingUsername)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.navy,
                  ),
                )
              else if (_isEditingUsername)
                IconButton(
                  onPressed: _saveUsername,
                  tooltip: 'Simpan username',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.check_rounded,
                    color: AppColors.navy,
                    size: 22,
                  ),
                )
              else
                IconButton(
                  onPressed: _startEditingUsername,
                  tooltip: 'Ubah username',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.navy,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textGray, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}