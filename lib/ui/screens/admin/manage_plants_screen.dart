import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/plant_provider.dart';
import '../../../data/models/plant_model.dart';
import 'edit_plant_screen.dart';

class ManagePlantsScreen extends StatefulWidget {
  const ManagePlantsScreen({super.key});

  @override
  ManagePlantsScreenState createState() => ManagePlantsScreenState();
}

class ManagePlantsScreenState extends State<ManagePlantsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlantProvider>(context, listen: false).fetchAllPlants();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kelola Tanaman',
          style: TextStyle(
            color: Color(0xFF4CAF50),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF4CAF50)),
      ),
      body: Consumer<PlantProvider>(
        builder: (context, plantProvider, child) {
          if (plantProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
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
                      backgroundColor: const Color(0xFF4CAF50),
                    ),
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
                      backgroundColor: const Color(0xFF4CAF50),
                    ),
                    child: const Text('Tambah Data Sampel'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: plantProvider.plants.length,
            itemBuilder: (context, index) {
              final plant = plantProvider.plants[index];
              return _buildPlantListItem(context, plant);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditPlantScreen(isEditing: false),
            ),
          );
          
          // Refresh data jika berhasil menambahkan tanaman
          if (result == true) {
            if (!mounted) return;
            Provider.of<PlantProvider>(context, listen: false).fetchAllPlants();
          }
        },
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPlantListItem(BuildContext context, Plant plant) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundImage: NetworkImage(plant.imageUrl),
          radius: 25,
          backgroundColor: const Color(0xFFE8F5E9),
          onBackgroundImageError: (_, __) {
            // Handle error
          },
          child: plant.imageUrl.isEmpty
              ? const Icon(
                  Icons.eco,
                  color: Color(0xFF4CAF50),
                )
              : null,
        ),
        title: Text(
          plant.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plant.scientificName),
            Text('Kategori: ${plant.category}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.edit,
                color: Color(0xFF4CAF50),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditPlantScreen(
                      isEditing: true,
                      plant: plant,
                    ),
                  ),
                );
                
                // Refresh data jika ada perubahan
                if (result == true) {
                  if (!mounted) return;
                  Provider.of<PlantProvider>(context, listen: false).fetchAllPlants();
                }
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              onPressed: () {
                _showDeleteConfirmation(context, plant);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Plant plant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus tanaman "${plant.name}"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Tutup dialog
                Navigator.pop(context);
                
                // Tampilkan loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Menghapus tanaman...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                
                // Hapus tanaman
                await Provider.of<PlantProvider>(context, listen: false)
                  .deletePlant(plant.id);
                  
                // Tampilkan notifikasi sukses
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tanaman berhasil dihapus'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              } catch (e) {
                // Tampilkan error
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}