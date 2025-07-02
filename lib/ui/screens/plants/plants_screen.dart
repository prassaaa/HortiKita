import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/constants/app_constants.dart';
import '../../../data/providers/plant_provider.dart';
import '../../widgets/plants/plant_card_widget.dart';
import 'plant_detail_screen.dart';

class PlantsScreen extends StatefulWidget {
  const PlantsScreen({super.key});

  @override
  PlantsScreenState createState() => PlantsScreenState();
}

class PlantsScreenState extends State<PlantsScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  
  // Animation Controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlantProvider>(context, listen: false).fetchAllPlants();
      _fadeController.forward();
    });
  }
  
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // Theme Colors - Modern Design System
  static const Color primaryColor = Color(0xFF2D5A27);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primarySurface = Color(0xFFF1F8E9);
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color dividerColor = Color(0xFFE0E0E0);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 600;
    
    return Scaffold(
      backgroundColor: surfaceColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32.0 : 24.0,
                vertical: 16.0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSearchSection(),
                  const SizedBox(height: 24),
                  _buildCategoryFilter(),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
            _buildPlantsList(isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        title: Text(
          'Katalog Tanaman',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            color: cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        onTap: () {
          showSearch(
            context: context,
            delegate: ModernPlantSearchDelegate(),
          );
        },
        readOnly: true,
        style: TextStyle(
          color: textPrimary,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Cari tanaman hortikultura...',
          hintStyle: TextStyle(
            color: textSecondary,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: textSecondary,
            size: 20,
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.filter_list,
              color: primaryColor,
              size: 16,
            ),
          ),
          filled: true,
          fillColor: surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori Tanaman',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        Consumer<PlantProvider>(
          builder: (context, plantProvider, child) {
            return SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildCategoryChip('Semua', plantProvider),
                  ..._getCategoriesFromConstants().map((category) {
                    return _buildCategoryChip(category, plantProvider);
                  }),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String category, PlantProvider plantProvider) {
    final isSelected = plantProvider.selectedCategory == category;
    
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: FilterChip(
        label: Text(
          category,
          style: TextStyle(
            color: isSelected ? primaryColor : textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            plantProvider.setSelectedCategory(category);
          }
        },
        backgroundColor: cardColor,
        selectedColor: primarySurface,
        showCheckmark: false,
        side: BorderSide(
          color: isSelected ? primaryLight : dividerColor,
          width: isSelected ? 1.5 : 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildPlantsList(bool isTablet) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 32.0 : 24.0),
      sliver: Consumer<PlantProvider>(
        builder: (context, plantProvider, child) {
          if (plantProvider.isLoading) {
            return _buildLoadingState(isTablet);
          }
          
          if (plantProvider.error.isNotEmpty) {
            return _buildErrorState(plantProvider);
          }
          
          if (plantProvider.plants.isEmpty) {
            return _buildEmptyState(plantProvider);
          }
          
          return isTablet
              ? _buildTabletGrid(plantProvider.plants)
              : _buildMobileList(plantProvider.plants);
        },
      ),
    );
  }

  Widget _buildLoadingState(bool isTablet) {
    return isTablet
        ? SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildLoadingCard(),
              childCount: 6,
            ),
          )
        : SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildLoadingCard(),
              childCount: 6,
            ),
          );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 14,
            width: 150,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(PlantProvider plantProvider) {
    return SliverFillRemaining(
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Oops! Terjadi Kesalahan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                plantProvider.error,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  plantProvider.fetchAllPlants();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'Coba Lagi',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(PlantProvider plantProvider) {
    return SliverFillRemaining(
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.eco_outlined,
                size: 64,
                color: textSecondary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Data Tanaman',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Data tanaman hortikultura akan segera tersedia.\nAtau Anda bisa menambah data sampel.',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  plantProvider.addSamplePlants();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'Tambah Data Sampel',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletGrid(List plants) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final plant = plants[index];
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
        childCount: plants.length,
      ),
    );
  }

  Widget _buildMobileList(List plants) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final plant = plants[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: PlantCard(
              plant: plant,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlantDetailScreen(plant: plant),
                  ),
                );
              },
            ),
          );
        },
        childCount: plants.length,
      ),
    );
  }

  List<String> _getCategoriesFromConstants() {
    try {
      return AppConstants.plantCategories;
    } catch (e) {
      return ['Sayuran', 'Buah', 'Tanaman Hias', 'Rempah', 'Lainnya'];
    }
  }
}

class ModernPlantSearchDelegate extends SearchDelegate<String> {
  // Theme Colors
  static const Color primaryColor = Color(0xFF2D5A27);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primarySurface = Color(0xFFF1F8E9);
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF6B6B6B);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: textSecondary),
        border: InputBorder.none,
      ),
    );
  }

  @override
  String get searchFieldLabel => 'Cari tanaman...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear, color: textSecondary),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: textPrimary),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.length < 2) {
      return _buildMinimumCharacterMessage();
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlantProvider>(context, listen: false).searchPlants(query);
    });
    
    return Container(
      color: surfaceColor,
      child: Consumer<PlantProvider>(
        builder: (context, plantProvider, child) {
          if (plantProvider.isLoading) {
            return _buildSearchLoading();
          }
          
          if (plantProvider.searchResults.isEmpty) {
            return _buildNoResults();
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plantProvider.searchResults.length,
            itemBuilder: (context, index) {
              final plant = plantProvider.searchResults[index];
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: PlantCard(
                  plant: plant,
                  onTap: () {
                    close(context, plant.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlantDetailScreen(plant: plant),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildSearchPlaceholder();
    }
    
    if (query.length < 2) {
      return _buildMinimumCharacterMessage();
    }
    
    return buildResults(context);
  }

  Widget _buildSearchPlaceholder() {
    return Container(
      color: surfaceColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco,
              size: 64,
              color: textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Cari Tanaman Hortikultura',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Temukan informasi tentang berbagai tanaman',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimumCharacterMessage() {
    return Container(
      color: surfaceColor,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit,
                size: 48,
                color: primaryLight,
              ),
              const SizedBox(height: 16),
              Text(
                'Masukkan minimal 2 karakter',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ketik lebih banyak untuk hasil pencarian yang lebih baik',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchLoading() {
    return Container(
      color: surfaceColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryLight),
            const SizedBox(height: 16),
            Text(
              'Mencari tanaman...',
              style: TextStyle(
                fontSize: 16,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Container(
      color: surfaceColor,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: textSecondary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak ada hasil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tidak ada tanaman yang cocok dengan "$query"',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Coba kata kunci lain atau kategori yang berbeda',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}