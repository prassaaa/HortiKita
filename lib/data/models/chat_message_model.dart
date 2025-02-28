import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String sender; // 'user' atau 'ai'
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.message,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      sender: map['sender'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}