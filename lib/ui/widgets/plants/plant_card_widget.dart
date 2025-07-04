import 'package:flutter/material.dart';
import '../../../data/models/plant_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;
  final bool useFlexLayout; // New parameter to control layout type

  const PlantCard({
    super.key,
    required this.plant,
    required this.onTap,
    this.useFlexLayout = true, // Default to flex layout for GridView
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha((0.1 * 255).toInt()),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plant Image
            useFlexLayout
                ? Expanded(
                    flex: 3,
                    child: _buildImageWidget(),
                  )
                : SizedBox(
                    height: 150,
                    child: _buildImageWidget(),
                  ),

            // Plant Info
            useFlexLayout
                ? Expanded(
                    flex: 2,
                    child: _buildInfoWidget(),
                  )
                : _buildInfoWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: CachedNetworkImage(
        imageUrl: plant.imageUrl,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: double.infinity,
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: double.infinity,
          color: Colors.grey[300],
          child: const Icon(
            Icons.error,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoWidget() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            plant.name,
            style: const TextStyle(
              fontSize: 14, // Further reduced
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1), // Minimal spacing
          Text(
            plant.scientificName,
            style: TextStyle(
              fontSize: 11, // Further reduced
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3), // Minimal spacing

          // Plant tags
          Row(
            children: [
              Flexible(child: _buildTag(plant.category, Colors.green[100]!)),
              const SizedBox(width: 2), // Minimal spacing
              Flexible(child: _buildTag(plant.difficulty, _getDifficultyColor(plant.difficulty))),
            ],
          ),

          const SizedBox(height: 2), // Minimal spacing
          Flexible(
            child: Text(
              plant.description,
              style: const TextStyle(
                fontSize: 11, // Further reduced
                color: Colors.black87,
              ),
              maxLines: useFlexLayout ? 2 : 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // Even smaller padding
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6), // Smaller radius
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9, // Even smaller font
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'mudah':
        return Colors.green[100]!;
      case 'sedang':
        return Colors.yellow[100]!;
      case 'sulit':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }
}