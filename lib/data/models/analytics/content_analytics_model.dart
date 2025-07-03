import 'package:cloud_firestore/cloud_firestore.dart';

// Model untuk Content Performance Analytics
class ContentPerformance {
  final String id;
  final String type; // 'plant' atau 'article'
  final String title;
  final int views;
  final int likes;
  final int shares;
  final double rating;
  final int ratingCount;
  final DateTime lastViewed;
  final Map<String, int> viewsByDate; // date -> view count
  final List<String> topSearchKeywords;

  ContentPerformance({
    required this.id,
    required this.type,
    required this.title,
    required this.views,
    required this.likes,
    required this.shares,
    required this.rating,
    required this.ratingCount,
    required this.lastViewed,
    required this.viewsByDate,
    required this.topSearchKeywords,
  });

  factory ContentPerformance.fromMap(Map<String, dynamic> data) {
    return ContentPerformance(
      id: data['id'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      views: data['views'] ?? 0,
      likes: data['likes'] ?? 0,
      shares: data['shares'] ?? 0,
      rating: data['rating']?.toDouble() ?? 0.0,
      ratingCount: data['ratingCount'] ?? 0,
      lastViewed: data['lastViewed'] is Timestamp 
          ? (data['lastViewed'] as Timestamp).toDate()
          : DateTime.now(),
      viewsByDate: Map<String, int>.from(data['viewsByDate'] ?? {}),
      topSearchKeywords: List<String>.from(data['topSearchKeywords'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'views': views,
      'likes': likes,
      'shares': shares,
      'rating': rating,
      'ratingCount': ratingCount,
      'lastViewed': Timestamp.fromDate(lastViewed),
      'viewsByDate': viewsByDate,
      'topSearchKeywords': topSearchKeywords,
    };
  }

  // Helper untuk trend calculation
  double get engagementRate {
    if (views == 0) return 0.0;
    return ((likes + shares) / views) * 100;
  }

  // Helper untuk weekly growth
  int get viewsThisWeek {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    int weeklyViews = 0;
    
    viewsByDate.forEach((dateStr, viewCount) {
      try {
        final date = DateTime.parse(dateStr);
        if (date.isAfter(weekAgo)) {
          weeklyViews += viewCount;
        }
      } catch (e) {
        // Handle parse error
      }
    });
    
    return weeklyViews;
  }
}

// Model untuk Category Performance
class CategoryPerformance {
  final String category;
  final int totalContent;
  final int totalViews;
  final double avgRating;
  final int totalSearches;
  final List<String> topKeywords;

  CategoryPerformance({
    required this.category,
    required this.totalContent,
    required this.totalViews,
    required this.avgRating,
    required this.totalSearches,
    required this.topKeywords,
  });

  factory CategoryPerformance.fromMap(Map<String, dynamic> data) {
    return CategoryPerformance(
      category: data['category'] ?? '',
      totalContent: data['totalContent'] ?? 0,
      totalViews: data['totalViews'] ?? 0,
      avgRating: data['avgRating']?.toDouble() ?? 0.0,
      totalSearches: data['totalSearches'] ?? 0,
      topKeywords: List<String>.from(data['topKeywords'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'totalContent': totalContent,
      'totalViews': totalViews,
      'avgRating': avgRating,
      'totalSearches': totalSearches,
      'topKeywords': topKeywords,
    };
  }
}

// Model untuk Search Analytics
class SearchAnalytics {
  final String keyword;
  final int searchCount;
  final int resultsFound;
  final double clickThroughRate;
  final DateTime lastSearched;
  final List<String> relatedKeywords;

  SearchAnalytics({
    required this.keyword,
    required this.searchCount,
    required this.resultsFound,
    required this.clickThroughRate,
    required this.lastSearched,
    required this.relatedKeywords,
  });

  factory SearchAnalytics.fromMap(Map<String, dynamic> data) {
    return SearchAnalytics(
      keyword: data['keyword'] ?? '',
      searchCount: data['searchCount'] ?? 0,
      resultsFound: data['resultsFound'] ?? 0,
      clickThroughRate: data['clickThroughRate']?.toDouble() ?? 0.0,
      lastSearched: data['lastSearched'] is Timestamp 
          ? (data['lastSearched'] as Timestamp).toDate()
          : DateTime.now(),
      relatedKeywords: List<String>.from(data['relatedKeywords'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'keyword': keyword,
      'searchCount': searchCount,
      'resultsFound': resultsFound,
      'clickThroughRate': clickThroughRate,
      'lastSearched': Timestamp.fromDate(lastSearched),
      'relatedKeywords': relatedKeywords,
    };
  }
}
