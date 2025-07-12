import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

/// Service untuk mengelola environment variables dengan aman
class EnvironmentService {
  static final Logger _logger = Logger();
  
  /// Private constructor untuk singleton pattern
  EnvironmentService._();
  
  /// Instance singleton
  static final EnvironmentService _instance = EnvironmentService._();
  
  /// Getter untuk instance
  static EnvironmentService get instance => _instance;
  
  /// Initialize environment variables
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
      _logger.i('Environment variables loaded successfully');
    } catch (e) {
      _logger.e('Failed to load environment variables: $e');
      // Dalam production, bisa throw exception atau fallback ke default values
    }
  }
  
  /// Get Gemini API Key dengan validation
  String get geminiApiKey {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty) {
      _logger.e('GEMINI_API_KEY not found or empty in .env file');
      throw Exception('Gemini API Key is required but not configured');
    }
    
    if (!_isValidGeminiApiKey(apiKey)) {
      _logger.e('Invalid Gemini API Key format');
      throw Exception('Invalid Gemini API Key format');
    }
    
    return apiKey;
  }
  
  /// Get environment variable dengan default value
  String getEnv(String key, {String defaultValue = ''}) {
    final value = dotenv.env[key] ?? defaultValue;
    if (value.isEmpty && defaultValue.isEmpty) {
      _logger.w('Environment variable $key is empty');
    }
    return value;
  }
  
  /// Check if running in development mode
  bool get isDevelopment {
    final env = dotenv.env['ENVIRONMENT'] ?? 'development';
    return env.toLowerCase() == 'development';
  }
  
  /// Check if running in production mode
  bool get isProduction {
    final env = dotenv.env['ENVIRONMENT'] ?? 'development';
    return env.toLowerCase() == 'production';
  }
  
  /// Validate Gemini API Key format
  bool _isValidGeminiApiKey(String apiKey) {
    // Gemini API keys biasanya dimulai dengan "AIza" dan memiliki panjang tertentu
    return apiKey.startsWith('AIza') && apiKey.length >= 35;
  }
  
  /// Get safe API key untuk logging (hanya menampilkan beberapa karakter pertama)
  String getSafeApiKey(String apiKey) {
    if (apiKey.length < 8) return 'Invalid';
    return '${apiKey.substring(0, 8)}...${apiKey.substring(apiKey.length - 4)}';
  }
  
  /// Log environment status untuk debugging
  void logEnvironmentStatus() {
    if (isDevelopment) {
      try {
        final geminiKey = geminiApiKey;
        _logger.d('Environment Status:');
        _logger.d('- Environment: ${getEnv('ENVIRONMENT', defaultValue: 'development')}');
        _logger.d('- Gemini API Key: ${getSafeApiKey(geminiKey)}');
        _logger.d('- API Key Valid: ${_isValidGeminiApiKey(geminiKey)}');
      } catch (e) {
        _logger.e('Error checking environment status: $e');
      }
    }
  }
}
