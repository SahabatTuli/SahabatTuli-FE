import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/message.dart';
import '../theme/app_colors.dart';

class ConversationCard extends StatelessWidget {
  final List<Message> messages;
  final bool isRecording;
  final bool isTTSMode; 
  final Duration recordingDuration;
  final VoidCallback? onTextToSpeechTap;
  final VoidCallback onSaveTap; 

  const ConversationCard({
    super.key,
    required this.messages,
    this.isRecording = false,
    required this.isTTSMode,
    this.recordingDuration = Duration.zero,
    this.onTextToSpeechTap,
    required this.onSaveTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasContent = messages.isNotEmpty || isRecording;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER CARD
          Text(
            hasContent ? 'Percakapan' : 'Percakapan Baru',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // KONTEN
          if (!hasContent)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Belum ada percakapan',
                style: TextStyle(color: AppColors.textGray, fontSize: 12),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                reverse: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...messages.map((msg) => _buildBubble(msg)),
                    if (isRecording) _buildRecordingBubble(),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // 👇 TOMBOL (SUDAH DIPERBAIKI)
          Row(
            children: [
              // Tombol Utama (Text-to-Speech / Text-to-Voice)
              Expanded(
                child: GestureDetector(
                  onTap: onTextToSpeechTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        // Teks berubah dinamis sesuai swipe
                        isTTSMode ? 'Text-to-Voice' : 'Text-to-Speech',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 10), // Jarak antar tombol
              
              // Tombol Simpan
              GestureDetector(
                onTap: onSaveTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: Text(
                      'Simpan',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // BUBBLE PESAN (TEXT + TIMESTAMP)
  Widget _buildBubble(Message msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              msg.text,
              style: const TextStyle(color: AppColors.textDark, fontSize: 14),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              DateFormat('HH:mm').format(msg.timestamp),
              style: const TextStyle(color: AppColors.textGray, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  // BUBBLE RECORDING (SEMENTARA)
  Widget _buildRecordingBubble() {
    final seconds = recordingDuration.inSeconds;
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.navy.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.navy.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mic, color: AppColors.navy, size: 18),
          const SizedBox(width: 8),
          Text(
            '$minutes:$secs',
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          ...List.generate(4, (i) => _buildWaveBar(i)),
        ],
      ),
    );
  }

  Widget _buildWaveBar(int index) {
    final heights = [8.0, 14.0, 10.0, 16.0];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      width: 3,
      height: heights[index % heights.length],
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}