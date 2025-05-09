import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/providers/auth_provider.dart' as local_auth;
import '../../../data/providers/chat_provider.dart';
import '../../../data/models/chat_message_model.dart';
import '../../widgets/chatbot/chat_bubble_widget.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ChatbotScreenState createState() => ChatbotScreenState();
}

class ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedImagePath; // untuk menyimpan path gambar yang dipilih
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Provider.of<local_auth.AuthProvider>(context, listen: false).currentUser?.uid 
          ?? FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        Provider.of<ChatProvider>(context, listen: false).loadChatHistory(userId).then((_) {
          _scrollToBottom();
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 70, // Kompresi kualitas
      maxWidth: 800,    // Batasi lebar
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImagePath = pickedFile.path;
        _showPreview = true;
      });
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "guest_user";
    
    // Skip jika tidak ada pesan dan tidak ada gambar
    if (message.isEmpty && _selectedImagePath == null) return;
    
    // Clear input teks
    _messageController.clear();
    
    // Reset selected image setelah diambil nilainya
    final imagePath = _selectedImagePath;
    setState(() {
      _selectedImagePath = null;
      _showPreview = false;
    });
    
    // Kirim pesan dengan gambar
    await Provider.of<ChatProvider>(context, listen: false)
      .sendMessageWithImage(userId, message, imagePath);
    
    _scrollToBottom();
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Fungsi untuk memfilter pesan hanya hari ini
  List<ChatMessage> _filterTodayMessages(List<ChatMessage> messages) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day); // Mulai hari ini (00:00:00)
    return messages.where((message) => message.timestamp.isAfter(todayStart)).toList();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF4CAF50);
    const Color lightGreen = Color(0xFFE8F5E9);
    const Color white = Colors.white;

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: white,
        title: const Text(
          'Asisten Hortikultura',
          style: TextStyle(
            color: primaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Image Preview (If Selected)
          if (_showPreview && _selectedImagePath != null)
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.grey[200],
              height: 120,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_selectedImagePath!),
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Gambar Tanaman',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tambahkan deskripsi atau pertanyaan tentang tanaman ini',
                          style: TextStyle(fontSize: 14),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _selectedImagePath = null;
                        _showPreview = false;
                      });
                    },
                  ),
                ],
              ),
            ),
          
          // Chat messages area
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat,
                          size: 64,
                          color: primaryGreen.withAlpha((0.5 * 255).toInt()),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tanyakan sesuatu tentang tanaman hortikultura!\nAtau kirim foto tanaman untuk diidentifikasi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF558B2F),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter pesan untuk hanya menampilkan hari ini
                final todayMessages = _filterTodayMessages(chatProvider.messages);
                
                if (todayMessages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat,
                          size: 64,
                          color: primaryGreen.withAlpha((0.5 * 255).toInt()),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum ada pesan hari ini.\nTanyakan sesuatu sekarang!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF558B2F),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: todayMessages.length,
                  itemBuilder: (context, index) {
                    final message = todayMessages[index];
                    return ChatBubble(
                      message: message,
                      isMe: message.sender == 'user',
                    );
                  },
                );
              },
            ),
          ),
          
          // Loading indicator
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return chatProvider.isLoading
                  ? LinearProgressIndicator(
                      backgroundColor: lightGreen,
                      valueColor: const AlwaysStoppedAnimation<Color>(primaryGreen),
                    )
                  : const SizedBox.shrink();
            },
          ),
          
          // Input area with Image buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha((0.5 * 255).toInt()),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, -5),
                ),
              ],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // Tombol Kamera
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: primaryGreen),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
                // Tombol Galeri
                IconButton(
                  icon: const Icon(Icons.photo_library, color: primaryGreen),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
                // Input Teks
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Tulis pesan...',
                      filled: true,
                      fillColor: lightGreen,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    minLines: 1,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                // Tombol Kirim
                Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    return FloatingActionButton(
                      onPressed: chatProvider.isLoading ? null : _sendMessage,
                      mini: true,
                      backgroundColor: chatProvider.isLoading ? Colors.grey[400] : primaryGreen,
                      elevation: 2,
                      shape: const CircleBorder(),
                      child: Icon(
                        chatProvider.isLoading ? Icons.hourglass_empty : Icons.send,
                        color: white,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}