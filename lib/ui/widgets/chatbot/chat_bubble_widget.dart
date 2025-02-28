import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime timestamp;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) _buildAvatar(isMe),
          Flexible(
            child: Container(
              margin: EdgeInsets.only(
                left: isMe ? 64 : 8,
                right: isMe ? 8 : 64,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isMe ? Colors.green[100] : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: isMe ? Colors.black87 : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(timestamp),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) _buildAvatar(isMe),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isMe) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isMe ? Colors.green : Colors.grey,
      child: Icon(
        isMe ? Icons.person : Icons.eco,
        size: 16,
        color: Colors.white,
      ),
    );
  }
}