import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class DebugDataService {
  static final DebugDataService _instance = DebugDataService._internal();
  factory DebugDataService() => _instance;
  DebugDataService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  /// Check and log current analytics data status
  Future<void> checkAnalyticsDataStatus() async {
    try {
      _logger.i('=== CHECKING REAL ANALYTICS DATA STATUS ===');
      
      // Check Users
      final usersSnapshot = await _firestore.collection('users').get();
      _logger.i('Users Collection: ${usersSnapshot.docs.length} users');
      
      // Check Plants
      final plantsSnapshot = await _firestore.collection('plants').get();
      _logger.i('Plants Collection: ${plantsSnapshot.docs.length} plants');
      
      // Check Articles
      final articlesSnapshot = await _firestore.collection('articles').get();
      _logger.i('Articles Collection: ${articlesSnapshot.docs.length} articles');
      
      // Check Chat History
      final chatHistorySnapshot = await _firestore.collection('chat_history').get();
      _logger.i('Chat History Collection: ${chatHistorySnapshot.docs.length} conversations');
      
      // Check User Sessions
      final userSessionsSnapshot = await _firestore.collection('user_sessions').get();
      _logger.i('User Sessions Collection: ${userSessionsSnapshot.docs.length} sessions');
      
      // Check Content Engagement
      final contentEngagementSnapshot = await _firestore.collection('content_engagement').get();
      _logger.i('Content Engagement Collection: ${contentEngagementSnapshot.docs.length} items');
      
      // Check Content Interactions
      final contentInteractionsSnapshot = await _firestore.collection('content_interactions').get();
      _logger.i('Content Interactions Collection: ${contentInteractionsSnapshot.docs.length} interactions');
      
      // Check Chatbot Interactions
      final chatbotInteractionsSnapshot = await _firestore.collection('chatbot_interactions').get();
      _logger.i('Chatbot Interactions Collection: ${chatbotInteractionsSnapshot.docs.length} interactions');
      
      _logger.i('=== DATA STATUS CHECK COMPLETE ===');
      
      // Recommendations
      if (chatHistorySnapshot.docs.isEmpty) {
        _logger.w('🚨 ISSUE: No chat history found. Users need to chat with AI to generate data.');
      }
      
      if (userSessionsSnapshot.docs.isEmpty) {
        _logger.w('🚨 ISSUE: No user sessions found. Session tracking may not be active.');
      }
      
      if (contentEngagementSnapshot.docs.isEmpty) {
        _logger.w('🚨 ISSUE: No content engagement data. Users need to view/like plants and articles.');
      }
      
      if (contentInteractionsSnapshot.docs.isEmpty) {
        _logger.w('🚨 ISSUE: No content interactions. Users need to interact with plants/articles.');
      }
      
    } catch (e) {
      _logger.e('Error checking analytics data status: $e');
    }
  }

  /// Force create a user session for testing
  Future<void> createTestUserSession() async {
    final user = _auth.currentUser;
    if (user == null) {
      _logger.e('No authenticated user for test session creation');
      return;
    }

    try {
      final sessionId = 'test_session_${DateTime.now().millisecondsSinceEpoch}';
      await _firestore.collection('user_sessions').doc(sessionId).set({
        'userId': user.uid,
        'startTime': Timestamp.now(),
        'endTime': Timestamp.now(),
        'duration': 600, // 10 minutes
        'screenViews': 5,
        'interactions': 8,
        'lastActivity': Timestamp.now(),
        'deviceInfo': {
          'platform': 'mobile',
          'userAgent': 'Flutter App Test',
        },
      });
      
      _logger.i('✅ Test user session created: $sessionId');
    } catch (e) {
      _logger.e('Error creating test user session: $e');
    }
  }

  /// Force create content engagement for testing
  Future<void> createTestContentEngagement() async {
    try {
      // Get first plant
      final plantsSnapshot = await _firestore.collection('plants').limit(1).get();
      if (plantsSnapshot.docs.isEmpty) {
        _logger.e('No plants found for test content engagement');
        return;
      }

      final plant = plantsSnapshot.docs.first;
      await _firestore.collection('content_engagement').doc(plant.id).set({
        'contentType': 'plant',
        'contentId': plant.id,
        'contentTitle': plant.data()['name'] ?? 'Test Plant',
        'totalViews': 25,
        'totalLikes': 5,
        'totalShares': 2,
        'totalFavorites': 3,
        'averageRating': 4.2,
        'ratingCount': 5,
        'lastViewed': Timestamp.now(),
        'viewsByDate': {
          _getDateKey(DateTime.now()): 5,
          _getDateKey(DateTime.now().subtract(Duration(days: 1))): 8,
          _getDateKey(DateTime.now().subtract(Duration(days: 2))): 12,
        },
        'topSearchKeywords': ['tanaman', 'perawatan'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      
      _logger.i('✅ Test content engagement created for plant: ${plant.id}');
    } catch (e) {
      _logger.e('Error creating test content engagement: $e');
    }
  }

  /// Force create content interaction for testing
  Future<void> createTestContentInteraction() async {
    final user = _auth.currentUser;
    if (user == null) {
      _logger.e('No authenticated user for test content interaction');
      return;
    }

    try {
      final plantsSnapshot = await _firestore.collection('plants').limit(1).get();
      if (plantsSnapshot.docs.isEmpty) {
        _logger.e('No plants found for test content interaction');
        return;
      }

      final plant = plantsSnapshot.docs.first;
      await _firestore.collection('content_interactions').add({
        'userId': user.uid,
        'sessionId': 'test_session_${DateTime.now().millisecondsSinceEpoch}',
        'contentType': 'plant',
        'contentId': plant.id,
        'action': 'like',
        'metadata': {
          'plant_name': plant.data()['name'] ?? 'Test Plant',
          'category': plant.data()['category'] ?? 'Test',
        },
        'timestamp': Timestamp.now(),
      });
      
      _logger.i('✅ Test content interaction created for plant: ${plant.id}');
    } catch (e) {
      _logger.e('Error creating test content interaction: $e');
    }
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
