import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../services/environment_service.dart';
import 'package:logger/logger.dart';

class GeminiTestScreen extends StatefulWidget {
  const GeminiTestScreen({super.key});

  @override
  GeminiTestScreenState createState() => GeminiTestScreenState();
}

class GeminiTestScreenState extends State<GeminiTestScreen> {
  final TextEditingController _promptController = TextEditingController();
  final Logger _logger = Logger();
  String _response = "Respons akan muncul di sini";
  bool _isLoading = false;

  String get _apiKey {
    try {
      return EnvironmentService.instance.geminiApiKey;
    } catch (e) {
      _logger.e('Failed to get Gemini API key: $e');
      return '';
    }
  }

  Future<void> _sendPrompt() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
      _response = "Menunggu respons...";
    });

    try {
      final geminiService = GeminiService(_apiKey);
      final response = await geminiService.generateResponse(prompt);
      
      setState(() {
        _response = response;
      });
    } catch (e) {
      setState(() {
        _response = "Error: $e";
      });
      _logger.e("Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini API Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'Masukkan pertanyaan',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendPrompt,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Kirim'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Respons AI:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(_response),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}