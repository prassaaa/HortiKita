import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class UserTrackingService {
  static final UserTrackingService _instance = UserTrackingService._internal();
  factory UserTrackingService() => _instance;
  UserTrackingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  String? _currentSessionId;
  DateTime? _sessionStartTime;

  // ===================== SESSION TRACKING =====================

  /// Start a new user session
  Future<void> startSession() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _currentSessionId = _generateSessionId();
      _sessionStartTime = DateTime.now();

      await _firestore.collection('user_sessions').doc(_currentSessionId).set({
        'userId': user.uid,
        'startTime': Timestamp.fromDate(_sessionStartTime!),
        'endTime': null,
        'duration': 0,
        'screenViews': 0,
        'interactions': 0,
        'lastActivity': Timestamp.fromDate(_sessionStartTime!),
        'deviceInfo': {
          'platform': 'mobile', // Could be enhanced with actual device info
          'userAgent': 'Flutter App',
        },
      });

      _logger.d('Session started: $_currentSessionId');
    } catch (e) {
      _logger.e('Error starting session: $e');
    }
  }

  /// End current session
  Future<void> endSession() async {
    if (_currentSessionId == null || _sessionStartTime == null) return;

    try {
      final endTime = DateTime.now();
      final duration = endTime.difference(_sessionStartTime!).inSeconds;

      await _firestore.collection('user_sessions').doc(_currentSessionId).update({
        'endTime': Timestamp.fromDate(endTime),
        'duration': duration,
        'lastActivity': Timestamp.fromDate(endTime),
      });

      _logger.d('Session ended: $_currentSessionId, duration: ${duration}s');
      
      _currentSessionId = null;
      _sessionStartTime = null;
    } catch (e) {
      _logger.e('Error ending session: $e');
    }
  }

  /// Track screen view
  Future<void> trackScreenView(String screenName) async {
    if (_currentSessionId == null) return;

    try {
      // Update session
      await _firestore.collection('user_sessions').doc(_currentSessionId).update({
        'screenViews': FieldValue.increment(1),
        'lastActivity': Timestamp.now(),
      });

      // Track individual screen view
      await _firestore.collection('screen_views').add({
        'sessionId': _currentSessionId,
        'userId': _auth.currentUser?.uid,
        'screenName': screenName,
        'timestamp': Timestamp.now(),
        'viewDuration': 0, // Will be updated when leaving screen
      });

      _logger.d('Screen view tracked: $screenName');
    } catch (e) {
      _logger.e('Error tracking screen view: $e');
    }
  }

  /// Track user interaction
  Future<void> trackInteraction(String action, {Map<String, dynamic>? metadata}) async {
    if (_currentSessionId == null) return;

    try {
      await _firestore.collection('user_interactions').add({
        'sessionId': _currentSessionId,
        'userId': _auth.currentUser?.uid,
        'action': action,
        'metadata': metadata ?? {},
        'timestamp': Timestamp.now(),
      });

      // Update session interaction count
      await _firestore.collection('user_sessions').doc(_currentSessionId).update({
        'interactions': FieldValue.increment(1),
        'lastActivity': Timestamp.now(),
      });

      _logger.d('Interaction tracked: $action');
    } catch (e) {
      _logger.e('Error tracking interaction: $e');
    }
  }

  // ===================== CONTENT TRACKING =====================

  /// Track content view (plants, articles)
  Future<void> trackContentView(String contentType, String contentId, String contentTitle) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Track individual content view
      await _firestore.collection('content_views').add({
        'userId': user.uid,
        'sessionId': _currentSessionId,
        'contentType': contentType, // 'plant' or 'article'
        'contentId': contentId,
        'contentTitle': contentTitle,
        'timestamp': Timestamp.now(),
        'viewDuration': 0, // Will be updated when leaving content
      });

      // Update content engagement metrics
      final engagementRef = _firestore.collection('content_engagement').doc(contentId);
      await engagementRef.set({
        'contentType': contentType,
        'contentId': contentId,
        'contentTitle': contentTitle,
        'totalViews': FieldValue.increment(1),
        'uniqueViews': FieldValue.increment(1), // We'll handle uniqueness later
        'lastViewed': Timestamp.now(),
        'viewsByDate': {
          _getDateKey(DateTime.now()): FieldValue.increment(1),
        },
      }, SetOptions(merge: true));

      _logger.d('Content view tracked: $contentType/$contentId');
    } catch (e) {
      _logger.e('Error tracking content view: $e');
    }
  }

  /// Track content interaction (like, share, favorite)
  Future<void> trackContentInteraction(
    String contentType, 
    String contentId, 
    String action, // 'like', 'share', 'favorite', 'unfavorite'
    {Map<String, dynamic>? metadata}
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Track individual interaction
      await _firestore.collection('content_interactions').add({
        'userId': user.uid,
        'sessionId': _currentSessionId,
        'contentType': contentType,
        'contentId': contentId,
        'action': action,
        'metadata': metadata ?? {},
        'timestamp': Timestamp.now(),
      });

      // Update content engagement metrics
      final engagementRef = _firestore.collection('content_engagement').doc(contentId);
      
      Map<String, dynamic> updates = {};
      switch (action) {
        case 'like':
          updates['totalLikes'] = FieldValue.increment(1);
          break;
        case 'share':
          updates['totalShares'] = FieldValue.increment(1);
          break;
        case 'favorite':
          updates['totalFavorites'] = FieldValue.increment(1);
          break;
        case 'unfavorite':
          updates['totalFavorites'] = FieldValue.increment(-1);
          break;
      }

      if (updates.isNotEmpty) {
        await engagementRef.update(updates);
      }

      _logger.d('Content interaction tracked: $action on $contentType/$contentId');
    } catch (e) {
      _logger.e('Error tracking content interaction: $e');
    }
  }

  // ===================== CHATBOT TRACKING =====================

  /// Track chatbot interaction
  Future<void> trackChatbotInteraction(
    String sessionId,
    String question,
    String response,
    {List<String>? topics, int? satisfaction}
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('chatbot_interactions').add({
        'userId': user.uid,
        'sessionId': sessionId,
        'question': question,
        'response': response,
        'topics': topics ?? [],
        'satisfaction': satisfaction,
        'timestamp': Timestamp.now(),
        'responseTime': 0, // Will be calculated based on request time
      });

      _logger.d('Chatbot interaction tracked');
    } catch (e) {
      _logger.e('Error tracking chatbot interaction: $e');
    }
  }

  // ===================== HELPER METHODS =====================

  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${_auth.currentUser?.uid}';
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ===================== ANALYTICS HELPERS =====================

  /// Get user analytics data
  Future<Map<String, dynamic>> getUserAnalytics() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      // Get user sessions
      final sessionsSnapshot = await _firestore
          .collection('user_sessions')
          .where('userId', isEqualTo: user.uid)
          .orderBy('startTime', descending: true)
          .get();

      // Get content views
      final viewsSnapshot = await _firestore
          .collection('content_views')
          .where('userId', isEqualTo: user.uid)
          .get();

      // Get content interactions
      final interactionsSnapshot = await _firestore
          .collection('content_interactions')
          .where('userId', isEqualTo: user.uid)
          .get();

      return {
        'totalSessions': sessionsSnapshot.docs.length,
        'totalViews': viewsSnapshot.docs.length,
        'totalInteractions': interactionsSnapshot.docs.length,
        'lastSession': sessionsSnapshot.docs.isNotEmpty
            ? (sessionsSnapshot.docs.first.data()['startTime'] as Timestamp).toDate()
            : null,
      };
    } catch (e) {
      _logger.e('Error getting user analytics: $e');
      return {};
    }
  }
}
