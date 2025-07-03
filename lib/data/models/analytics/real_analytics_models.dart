import 'package:cloud_firestore/cloud_firestore.dart';

// Real Analytics Data Models
class UserSession {
  final String id;
  final String userId;
  final String screen;
  final DateTime startTime;
  final DateTime? endTime;
  final int duration; // in seconds
  final Map<String, dynamic> metadata;

  UserSession({
    required this.id,
    required this.userId,
    required this.screen,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.metadata,
  });

  factory UserSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserSession(
      id: doc.id,
      userId: data['userId'] ?? '',
      screen: data['screen'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null ? (data['endTime'] as Timestamp).toDate() : null,
      duration: data['duration'] ?? 0,
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'screen': screen,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'duration': duration,
      'metadata': metadata,
    };
  }
}

class ContentInteraction {
  final String id;
  final String userId;
  final String contentId;
  final String contentType; // 'plant' or 'article'
  final String action; // 'view', 'favorite', 'share'
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  ContentInteraction({
    required this.id,
    required this.userId,
    required this.contentId,
    required this.contentType,
    required this.action,
    required this.timestamp,
    required this.metadata,
  });

  factory ContentInteraction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContentInteraction(
      id: doc.id,
      userId: data['userId'] ?? '',
      contentId: data['contentId'] ?? '',
      contentType: data['contentType'] ?? '',
      action: data['action'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'contentId': contentId,
      'contentType': contentType,
      'action': action,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }
}

class ChatbotInteraction {
  final String id;
  final String userId;
  final String sessionId;
  final String question;
  final String response;
  final DateTime timestamp;
  final int? satisfaction; // 1-5 rating
  final List<String> topics;

  ChatbotInteraction({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.question,
    required this.response,
    required this.timestamp,
    this.satisfaction,
    required this.topics,
  });

  factory ChatbotInteraction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatbotInteraction(
      id: doc.id,
      userId: data['userId'] ?? '',
      sessionId: data['sessionId'] ?? '',
      question: data['question'] ?? '',
      response: data['response'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      satisfaction: data['satisfaction'],
      topics: List<String>.from(data['topics'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'sessionId': sessionId,
      'question': question,
      'response': response,
      'timestamp': Timestamp.fromDate(timestamp),
      'satisfaction': satisfaction,
      'topics': topics,
    };
  }
}

class SearchQuery {
  final String id;
  final String userId;
  final String query;
  final String screen;
  final int resultsCount;
  final DateTime timestamp;
  final bool hasClickthrough;

  SearchQuery({
    required this.id,
    required this.userId,
    required this.query,
    required this.screen,
    required this.resultsCount,
    required this.timestamp,
    required this.hasClickthrough,
  });

  factory SearchQuery.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SearchQuery(
      id: doc.id,
      userId: data['userId'] ?? '',
      query: data['query'] ?? '',
      screen: data['screen'] ?? '',
      resultsCount: data['resultsCount'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      hasClickthrough: data['hasClickthrough'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'query': query,
      'screen': screen,
      'resultsCount': resultsCount,
      'timestamp': Timestamp.fromDate(timestamp),
      'hasClickthrough': hasClickthrough,
    };
  }
}
