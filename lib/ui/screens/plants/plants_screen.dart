import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/constants/app_constants.dart';
import '../../../data/providers/plant_provider.dart';
import '../../widgets/plants/plant_card_widget.dart';
import 'plant_detail_screen.dart';

class PlantsScreen extends StatefulWidget {
  const PlantsScreen({Key? key}) : super(key: key);

  @override
  _PlantsScreenState createState() => _PlantsScreenState();
}

class _PlantsScreenState extends State<PlantsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlantProvider>(context, listen: false).fetchAllPlants();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Definisi warna tema yang sama
    const Color primaryGreen = Color(0xFF4CAF50);
    const Color lightGreen = Color(0xFFE8F5E9);
    const Color whiteColor = Colors.white; // Mengganti 'white' menjadi 'whiteColor' untuk menghindari konflik

    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: whiteColor,
        title: const Text(
          'Katalog Tanaman',
          style: TextStyle(
            color: primaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: primaryGreen),
            onPressed: () {
              showSearch(
                context: context,
                delegate: PlantSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: whiteColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Consumer<PlantProvider>(
              builder: (context, plantProvider, child) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategoryChip('Semua', plantProvider, primaryGreen, lightGreen, whiteColor),
                    ..._getCategoriesFromConstants().map((category) {
                      return _buildCategoryChip(category, plantProvider, primaryGreen, lightGreen, whiteColor);
                    }).toList(),
                  ],
                );
              },
            ),
          ),
          
          // Plant List
          Expanded(
            child: Consumer<PlantProvider>(
              builder: (context, plantProvider, child) {
                if (plantProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                    ),
                  );
                }
                
                if (plantProvider.error.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error: ${plantProvider.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            plantProvider.fetchAllPlants();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Coba Lagi',
                            style: TextStyle(color: whiteColor),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                if (plantProvider.plants.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Tidak ada data tanaman tersedia',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF558B2F),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            plantProvider.addSamplePlants();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Tambah Data Sampel',
                            style: TextStyle(color: whiteColor),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: plantProvider.plants.length,
                  itemBuilder: (context, index) {
                    final plant = plantProvider.plants[index];
                    
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
      return AppConstants.plantCategories;
    } catch (e) {
      return ['Sayuran', 'Buah', 'Tanaman Hias', 'Rempah', 'Lainnya'];
    }
  }

  Widget _buildCategoryChip(
    String category,
    PlantProvider plantProvider,
    Color primaryGreen,
    Color lightGreen,
    Color whiteColor,
  ) {
    final isSelected = plantProvider.selectedCategory == category;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          category,
          style: TextStyle(
            color: isSelected ? whiteColor : primaryGreen,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            plantProvider.setSelectedCategory(category);
          }
        },
        backgroundColor: lightGreen,
        selectedColor: primaryGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: isSelected ? 2 : 0,
        shadowColor: Colors.grey.withOpacity(0.3),
      ),
    );
  }
}

class PlantSearchDelegate extends SearchDelegate<String> {
  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Color(0xFF4CAF50),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Color(0xFF4CAF50)),
      ),
      textTheme: Theme.of(context).textTheme,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFE8F5E9),
        hintStyle: const TextStyle(color: Color(0xFF558B2F)),
      ),
    );
  }

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
        child: Text(
          'Masukkan minimal 2 karakter untuk mencari',
          style: TextStyle(color: Color(0xFF558B2F)),
        ),
      );
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlantProvider>(context, listen: false).searchPlants(query);
    });
    
    return Consumer<PlantProvider>(
      builder: (context, plantProvider, child) {
        if (plantProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          );
        }
        
        if (plantProvider.searchResults.isEmpty) {
          return Center(
            child: Text(
              'Tidak ada hasil untuk "$query"',
              style: const TextStyle(color: Color(0xFF558B2F)),
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: plantProvider.searchResults.length,
          itemBuilder: (context, index) {
            final plant = plantProvider.searchResults[index];
            
            return PlantCard(
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
        child: Text(
          'Cari tanaman...',
          style: TextStyle(color: Color(0xFF558B2F)),
        ),
      );
    }
    
    if (query.length < 2) {
      return const Center(
        child: Text(
          'Masukkan minimal 2 karakter untuk mencari',
          style: TextStyle(color: Color(0xFF558B2F)),
        ),
      );
    }
    
    return buildResults(context);
  }
}