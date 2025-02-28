import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';
import '../repositories/chat_repository.dart';
import '../../services/gemini_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatRepository _chatRepository;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _error = '';

  ChatProvider(String apiKey)
      : _chatRepository = ChatRepository(GeminiService(apiKey));

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> sendMessage(String userId, String message) async {
    if (message.trim().isEmpty) return;

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Tambahkan pesan user ke list (optimistic update)
      final userMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_user',
        sender: 'user',
        message: message,
        timestamp: DateTime.now(),
      );
      _messages.add(userMsg);
      notifyListeners();

      // Kirim pesan ke repository dan dapatkan respons
      final response = await _chatRepository.sendMessage(userId, message);

      // Tambahkan respons AI ke list
      final aiMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_ai',
        sender: 'ai',
        message: response,
        timestamp: DateTime.now(),
      );
      _messages.add(aiMsg);
    } catch (e) {
      _error = e.toString();
      print('Error sending message: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadChatHistory(String userId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _messages = await _chatRepository.getChatHistory(userId);
    } catch (e) {
      _error = e.toString();
      print('Error loading chat history: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages = [];
    notifyListeners();
  }
}