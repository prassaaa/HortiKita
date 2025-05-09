import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/chat_message_model.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
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
              child: _buildBubbleContent(),
            ),
          ),
          if (isMe) _buildAvatar(isMe),
        ],
      ),
    );
  }
  
  Widget _buildBubbleContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tampilkan gambar jika ada
        if (message.imageUrl != null || message.localImagePath != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: message.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: message.imageUrl!,
                      width: 200,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 150,
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 150,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    )
                  : Image.file(
                      File(message.localImagePath!),
                      width: 200,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        
        // Konten pesan teks
        MarkdownBody(
          data: message.message,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
              height: 1.4,
            ),
            strong: const TextStyle(
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
            listBullet: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
            ),
          ),
          selectable: true,
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('HH:mm').format(message.timestamp),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
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