import 'package:cloud_firestore/cloud_firestore.dart';

// Model untuk Chatbot Analytics
class ChatbotAnalytics {
  final int totalConversations;
  final int totalMessages;
  final double avgConversationLength;
  final double avgResponseTime;
  final double userSatisfactionScore;
  final int totalUsers;
  final DateTime lastUpdated;
  final Map<String, int> topQuestions;
  final Map<String, int> topTopics;
  final Map<String, int> hourlyUsage;
  final List<ContentGap> contentGaps;

  ChatbotAnalytics({
    required this.totalConversations,
    required this.totalMessages,
    required this.avgConversationLength,
    required this.avgResponseTime,
    required this.userSatisfactionScore,
    required this.totalUsers,
    required this.lastUpdated,
    required this.topQuestions,
    required this.topTopics,
    required this.hourlyUsage,
    required this.contentGaps,
  });

  factory ChatbotAnalytics.fromMap(Map<String, dynamic> data) {
    List<ContentGap> gaps = [];
    if (data['contentGaps'] != null) {
      gaps = (data['contentGaps'] as List)
          .map((gap) => ContentGap.fromMap(gap))
          .toList();
    }

    return ChatbotAnalytics(
      totalConversations: data['totalConversations'] ?? 0,
      totalMessages: data['totalMessages'] ?? 0,
      avgConversationLength: data['avgConversationLength']?.toDouble() ?? 0.0,
      avgResponseTime: data['avgResponseTime']?.toDouble() ?? 0.0,
      userSatisfactionScore: data['userSatisfactionScore']?.toDouble() ?? 0.0,
      totalUsers: data['totalUsers'] ?? 0,
      lastUpdated: data['lastUpdated'] is Timestamp 
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
      topQuestions: Map<String, int>.from(data['topQuestions'] ?? {}),
      topTopics: Map<String, int>.from(data['topTopics'] ?? {}),
      hourlyUsage: Map<String, int>.from(data['hourlyUsage'] ?? {}),
      contentGaps: gaps,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalConversations': totalConversations,
      'totalMessages': totalMessages,
      'avgConversationLength': avgConversationLength,
      'avgResponseTime': avgResponseTime,
      'userSatisfactionScore': userSatisfactionScore,
      'totalUsers': totalUsers,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'topQuestions': topQuestions,
      'topTopics': topTopics,
      'hourlyUsage': hourlyUsage,
      'contentGaps': contentGaps.map((gap) => gap.toMap()).toList(),
    };
  }
}

// Model untuk Content Gap Analysis
class ContentGap {
  final String topic;
  final int questionCount;
  final double priority; // 1-10, 10 = highest priority
  final String suggestedAction;
  final List<String> relatedQuestions;
  final DateTime lastDetected;

  ContentGap({
    required this.topic,
    required this.questionCount,
    required this.priority,
    required this.suggestedAction,
    required this.relatedQuestions,
    required this.lastDetected,
  });

  factory ContentGap.fromMap(Map<String, dynamic> data) {
    return ContentGap(
      topic: data['topic'] ?? '',
      questionCount: data['questionCount'] ?? 0,
      priority: data['priority']?.toDouble() ?? 1.0,
      suggestedAction: data['suggestedAction'] ?? '',
      relatedQuestions: List<String>.from(data['relatedQuestions'] ?? []),
      lastDetected: data['lastDetected'] is Timestamp 
          ? (data['lastDetected'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'topic': topic,
      'questionCount': questionCount,
      'priority': priority,
      'suggestedAction': suggestedAction,
      'relatedQuestions': relatedQuestions,
      'lastDetected': Timestamp.fromDate(lastDetected),
    };
  }

  // Helper untuk priority color
  String get priorityLevel {
    if (priority >= 8) return 'high';
    if (priority >= 5) return 'medium';
    return 'low';
  }
}

// Model untuk Question Analysis
class QuestionAnalysis {
  final String question;
  final int askCount;
  final double avgResponseQuality;
  final bool hasRelatedContent;
  final String category;
  final DateTime firstAsked;
  final DateTime lastAsked;
  final List<String> variations;

  QuestionAnalysis({
    required this.question,
    required this.askCount,
    required this.avgResponseQuality,
    required this.hasRelatedContent,
    required this.category,
    required this.firstAsked,
    required this.lastAsked,
    required this.variations,
  });

  factory QuestionAnalysis.fromMap(Map<String, dynamic> data) {
    return QuestionAnalysis(
      question: data['question'] ?? '',
      askCount: data['askCount'] ?? 0,
      avgResponseQuality: data['avgResponseQuality']?.toDouble() ?? 0.0,
      hasRelatedContent: data['hasRelatedContent'] ?? false,
      category: data['category'] ?? '',
      firstAsked: data['firstAsked'] is Timestamp 
          ? (data['firstAsked'] as Timestamp).toDate()
          : DateTime.now(),
      lastAsked: data['lastAsked'] is Timestamp 
          ? (data['lastAsked'] as Timestamp).toDate()
          : DateTime.now(),
      variations: List<String>.from(data['variations'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'askCount': askCount,
      'avgResponseQuality': avgResponseQuality,
      'hasRelatedContent': hasRelatedContent,
      'category': category,
      'firstAsked': Timestamp.fromDate(firstAsked),
      'lastAsked': Timestamp.fromDate(lastAsked),
      'variations': variations,
    };
  }

  // Helper untuk trend analysis
  bool get isTrending {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return lastAsked.isAfter(weekAgo) && askCount >= 5;
  }
}

// Model untuk Topic Trends
class TopicTrend {
  final String topic;
  final List<TrendPoint> trendData;
  final double growthRate;
  final String trendDirection; // 'up', 'down', 'stable'

  TopicTrend({
    required this.topic,
    required this.trendData,
    required this.growthRate,
    required this.trendDirection,
  });

  factory TopicTrend.fromMap(Map<String, dynamic> data) {
    List<TrendPoint> trends = [];
    if (data['trendData'] != null) {
      trends = (data['trendData'] as List)
          .map((point) => TrendPoint.fromMap(point))
          .toList();
    }

    return TopicTrend(
      topic: data['topic'] ?? '',
      trendData: trends,
      growthRate: data['growthRate']?.toDouble() ?? 0.0,
      trendDirection: data['trendDirection'] ?? 'stable',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'topic': topic,
      'trendData': trendData.map((point) => point.toMap()).toList(),
      'growthRate': growthRate,
      'trendDirection': trendDirection,
    };
  }
}

class TrendPoint {
  final String date;
  final int count;

  TrendPoint({
    required this.date,
    required this.count,
  });

  factory TrendPoint.fromMap(Map<String, dynamic> data) {
    return TrendPoint(
      date: data['date'] ?? '',
      count: data['count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'count': count,
    };
  }
}
