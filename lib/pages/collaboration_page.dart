import 'package:flutter/material.dart';

import '../services/collaboration_service.dart';
import '../theme/app_colors.dart';
import 'add_friend_page.dart';
import 'live_transcript_page.dart';
import 'profile_page.dart';

class CollaborationPage extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const CollaborationPage({super.key, this.onBackToHome});

  @override
  State<CollaborationPage> createState() => _CollaborationPageState();
}

class _CollaborationPageState extends State<CollaborationPage> {
  final CollaborationService _collaborationService = CollaborationService();

  List _rooms = [];
  bool _isLoading = true;
  bool _isCreating = false;
  String? _joiningRoomId;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    try {
      final rooms = await _collaborationService.getActiveRooms();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
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

  Future<void> _openLiveTranscript({
    required String roomId,
    required String roomTitle,
    required String hostName,
    required bool isHost,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveTranscriptPage(
          roomId: roomId,
          roomTitle: roomTitle,
          hostName: hostName,
          isHost: isHost,
        ),
      ),
    );
    // Refresh daftar room setelah keluar dari ruangan
    if (mounted) {
      _loadRooms();
    }
  }

  Future<void> _handleJoinRoom(Map room) async {
    final roomId = room['id']?.toString() ?? '';
    if (roomId.isEmpty || _joiningRoomId != null) return;

    setState(() => _joiningRoomId = roomId);
    try {
      await _collaborationService.joinRoom(roomId);
      if (!mounted) return;
      await _openLiveTranscript(
        roomId: roomId,
        roomTitle: room['title']?.toString() ?? 'Collaboration Room',
        hostName: room['creator']?.toString() ?? 'Host',
        isHost: false,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _joiningRoomId = null);
      }
    }
  }

  void _showCreateRoomDialog() {
    final TextEditingController roomController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 36),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Create New Room',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 40,
                      child: TextField(
                        controller: roomController,
                        autofocus: true,
                        enabled: !_isCreating,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textDark,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Room ${_rooms.length + 1}',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFE0E0E0),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: _isCreating
                            ? null
                            : () async {
                                final title = roomController.text.trim().isEmpty
                                    ? 'Room ${_rooms.length + 1}'
                                    : roomController.text.trim();

                                setDialogState(() => _isCreating = true);
                                setState(() => _isCreating = true);

                                try {
                                  final newRoom = await _collaborationService
                                      .createRoom(title);
                                  if (!mounted) return;
                                  Navigator.pop(dialogContext);

                                  await _openLiveTranscript(
                                    roomId: newRoom['id'].toString(),
                                    roomTitle: newRoom['title'].toString(),
                                    hostName: newRoom['creator'].toString(),
                                    isHost: true,
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  _showSnackBar(
                                    e.toString().replaceFirst('Exception: ', ''),
                                    isError: true,
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => _isCreating = false);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: _isCreating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Create',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

  Widget _buildAddFriendsButton() {
    return ElevatedButton(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddFriendPage(),
          ),
        );
        _loadRooms();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.navy,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 12,
        ),
      ),
      child: const Text(
        '+ Add friends for collab',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
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
                    onPressed: () {
                      if (widget.onBackToHome != null) {
                        widget.onBackToHome!();
                      } else if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.navy,
                      size: 20,
                    ),
                  ),
                  const Text(
                    'Collaboration',
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

            const SizedBox(height: 20),

            // --- LIST ROOM COLLABORATION ---
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.navy),
                    )
                  : RefreshIndicator(
                      color: AppColors.navy,
                      onRefresh: _loadRooms,
                      child: _rooms.isEmpty
                          ? ListView(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 40, 24, 88),
                              children: [
                                Center(
                                  child: Text(
                                    'Belum ada room kolaborasi aktif.\nBuat room baru atau tambahkan teman terlebih dahulu.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Center(child: _buildAddFriendsButton()),
                              ],
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 0, 24, 88),
                              itemCount: _rooms.length,
                              itemBuilder: (context, index) {
                                final room = _rooms[index] as Map;
                                final roomId = room['id']?.toString() ?? '';
                                final isJoining = _joiningRoomId == roomId;

                                return Column(
                                  children: [
                                    // CARD ROOM
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 14),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 18,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.04),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  room['title'].toString(),
                                                  style: const TextStyle(
                                                    color: AppColors.textDark,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                const Text(
                                                  'Created by',
                                                  style: TextStyle(
                                                    color: AppColors.textDark,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 16,
                                                      height: 16,
                                                      decoration:
                                                          const BoxDecoration(
                                                        color:
                                                            Color(0xFF9CCC65),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.person,
                                                        color: Colors.white,
                                                        size: 11,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Text(
                                                        room['creator']
                                                            .toString(),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          color: AppColors
                                                              .textDark,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          ElevatedButton(
                                            onPressed: isJoining
                                                ? null
                                                : () => _handleJoinRoom(room),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.navy,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 22,
                                                vertical: 10,
                                              ),
                                            ),
                                            child: isJoining
                                                ? const SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : const Text(
                                                    'Join',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // TOMBOL ADD FRIENDS FOR COLLAB
                                    if (index == _rooms.length - 1) ...[
                                      const SizedBox(height: 6),
                                      _buildAddFriendsButton(),
                                      const SizedBox(height: 20),
                                    ],
                                  ],
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),

        // --- TOMBOL PLUS BULAT DI POJOK KANAN BAWAH ---
        Positioned(
          right: 24,
          bottom: 20,
          child: GestureDetector(
            onTap: _showCreateRoomDialog,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.navy,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}