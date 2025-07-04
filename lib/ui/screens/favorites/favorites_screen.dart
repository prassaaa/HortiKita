import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../../../data/providers/user_engagement_provider.dart';
import '../../../data/models/plant_model.dart';
import '../../../data/models/article_model.dart';
import '../../widgets/plants/plant_card_widget.dart';
import '../../widgets/articles/article_card_widget.dart';
import '../plants/plant_detail_screen.dart';
import '../articles/article_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> 
    with TickerProviderStateMixin {
  final Logger _logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late TabController _tabController;
  
  // Content data
  List<Plant> _favoritePlants = [];
  List<Article> _favoriteArticles = [];
  bool _isLoadingPlants = false;
  bool _isLoadingArticles = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Defer loading until after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavoriteContent();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadFavoriteContent() async {
    final engagementProvider = Provider.of<UserEngagementProvider>(
      context, 
      listen: false
    );
    
    await engagementProvider.loadUserFavorites();
    
    if (engagementProvider.userFavorites != null) {
      _loadFavoritePlants(engagementProvider.userFavorites!.favoritePlants);
      _loadFavoriteArticles(engagementProvider.userFavorites!.favoriteArticles);
    }
  }

  void _loadFavoritePlants(List<String> plantIds) async {
    if (plantIds.isEmpty) {
      setState(() {
        _favoritePlants = [];
        _isLoadingPlants = false;
      });
      return;
    }

    setState(() {
      _isLoadingPlants = true;
    });

    try {
      final List<Plant> plants = [];
      
      // Load plants in batches (Firestore 'in' query limit is 10)
      for (int i = 0; i < plantIds.length; i += 10) {
        final batch = plantIds.skip(i).take(10).toList();
        
        final snapshot = await _firestore
            .collection('plants')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in snapshot.docs) {
          try {
            plants.add(Plant.fromFirestore(doc));
          } catch (e) {
            _logger.e('Error parsing plant ${doc.id}: $e');
          }
        }
      }

      setState(() {
        _favoritePlants = plants;
        _isLoadingPlants = false;
      });
    } catch (e) {
      _logger.e('Error loading favorite plants: $e');
      setState(() {
        _isLoadingPlants = false;
      });
    }
  }

  void _loadFavoriteArticles(List<String> articleIds) async {
    if (articleIds.isEmpty) {
      setState(() {
        _favoriteArticles = [];
        _isLoadingArticles = false;
      });
      return;
    }

    setState(() {
      _isLoadingArticles = true;
    });

    try {
      final List<Article> articles = [];
      
      // Load articles in batches
      for (int i = 0; i < articleIds.length; i += 10) {
        final batch = articleIds.skip(i).take(10).toList();
        
        final snapshot = await _firestore
            .collection('articles')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in snapshot.docs) {
          try {
            articles.add(Article.fromFirestore(doc));
          } catch (e) {
            _logger.e('Error parsing article ${doc.id}: $e');
          }
        }
      }

      setState(() {
        _favoriteArticles = articles;
        _isLoadingArticles = false;
      });
    } catch (e) {
      _logger.e('Error loading favorite articles: $e');
      setState(() {
        _isLoadingArticles = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text(
          'Koleksi Favorit',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(Icons.local_florist),
              text: 'Tanaman',
            ),
            Tab(
              icon: Icon(Icons.article),
              text: 'Artikel',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlantsTab(),
          _buildArticlesTab(),
        ],
      ),
    );
  }

  Widget _buildPlantsTab() {
    return Consumer<UserEngagementProvider>(
      builder: (context, engagementProvider, child) {
        if (engagementProvider.isLoading || _isLoadingPlants) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2E7D32),
            ),
          );
        }

        if (_favoritePlants.isEmpty) {
          return _buildEmptyState(
            icon: Icons.local_florist_outlined,
            title: 'Belum Ada Tanaman Favorit',
            subtitle: 'Tandai tanaman sebagai favorit untuk melihatnya di sini',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await engagementProvider.refreshData();
            _loadFavoriteContent();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.65, // Reduced to give more height
              ),
              itemCount: _favoritePlants.length,
              itemBuilder: (context, index) {
                final plant = _favoritePlants[index];
                return PlantCard(
                  plant: plant,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlantDetailScreen(plant: plant),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildArticlesTab() {
    return Consumer<UserEngagementProvider>(
      builder: (context, engagementProvider, child) {
        if (engagementProvider.isLoading || _isLoadingArticles) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2E7D32),
            ),
          );
        }

        if (_favoriteArticles.isEmpty) {
          return _buildEmptyState(
            icon: Icons.article_outlined,
            title: 'Belum Ada Artikel Favorit',
            subtitle: 'Tandai artikel sebagai favorit untuk melihatnya di sini',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await engagementProvider.refreshData();
            _loadFavoriteContent();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView.builder(
              itemCount: _favoriteArticles.length,
              itemBuilder: (context, index) {
                final article = _favoriteArticles[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ArticleCard(
                    article: article,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticleDetailScreen(article: article),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.explore),
              label: const Text('Jelajahi Konten'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
