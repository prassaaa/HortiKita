import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/plant_model.dart';

class PlantDetailScreen extends StatelessWidget {
  final Plant plant;

  const PlantDetailScreen({
    Key? key,
    required this.plant,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Definisi warna tema yang sama
    const Color primaryGreen = Color(0xFF4CAF50);
    const Color lightGreen = Color(0xFFE8F5E9);
    const Color whiteColor = Colors.white;

    return Scaffold(
      backgroundColor: whiteColor,
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: whiteColor,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: plant.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: lightGreen,
                  child: const Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plant Name
                    Text(
                      plant.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Scientific name
                    Text(
                      plant.scientificName,
                      style: TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Summary info (tags)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildInfoChip('Kategori: ${plant.category}', Icons.category, primaryGreen, lightGreen),
                        _buildInfoChip('Kesulitan: ${plant.difficulty}', Icons.trending_up, primaryGreen, lightGreen),
                        _buildInfoChip('Durasi Tumbuh: ${plant.growthDuration} hari', Icons.access_time, primaryGreen, lightGreen),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Description
                    _buildSectionTitle('Deskripsi', primaryGreen),
                    const SizedBox(height: 8),
                    Text(
                      plant.description,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 24),
                    
                    // Planting Requirements
                    _buildSectionTitle('Kebutuhan Tanam', primaryGreen),
                    const SizedBox(height: 16),
                    _buildRequirementItem(
                      'Kebutuhan Air',
                      plant.wateringFrequency,
                      Icons.water_drop,
                      Colors.blue,
                    ),
                    _buildRequirementItem(
                      'Kebutuhan Cahaya',
                      plant.sunlightRequirement,
                      Icons.wb_sunny,
                      Colors.orange,
                    ),
                    _buildRequirementItem(
                      'Jenis Tanah',
                      plant.soilType,
                      Icons.landscape,
                      Colors.brown,
                    ),
                    _buildRequirementItem(
                      'Waktu Panen',
                      plant.harvestTime,
                      Icons.calendar_today,
                      primaryGreen,
                    ),
                    const SizedBox(height: 24),
                    
                    // Benefits
                    _buildSectionTitle('Manfaat', primaryGreen),
                    const SizedBox(height: 8),
                    Text(
                      plant.benefits,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 24),
                    
                    // Planting Steps
                    _buildSectionTitle('Cara Menanam', primaryGreen),
                    const SizedBox(height: 16),
                    ...plant.plantingSteps.asMap().entries.map((entry) {
                      final index = entry.key;
                      final step = entry.value;
                      return _buildStepItem(
                        index + 1,
                        step['title'],
                        step['description'],
                        primaryGreen,
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                    
                    // Care Instructions
                    _buildSectionTitle('Perawatan', primaryGreen),
                    const SizedBox(height: 16),
                    ...plant.careInstructions.map((instruction) {
                      return _buildCareItem(
                        instruction['title'],
                        instruction['description'],
                        lightGreen,
                        whiteColor,
                      );
                    }).toList(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color primaryGreen) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: primaryGreen,
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color primaryGreen, Color lightGreen) {
    return Chip(
      label: Text(
        text,
        style: const TextStyle(color: Color(0xFF558B2F)),
      ),
      avatar: Icon(
        icon,
        size: 16,
        color: primaryGreen,
      ),
      backgroundColor: lightGreen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      shadowColor: Colors.grey.withOpacity(0.2),
    );
  }

  Widget _buildRequirementItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int number, String title, String description, Color primaryGreen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareItem(String title, String description, Color lightGreen, Color whiteColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: lightGreen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}