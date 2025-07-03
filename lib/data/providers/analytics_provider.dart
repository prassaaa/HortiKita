import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/analytics/analytics_model.dart';
import '../models/analytics/content_analytics_model.dart';
import '../models/analytics/chatbot_analytics_model.dart';

class AnalyticsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  
  // State variables
  bool _isLoading = false;
  String _error = '';
  
  // Analytics data
  AnalyticsOverview? _overview;
  List<ContentPerformance> _topPlants = [];
  List<ContentPerformance> _topArticles = [];
  final List<CategoryPerformance> _categoryPerformance = [];
  final List<SearchAnalytics> _searchAnalytics = [];
  ChatbotAnalytics? _chatbotAnalytics;
  List<UserActivityData> _userActivity = [];
  List<GrowthData> _growthData = [];

  // Getters
  bool get isLoading => _isLoading;
  String get error => _error;
  AnalyticsOverview? get overview => _overview;
  List<ContentPerformance> get topPlants => _topPlants;
  List<ContentPerformance> get topArticles => _topArticles;
  List<CategoryPerformance> get categoryPerformance => _categoryPerformance;
  List<SearchAnalytics> get searchAnalytics => _searchAnalytics;
  ChatbotAnalytics? get chatbotAnalytics => _chatbotAnalytics;
  List<UserActivityData> get userActivity => _userActivity;
  List<GrowthData> get growthData => _growthData;

  // Load all analytics data
  Future<void> loadAnalyticsData() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _logger.d('Loading analytics data...');
      
      // Load data concurrently
      await Future.wait([
        _loadOverview(),
        _loadContentPerformance(),
        _loadChatbotAnalytics(),
        _loadUserActivity(),
        _loadGrowthData(),
      ]);

      _logger.d('Analytics data loaded successfully');
    } catch (e) {
      _error = 'Failed to load analytics data: ${e.toString()}';
      _logger.e('Error loading analytics: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load overview data
  Future<void> _loadOverview() async {
    try {
      // Get counts from collections
      final usersSnapshot = await _firestore.collection('users').get();
      final plantsSnapshot = await _firestore.collection('plants').get();
      final articlesSnapshot = await _firestore.collection('articles').get();
      
      // Get conversations count (if you have conversations collection)
      int conversationsCount = 0;
      try {
        final conversationsSnapshot = await _firestore.collection('conversations').get();
        conversationsCount = conversationsSnapshot.docs.length;
      } catch (e) {
        _logger.w('Conversations collection not found: $e');
      }

      // Calculate active users (this is simplified - you might want to track this differently)
      // In real app, you'd track user sessions
      final activeUsersToday = (usersSnapshot.docs.length * 0.1).round();
      final activeUsersWeek = (usersSnapshot.docs.length * 0.3).round();
      final activeUsersMonth = (usersSnapshot.docs.length * 0.6).round();

      _overview = AnalyticsOverview(
        totalUsers: usersSnapshot.docs.length,
        totalPlants: plantsSnapshot.docs.length,
        totalArticles: articlesSnapshot.docs.length,
        totalConversations: conversationsCount,
        activeUsersToday: activeUsersToday,
        activeUsersWeek: activeUsersWeek,
        activeUsersMonth: activeUsersMonth,
        avgSessionDuration: 8.5, // minutes, simplified
        lastUpdated: DateTime.now(),
      );

      _logger.d('Overview loaded: ${_overview!.totalUsers} users, ${_overview!.totalPlants} plants');
    } catch (e) {
      _logger.e('Error loading overview: $e');
      rethrow;
    }
  }

  // Load content performance data
  Future<void> _loadContentPerformance() async {
    try {
      // Load plants performance
      final plantsSnapshot = await _firestore
          .collection('plants')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      _topPlants = plantsSnapshot.docs.map((doc) {
        final data = doc.data();
        return ContentPerformance(
          id: doc.id,
          type: 'plant',
          title: data['name'] ?? 'Unknown Plant',
          views: _generateRandomViews(), // Simplified - you'd track this
          likes: _generateRandomLikes(),
          shares: _generateRandomShares(),
          rating: _generateRandomRating(),
          ratingCount: _generateRandomRatingCount(),
          lastViewed: DateTime.now().subtract(Duration(days: _generateRandomDays())),
          viewsByDate: _generateViewsByDate(),
          topSearchKeywords: _generateSearchKeywords(data['name'] ?? ''),
        );
      }).toList();

      // Load articles performance
      final articlesSnapshot = await _firestore
          .collection('articles')
          .orderBy('publishedAt', descending: true)
          .limit(20)
          .get();

      _topArticles = articlesSnapshot.docs.map((doc) {
        final data = doc.data();
        return ContentPerformance(
          id: doc.id,
          type: 'article',
          title: data['title'] ?? 'Unknown Article',
          views: _generateRandomViews(),
          likes: _generateRandomLikes(),
          shares: _generateRandomShares(),
          rating: _generateRandomRating(),
          ratingCount: _generateRandomRatingCount(),
          lastViewed: DateTime.now().subtract(Duration(days: _generateRandomDays())),
          viewsByDate: _generateViewsByDate(),
          topSearchKeywords: _generateSearchKeywords(data['title'] ?? ''),
        );
      }).toList();

      // Sort by views
      _topPlants.sort((a, b) => b.views.compareTo(a.views));
      _topArticles.sort((a, b) => b.views.compareTo(a.views));

      _logger.d('Content performance loaded: ${_topPlants.length} plants, ${_topArticles.length} articles');
    } catch (e) {
      _logger.e('Error loading content performance: $e');
      rethrow;
    }
  }

  // Load chatbot analytics
  Future<void> _loadChatbotAnalytics() async {
    try {
      // This would typically come from your chatbot logs
      // For now, we'll create sample data
      _chatbotAnalytics = ChatbotAnalytics(
        totalConversations: 245,
        totalMessages: 1876,
        avgConversationLength: 7.6,
        avgResponseTime: 1.2,
        userSatisfactionScore: 4.3,
        totalUsers: 89,
        lastUpdated: DateTime.now(),
        topQuestions: {
          'Cara menyiram tanaman tomat': 45,
          'Pupuk apa yang baik untuk cabai': 38,
          'Kenapa daun tanaman menguning': 32,
          'Kapan waktu tanam yang tepat': 28,
          'Cara mengatasi hama tanaman': 25,
        },
        topTopics: {
          'Perawatan Tanaman': 156,
          'Penyiraman': 134,
          'Pemupukan': 98,
          'Hama dan Penyakit': 87,
          'Waktu Tanam': 76,
        },
        hourlyUsage: _generateHourlyUsage(),
        contentGaps: [
          ContentGap(
            topic: 'Penyakit Tanaman',
            questionCount: 32,
            priority: 8.5,
            suggestedAction: 'Buat artikel tentang penyakit tanaman umum',
            relatedQuestions: [
              'Daun menguning kenapa?',
              'Cara mengatasi jamur pada tanaman',
              'Tanaman layu tiba-tiba'
            ],
            lastDetected: DateTime.now().subtract(const Duration(days: 2)),
          ),
          ContentGap(
            topic: 'Pupuk Organik',
            questionCount: 28,
            priority: 7.2,
            suggestedAction: 'Tambah informasi tentang pupuk organik',
            relatedQuestions: [
              'Cara membuat pupuk kompos',
              'Pupuk organik terbaik untuk sayuran',
              'Berapa sering kasih pupuk organik'
            ],
            lastDetected: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ],
      );

      _logger.d('Chatbot analytics loaded: ${_chatbotAnalytics!.totalConversations} conversations');
    } catch (e) {
      _logger.e('Error loading chatbot analytics: $e');
      rethrow;
    }
  }

  // Load user activity data
  Future<void> _loadUserActivity() async {
    try {
      // Generate sample user activity data for the last 30 days
      _userActivity = [];
      for (int i = 29; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        _userActivity.add(UserActivityData(
          date: '${date.day}/${date.month}',
          activeUsers: _generateRandomActiveUsers(),
          newUsers: _generateRandomNewUsers(),
          totalSessions: _generateRandomSessions(),
          avgSessionDuration: _generateRandomSessionDuration(),
        ));
      }

      _logger.d('User activity loaded: ${_userActivity.length} days of data');
    } catch (e) {
      _logger.e('Error loading user activity: $e');
      rethrow;
    }
  }

  // Load growth data
  Future<void> _loadGrowthData() async {
    try {
      // Generate sample growth data for the last 12 months
      _growthData = [];
      for (int i = 11; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i * 30));
        _growthData.add(GrowthData(
          period: 'monthly',
          date: '${date.month}/${date.year}',
          users: _generateCumulativeUsers(i),
          articles: _generateCumulativeArticles(i),
          plants: _generateCumulativePlants(i),
          conversations: _generateCumulativeConversations(i),
        ));
      }

      _logger.d('Growth data loaded: ${_growthData.length} months of data');
    } catch (e) {
      _logger.e('Error loading growth data: $e');
      rethrow;
    }
  }

  // Helper methods for generating sample data
  int _generateRandomViews() => 50 + (DateTime.now().millisecondsSinceEpoch % 500);
  int _generateRandomLikes() => 5 + (DateTime.now().millisecondsSinceEpoch % 50);
  int _generateRandomShares() => 1 + (DateTime.now().millisecondsSinceEpoch % 20);
  double _generateRandomRating() => 3.5 + ((DateTime.now().millisecondsSinceEpoch % 15) / 10);
  int _generateRandomRatingCount() => 10 + (DateTime.now().millisecondsSinceEpoch % 100);
  int _generateRandomDays() => DateTime.now().millisecondsSinceEpoch % 30;
  
  Map<String, int> _generateViewsByDate() {
    Map<String, int> viewsByDate = {};
    for (int i = 7; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      viewsByDate[dateStr] = 5 + (DateTime.now().millisecondsSinceEpoch % 25);
    }
    return viewsByDate;
  }
  
  List<String> _generateSearchKeywords(String title) {
    final words = title.toLowerCase().split(' ');
    return words.take(3).toList();
  }
  
  Map<String, int> _generateHourlyUsage() {
    Map<String, int> hourlyUsage = {};
    for (int i = 0; i < 24; i++) {
      hourlyUsage[i.toString()] = _generateHourlyUsageCount(i);
    }
    return hourlyUsage;
  }
  
  int _generateHourlyUsageCount(int hour) {
    // Peak hours: 7-9 AM, 12-2 PM, 7-10 PM
    if ((hour >= 7 && hour <= 9) || (hour >= 12 && hour <= 14) || (hour >= 19 && hour <= 22)) {
      return 15 + (hour % 10);
    } else if (hour >= 6 && hour <= 23) {
      return 5 + (hour % 8);
    } else {
      return 1 + (hour % 3);
    }
  }
  
  int _generateRandomActiveUsers() => 15 + (DateTime.now().millisecondsSinceEpoch % 30);
  int _generateRandomNewUsers() => 2 + (DateTime.now().millisecondsSinceEpoch % 8);
  int _generateRandomSessions() => 25 + (DateTime.now().millisecondsSinceEpoch % 50);
  double _generateRandomSessionDuration() => 5.0 + ((DateTime.now().millisecondsSinceEpoch % 100) / 10);
  
  int _generateCumulativeUsers(int monthsAgo) => 50 + ((11 - monthsAgo) * 25) + (DateTime.now().millisecondsSinceEpoch % 50);
  int _generateCumulativeArticles(int monthsAgo) => 10 + ((11 - monthsAgo) * 5) + (DateTime.now().millisecondsSinceEpoch % 15);
  int _generateCumulativePlants(int monthsAgo) => 20 + ((11 - monthsAgo) * 8) + (DateTime.now().millisecondsSinceEpoch % 20);
  int _generateCumulativeConversations(int monthsAgo) => 30 + ((11 - monthsAgo) * 40) + (DateTime.now().millisecondsSinceEpoch % 100);

  // Refresh analytics data
  Future<void> refreshAnalytics() async {
    await loadAnalyticsData();
  }

  // Get content gaps for content strategy
  List<ContentGap> getHighPriorityContentGaps() {
    if (_chatbotAnalytics == null) return [];
    return _chatbotAnalytics!.contentGaps
        .where((gap) => gap.priority >= 7.0)
        .toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  // Get trending topics
  List<String> getTrendingTopics() {
    if (_chatbotAnalytics == null) return [];
    final sortedTopics = _chatbotAnalytics!.topTopics.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedTopics.take(5).map((e) => e.key).toList();
  }

  // Get top performing content
  List<ContentPerformance> getTopContent({String? type, int limit = 10}) {
    List<ContentPerformance> content = [];
    
    if (type == null || type == 'plant') {
      content.addAll(_topPlants);
    }
    if (type == null || type == 'article') {
      content.addAll(_topArticles);
    }
    
    content.sort((a, b) => b.views.compareTo(a.views));
    return content.take(limit).toList();
  }

  // Get engagement metrics
  Map<String, double> getEngagementMetrics() {
    if (_topPlants.isEmpty && _topArticles.isEmpty) return {};
    
    final allContent = [..._topPlants, ..._topArticles];
    final totalViews = allContent.fold<int>(0, (total, item) => total + item.views);
    final totalLikes = allContent.fold<int>(0, (total, item) => total + item.likes);
    final totalShares = allContent.fold<int>(0, (total, item) => total + item.shares);
    
    return {
      'totalViews': totalViews.toDouble(),
      'totalLikes': totalLikes.toDouble(),
      'totalShares': totalShares.toDouble(),
      'engagementRate': totalViews > 0 ? ((totalLikes + totalShares) / totalViews) * 100 : 0.0,
      'avgRating': allContent.isNotEmpty 
          ? allContent.fold<double>(0, (total, item) => total + item.rating) / allContent.length
          : 0.0,
    };
  }

  // Clear analytics data
  void clearAnalytics() {
    _overview = null;
    _topPlants.clear();
    _topArticles.clear();
    _categoryPerformance.clear();
    _searchAnalytics.clear();
    _chatbotAnalytics = null;
    _userActivity.clear();
    _growthData.clear();
    _error = '';
    notifyListeners();
  }
}
