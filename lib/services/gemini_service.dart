import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class GeminiService {
  // Gunakan endpoint sesuai dengan model yang valid
  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  final String _apiKey;
  final Logger _logger = Logger();

  GeminiService(this._apiKey);

  Future<String> generateResponse(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": _preparePrompt(prompt)
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return _extractResponseText(data);
      } else {
        _logger.e('Error response: ${response.body}');
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Exception during API call: $e');
      throw Exception('Error communicating with Gemini API: $e');
    }
  }

  String _preparePrompt(String userQuery) {
    // Tambahkan konteks tentang tanaman hortikultura
    return '''
    Anda adalah asisten virtual yang ahli dalam bidang tanaman hortikultura khususnya di Indonesia.
    Anda dapat membantu pengguna dengan memberikan informasi tentang:
    1. Cara menanam dan merawat tanaman hortikultura di pekarangan rumah
    2. Teknik optimalisasi lahan pekarangan untuk budidaya tanaman
    3. Penanganan hama dan penyakit tanaman
    4. Pemilihan tanaman yang sesuai dengan kondisi lahan
    5. Teknik panen dan pasca panen untuk hasil maksimal
    
    Gunakan markdown untuk memformat respons Anda:
    - Judul dengan awalan # atau ## 
    - Bagian penting dengan **teks tebal**
    - Penekanan dengan *teks miring*
    - Daftar dengan - atau 1. 2. 3.
    
    Pertanyaan pengguna: $userQuery
    
    Berikan jawaban yang lengkap, informatif, dan mudah dipahami oleh orang awam.
    ''';
  }

  String _extractResponseText(Map<String, dynamic> data) {
    try {
      String text = data['candidates'][0]['content']['parts'][0]['text'];
      
      // Perbaiki format Markdown jika diperlukan
      return _fixMarkdownFormat(text);
    } catch (e) {
      _logger.e('Error extracting response: $e');
      _logger.e('Response data structure: $data');
      return 'Maaf, terjadi kesalahan dalam memproses respons. Silakan coba lagi.';
    }
  }
  
  // Fungsi untuk memperbaiki format Markdown
  String _fixMarkdownFormat(String text) {
  // replaceAllMapped
  text = text.replaceAllMapped(
    RegExp(r'(\w)\*\*(\w)'),
    (match) => '${match.group(1)} **${match.group(2)}'
  );
  
  text = text.replaceAllMapped(
    RegExp(r'(\w)\*\*\s'),
    (match) => '${match.group(1)}** '
  );
  
  // Untuk format miring
  text = text.replaceAllMapped(
    RegExp(r'(\w)\*(\w)'),
    (match) => '${match.group(1)} *${match.group(2)}'
  );
  
  // Untuk nomor list
  text = text.replaceAllMapped(
    RegExp(r'(\d+)\.(\w)'),
    (match) => '${match.group(1)}. ${match.group(2)}'
  );
  
  return text;
}
}