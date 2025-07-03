import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../data/models/analytics/real_analytics_models.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  String? _currentSessionId;
  DateTime? _sessionStartTime;
  String? _currentScreen;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Session Management
  void startSession(String screenName) {
    if (_userId == null) return;

    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _sessionStartTime = DateTime.now();
    _currentScreen = screenName;

    _logger.d('Started session: $_currentSessionId on $screenName');
  }

  void endSession() {
    if (_userId == null || _currentSessionId == null || _sessionStartTime == null) return;

    final endTime = DateTime.now();
    final duration = endTime.difference(_sessionStartTime!).inSeconds;

    final session = UserSession(
      id: _currentSessionId!,
      userId: _userId!,
      screen: _currentScreen ?? 'unknown',
      startTime: _sessionStartTime!,
      endTime: endTime,
      duration: duration,
      metadata: {},
    );

    _firestore.collection('user_sessions').add(session.toMap()).then((_) {
      _logger.d('Session saved successfully');
    }).catchError((error) {
      _logger.e('Error saving session: $error');
      return null; // Return null for proper error handling
    });

    _logger.d('Ended session: $_currentSessionId, duration: ${duration}s');
    _currentSessionId = null;
    _sessionStartTime = null;
    _currentScreen = null;
  }

  void switchScreen(String screenName) {
    endSession();
    startSession(screenName);
  }

  // Content Interaction Tracking
  Future<void> trackContentView(String contentId, String contentType) async {
    if (_userId == null) return;

    try {
      final interaction = ContentInteraction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _userId!,
        contentId: contentId,
        contentType: contentType,
        action: 'view',
        timestamp: DateTime.now(),
        metadata: {'screen': _currentScreen ?? 'unknown'},
      );

      await _firestore.collection('content_interactions').add(interaction.toMap());
      _logger.d('Tracked view: $contentType/$contentId');
    } catch (e) {
      _logger.e('Error tracking content view: $e');
    }
  }

  Future<void> trackContentFavorite(String contentId, String contentType, bool isFavorited) async {
    if (_userId == null) return;

    try {
      final interaction = ContentInteraction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _userId!,
        contentId: contentId,
        contentType: contentType,
        action: isFavorited ? 'favorite' : 'unfavorite',
        timestamp: DateTime.now(),
        metadata: {'screen': _currentScreen ?? 'unknown'},
      );

      await _firestore.collection('content_interactions').add(interaction.toMap());
      _logger.d('Tracked favorite: $contentType/$contentId = $isFavorited');
    } catch (e) {
      _logger.e('Error tracking content favorite: $e');
    }
  }

  Future<void> trackContentShare(String contentId, String contentType, String shareMethod) async {
    if (_userId == null) return;

    try {
      final interaction = ContentInteraction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _userId!,
        contentId: contentId,
        contentType: contentType,
        action: 'share',
        timestamp: DateTime.now(),
        metadata: {
          'screen': _currentScreen ?? 'unknown',
          'shareMethod': shareMethod,
        },
      );

      await _firestore.collection('content_interactions').add(interaction.toMap());
      _logger.d('Tracked share: $contentType/$contentId via $shareMethod');
    } catch (e) {
      _logger.e('Error tracking content share: $e');
    }
  }

  // Chatbot Interaction Tracking
  Future<void> trackChatbotInteraction({
    required String question,
    required String response,
    required List<String> topics,
  }) async {
    if (_userId == null) return;

    try {
      final sessionId = _currentSessionId ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      final interaction = ChatbotInteraction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _userId!,
        sessionId: sessionId,
        question: question,
        response: response,
        timestamp: DateTime.now(),
        topics: topics,
      );

      await _firestore.collection('chatbot_interactions').add(interaction.toMap());
      _logger.d('Tracked chatbot interaction: ${question.substring(0, 50)}...');
    } catch (e) {
      _logger.e('Error tracking chatbot interaction: $e');
    }
  }

  Future<void> rateChatbotResponse(String interactionId, int satisfaction) async {
    try {
      await _firestore
          .collection('chatbot_interactions')
          .doc(interactionId)
          .update({'satisfaction': satisfaction});
      _logger.d('Rated chatbot response: $satisfaction/5');
    } catch (e) {
      _logger.e('Error rating chatbot response: $e');
    }
  }

  // Search Tracking
  Future<void> trackSearchQuery({
    required String query,
    required String screen,
    required int resultsCount,
  }) async {
    if (_userId == null) return;

    try {
      final searchQuery = SearchQuery(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _userId!,
        query: query.toLowerCase().trim(),
        screen: screen,
        resultsCount: resultsCount,
        timestamp: DateTime.now(),
        hasClickthrough: false,
      );

      await _firestore.collection('search_queries').add(searchQuery.toMap());
      _logger.d('Tracked search: "$query" ($resultsCount results)');
    } catch (e) {
      _logger.e('Error tracking search query: $e');
    }
  }

  Future<void> trackSearchClickthrough(String query) async {
    try {
      // Update the latest search query to mark clickthrough
      final querySnapshot = await _firestore
          .collection('search_queries')
          .where('userId', isEqualTo: _userId)
          .where('query', isEqualTo: query.toLowerCase().trim())
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({'hasClickthrough': true});
        _logger.d('Tracked search clickthrough: "$query"');
      }
    } catch (e) {
      _logger.e('Error tracking search clickthrough: $e');
    }
  }

  // Utility method to extract topics from text
  List<String> extractTopics(String text) {
    final topics = <String>[];
    final lowerText = text.toLowerCase();

    // Define topic keywords
    final topicKeywords = {
      'penyiraman': ['siram', 'air', 'penyiraman', 'basah', 'kering'],
      'pemupukan': ['pupuk', 'nutrisi', 'kompos', 'organik'],
      'hama': ['hama', 'serangga', 'ulat', 'kutu', 'penyakit'],
      'tanaman': ['tanaman', 'tumbuhan', 'daun', 'bunga', 'buah'],
      'perawatan': ['rawat', 'maintenance', 'care', 'jaga'],
      'menanam': ['tanam', 'semai', 'bibit', 'benih'],
      'panen': ['panen', 'harvest', 'petik', 'ambil'],
    };

    topicKeywords.forEach((topic, keywords) {
      if (keywords.any((keyword) => lowerText.contains(keyword))) {
        topics.add(topic);
      }
    });

    return topics.isEmpty ? ['general'] : topics;
  }
}
