import 'package:cloud_firestore/cloud_firestore.dart';

class UserFavorites {
  final String userId;
  final List<String> favoritePlants;
  final List<String> favoriteArticles;
  final List<String> readingHistory;
  final List<String> searchHistory;
  final Map<String, dynamic> plantingExperience;
  final List<String> interests;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserFavorites({
    required this.userId,
    required this.favoritePlants,
    required this.favoriteArticles,
    required this.readingHistory,
    required this.searchHistory,
    required this.plantingExperience,
    required this.interests,
    required this.preferences,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserFavorites.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserFavorites(
      userId: doc.id,
      favoritePlants: List<String>.from(data['favoritePlants'] ?? []),
      favoriteArticles: List<String>.from(data['favoriteArticles'] ?? []),
      readingHistory: List<String>.from(data['readingHistory'] ?? []),
      searchHistory: List<String>.from(data['searchHistory'] ?? []),
      plantingExperience: Map<String, dynamic>.from(data['plantingExperience'] ?? {}),
      interests: List<String>.from(data['interests'] ?? []),
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
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
      'favoritePlants': favoritePlants,
      'favoriteArticles': favoriteArticles,
      'readingHistory': readingHistory,
      'searchHistory': searchHistory,
      'plantingExperience': plantingExperience,
      'interests': interests,
      'preferences': preferences,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Helper methods
  bool isFavoritePlant(String plantId) => favoritePlants.contains(plantId);
  bool isFavoriteArticle(String articleId) => favoriteArticles.contains(articleId);
  
  UserFavorites copyWith({
    List<String>? favoritePlants,
    List<String>? favoriteArticles,
    List<String>? readingHistory,
    List<String>? searchHistory,
    Map<String, dynamic>? plantingExperience,
    List<String>? interests,
    Map<String, dynamic>? preferences,
    DateTime? updatedAt,
  }) {
    return UserFavorites(
      userId: userId,
      favoritePlants: favoritePlants ?? this.favoritePlants,
      favoriteArticles: favoriteArticles ?? this.favoriteArticles,
      readingHistory: readingHistory ?? this.readingHistory,
      searchHistory: searchHistory ?? this.searchHistory,
      plantingExperience: plantingExperience ?? this.plantingExperience,
      interests: interests ?? this.interests,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
