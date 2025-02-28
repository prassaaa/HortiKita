import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/article_model.dart';

class ArticleRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Mendapatkan semua artikel
  Future<List<Article>> getAllArticles() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('articles')
          .orderBy('publishedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Article.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to load articles: $e');
    }
  }
  
  // Mendapatkan artikel berdasarkan kategori
  Future<List<Article>> getArticlesByCategory(String category) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('articles')
          .where('category', isEqualTo: category)
          .orderBy('publishedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Article.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to load articles by category: $e');
    }
  }
  
  // Mendapatkan artikel berdasarkan ID
  Future<Article> getArticleById(String articleId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('articles')
          .doc(articleId)
          .get();
      
      if (!doc.exists) {
        throw Exception('Article not found');
      }
      
      return Article.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to load article: $e');
    }
  }
  
  // Mencari artikel
  Future<List<Article>> searchArticles(String query) async {
    try {
      // Firebase tidak mendukung full-text search, jadi kita gunakan filter client-side
      final QuerySnapshot snapshot = await _firestore
          .collection('articles')
          .orderBy('publishedAt', descending: true)
          .get();

      final List<Article> articles = snapshot.docs
          .map((doc) => Article.fromFirestore(doc))
          .toList();
      
      // Filter di client
      return articles.where((article) {
        final titleLower = article.title.toLowerCase();
        final contentLower = article.content.toLowerCase();
        final queryLower = query.toLowerCase();
        
        return titleLower.contains(queryLower) ||
               contentLower.contains(queryLower);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search articles: $e');
    }
  }
}