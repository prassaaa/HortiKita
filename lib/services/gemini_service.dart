import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // Gunakan endpoint sesuai dengan model gemini-2.0-flash
  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  final String _apiKey;

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
        print('Error response: ${response.body}');
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception during API call: $e');
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
    
    Pertanyaan pengguna: $userQuery
    
    Berikan jawaban yang lengkap, informatif, dan mudah dipahami oleh orang awam.
    ''';
  }

  String _extractResponseText(Map<String, dynamic> data) {
    try {
      // Struktur respons dari gemini-2.0-flash
      return data['candidates'][0]['content']['parts'][0]['text'];
    } catch (e) {
      print('Error extracting response: $e');
      print('Response data structure: $data');
      return 'Maaf, terjadi kesalahan dalam memproses respons. Silakan coba lagi.';
    }
  }
}