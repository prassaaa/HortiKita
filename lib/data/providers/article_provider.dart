import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../repositories/article_repository.dart';

class ArticleProvider with ChangeNotifier {
  final ArticleRepository _articleRepository = ArticleRepository();
  
  List<Article> _articles = [];
  List<Article> _searchResults = [];
  bool _isLoading = false;
  String _error = '';
  String _selectedCategory = 'Semua';
  
  // Getters
  List<Article> get articles => _articles;
  List<Article> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get selectedCategory => _selectedCategory;
  
  // Menyetel kategori yang dipilih
  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
    
    if (category == 'Semua') {
      fetchAllArticles();
    } else {
      fetchArticlesByCategory(category);
    }
  }
  
  // Mendapatkan semua artikel
  Future<void> fetchAllArticles() async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      _articles = await _articleRepository.getAllArticles();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Mendapatkan artikel berdasarkan kategori
  Future<void> fetchArticlesByCategory(String category) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      _articles = await _articleRepository.getArticlesByCategory(category);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Mendapatkan artikel berdasarkan ID
  Future<Article?> fetchArticleById(String articleId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      final article = await _articleRepository.getArticleById(articleId);
      _isLoading = false;
      notifyListeners();
      return article;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  // Mencari artikel
  Future<void> searchArticles(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      _searchResults = await _articleRepository.searchArticles(query);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}