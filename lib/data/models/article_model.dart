import 'package:cloud_firestore/cloud_firestore.dart';

class Article {
  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final String authorId;
  final String authorName;
  final String category;
  final List<String> tags;
  final int readTime; // Dalam menit
  final DateTime publishedAt;
  final DateTime updatedAt;

  Article({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.authorId,
    required this.authorName,
    required this.category,
    required this.tags,
    required this.readTime,
    required this.publishedAt,
    required this.updatedAt,
  });

  factory Article.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return Article(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      category: data['category'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      readTime: data['readTime'] ?? 5,
      publishedAt: (data['publishedAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'authorId': authorId,
      'authorName': authorName,
      'category': category,
      'tags': tags,
      'readTime': readTime,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}