import 'dart:async';
import 'package:flutter/material.dart';

import '../services/friend_services.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button_nav.dart';
import 'profile_page.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final TextEditingController _searchController = TextEditingController();
  final FriendService _friendService = FriendService();

  List _users = [];
  Set _friendIds = {};
  final Set _processingIds = {};

  bool _isLoading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadInitialFriends();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialFriends() async {
    setState(() => _isLoading = true);
    try {
      final friends = await _friendService.getFriends();
      if (!mounted) return;
      setState(() {
        _friendIds = friends.map((f) => f['id'].toString()).toSet();
        _users = friends;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final query = value.trim();
      if (query.isEmpty) {
        await _loadInitialFriends();
        return;
      }

      setState(() => _isLoading = true);
      try {
        final results = await _friendService.searchUsers(query);
        if (!mounted) return;
        for (final user in results) {
          final id = user['id'].toString();
          if (_friendIds.contains(id)) {
            user['isAdded'] = true;
          }
        }
        setState(() {
          _users = results;
          _isLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showSnackBar(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    });
  }

  Future<void> _toggleAddFriend(Map user) async {
    final friendId = user['id'].toString();
    if (friendId.isEmpty || _processingIds.contains(friendId)) return;

    final currentlyAdded = user['isAdded'] == true;

    setState(() {
      _processingIds.add(friendId);
    });

    try {
      if (currentlyAdded) {
        await _friendService.removeFriend(friendId);
        _friendIds.remove(friendId);
        user['isAdded'] = false;
      } else {
        await _friendService.addFriend(friendId);
        _friendIds.add(friendId);
        user['isAdded'] = true;
      }

      if (!mounted) return;
      setState(() {});

      final added = user['isAdded'] == true;
      _showSnackBar(
        added
            ? '${user['name']} ditambahkan ke daftar teman'
            : '${user['name']} dihapus dari daftar teman',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingIds.remove(friendId);
        });
      }
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
    final isSearching = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // --- HEADER PUTIH MELENGKUNG ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.navy,
                      size: 20,
                    ),
                  ),
                  const Text(
                    'Add Friends',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.navy,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // --- SEARCH BAR PILL ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 44,
                padding: const EdgeInsets.only(left: 20, right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 13.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cari....',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13.5,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                      )
                    else
                      const Icon(
                        Icons.search_rounded,
                        color: AppColors.textDark,
                        size: 22,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // --- CONTAINER PUTIH DAFTAR PENGGUNA ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.navy,
                          ),
                        )
                      : _users.isEmpty
                          ? Center(
                              child: Text(
                                isSearching
                                    ? 'Pengguna tidak ditemukan'
                                    : 'Belum ada teman. Cari nama atau email di atas',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _users.length,
                              separatorBuilder: (_, __) => Divider(
                                color: Colors.grey.shade200,
                                height: 24,
                                thickness: 1,
                              ),
                              itemBuilder: (context, index) {
                                final user = _users[index] as Map;
                                final userId = user['id'].toString();
                                final isAdded = user['isAdded'] == true;
                                final isProcessing =
                                    _processingIds.contains(userId);

                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF9CCC65),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user['name'].toString(),
                                                style: const TextStyle(
                                                  color: AppColors.textDark,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (user['email']
                                                  .toString()
                                                  .isNotEmpty)
                                                Text(
                                                  user['email'].toString(),
                                                  style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 11.5,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: 30,
                                          child: ElevatedButton(
                                            onPressed: isProcessing
                                                ? null
                                                : () => _toggleAddFriend(user),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isAdded
                                                  ? Colors.grey.shade400
                                                  : AppColors.navy,
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                            ),
                                            child: isProcessing
                                                ? const SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : Text(
                                                    isAdded ? 'Added' : '+ Add',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Divider(
                                      color: Colors.grey.shade200,
                                      height: 1,
                                      thickness: 1,
                                    ),
                                  ],
                                );
                              },
                            ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: CustomBottomNav(
            currentIndex: 1,
            onTap: (index) {
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }
}