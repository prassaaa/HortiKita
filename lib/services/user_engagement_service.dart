import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../data/models/user_engagement/user_favorites_model.dart';
import '../data/models/user_engagement/content_engagement_model.dart';
import '../data/models/user_engagement/content_rating_model.dart';
import '../app/constants/app_constants.dart';

class UserEngagementService {
  static final UserEngagementService _instance = UserEngagementService._internal();
  factory UserEngagementService() => _instance;
  UserEngagementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  String? get _userId => _auth.currentUser?.uid;

  // ===================== USER FAVORITES =====================

  /// Get user favorites
  Future<UserFavorites?> getUserFavorites() async {
    if (_userId == null) return null;

    try {
      final doc = await _firestore
          .collection(AppConstants.userFavoritesCollection)
          .doc(_userId)
          .get();

      if (doc.exists) {
        return UserFavorites.fromFirestore(doc);
      } else {
        // Create new user favorites document
        final newFavorites = UserFavorites(
          userId: _userId!,
          favoritePlants: [],
          favoriteArticles: [],
          readingHistory: [],
          searchHistory: [],
          plantingExperience: {},
          interests: [],
          preferences: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await _firestore
            .collection(AppConstants.userFavoritesCollection)
            .doc(_userId)
            .set(newFavorites.toMap());
            
        return newFavorites;
      }
    } catch (e) {
      _logger.e('Error getting user favorites: $e');
      return null;
    }
  }

  /// Toggle plant favorite
  Future<bool> togglePlantFavorite(String plantId) async {
    if (_userId == null) return false;

    try {
      final favorites = await getUserFavorites();
      if (favorites == null) return false;

      List<String> updatedFavorites = List.from(favorites.favoritePlants);
      bool isFavorited = false;

      if (updatedFavorites.contains(plantId)) {
        updatedFavorites.remove(plantId);
        isFavorited = false;
      } else {
        updatedFavorites.add(plantId);
        isFavorited = true;
      }

      // Update user favorites
      await _firestore
          .collection(AppConstants.userFavoritesCollection)
          .doc(_userId)
          .update({
            'favoritePlants': updatedFavorites,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Update content engagement
      await _updateContentEngagement(plantId, 'plant', 'favorite', isFavorited);

      _logger.d('Plant $plantId ${isFavorited ? 'added to' : 'removed from'} favorites');
      return isFavorited;

    } catch (e) {
      _logger.e('Error toggling plant favorite: $e');
      return false;
    }
  }

  /// Toggle article favorite
  Future<bool> toggleArticleFavorite(String articleId) async {
    if (_userId == null) return false;

    try {
      final favorites = await getUserFavorites();
      if (favorites == null) return false;

      List<String> updatedFavorites = List.from(favorites.favoriteArticles);
      bool isFavorited = false;

      if (updatedFavorites.contains(articleId)) {
        updatedFavorites.remove(articleId);
        isFavorited = false;
      } else {
        updatedFavorites.add(articleId);
        isFavorited = true;
      }

      // Update user favorites
      await _firestore
          .collection(AppConstants.userFavoritesCollection)
          .doc(_userId)
          .update({
            'favoriteArticles': updatedFavorites,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Update content engagement
      await _updateContentEngagement(articleId, 'article', 'favorite', isFavorited);

      _logger.d('Article $articleId ${isFavorited ? 'added to' : 'removed from'} favorites');
      return isFavorited;

    } catch (e) {
      _logger.e('Error toggling article favorite: $e');
      return false;
    }
  }

  /// Check if plant is favorited
  Future<bool> isPlantFavorited(String plantId) async {
    final favorites = await getUserFavorites();
    return favorites?.isFavoritePlant(plantId) ?? false;
  }

  /// Check if article is favorited
  Future<bool> isArticleFavorited(String articleId) async {
    final favorites = await getUserFavorites();
    return favorites?.isFavoriteArticle(articleId) ?? false;
  }

  // ===================== CONTENT ENGAGEMENT =====================

  /// Track content view
  Future<void> trackContentView(String contentId, String contentType) async {
    if (_userId == null) return;

    try {
      await _updateContentEngagement(contentId, contentType, 'view', true);
      
      // Also add to reading history
      await _addToReadingHistory(contentId, contentType);
      
      _logger.d('Tracked view for $contentType: $contentId');
    } catch (e) {
      _logger.e('Error tracking content view: $e');
    }
  }

  /// Track content share
  Future<void> trackContentShare(String contentId, String contentType, String platform) async {
    if (_userId == null) return;

    try {
      await _updateContentEngagement(contentId, contentType, 'share', true);
      _logger.d('Tracked share for $contentType: $contentId on $platform');
    } catch (e) {
      _logger.e('Error tracking content share: $e');
    }
  }

  /// Get content engagement
  Future<ContentEngagement?> getContentEngagement(String contentId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.contentEngagementCollection)
          .doc(contentId)
          .get();

      if (doc.exists) {
        return ContentEngagement.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting content engagement: $e');
      return null;
    }
  }

  // ===================== CONTENT RATINGS =====================

  /// Add or update content rating
  Future<bool> rateContent({
    required String contentId,
    required String contentType,
    required int rating,
    String? comment,
    bool isVerified = false,
  }) async {
    if (_userId == null) return false;

    try {
      // Check if user already rated this content
      final existingRating = await _firestore
          .collection(AppConstants.contentRatingsCollection)
          .where('userId', isEqualTo: _userId)
          .where('contentId', isEqualTo: contentId)
          .limit(1)
          .get();

      final ratingData = ContentRating(
        id: existingRating.docs.isNotEmpty 
            ? existingRating.docs.first.id 
            : DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _userId!,
        contentId: contentId,
        contentType: contentType,
        rating: rating,
        comment: comment,
        helpfulVotes: existingRating.docs.isNotEmpty 
            ? existingRating.docs.first.data()['helpfulVotes'] ?? 0 
            : 0,
        votedBy: existingRating.docs.isNotEmpty 
            ? List<String>.from(existingRating.docs.first.data()['votedBy'] ?? [])
            : [],
        isVerified: isVerified,
        metadata: {},
        createdAt: existingRating.docs.isNotEmpty 
            ? (existingRating.docs.first.data()['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (existingRating.docs.isNotEmpty) {
        // Update existing rating
        await _firestore
            .collection(AppConstants.contentRatingsCollection)
            .doc(existingRating.docs.first.id)
            .update(ratingData.toMap());
      } else {
        // Create new rating
        await _firestore
            .collection(AppConstants.contentRatingsCollection)
            .add(ratingData.toMap());
      }

      // Update content engagement with new average rating
      await _updateContentRating(contentId, contentType);

      _logger.d('Rated $contentType $contentId: $rating stars');
      return true;

    } catch (e) {
      _logger.e('Error rating content: $e');
      return false;
    }
  }

  /// Get user's rating for content
  Future<ContentRating?> getUserRating(String contentId) async {
    if (_userId == null) return null;

    try {
      final snapshot = await _firestore
          .collection(AppConstants.contentRatingsCollection)
          .where('userId', isEqualTo: _userId)
          .where('contentId', isEqualTo: contentId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return ContentRating.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting user rating: $e');
      return null;
    }
  }

  /// Get all ratings for content
  Future<List<ContentRating>> getContentRatings(String contentId, {int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.contentRatingsCollection)
          .where('contentId', isEqualTo: contentId)
          .orderBy('helpfulVotes', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => ContentRating.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.e('Error getting content ratings: $e');
      return [];
    }
  }

  /// Vote rating as helpful
  Future<bool> voteRatingHelpful(String ratingId) async {
    if (_userId == null) return false;

    try {
      final ratingDoc = await _firestore
          .collection(AppConstants.contentRatingsCollection)
          .doc(ratingId)
          .get();

      if (!ratingDoc.exists) return false;

      final rating = ContentRating.fromFirestore(ratingDoc);
      
      if (!rating.canVoteHelpful(_userId!)) return false;

      await _firestore
          .collection(AppConstants.contentRatingsCollection)
          .doc(ratingId)
          .update({
            'helpfulVotes': FieldValue.increment(1),
            'votedBy': FieldValue.arrayUnion([_userId]),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      _logger.d('Voted rating $ratingId as helpful');
      return true;

    } catch (e) {
      _logger.e('Error voting rating helpful: $e');
      return false;
    }
  }

  // ===================== ANALYTICS & INSIGHTS =====================

  /// Get user engagement insights
  Future<Map<String, dynamic>> getUserEngagementInsights() async {
    if (_userId == null) return {};

    try {
      final favorites = await getUserFavorites();
      if (favorites == null) return {};

      // Get user's content interactions
      final interactionsSnapshot = await _firestore
          .collection(AppConstants.contentInteractionsCollection)
          .where('userId', isEqualTo: _userId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      final interactions = interactionsSnapshot.docs;
      
      // Calculate insights
      final insights = <String, dynamic>{
        'totalFavorites': favorites.favoritePlants.length + favorites.favoriteArticles.length,
        'favoritePlants': favorites.favoritePlants.length,
        'favoriteArticles': favorites.favoriteArticles.length,
        'readingHistoryCount': favorites.readingHistory.length,
        'interests': favorites.interests,
        'lastActivity': interactions.isNotEmpty 
            ? (interactions.first.data()['timestamp'] as Timestamp).toDate()
            : null,
        'activityCount': interactions.length,
        'preferredCategories': _calculatePreferredCategories(favorites),
        'engagementLevel': _calculateEngagementLevel(favorites, interactions.length),
      };

      return insights;

    } catch (e) {
      _logger.e('Error getting user engagement insights: $e');
      return {};
    }
  }

  /// Get popular content based on engagement
  Future<List<Map<String, dynamic>>> getPopularContent({
    String? contentType,
    int limit = 10,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.contentEngagementCollection)
          .orderBy('totalViews', descending: true);

      if (contentType != null) {
        query = query.where('contentType', isEqualTo: contentType);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'contentId': doc.id,
          'contentType': data['contentType'],
          'totalViews': data['totalViews'] ?? 0,
          'favorites': data['favorites'] ?? 0,
          'averageRating': data['averageRating'] ?? 0.0,
          'engagementRate': ((data['favorites'] ?? 0) + (data['shares'] ?? 0)) / 
                           (data['totalViews'] ?? 1) * 100,
        };
      }).toList();

    } catch (e) {
      _logger.e('Error getting popular content: $e');
      return [];
    }
  }

  /// Get trending content (popular in last 7 days)
  Future<List<Map<String, dynamic>>> getTrendingContent({
    String? contentType,
    int limit = 10,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.contentEngagementCollection);

      if (contentType != null) {
        query = query.where('contentType', isEqualTo: contentType);
      }

      final snapshot = await query.get();
      
      final contentWithTrending = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final engagement = ContentEngagement.fromFirestore(doc);
        
        return {
          'contentId': doc.id,
          'contentType': data['contentType'],
          'trendingScore': engagement.getTrendingScore(),
          'totalViews': data['totalViews'] ?? 0,
          'favorites': data['favorites'] ?? 0,
          'averageRating': data['averageRating'] ?? 0.0,
        };
      }).toList();

      // Sort by trending score
      contentWithTrending.sort((a, b) => 
          b['trendingScore'].compareTo(a['trendingScore']));

      return contentWithTrending.take(limit).toList();

    } catch (e) {
      _logger.e('Error getting trending content: $e');
      return [];
    }
  }

  // ===================== PRIVATE HELPER METHODS =====================

  /// Update content engagement metrics
  Future<void> _updateContentEngagement(
    String contentId, 
    String contentType, 
    String action, 
    bool increment
  ) async {
    try {
      final docRef = _firestore
          .collection(AppConstants.contentEngagementCollection)
          .doc(contentId);

      final doc = await docRef.get();
      
      if (doc.exists) {
        // Update existing engagement
        final updates = <String, dynamic>{
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        switch (action) {
          case 'view':
            updates['totalViews'] = FieldValue.increment(1);
            // Track daily views
            final today = DateTime.now();
            final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
            updates['viewsByDate.$dateKey'] = FieldValue.increment(1);
            break;
          case 'favorite':
            updates['favorites'] = FieldValue.increment(increment ? 1 : -1);
            break;
          case 'share':
            updates['shares'] = FieldValue.increment(1);
            break;
        }

        await docRef.update(updates);
      } else {
        // Create new engagement document
        final newEngagement = ContentEngagement(
          contentId: contentId,
          contentType: contentType,
          totalViews: action == 'view' ? 1 : 0,
          uniqueViews: action == 'view' ? 1 : 0,
          favorites: action == 'favorite' && increment ? 1 : 0,
          shares: action == 'share' ? 1 : 0,
          averageRating: 0.0,
          ratingCount: 0,
          comments: 0,
          viewsByDate: action == 'view' ? {
            '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}': 1
          } : {},
          categoryBreakdown: {},
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        await docRef.set(newEngagement.toMap());
      }
    } catch (e) {
      _logger.e('Error updating content engagement: $e');
    }
  }

  /// Update content rating average
  Future<void> _updateContentRating(String contentId, String contentType) async {
    try {
      final ratingsSnapshot = await _firestore
          .collection(AppConstants.contentRatingsCollection)
          .where('contentId', isEqualTo: contentId)
          .get();

      if (ratingsSnapshot.docs.isEmpty) return;

      final ratings = ratingsSnapshot.docs
          .map((doc) => doc.data()['rating'] as int)
          .toList();

      final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;

      // Update content engagement with new rating
      await _firestore
          .collection(AppConstants.contentEngagementCollection)
          .doc(contentId)
          .update({
            'averageRating': averageRating,
            'ratingCount': ratings.length,
            'lastUpdated': FieldValue.serverTimestamp(),
          });

    } catch (e) {
      _logger.e('Error updating content rating: $e');
    }
  }

  /// Add content to reading history
  Future<void> _addToReadingHistory(String contentId, String contentType) async {
    if (_userId == null) return;

    try {
      final favorites = await getUserFavorites();
      if (favorites == null) return;

      List<String> history = List.from(favorites.readingHistory);
      
      // Remove if already exists to move to front
      history.remove(contentId);
      
      // Add to beginning
      history.insert(0, contentId);
      
      // Keep only last 50 items
      if (history.length > 50) {
        history = history.take(50).toList();
      }

      await _firestore
          .collection(AppConstants.userFavoritesCollection)
          .doc(_userId)
          .update({
            'readingHistory': history,
            'updatedAt': FieldValue.serverTimestamp(),
          });

    } catch (e) {
      _logger.e('Error adding to reading history: $e');
    }
  }

  // ===================== HELPER METHODS =====================

  List<String> _calculatePreferredCategories(UserFavorites favorites) {
    // This would be enhanced with actual content category data
    // For now, return user's interests
    return favorites.interests;
  }

  String _calculateEngagementLevel(UserFavorites favorites, int activityCount) {
    final totalFavorites = favorites.favoritePlants.length + favorites.favoriteArticles.length;
    final score = (totalFavorites * 2) + activityCount;

    if (score >= 50) return 'Sangat Aktif';
    if (score >= 20) return 'Aktif';
    if (score >= 10) return 'Sedang';
    return 'Pemula';
  }

  /// Clear user data (for testing or user request)
  Future<void> clearUserEngagementData() async {
    if (_userId == null) return;

    try {
      // Clear user favorites
      await _firestore
          .collection(AppConstants.userFavoritesCollection)
          .doc(_userId)
          .delete();

      // Clear user ratings
      final ratingsSnapshot = await _firestore
          .collection(AppConstants.contentRatingsCollection)
          .where('userId', isEqualTo: _userId)
          .get();

      for (final doc in ratingsSnapshot.docs) {
        await doc.reference.delete();
      }

      _logger.d('Cleared user engagement data');
    } catch (e) {
      _logger.e('Error clearing user engagement data: $e');
    }
  }
}
