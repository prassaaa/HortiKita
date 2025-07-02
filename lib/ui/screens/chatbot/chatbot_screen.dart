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

class ChatbotScreenState extends State<ChatbotScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedImagePath;
  bool _showPreview = false;
  
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadChatData();
  }
  
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }
  
  void _loadChatData() {
    _fadeController.forward();
    _slideController.forward();
    
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
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Theme Colors - Modern Design System
  static const Color primaryColor = Color(0xFF2D5A27);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primarySurface = Color(0xFFF1F8E9);
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color dividerColor = Color(0xFFE0E0E0);

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 800,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImagePath = pickedFile.path;
        _showPreview = true;
      });
    }
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.camera_alt, color: primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Pilih Gambar Tanaman',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Kirim foto tanaman untuk identifikasi atau konsultasi',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildImageSourceButton(
                    'Kamera',
                    Icons.camera_alt_outlined,
                    () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageSourceButton(
                    'Galeri',
                    Icons.photo_library_outlined,
                    () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceButton(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: primaryColor, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "guest_user";
    
    if (message.isEmpty && _selectedImagePath == null) return;
    
    _messageController.clear();
    
    final imagePath = _selectedImagePath;
    setState(() {
      _selectedImagePath = null;
      _showPreview = false;
    });
    
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

  List<ChatMessage> _filterTodayMessages(List<ChatMessage> messages) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return messages.where((message) => message.timestamp.isAfter(todayStart)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildAppBar(),
            if (_showPreview && _selectedImagePath != null) _buildImagePreview(),
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildChatArea(),
              ),
            ),
            _buildLoadingIndicator(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primarySurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy,
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asisten Hortikultura',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                Text(
                  'AI Plant Expert',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(_selectedImagePath!),
              height: 80,
              width: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gambar Tanaman Siap Dikirim',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tambahkan deskripsi atau pertanyaan tentang tanaman ini',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade400),
            onPressed: () {
              setState(() {
                _selectedImagePath = null;
                _showPreview = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.messages.isEmpty) {
          return _buildEmptyState();
        }

        final todayMessages = _filterTodayMessages(chatProvider.messages);
        
        if (todayMessages.isEmpty) {
          return _buildNoTodayMessagesState();
        }

        return Container(
          decoration: BoxDecoration(
            color: surfaceColor,
          ),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: todayMessages.length,
            itemBuilder: (context, index) {
              final message = todayMessages[index];
              return ChatBubble(
                message: message,
                isMe: message.sender == 'user',
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 40,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Selamat datang! 👋',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tanyakan sesuatu tentang tanaman hortikultura atau kirim foto tanaman untuk diidentifikasi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickActionChip('🌱 Identifikasi Tanaman', () {
                  _showImagePickerDialog();
                }),
                _buildQuickActionChip('💬 Tanya Ahli', () {
                  _messageController.text = 'Bagaimana cara merawat tanaman ';
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTodayMessagesState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wb_sunny,
              size: 64,
              color: Colors.orange.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Hari Baru, Pertanyaan Baru! 🌅',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada percakapan hari ini.\nAyo mulai bertanya tentang tanaman!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionChip(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: primarySurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryLight.withValues(alpha: 0.3)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return chatProvider.isLoading
            ? SizedBox(
                height: 4,
                child: LinearProgressIndicator(
                  backgroundColor: primarySurface,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryLight),
                ),
              )
            : const SizedBox.shrink();
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Image picker button
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.add_a_photo, color: primaryColor, size: 20),
                onPressed: _showImagePickerDialog,
              ),
            ),
            const SizedBox(width: 12),
            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: dividerColor),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Tulis pesan tentang tanaman...',
                    hintStyle: TextStyle(color: textSecondary),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  style: TextStyle(color: textPrimary),
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Send button
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                return Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: chatProvider.isLoading ? textSecondary : primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (chatProvider.isLoading ? textSecondary : primaryColor).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: chatProvider.isLoading ? null : _sendMessage,
                    icon: Icon(
                      chatProvider.isLoading ? Icons.hourglass_empty : Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}