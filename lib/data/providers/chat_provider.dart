import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/chat_message_model.dart';
import '../repositories/chat_repository.dart';
import '../../services/gemini_service.dart';
import '../../services/analytics_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatRepository _chatRepository;
  final Logger _logger = Logger();
  final AnalyticsService _analytics = AnalyticsService();
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
        id: '${DateTime.now().millisecondsSinceEpoch}_user',
        sender: 'user',
        message: message,
        timestamp: DateTime.now(),
      );
      _messages.add(userMsg);
      notifyListeners();

      // Kirim pesan ke repository dan dapatkan respons
      final response = await _chatRepository.sendMessage(userId, message, null, null);

      // Track chatbot interaction
      final topics = _analytics.extractTopics(message);
      await _analytics.trackChatbotInteraction(
        question: message,
        response: response,
        topics: topics,
      );

      // Tambahkan respons AI ke list
      final aiMsg = ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_ai',
        sender: 'ai',
        message: response,
        timestamp: DateTime.now(),
      );
      _messages.add(aiMsg);
    } catch (e) {
      _error = e.toString();
      _logger.e('Error sending message: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessageWithImage(String userId, String message, String? imagePath) async {
    final now = DateTime.now();
    String? base64Image;
    
    // Reset state
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Jika ada gambar, konversi ke base64
      if (imagePath != null) {
        // Buat ChatMessage dengan path lokal untuk UI optimistic update
        final userMsgWithLocalImage = ChatMessage(
          id: '${now.millisecondsSinceEpoch}_user',
          sender: 'user',
          message: message.isEmpty ? 'Foto tanaman' : message,
          timestamp: now,
          localImagePath: imagePath,
        );
        _messages.add(userMsgWithLocalImage);
        notifyListeners();
        
        try {
          // Konversi gambar ke base64
          base64Image = await _convertImageToBase64(imagePath);
          _logger.d('Image converted to base64 successfully');
        } catch (conversionError) {
          _logger.e('Error converting image: $conversionError');
          // Lanjutkan tanpa gambar jika konversi gagal
          base64Image = null;
        }
      } else {
        // Tambahkan pesan user ke list (optimistic update)
        final userMsg = ChatMessage(
          id: '${now.millisecondsSinceEpoch}_user',
          sender: 'user',
          message: message,
          timestamp: now,
        );
        _messages.add(userMsg);
        notifyListeners();
      }

      // Tambahkan prompt untuk Gemini 
      String finalPrompt = message;
      if (imagePath != null) {
        // Jika ada gambar yang berhasil dikonversi, gunakan untuk Gemini
        if (base64Image != null) {
          finalPrompt = message.isEmpty ? 
            "Tolong identifikasi tanaman ini, jelaskan karakteristiknya, cara menanam, dan merawatnya." :
            "$message\nTolong identifikasi tanaman ini, jelaskan karakteristiknya, cara menanam, dan merawatnya.";
        } else {
          // Jika gambar gagal dikonversi, tetap kirim pesan tanpa gambar
          finalPrompt = message.isEmpty ? 
            "Maaf, saya tidak bisa mengidentifikasi tanaman dari gambar. Bisa jelaskan tanaman tersebut?" :
            "$message (Catatan: Gambar gagal diproses)";
        }
      }

      // Kirim pesan ke repository dan dapatkan respons
      final response = await _chatRepository.sendMessage(
        userId, 
        finalPrompt, 
        null, // Tidak menggunakan URL gambar
        base64Image // Menggunakan base64 gambar langsung
      );

      // Tambahkan respons AI ke list
      final aiMsg = ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_ai',
        sender: 'ai',
        message: response,
        timestamp: DateTime.now(),
      );
      _messages.add(aiMsg);
      
      // Update pesan user dalam state supaya tetap menunjukkan gambar
      if (imagePath != null) {
        // Pertahankan lokalImagePath untuk tetap menampilkan gambar di UI
        final userMsgIndex = _messages.indexWhere(
          (msg) => msg.id == '${now.millisecondsSinceEpoch}_user' && msg.localImagePath == imagePath
        );
        
        if (userMsgIndex != -1) {
          // Tidak perlu update imageUrl karena kita menggunakan localImagePath
          // untuk menampilkan gambar di UI
        }
      }
    } catch (e) {
      _error = e.toString();
      _logger.e('Error sending message with image: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Metode untuk mengkonversi gambar ke base64
  Future<String> _convertImageToBase64(String imagePath) async {
    try {
      File file = File(imagePath);
      
      // Periksa apakah file ada
      if (!file.existsSync()) {
        _logger.e('File tidak ditemukan: $imagePath');
        throw Exception('File not found');
      }
      
      // Kompresi gambar untuk mengurangi ukuran
      File? compressedFile;
      try {
        final targetPath = '${imagePath}_compressed.jpg';
        final compressedData = await FlutterImageCompress.compressAndGetFile(
          imagePath, 
          targetPath,
          quality: 50, // Kualitas lebih rendah untuk file lebih kecil
          minWidth: 600,
          minHeight: 600,
        );
        
        if (compressedData != null) {
          compressedFile = File(compressedData.path);
        }
      } catch (compressError) {
        _logger.w('Kompresi gambar gagal: $compressError. Menggunakan file asli.');
        // Lanjutkan dengan file asli jika kompresi gagal
      }
      
      // Gunakan file yang sudah dikompresi atau file asli
      final fileToUse = compressedFile ?? file;
      
      // Baca file sebagai bytes
      final bytes = await fileToUse.readAsBytes();
      
      // Konversi ke base64
      final base64String = base64Encode(bytes);
      
      return base64String;
    } catch (e) {
      _logger.e('Error in _convertImageToBase64: $e');
      throw Exception('Failed to convert image: $e');
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
      _logger.e('Error loading chat history: $_error');
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