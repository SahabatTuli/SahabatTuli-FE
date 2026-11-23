import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import '../models/message.dart';
import '../services/auth_service.dart';
import '../services/history_service.dart';
import '../theme/app_colors.dart';
import '../pages/profile_page.dart';
import 'chat_bubble.dart';
import 'custom_button_nav.dart';

class HomeChatView extends StatefulWidget {
  final int currentTabIndex;
  final ValueChanged<int> onTabChanged;

  const HomeChatView({
    super.key,
    required this.currentTabIndex,
    required this.onTabChanged,
  });

  @override
  State<HomeChatView> createState() => _HomeChatViewState();
}

class _HomeChatViewState extends State<HomeChatView>
    with WidgetsBindingObserver {
  final List<Message> _messages = [];

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final AuthService _authService = AuthService();
  final HistoryService _historyService = HistoryService();

  bool _isRecording = false;
  bool _isChatStarted = false;
  bool _isTTSMode = false;
  bool _isSaving = false;
  String _userName = 'User';

  // State untuk gesture slide-up mic & deteksi keyboard
  double _micDragOffsetY = 0.0;
  bool _hasTriggeredSwipeUp = false;
  bool _keyboardOpenedInTTS = false;

  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  String _currentText = '';

  final TextEditingController _ttsController = TextEditingController();
  final FocusNode _ttsFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initTts();
    _loadUserName();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("id-ID");
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _loadUserName() async {
    try {
      final session = await _authService.getSession();
      if (!mounted) return;
      final user = session?['user'];
      if (user is Map && user['name'] != null) {
        final fullName = user['name'].toString().trim();
        if (fullName.isNotEmpty) {
          setState(() {
            _userName = fullName.split(' ').first;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _ttsController.dispose();
    _ttsFocusNode.dispose();
    _scrollController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  /// Mendeteksi perubahan tinggi keyboard secara real-time
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!mounted || !_isTTSMode) return;

    final bottomInset = View.of(context).viewInsets.bottom;

    if (bottomInset > 0) {
      // Keyboard sudah terbuka penuh
      _keyboardOpenedInTTS = true;
    } else if (_keyboardOpenedInTTS && bottomInset == 0) {
      // Keyboard baru saja ditutup -> otomatis kembalikan tombol mic
      _keyboardOpenedInTTS = false;
      _switchToSTTMode();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _switchToTTSMode() {
    if (_isRecording) {
      _speech.stop();
      _timer?.cancel();
    }
    setState(() {
      _isRecording = false;
      _isChatStarted = true;
      _isTTSMode = true;
      _keyboardOpenedInTTS = false;
      _micDragOffsetY = 0.0;
    });
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) {
        _ttsFocusNode.requestFocus();
      }
    });
  }

  void _switchToSTTMode() {
    _ttsFocusNode.unfocus();
    setState(() {
      _isChatStarted = true;
      _isTTSMode = false;
      _keyboardOpenedInTTS = false;
      _micDragOffsetY = 0.0;
    });
  }

  void _resetChat() {
    if (_isRecording) {
      _speech.stop();
      _timer?.cancel();
    }
    _ttsFocusNode.unfocus();
    setState(() {
      _isRecording = false;
      _isChatStarted = false;
      _isTTSMode = false;
      _keyboardOpenedInTTS = false;
      _micDragOffsetY = 0.0;
      _messages.clear();
      _currentText = '';
      _recordingDuration = Duration.zero;
      _ttsController.clear();
    });
  }

  Future<void> _handleSendTTS() async {
    final text = _ttsController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isChatStarted = true;
      _messages.add(
        Message(
          text: text,
          timestamp: DateTime.now(),
          isFromUser: true,
        ),
      );
      _ttsController.clear();
    });

    _scrollToBottom();
    await _flutterTts.speak(text);
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _speech.stop();
      _timer?.cancel();

      setState(() => _isRecording = false);

      await Future.delayed(const Duration(milliseconds: 300));

      if (_currentText.trim().isNotEmpty) {
        setState(() {
          _messages.add(
            Message(
              text: _currentText.trim(),
              timestamp: DateTime.now(),
              isFromUser: false,
            ),
          );
          _currentText = '';
          _recordingDuration = Duration.zero;
        });
        _scrollToBottom();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada suara terdeteksi'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (_isRecording) _toggleRecording();
          }
        },
        onError: (error) {
          debugPrint('Speech error: $error');
        },
      );

      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mikrofon tidak tersedia'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      _currentText = '';
      _recordingDuration = Duration.zero;

      setState(() {
        _isChatStarted = true;
        _isTTSMode = false;
        _isRecording = true;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingDuration = Duration(seconds: timer.tick);
          });
        }
      });

      await _speech.listen(
        onResult: (result) {
          setState(() {
            _currentText = result.recognizedWords;
          });
          _scrollToBottom();
        },
        localeId: 'id_ID',
        listenOptions: stt.SpeechListenOptions(partialResults: true),
      );
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour.$minute';
  }

  void _showSaveDialog(BuildContext context) {
    if (_messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada percakapan untuk disimpan'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final TextEditingController nameController = TextEditingController(
      text: 'Percakapan 1',
    );

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
                      'Simpan percakapan?',
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
                        controller: nameController,
                        autofocus: true,
                        enabled: !_isSaving,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textDark,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Percakapan 1',
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
                        onPressed: _isSaving
                            ? null
                            : () async {
                                final namaPercakapan =
                                    nameController.text.trim().isEmpty
                                        ? 'Percakapan 1'
                                        : nameController.text.trim();

                                setDialogState(() => _isSaving = true);
                                setState(() => _isSaving = true);

                                try {
                                  await _historyService.saveConversationHistory(
                                    title: namaPercakapan,
                                    messages: List<Message>.from(_messages),
                                  );

                                  if (!mounted) return;
                                  Navigator.pop(dialogContext);
                                  ScaffoldMessenger.of(this.context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Percakapan "$namaPercakapan" berhasil disimpan ke History!',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(this.context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e
                                            .toString()
                                            .replaceFirst('Exception: ', ''),
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => _isSaving = false);
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
                        child: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Simpan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12.5,
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

  @override
  Widget build(BuildContext context) {
    final bool isChatView =
        _isChatStarted || _messages.isNotEmpty || _isRecording;

    return Column(
      children: [
        // Header putih melengkung
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: isChatView
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _resetChat,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.navy,
                        size: 20,
                      ),
                    ),
                    const Text(
                      'Percakapan Baru',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                    _buildProfileAvatar(),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/images/LogoAPP2.webp',
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                    _buildProfileAvatar(),
                  ],
                ),
        ),

        // Konten utama: Welcome Card (idle) atau Daftar Chat Bubble (aktif)
        // Ketuk area chat saat keyboard terbuka akan menutup keyboard & memunculkan mic lagi
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (_isTTSMode) {
                _switchToSTTMode();
              }
            },
            child: isChatView ? _buildChatList() : _buildWelcomeCard(),
          ),
        ),

        // Bagian Bawah (Mic / TTS Input + Pill Bottom Nav)
        isChatView ? _buildChatBottomSection() : _buildIdleBottomSection(),
      ],
    );
  }

  Widget _buildProfileAvatar() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
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
    );
  }

  Widget _buildWelcomeCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    color: AppColors.navy,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Salam hangat, ',
                      style: TextStyle(fontWeight: FontWeight.w400),
                    ),
                    TextSpan(
                      text: '$_userName.',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mulai Percakapan Baru?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _switchToTTSMode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    elevation: 0,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Text-to-Speech',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatList() {
    final int extraItem = _isRecording ? 1 : 0;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      itemCount: _messages.length + extraItem,
      itemBuilder: (context, index) {
        if (_isRecording && index == _messages.length) {
          final liveText = _currentText.isEmpty
              ? 'Mendengarkan... (${_recordingDuration.inSeconds}d)'
              : _currentText;
          return ChatBubble(
            text: liveText,
            time: _formatTime(DateTime.now()),
            isFromUser: false,
            isLivePreview: true,
          );
        }

        final msg = _messages[index];
        return ChatBubble(
          text: msg.text,
          time: _formatTime(msg.timestamp),
          isFromUser: msg.isFromUser,
        );
      },
    );
  }

  Widget _buildIdleBottomSection() {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildMicButton(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: CustomBottomNav(
              currentIndex: widget.currentTabIndex,
              onTap: widget.onTabChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBottomSection() {
    if (_isTTSMode) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                height: 48,
                padding: const EdgeInsets.only(left: 20, right: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ttsController,
                        focusNode: _ttsFocusNode,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 13.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Kirim pesan',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13.5,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (_) => _handleSendTTS(),
                      ),
                    ),
                    IconButton(
                      onPressed: _handleSendTTS,
                      icon: const Icon(
                        Icons.send_outlined,
                        color: AppColors.navy,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _switchToSTTMode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navy,
                                elevation: 0,
                                alignment: Alignment.centerLeft,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'Speech-to-text',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () => _showSaveDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.navy,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Simpan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomBottomNav(
                      currentIndex: widget.currentTabIndex,
                      onTap: widget.onTabChanged,
                      withShadow: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 32),
            padding: const EdgeInsets.fromLTRB(16, 44, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _switchToTTSMode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            elevation: 0,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Text-to-Speech',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => _showSaveDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Simpan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomBottomNav(
                  currentIndex: widget.currentTabIndex,
                  onTap: widget.onTabChanged,
                  withShadow: false,
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: _buildMicButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: _toggleRecording,
      onVerticalDragStart: (_) {
        _hasTriggeredSwipeUp = false;
      },
      onVerticalDragUpdate: (details) {
        if (_hasTriggeredSwipeUp) return;

        setState(() {
          // Batasi geseran ke atas maksimal -36px agar terasa kenyal & responsif
          _micDragOffsetY = (_micDragOffsetY + details.delta.dy).clamp(-36.0, 0.0);
        });

        // Jika digeser ke atas minimal 20px, langsung pindah ke TTS + buka keyboard
        if (_micDragOffsetY <= -20.0) {
          _hasTriggeredSwipeUp = true;
          _switchToTTSMode();
        }
      },
      onVerticalDragEnd: (_) {
        if (!_hasTriggeredSwipeUp && mounted) {
          setState(() {
            _micDragOffsetY = 0.0;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.translationValues(0, _micDragOffsetY, 0),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: _isRecording ? Colors.red.shade700 : AppColors.navy,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          _isRecording ? Icons.stop : Icons.mic_none_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}