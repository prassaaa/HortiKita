import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime timestamp;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.timestamp,
  });

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
                  // Gunakan MarkdownBody untuk render Markdown
                  MarkdownBody(
                    data: message,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        height: 1.4,
                      ),
                      strong: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      em: const TextStyle(
                        fontStyle: FontStyle.italic,
                      ),
                      h1: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      h2: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      h3: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      listBullet: TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                    selectable: true,
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