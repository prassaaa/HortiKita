import 'package:cloud_firestore/cloud_firestore.dart';

class ContentEngagement {
  final String contentId;
  final String contentType; // 'plant' or 'article'
  final int totalViews;
  final int uniqueViews;
  final int favorites;
  final int shares;
  final double averageRating;
  final int ratingCount;
  final int comments;
  final Map<String, int> viewsByDate; // date -> view count
  final Map<String, int> categoryBreakdown;
  final DateTime createdAt;
  final DateTime lastUpdated;

  ContentEngagement({
    required this.contentId,
    required this.contentType,
    required this.totalViews,
    required this.uniqueViews,
    required this.favorites,
    required this.shares,
    required this.averageRating,
    required this.ratingCount,
    required this.comments,
    required this.viewsByDate,
    required this.categoryBreakdown,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory ContentEngagement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ContentEngagement(
      contentId: doc.id,
      contentType: data['contentType'] ?? '',
      totalViews: data['totalViews'] ?? 0,
      uniqueViews: data['uniqueViews'] ?? 0,
      favorites: data['favorites'] ?? 0,
      shares: data['shares'] ?? 0,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      comments: data['comments'] ?? 0,
      viewsByDate: Map<String, int>.from(data['viewsByDate'] ?? {}),
      categoryBreakdown: Map<String, int>.from(data['categoryBreakdown'] ?? {}),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      lastUpdated: data['lastUpdated'] != null 
          ? (data['lastUpdated'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contentType': contentType,
      'totalViews': totalViews,
      'uniqueViews': uniqueViews,
      'favorites': favorites,
      'shares': shares,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      'comments': comments,
      'viewsByDate': viewsByDate,
      'categoryBreakdown': categoryBreakdown,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  // Calculate engagement rate
  double get engagementRate {
    if (totalViews == 0) return 0.0;
    return ((favorites + shares + comments) / totalViews) * 100;
  }

  // Get trending score based on recent activity
  double getTrendingScore() {
    final now = DateTime.now();
    final last7Days = now.subtract(const Duration(days: 7));
    
    int recentViews = 0;
    viewsByDate.forEach((dateStr, views) {
      try {
        final parts = dateStr.split('-');
        final date = DateTime(
          int.parse(parts[0]), 
          int.parse(parts[1]), 
          int.parse(parts[2])
        );
        if (date.isAfter(last7Days)) {
          recentViews += views;
        }
      } catch (e) {
        // Skip invalid date formats
      }
    });

    // Weighted score: recent activity + engagement rate + rating
    return (recentViews * 0.4) + (engagementRate * 0.4) + (averageRating * 0.2);
  }

  ContentEngagement copyWith({
    int? totalViews,
    int? uniqueViews,
    int? favorites,
    int? shares,
    double? averageRating,
    int? ratingCount,
    int? comments,
    Map<String, int>? viewsByDate,
    Map<String, int>? categoryBreakdown,
    DateTime? lastUpdated,
  }) {
    return ContentEngagement(
      contentId: contentId,
      contentType: contentType,
      totalViews: totalViews ?? this.totalViews,
      uniqueViews: uniqueViews ?? this.uniqueViews,
      favorites: favorites ?? this.favorites,
      shares: shares ?? this.shares,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      comments: comments ?? this.comments,
      viewsByDate: viewsByDate ?? this.viewsByDate,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      createdAt: createdAt,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }
}
