import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';
import '../../services/gemini_service.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeminiService _geminiService;
  
  ChatRepository(this._geminiService);
  
  Future<String> sendMessage(
    String userId, 
    String message, 
    String? imageUrl, 
    String? base64Image // Parameter baru untuk base64 image
  ) async {
    try {
      // Mendapatkan respons dari Gemini API
      String response;
      if (base64Image != null) {
        // Gunakan base64 langsung ke Gemini
        response = await _geminiService.generateResponseWithImage(message, base64Image);
      } else {
        response = await _geminiService.generateResponse(message);
      }
      
      // Simpan percakapan ke Firebase - tanpa menyimpan base64 image karena terlalu besar
      // Hanya simpan referensi jika ada imageUrl (kasus penggunaan Firebase Storage)
      await _saveMessageToFirebase(userId, message, response, imageUrl);
      
      return response;
    } catch (e) {
      throw Exception('Failed to process chat: $e');
    }
  }
  
  Future<void> _saveMessageToFirebase(
    String userId, 
    String userMessage, 
    String aiResponse,
    String? imageUrl // Tetap gunakan imageUrl jika ada
  ) async {
    try {
      // Periksa apakah ada chat history untuk user ini
      final chatRef = _firestore.collection('chat_history').doc(userId);
      final now = DateTime.now();
      
      await _firestore.runTransaction((transaction) async {
        final chatDoc = await transaction.get(chatRef);
        
        if (chatDoc.exists) {
          // Update chat history yang sudah ada
          transaction.update(chatRef, {
            'messages': FieldValue.arrayUnion([
              {
                'id': '${now.millisecondsSinceEpoch}_user',
                'sender': 'user',
                'message': userMessage,
                'timestamp': now,
                'imageUrl': imageUrl, // Opsional, bisa null
              },
              {
                'id': '${now.millisecondsSinceEpoch + 1}_ai',
                'sender': 'ai',
                'message': aiResponse,
                'timestamp': now,
              }
            ]),
            'updatedAt': now,
          });
        } else {
          // Buat chat history baru
          transaction.set(chatRef, {
            'userId': userId,
            'messages': [
              {
                'id': '${now.millisecondsSinceEpoch}_user',
                'sender': 'user',
                'message': userMessage,
                'timestamp': now,
                'imageUrl': imageUrl, // Opsional, bisa null
              },
              {
                'id': '${now.millisecondsSinceEpoch + 1}_ai',
                'sender': 'ai',
                'message': aiResponse,
                'timestamp': now,
              }
            ],
            'createdAt': now,
            'updatedAt': now,
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to save chat to database: $e');
    }
  }
  
  Future<List<ChatMessage>> getChatHistory(String userId) async {
    try {
      final chatDoc = await _firestore.collection('chat_history').doc(userId).get();
      
      if (chatDoc.exists) {
        final data = chatDoc.data();
        final List<dynamic> messages = data?['messages'] ?? [];
        
        return messages.map((msg) => ChatMessage.fromMap(msg)).toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('Failed to get chat history: $e');
    }
  }
}