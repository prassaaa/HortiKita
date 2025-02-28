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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog Tanaman'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
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
            child: Consumer<PlantProvider>(
              builder: (context, plantProvider, child) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategoryChip('Semua', plantProvider),
                    ..._getCategoriesFromConstants().map((category) {
                      return _buildCategoryChip(category, plantProvider);
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
                    child: CircularProgressIndicator(),
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
                          child: const Text('Coba Lagi'),
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
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            plantProvider.addSamplePlants();
                          },
                          child: const Text('Tambah Data Sampel'),
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
      // Fallback if constants not available
      return ['Sayuran', 'Buah', 'Tanaman Hias', 'Rempah', 'Lainnya'];
    }
  }

  Widget _buildCategoryChip(String category, PlantProvider plantProvider) {
    final isSelected = plantProvider.selectedCategory == category;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            plantProvider.setSelectedCategory(category);
          }
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.green[100],
      ),
    );
  }
}

class PlantSearchDelegate extends SearchDelegate<String> {
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
    
    // Call search in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlantProvider>(context, listen: false).searchPlants(query);
    });
    
    return Consumer<PlantProvider>(
      builder: (context, plantProvider, child) {
        if (plantProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (plantProvider.searchResults.isEmpty) {
          return Center(
            child: Text('Tidak ada hasil untuk "$query"'),
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
        child: Text('Cari tanaman...'),
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