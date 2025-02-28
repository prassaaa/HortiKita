import 'package:cloud_firestore/cloud_firestore.dart';

class Plant {
  final String id;
  final String name;
  final String scientificName;
  final String description;
  final String imageUrl;
  final String category;
  final int growthDuration; // Dalam hari
  final String difficulty; // Mudah, Sedang, Sulit
  final String wateringFrequency;
  final String sunlightRequirement;
  final String soilType;
  final String harvestTime;
  final String benefits;
  final List<Map<String, dynamic>> plantingSteps;
  final List<Map<String, dynamic>> careInstructions;
  final DateTime createdAt;
  final DateTime updatedAt;

  Plant({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.growthDuration,
    required this.difficulty,
    required this.wateringFrequency,
    required this.sunlightRequirement,
    required this.soilType,
    required this.harvestTime,
    required this.benefits,
    required this.plantingSteps,
    required this.careInstructions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Plant.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      // Lebih defensif dalam menangani data
      List<Map<String, dynamic>> plantingStepsList = [];
      if (data['plantingSteps'] != null) {
        if (data['plantingSteps'] is List) {
          plantingStepsList = (data['plantingSteps'] as List)
              .where((item) => item is Map<String, dynamic>)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        }
      }

      List<Map<String, dynamic>> careInstructionsList = [];
      if (data['careInstructions'] != null) {
        if (data['careInstructions'] is List) {
          careInstructionsList = (data['careInstructions'] as List)
              .where((item) => item is Map<String, dynamic>)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        }
      }
      
      return Plant(
        id: doc.id,
        name: data['name']?.toString() ?? '',
        scientificName: data['scientificName']?.toString() ?? '',
        description: data['description']?.toString() ?? '',
        imageUrl: data['imageUrl']?.toString() ?? '',
        category: data['category']?.toString() ?? '',
        growthDuration: data['growthDuration'] is int ? data['growthDuration'] : 0,
        difficulty: data['difficulty']?.toString() ?? 'Sedang',
        wateringFrequency: data['wateringFrequency']?.toString() ?? '',
        sunlightRequirement: data['sunlightRequirement']?.toString() ?? '',
        soilType: data['soilType']?.toString() ?? '',
        harvestTime: data['harvestTime']?.toString() ?? '',
        benefits: data['benefits']?.toString() ?? '',
        plantingSteps: plantingStepsList,
        careInstructions: careInstructionsList,
        createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
        updatedAt: data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing Plant document: $e');
      print('Document data: ${doc.data()}');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'scientificName': scientificName,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'growthDuration': growthDuration,
      'difficulty': difficulty,
      'wateringFrequency': wateringFrequency,
      'sunlightRequirement': sunlightRequirement,
      'soilType': soilType,
      'harvestTime': harvestTime,
      'benefits': benefits,
      'plantingSteps': plantingSteps,
      'careInstructions': careInstructions,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}