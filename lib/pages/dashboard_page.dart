import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import 'dart:async';

import '../models/message.dart';
import '../theme/app_colors.dart';
import '../widgets/conversation_card.dart';
import '../widgets/custom_bottom_nav.dart';
import 'profile_page.dart';
import 'history_page.dart';
import 'collaboration_page.dart'; 

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  final List<Message> _messages = [];

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isRecording = false;
  bool _isTTSMode = false; 
  
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  String _currentText = '';
  
  final TextEditingController _ttsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("id-ID");
    await _flutterTts.setSpeechRate(0.5);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ttsController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _toggleFeatureMode() {
    setState(() {
      _isTTSMode = !_isTTSMode;
      if (_isRecording) {
        _speech.stop();
        _timer?.cancel();
        _isRecording = false;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isTTSMode ? 'Beralih ke Text-to-Voice' : 'Beralih ke Voice-to-Text'),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  Future<void> _handleSendTTS() async {
    final text = _ttsController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(Message(text: text, timestamp: DateTime.now()));
      _ttsController.clear();
    });

    await _flutterTts.speak(text);
  }

  Future<void> _toggleRecording() async {
    if (_isTTSMode) {
      _handleSendTTS();
      return;
    }

    if (_isRecording) {
      await _speech.stop();
      _timer?.cancel();

      setState(() => _isRecording = false);

      // 👇 TAMBAHAN: Jeda 300ms agar onResult terakhir sempat masuk
      await Future.delayed(const Duration(milliseconds: 300));

      if (_currentText.trim().isNotEmpty) {
        setState(() {
          _messages.add(
            Message(text: _currentText.trim(), timestamp: DateTime.now()),
          );
          _currentText = '';
          _recordingDuration = Duration.zero;
        });
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

      setState(() => _isRecording = true);

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
        },
        localeId: 'id_ID',
        listenOptions: stt.SpeechListenOptions(partialResults: true),
      );
    }
  }

  void _showSaveDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    
    nameController.text = 'Percakapan ${_messages.length > 0 ? _messages.length : 1}';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Simpan percakapan?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 20),
                
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFE0E0E0),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Nama percakapan...',
                  ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textGray,
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text('Batal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: ElevatedButton(
                          onPressed: () {
                            final namaPercakapan = nameController.text;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Percakapan "$namaPercakapan" berhasil disimpan!')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onHomeTap() => setState(() => _currentIndex = 0);
  void _onHistoryTap() => setState(() => _currentIndex = 2);
  void _onCollaborationTap() => setState(() => _currentIndex = 3);

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 2:
        return const HistoryPage(isTabMode: true); 
      case 3:
        return const CollaborationPage();
      case 0:
      default:
        return _buildHomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(_currentIndex),
            child: _getCurrentPage(),
          ),
        ),
      ),

      floatingActionButton: _currentIndex == 3 
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: FloatingActionButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Membuat room baru...')),
                  );
                },
                backgroundColor: AppColors.navy,
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            )
          : null,

      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        isRecording: _isRecording,
        isTTSMode: _isTTSMode, 
        onSwipeFeature: _toggleFeatureMode,
        onHomeTap: _onHomeTap,
        onMicTap: _toggleRecording, 
        onHistoryTap: _onHistoryTap,
        onCollaborationTap: _onCollaborationTap, 
      ),
    );
  }

  Widget _buildHomePage() {
    return Column(
      children: [
        // HEADER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ColorFiltered(
                  colorFilter: ColorFilter.mode(AppColors.navy, BlendMode.srcIn),
                  child: Image.asset('assets/images/LOGO.png', height: 35, fit: BoxFit.contain),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfilePage()),
                    );
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(color: AppColors.navy, shape: BoxShape.circle),
                    child: const Icon(Icons.person, color: AppColors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Salam hangat, User.',
                  style: TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                
                ConversationCard(
                  messages: _messages,
                  isRecording: _isRecording,
                  isTTSMode: _isTTSMode, 
                  recordingDuration: _recordingDuration,
                  onTextToSpeechTap: () {},
                  onSaveTap: () => _showSaveDialog(context), 
                ),
                
                if (_isTTSMode) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ttsController,
                            decoration: const InputDecoration(
                              hintText: 'Ketik pesan untuk dibacakan...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                            onSubmitted: (_) => _handleSendTTS(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: AppColors.navy),
                          onPressed: _handleSendTTS,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}