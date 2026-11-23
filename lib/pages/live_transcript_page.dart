import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../services/auth_service.dart';
import '../services/collaboration_service.dart';
import '../services/collaboration_socket_service.dart';
import '../services/history_service.dart';
import '../theme/app_colors.dart';

class LiveTranscriptPage extends StatefulWidget {
  final String roomId;
  final String roomTitle;
  final String hostName;
  final bool isHost;

  const LiveTranscriptPage({
    super.key,
    required this.roomId,
    required this.roomTitle,
    required this.hostName,
    required this.isHost,
  });

  @override
  State<LiveTranscriptPage> createState() => _LiveTranscriptPageState();
}

class _LiveTranscriptPageState extends State<LiveTranscriptPage> {
  final CollaborationService _collaborationService = CollaborationService();
  final CollaborationSocketService _socketService =
      CollaborationSocketService();
  final AuthService _authService = AuthService();
  final HistoryService _historyService = HistoryService();
  final SpeechToText _speech = SpeechToText();
  final ScrollController _scrollController = ScrollController();

  final List _finalSentences = [];
  String _interimText = '';
  int _participantCount = 1;
  bool _isHostUser = false;
  bool _isLoading = true;
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _isLeaving = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isHostUser = widget.isHost;
    _initRoom();
  }

  @override
  void dispose() {
    _speech.stop();
    _socketService.leaveRoom(widget.roomId);
    _socketService.disconnect();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initRoom() async {
    try {
      final results = await Future.wait([
        _authService.getSession(),
        _collaborationService.getRoomDetail(widget.roomId),
      ]);

      if (!mounted) return;

      final sessionData = results[0] as Map?;
      final roomDetail = results[1] as Map;

      final currentUserId = sessionData?['user'] is Map
          ? (sessionData!['user'] as Map)['id']?.toString() ?? ''
          : '';
      final roomHostId = roomDetail['hostId']?.toString() ?? '';

      if (currentUserId.isNotEmpty && roomHostId.isNotEmpty) {
        _isHostUser = currentUserId == roomHostId;
      }

      final existingTranscripts = roomDetail['transcripts'] is List
          ? roomDetail['transcripts'] as List
          : [];
      for (final item in existingTranscripts) {
        if (item is Map && item['text'] != null) {
          _finalSentences.add(item['text'].toString());
        } else if (item is String) {
          _finalSentences.add(item);
        }
      }

      await _socketService.connect(
        roomId: widget.roomId,
        onParticipantCount: (count) {
          if (!mounted) return;
          setState(() => _participantCount = count);
        },
        onInterimTranscript: (data) {
          if (!mounted) return;
          setState(() {
            _interimText = data['text']?.toString() ?? '';
          });
          _scrollToBottom();
        },
        onFinalTranscript: (data) {
          if (!mounted) return;
          final text = data['text']?.toString().trim() ?? '';
          if (text.isEmpty) return;
          setState(() {
            if (_finalSentences.isEmpty || _finalSentences.last != text) {
              _finalSentences.add(text);
            }
            _interimText = '';
          });
          _scrollToBottom();
        },
        onRoomEnded: (message) {
          if (!mounted) return;
          _speech.stop();
          _showSnackBar(message);
          Navigator.pop(context, true);
        },
        onError: (err) {
          if (!mounted) return;
          _showSnackBar(err, isError: true);
        },
      );

      if (_isHostUser) {
        await _initSpeech();
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          if (!mounted) return;
          setState(() => _isListening = false);
        },
      );
      if (_speechAvailable && mounted) {
        await _startListening();
      }
    } catch (_) {
      _speechAvailable = false;
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      _speechAvailable = await _speech.initialize();
    }
    if (!_speechAvailable) {
      _showSnackBar(
        'Izin mikrofon tidak tersedia di perangkat ini',
        isError: true,
      );
      return;
    }

    setState(() => _isListening = true);

    await _speech.listen(
      localeId: 'id_ID',
      listenMode: ListenMode.dictation,
      partialResults: true,
      onResult: (result) {
        if (!mounted) return;
        final words = result.recognizedWords.trim();
        if (words.isEmpty) return;

        if (result.finalResult) {
          setState(() {
            _finalSentences.add(words);
            _interimText = '';
          });
          _socketService.sendFinalTranscript(
            roomId: widget.roomId,
            text: words,
          );
          _scrollToBottom();
        } else {
          setState(() {
            _interimText = words;
          });
          _socketService.sendInterimTranscript(
            roomId: widget.roomId,
            text: words,
          );
          _scrollToBottom();
        }
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
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

  void _showSaveTranscriptDialog() {
    final TextEditingController titleController = TextEditingController(
      text: widget.roomTitle,
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
                        controller: titleController,
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
                                final title =
                                    titleController.text.trim().isEmpty
                                        ? widget.roomTitle
                                        : titleController.text.trim();

                                setDialogState(() => _isSaving = true);
                                setState(() => _isSaving = true);

                                try {
                                  await _historyService
                                      .saveCollaborationHistory(
                                    roomId: widget.roomId,
                                    title: title,
                                    hostName: widget.hostName,
                                    transcriptText: _combinedTranscriptText,
                                  );

                                  if (!mounted) return;
                                  Navigator.pop(dialogContext);
                                  _showSnackBar(
                                    'Transkrip disimpan ke History sebagai "$title"',
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  _showSnackBar(
                                    e.toString().replaceFirst('Exception: ', ''),
                                    isError: true,
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

  Future<void> _handleLeave() async {
    if (_isLeaving) return;

    if (_isHostUser) {
      final confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Akhiri Ruangan?',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Karena Anda adalah Host, keluar dari ruangan akan otomatis mengakhiri sesi kolaborasi untuk semua peserta.',
            style: TextStyle(fontSize: 13, color: AppColors.textDark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Akhiri & Keluar',
                style: TextStyle(color: Colors.white, fontSize: 12.5),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() => _isLeaving = true);
    try {
      await _speech.stop();
      await _collaborationService.leaveRoom(widget.roomId);
      _socketService.leaveRoom(widget.roomId);
      _socketService.disconnect();

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLeaving = false);
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

  String get _combinedTranscriptText {
    final buffer = StringBuffer();
    if (_finalSentences.isNotEmpty) {
      buffer.write(_finalSentences.join(' '));
    }
    if (_interimText.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(_interimText);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _combinedTranscriptText;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleLeave();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F2),
        body: SafeArea(
          child: Column(
            children: [
              // --- HEADER PUTIH MELENGKUNG ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.roomTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Color(0xFF9CCC65),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.hostName} (Host)',
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // --- KOTAK PUTIH LIVE TRANSCRIPT ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
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
                        : displayText.isEmpty
                            ? Center(
                                child: Text(
                                  _isHostUser
                                      ? 'Mulai berbicara untuk menampilkan transkrip langsung...'
                                      : 'Menunggu Host berbicara...',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 18,
                                    height: 1.5,
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                controller: _scrollController,
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 22,
                                      height: 1.45,
                                      color: Colors.black87,
                                    ),
                                    children: [
                                      if (_finalSentences.isNotEmpty)
                                        TextSpan(
                                          text: _finalSentences.join(' '),
                                        ),
                                      if (_interimText.isNotEmpty)
                                        TextSpan(
                                          text:
                                              '${_finalSentences.isNotEmpty ? ' ' : ''}$_interimText',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- KONTROL BAWAH: MIC (HOST), SIMPAN, LEAVE, & JUMLAH PESERTA ---
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isHostUser) ...[
                          GestureDetector(
                            onTap: _isListening
                                ? _stopListening
                                : _startListening,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _isListening
                                    ? Colors.redAccent
                                    : Colors.grey.shade400,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isListening ? Icons.mic : Icons.mic_off,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: _showSaveTranscriptDialog,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(
                                color: AppColors.navy,
                                width: 1.4,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                            child: const Text(
                              'Simpan',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 120,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _isLeaving ? null : _handleLeave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.navy,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                            child: _isLeaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Leave',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 42,
                      height: 24,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: 0,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: Color(0xFF9CCC65),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: AppColors.navy,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFF2F2F2),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_participantCount Person in this room',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}