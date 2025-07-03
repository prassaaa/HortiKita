import 'package:cloud_firestore/cloud_firestore.dart';

class ContentRating {
  final String id;
  final String userId;
  final String contentId;
  final String contentType; // 'plant' or 'article'
  final int rating; // 1-5
  final String? comment;
  final int helpfulVotes;
  final List<String> votedBy; // users who voted this review as helpful
  final bool isVerified; // if user actually tried the plant/read article
  final Map<String, dynamic> metadata; // additional context
  final DateTime createdAt;
  final DateTime updatedAt;

  ContentRating({
    required this.id,
    required this.userId,
    required this.contentId,
    required this.contentType,
    required this.rating,
    this.comment,
    required this.helpfulVotes,
    required this.votedBy,
    required this.isVerified,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContentRating.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ContentRating(
      id: doc.id,
      userId: data['userId'] ?? '',
      contentId: data['contentId'] ?? '',
      contentType: data['contentType'] ?? '',
      rating: data['rating'] ?? 1,
      comment: data['comment'],
      helpfulVotes: data['helpfulVotes'] ?? 0,
      votedBy: List<String>.from(data['votedBy'] ?? []),
      isVerified: data['isVerified'] ?? false,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'contentId': contentId,
      'contentType': contentType,
      'rating': rating,
      'comment': comment,
      'helpfulVotes': helpfulVotes,
      'votedBy': votedBy,
      'isVerified': isVerified,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Check if user can vote this review as helpful
  bool canVoteHelpful(String userId) {
    return this.userId != userId && !votedBy.contains(userId);
  }

  // Get quality score based on various factors
  double get qualityScore {
    double score = 0.0;
    
    // Rating contributes 30%
    score += (rating / 5.0) * 0.3;
    
    // Comment length contributes 20%
    if (comment != null && comment!.isNotEmpty) {
      final commentLength = comment!.length;
      final normalizedLength = (commentLength / 200).clamp(0.0, 1.0);
      score += normalizedLength * 0.2;
    }
    
    // Helpful votes contribute 30%
    final normalizedHelpful = (helpfulVotes / 10).clamp(0.0, 1.0);
    score += normalizedHelpful * 0.3;
    
    // Verification contributes 20%
    if (isVerified) {
      score += 0.2;
    }
    
    return score;
  }

  ContentRating copyWith({
    int? rating,
    String? comment,
    int? helpfulVotes,
    List<String>? votedBy,
    bool? isVerified,
    Map<String, dynamic>? metadata,
    DateTime? updatedAt,
  }) {
    return ContentRating(
      id: id,
      userId: userId,
      contentId: contentId,
      contentType: contentType,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      helpfulVotes: helpfulVotes ?? this.helpfulVotes,
      votedBy: votedBy ?? this.votedBy,
      isVerified: isVerified ?? this.isVerified,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
