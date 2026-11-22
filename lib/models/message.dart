class Message {
  final String text;
  final DateTime timestamp;
  final bool isFromUser;

  Message({
    required this.text,
    required this.timestamp,
    this.isFromUser = false,
  });
}