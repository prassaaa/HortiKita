import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/user_engagement/user_favorites_model.dart';
import '../models/user_engagement/content_engagement_model.dart';
import '../models/user_engagement/content_rating_model.dart';
import '../../services/user_engagement_service.dart';

class UserEngagementProvider with ChangeNotifier {
  final UserEngagementService _engagementService = UserEngagementService();
  final Logger _logger = Logger();

  // State variables
  bool _isLoading = false;
  String _error = '';
  
  // User data
  UserFavorites? _userFavorites;
  final Map<String, ContentEngagement> _contentEngagements = {};
  final Map<String, ContentRating> _userRatings = {};
  Map<String, dynamic> _userInsights = {};
  
  // Popular & trending content
  List<Map<String, dynamic>> _popularPlants = [];
  List<Map<String, dynamic>> _popularArticles = [];
  List<Map<String, dynamic>> _trendingPlants = [];
  List<Map<String, dynamic>> _trendingArticles = [];

  // Getters
  bool get isLoading => _isLoading;
  String get error => _error;
  UserFavorites? get userFavorites => _userFavorites;
  Map<String, ContentEngagement> get contentEngagements => _contentEngagements;
  Map<String, ContentRating> get userRatings => _userRatings;
  Map<String, dynamic> get userInsights => _userInsights;
  List<Map<String, dynamic>> get popularPlants => _popularPlants;
  List<Map<String, dynamic>> get popularArticles => _popularArticles;
  List<Map<String, dynamic>> get trendingPlants => _trendingPlants;
  List<Map<String, dynamic>> get trendingArticles => _trendingArticles;

  // ===================== USER FAVORITES =====================

