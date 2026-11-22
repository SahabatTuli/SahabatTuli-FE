import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isFromUser;
  final bool isLivePreview;

  const ChatBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isFromUser,
    this.isLivePreview = false,
  });

  @override
  Widget build(BuildContext context) {
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.72;

    return Align(
      alignment: isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(16, 12, 14, 10),
        decoration: BoxDecoration(
          color: isFromUser ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  fontStyle:
                      isLivePreview ? FontStyle.italic : FontStyle.normal,
                  color: isFromUser ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: isFromUser
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}