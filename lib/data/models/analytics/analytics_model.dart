import 'package:cloud_firestore/cloud_firestore.dart';

// Model untuk Overall Analytics
class AnalyticsOverview {
  final int totalUsers;
  final int totalPlants;
  final int totalArticles;
  final int totalConversations;
  final int activeUsersToday;
  final int activeUsersWeek;
  final int activeUsersMonth;
  final double avgSessionDuration;
  final DateTime lastUpdated;

  AnalyticsOverview({
    required this.totalUsers,
    required this.totalPlants,
    required this.totalArticles,
    required this.totalConversations,
    required this.activeUsersToday,
    required this.activeUsersWeek,
    required this.activeUsersMonth,
    required this.avgSessionDuration,
    required this.lastUpdated,
  });

  factory AnalyticsOverview.fromMap(Map<String, dynamic> data) {
    return AnalyticsOverview(
      totalUsers: data['totalUsers'] ?? 0,
      totalPlants: data['totalPlants'] ?? 0,
      totalArticles: data['totalArticles'] ?? 0,
      totalConversations: data['totalConversations'] ?? 0,
      activeUsersToday: data['activeUsersToday'] ?? 0,
      activeUsersWeek: data['activeUsersWeek'] ?? 0,
      activeUsersMonth: data['activeUsersMonth'] ?? 0,
      avgSessionDuration: data['avgSessionDuration']?.toDouble() ?? 0.0,
      lastUpdated: data['lastUpdated'] is Timestamp 
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalUsers': totalUsers,
      'totalPlants': totalPlants,
      'totalArticles': totalArticles,
      'totalConversations': totalConversations,
      'activeUsersToday': activeUsersToday,
      'activeUsersWeek': activeUsersWeek,
      'activeUsersMonth': activeUsersMonth,
      'avgSessionDuration': avgSessionDuration,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}

// Model untuk User Activity Data
class UserActivityData {
  final String date;
  final int activeUsers;
  final int newUsers;
  final int totalSessions;
  final double avgSessionDuration;

  UserActivityData({
    required this.date,
    required this.activeUsers,
    required this.newUsers,
    required this.totalSessions,
    required this.avgSessionDuration,
  });

  factory UserActivityData.fromMap(Map<String, dynamic> data) {
    return UserActivityData(
      date: data['date'] ?? '',
      activeUsers: data['activeUsers'] ?? 0,
      newUsers: data['newUsers'] ?? 0,
      totalSessions: data['totalSessions'] ?? 0,
      avgSessionDuration: data['avgSessionDuration']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'activeUsers': activeUsers,
      'newUsers': newUsers,
      'totalSessions': totalSessions,
      'avgSessionDuration': avgSessionDuration,
    };
  }
}

// Model untuk Growth Data
class GrowthData {
  final String period; // 'daily', 'weekly', 'monthly'
  final String date;
  final int users;
  final int articles;
  final int plants;
  final int conversations;

  GrowthData({
    required this.period,
    required this.date,
    required this.users,
    required this.articles,
    required this.plants,
    required this.conversations,
  });

  factory GrowthData.fromMap(Map<String, dynamic> data) {
    return GrowthData(
      period: data['period'] ?? 'daily',
      date: data['date'] ?? '',
      users: data['users'] ?? 0,
      articles: data['articles'] ?? 0,
      plants: data['plants'] ?? 0,
      conversations: data['conversations'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'period': period,
      'date': date,
      'users': users,
      'articles': articles,
      'plants': plants,
      'conversations': conversations,
    };
  }
}
