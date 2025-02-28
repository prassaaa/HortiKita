import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/chat_provider.dart';
// Removed unused import
import '../../widgets/chatbot/chat_bubble_widget.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ChatbotScreenState createState() => ChatbotScreenState();
}

class ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Tambahkan di sini untuk load chat history
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.uid;
    //   if (userId != null) {
    //     Provider.of<ChatProvider>(context, listen: false).loadChatHistory(userId);
    //   }
    // });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.uid;
    if (userId == null) return;

    _messageController.clear();
    
    await Provider.of<ChatProvider>(context, listen: false).sendMessage(userId, message);
    
    // Scroll to bottom
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asisten Hortikultura'),
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.messages.isEmpty) {
                  return const Center(
                    child: Text('Tanyakan sesuatu tentang tanaman hortikultura!'),
                  );
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    return ChatBubble(
                      message: message.message,
                      isMe: message.sender == 'user',
                      timestamp: message.timestamp,
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
                  ? const LinearProgressIndicator()
                  : const SizedBox.shrink();
            },
          ),
          
          // Input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha((0.1 * 255).toInt()),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Tulis pesan...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    minLines: 1,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}