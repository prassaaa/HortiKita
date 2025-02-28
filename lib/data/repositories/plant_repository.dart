import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plant_model.dart';

class PlantRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Mendapatkan semua tanaman
  Future<List<Plant>> getAllPlants() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('plants')
          .orderBy('name')
          .get();

      if (snapshot.docs.isEmpty) {
        return []; // Return empty list if no documents exist
      }

      List<Plant> plants = [];
      
      for (var doc in snapshot.docs) {
        try {
          Plant plant = Plant.fromFirestore(doc);
          plants.add(plant);
        } catch (e) {
          print('Error parsing document ${doc.id}: $e');
          // Skip invalid documents instead of crashing
        }
      }
      
      return plants;
    } catch (e) {
      print('Error in getAllPlants: $e');
      throw Exception('Failed to load plants: $e');
    }
  }
  
  // Mendapatkan tanaman berdasarkan kategori
  Future<List<Plant>> getPlantsByCategory(String category) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('plants')
          .where('category', isEqualTo: category)
          .orderBy('name')
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      List<Plant> plants = [];
      
      for (var doc in snapshot.docs) {
        try {
          Plant plant = Plant.fromFirestore(doc);
          plants.add(plant);
        } catch (e) {
          print('Error parsing document ${doc.id}: $e');
        }
      }
      
      return plants;
    } catch (e) {
      print('Error in getPlantsByCategory: $e');
      throw Exception('Failed to load plants by category: $e');
    }
  }
  
  // Mendapatkan tanaman berdasarkan ID
  Future<Plant> getPlantById(String plantId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('plants')
          .doc(plantId)
          .get();
      
      if (!doc.exists) {
        throw Exception('Plant not found');
      }
      
      return Plant.fromFirestore(doc);
    } catch (e) {
      print('Error in getPlantById: $e');
      throw Exception('Failed to load plant: $e');
    }
  }
  
  // Mencari tanaman
  Future<List<Plant>> searchPlants(String query) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('plants')
          .orderBy('name')
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      List<Plant> allPlants = [];
      
      for (var doc in snapshot.docs) {
        try {
          Plant plant = Plant.fromFirestore(doc);
          allPlants.add(plant);
        } catch (e) {
          print('Error parsing document ${doc.id}: $e');
        }
      }
      
      // Filter di client
      return allPlants.where((plant) {
        final nameLower = plant.name.toLowerCase();
        final scientificNameLower = plant.scientificName.toLowerCase();
        final descriptionLower = plant.description.toLowerCase();
        final queryLower = query.toLowerCase();
        
        return nameLower.contains(queryLower) ||
               scientificNameLower.contains(queryLower) ||
               descriptionLower.contains(queryLower);
      }).toList();
    } catch (e) {
      print('Error in searchPlants: $e');
      throw Exception('Failed to search plants: $e');
    }
  }
  
  // Tambahkan metode untuk menambahkan data tanaman sampel
  Future<bool> shouldAddSamplePlants() async {
    try {
      // List of sample plants to check
      final List<Map<String, dynamic>> samplePlants = [
        {
          'name': 'Tomat',
          'scientificName': 'Solanum lycopersicum',
          'description': 'Tomat adalah tanaman sayuran populer yang menghasilkan buah berwarna merah dengan rasa asam segar.',
          'category': 'Sayuran',
        },
        {
          'name': 'Cabai',
          'scientificName': 'Capsicum annuum',
          'description': 'Cabai adalah tanaman yang menghasilkan buah dengan rasa pedas yang digunakan sebagai bumbu masakan.',
          'category': 'Sayuran',
        }
      ];

      // Check for each sample plant
      for (var samplePlant in samplePlants) {
        final QuerySnapshot existingPlant = await _firestore
            .collection('plants')
            .where('name', isEqualTo: samplePlant['name'])
            .where('scientificName', isEqualTo: samplePlant['scientificName'])
            .where('description', isEqualTo: samplePlant['description'])
            .limit(1)
            .get();

        // If any sample plant is missing, return true to add sample plants
        if (existingPlant.docs.isEmpty) {
          return true;
        }
      }

      // All sample plants exist
      return false;
    } catch (e) {
      print('Error checking sample plants: $e');
      return true; // If there's an error, suggest adding sample plants
    }
  }
  
  // Tambahkan metode untuk menambahkan data tanaman sampel
  Future<void> addSamplePlants() async {
    try {
      // Data tanaman tomat
      await _firestore.collection('plants').add({
        'name': 'Tomat',
        'scientificName': 'Solanum lycopersicum',
        'description': 'Tomat adalah tanaman sayuran populer yang menghasilkan buah berwarna merah dengan rasa asam segar.',
        'imageUrl': 'https://cdn.pixabay.com/photo/2017/01/11/19/56/tomatoes-1972462_1280.jpg',
        'category': 'Sayuran',
        'growthDuration': 90,
        'difficulty': 'Sedang',
        'wateringFrequency': 'Setiap 2-3 hari',
        'sunlightRequirement': 'Sinar matahari penuh',
        'soilType': 'Tanah gembur kaya humus',
        'harvestTime': '75-90 hari setelah tanam',
        'benefits': 'Kaya vitamin C dan antioksidan likopen',
        'plantingSteps': [
          {
            'stepNumber': 1,
            'title': 'Persiapan Benih',
            'description': 'Rendam benih dalam air hangat selama 12 jam'
          },
          {
            'stepNumber': 2,
            'title': 'Penyemaian',
            'description': 'Tanam benih dalam media semai dengan kedalaman 0,5 cm'
          }
        ],
        'careInstructions': [
          {
            'title': 'Penyiraman',
            'description': 'Siram secara teratur, jaga agar tanah tetap lembab'
          }
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp()
      });
      
      // Data tanaman cabai
      await _firestore.collection('plants').add({
        'name': 'Cabai',
        'scientificName': 'Capsicum annuum',
        'description': 'Cabai adalah tanaman yang menghasilkan buah dengan rasa pedas yang digunakan sebagai bumbu masakan.',
        'imageUrl': 'https://cdn.pixabay.com/photo/2018/05/26/18/06/chili-3431722_1280.jpg',
        'category': 'Sayuran',
        'growthDuration': 120,
        'difficulty': 'Sedang',
        'wateringFrequency': 'Saat tanah mulai kering',
        'sunlightRequirement': 'Sinar matahari penuh',
        'soilType': 'Tanah gembur dengan drainase baik',
        'harvestTime': '90-120 hari setelah tanam',
        'benefits': 'Mengandung vitamin C dan capsaicin yang baik untuk kesehatan',
        'plantingSteps': [
          {
            'stepNumber': 1,
            'title': 'Persiapan Benih',
            'description': 'Pilih benih cabai yang berkualitas'
          },
          {
            'stepNumber': 2,
            'title': 'Penyemaian',
            'description': 'Tanam benih dalam media semai dengan kedalaman 1 cm'
          }
        ],
        'careInstructions': [
          {
            'title': 'Pemupukan',
            'description': 'Berikan pupuk kompos saat tanaman berusia 2 minggu'
          }
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp()
      });
      
      print('Sample plants added successfully');
    } catch (e) {
      print('Error adding sample plants: $e');
      throw Exception('Failed to add sample plants: $e');
    }
  }
}