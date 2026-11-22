import 'package:flutter/material.dart';

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

  final List _allUsers = [
    {
      'id': '2',
      'name': 'User 2',
      'isAdded': false,
    },
  ];

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List get _filteredUsers {
    if (_searchQuery.trim().isEmpty) return _allUsers;
    return _allUsers.where((user) {
      final name = user['name'].toString().toLowerCase();
      return name.contains(_searchQuery.trim().toLowerCase());
    }).toList();
  }

  void _toggleAddFriend(Map user) {
    setState(() {
      user['isAdded'] = !(user['isAdded'] as bool);
    });

    final added = user['isAdded'] as bool;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added
              ? '${user['name']} ditambahkan ke daftar teman'
              : '${user['name']} dihapus dari daftar teman',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = _filteredUsers;

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
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
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
                  child: users.isEmpty
                      ? Center(
                          child: Text(
                            'Pengguna tidak ditemukan',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: users.length,
                          separatorBuilder: (_, __) => Divider(
                            color: Colors.grey.shade200,
                            height: 24,
                            thickness: 1,
                          ),
                          itemBuilder: (context, index) {
                            final user = users[index] as Map;
                            final isAdded = user['isAdded'] as bool;

                            return Column(
                              children: [
                                Row(
                                  children: [
                                    // Avatar Hijau Muda
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
                                    // Nama User
                                    Expanded(
                                      child: Text(
                                        user['name'].toString(),
                                        style: const TextStyle(
                                          color: AppColors.textDark,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    // Tombol + Add
                                    SizedBox(
                                      height: 30,
                                      child: ElevatedButton(
                                        onPressed: () => _toggleAddFriend(user),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isAdded
                                              ? Colors.grey.shade400
                                              : AppColors.navy,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: Text(
                                          isAdded ? 'Added' : '+ Add',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
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
              // Kembali ke halaman utama / tab yang dipilih
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }
}