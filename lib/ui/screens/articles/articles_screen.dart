import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/constants/app_constants.dart';
import '../../../data/providers/article_provider.dart';
import '../../widgets/articles/article_card_widget.dart';
import 'article_detail_screen.dart';

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key});

  @override
  ArticlesScreenState createState() => ArticlesScreenState();
}

class ArticlesScreenState extends State<ArticlesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ArticleProvider>(context, listen: false).fetchAllArticles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artikel Hortikultura'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ArticleSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Consumer<ArticleProvider>(
              builder: (context, articleProvider, child) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategoryChip('Semua', articleProvider),
                    ..._getCategoriesFromConstants().map((category) {
                      return _buildCategoryChip(category, articleProvider);
                    }),
                  ],
                );
              },
            ),
          ),
          
          // Articles list
          Expanded(
            child: Consumer<ArticleProvider>(
              builder: (context, articleProvider, child) {
                if (articleProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (articleProvider.error.isNotEmpty) {
                  return Center(
                    child: Text(
                      'Error: ${articleProvider.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                
                if (articleProvider.articles.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada artikel yang tersedia'),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: articleProvider.articles.length,
                  itemBuilder: (context, index) {
                    final article = articleProvider.articles[index];
                    
                    return ArticleCard(
                      article: article,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ArticleDetailScreen(articleId: article.id),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getCategoriesFromConstants() {
    try {
      return AppConstants.articleCategories;
    } catch (e) {
      // Fallback jika konstanta tidak tersedia
      return ['Sayuran', 'Buah', 'Tanaman Hias', 'Rempah', 'Tips & Trik'];
    }
  }

  Widget _buildCategoryChip(String category, ArticleProvider articleProvider) {
    final isSelected = articleProvider.selectedCategory == category;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            articleProvider.setSelectedCategory(category);
          }
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.green[100],
      ),
    );
  }
}

class ArticleSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.length < 2) {
      return const Center(
        child: Text('Masukkan minimal 2 karakter untuk mencari'),
      );
    }
    
    // Panggil search di provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ArticleProvider>(context, listen: false).searchArticles(query);
    });
    
    return Consumer<ArticleProvider>(
      builder: (context, articleProvider, child) {
        if (articleProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (articleProvider.searchResults.isEmpty) {
          return Center(
            child: Text('Tidak ada hasil untuk "$query"'),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: articleProvider.searchResults.length,
          itemBuilder: (context, index) {
            final article = articleProvider.searchResults[index];
            
            return ArticleCard(
              article: article,
              onTap: () {
                close(context, article.id);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArticleDetailScreen(articleId: article.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('Cari artikel hortikultura...'),
      );
    }
    
    if (query.length < 2) {
      return const Center(
        child: Text('Masukkan minimal 2 karakter untuk mencari'),
      );
    }
    
    // Show instant results for suggestions too
    return buildResults(context);
  }
}