  /// Load user favorites
  Future<void> loadUserFavorites() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _userFavorites = await _engagementService.getUserFavorites();
      _logger.d('User favorites loaded');
    } catch (e) {
      _error = 'Failed to load user favorites: ${e.toString()}';
      _logger.e('Error loading user favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle plant favorite
  Future<bool> togglePlantFavorite(String plantId) async {
    try {
      final isFavorited = await _engagementService.togglePlantFavorite(plantId);
      
      // Refresh user favorites
      await loadUserFavorites();
      
      return isFavorited;
    } catch (e) {
      _error = 'Failed to toggle plant favorite: ${e.toString()}';
      _logger.e('Error toggling plant favorite: $e');
      notifyListeners();
      return false;
    }
  }

  /// Toggle article favorite
  Future<bool> toggleArticleFavorite(String articleId) async {
    try {
      final isFavorited = await _engagementService.toggleArticleFavorite(articleId);
      
      // Refresh user favorites
      await loadUserFavorites();
      
      return isFavorited;
    } catch (e) {
      _error = 'Failed to toggle article favorite: ${e.toString()}';
      _logger.e('Error toggling article favorite: $e');
      notifyListeners();
      return false;
    }
  }

  /// Check if plant is favorited
  bool isPlantFavorited(String plantId) {
    return _userFavorites?.isFavoritePlant(plantId) ?? false;
  }

  /// Check if article is favorited
  bool isArticleFavorited(String articleId) {
    return _userFavorites?.isFavoriteArticle(articleId) ?? false;
  }

  // ===================== CONTENT ENGAGEMENT =====================

  /// Track content view
  Future<void> trackContentView(String contentId, String contentType) async {
    try {
      await _engagementService.trackContentView(contentId, contentType);
      
      // Update local engagement data
      await loadContentEngagement(contentId);
      
    } catch (e) {
      _logger.e('Error tracking content view: $e');
    }
  }

  /// Track content share
  Future<void> trackContentShare(String contentId, String contentType, String platform) async {
    try {
      await _engagementService.trackContentShare(contentId, contentType, platform);
      
      // Update local engagement data
      await loadContentEngagement(contentId);
      
    } catch (e) {
      _logger.e('Error tracking content share: $e');
    }
  }

  /// Load content engagement
  Future<void> loadContentEngagement(String contentId) async {
    try {
      final engagement = await _engagementService.getContentEngagement(contentId);
      if (engagement != null) {
        _contentEngagements[contentId] = engagement;
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Error loading content engagement: $e');
    }
  }

  /// Get content engagement
  ContentEngagement? getContentEngagement(String contentId) {
    return _contentEngagements[contentId];
  }

  // ===================== CONTENT RATINGS =====================

  /// Rate content
  Future<bool> rateContent({
    required String contentId,
    required String contentType,
    required int rating,
    String? comment,
    bool isVerified = false,
  }) async {
    try {
      final success = await _engagementService.rateContent(
        contentId: contentId,
        contentType: contentType,
        rating: rating,
        comment: comment,
        isVerified: isVerified,
      );

      if (success) {
        // Refresh user rating and content engagement
        await loadUserRating(contentId);
        await loadContentEngagement(contentId);
      }

      return success;
    } catch (e) {
      _error = 'Failed to rate content: ${e.toString()}';
      _logger.e('Error rating content: $e');
      notifyListeners();
      return false;
    }
  }

  /// Load user rating for content
  Future<void> loadUserRating(String contentId) async {
    try {
      final rating = await _engagementService.getUserRating(contentId);
      if (rating != null) {
        _userRatings[contentId] = rating;
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Error loading user rating: $e');
    }
  }

  /// Get user rating for content
  ContentRating? getUserRating(String contentId) {
    return _userRatings[contentId];
  }

  /// Vote rating as helpful
  Future<bool> voteRatingHelpful(String ratingId) async {
    try {
      return await _engagementService.voteRatingHelpful(ratingId);
    } catch (e) {
      _error = 'Failed to vote rating: ${e.toString()}';
      _logger.e('Error voting rating helpful: $e');
      notifyListeners();
      return false;
    }
  }

  // ===================== ANALYTICS & INSIGHTS =====================

  /// Load user insights
  Future<void> loadUserInsights() async {
    try {
      _userInsights = await _engagementService.getUserEngagementInsights();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load user insights: ${e.toString()}';
      _logger.e('Error loading user insights: $e');
      notifyListeners();
    }
  }

  /// Load popular content
  Future<void> loadPopularContent() async {
    try {
      _popularPlants = await _engagementService.getPopularContent(
        contentType: 'plant',
        limit: 10,
      );
      
      _popularArticles = await _engagementService.getPopularContent(
        contentType: 'article',
        limit: 10,
      );
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load popular content: ${e.toString()}';
      _logger.e('Error loading popular content: $e');
      notifyListeners();
    }
  }

  /// Load trending content
  Future<void> loadTrendingContent() async {
    try {
      _trendingPlants = await _engagementService.getTrendingContent(
        contentType: 'plant',
        limit: 10,
      );
      
      _trendingArticles = await _engagementService.getTrendingContent(
        contentType: 'article',
        limit: 10,
      );
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load trending content: ${e.toString()}';
      _logger.e('Error loading trending content: $e');
      notifyListeners();
    }
  }

  /// Load all engagement data
  Future<void> loadAllEngagementData() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await Future.wait([
        loadUserFavorites(),
        loadUserInsights(),
        loadPopularContent(),
        loadTrendingContent(),
      ]);

      _logger.d('All engagement data loaded successfully');
    } catch (e) {
      _error = 'Failed to load engagement data: ${e.toString()}';
      _logger.e('Error loading all engagement data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear all data
  void clearData() {
    _userFavorites = null;
    _contentEngagements.clear();
    _userRatings.clear();
    _userInsights.clear();
    _popularPlants.clear();
    _popularArticles.clear();
    _trendingPlants.clear();
    _trendingArticles.clear();
    _error = '';
    notifyListeners();
  }

  /// Refresh data
  Future<void> refreshData() async {
    await loadAllEngagementData();
  }
}
