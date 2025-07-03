import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/user_engagement_provider.dart';

class ContentEngagementWidget extends StatelessWidget {
  final String contentId;
  final String contentType;

  const ContentEngagementWidget({
    super.key,
    required this.contentId,
    required this.contentType,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserEngagementProvider>(
      builder: (context, engagementProvider, child) {
        final engagement = engagementProvider.getContentEngagement(contentId);
        
        if (engagement == null) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistik Konten',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.visibility,
                      label: 'Dilihat',
                      value: _formatNumber(engagement.totalViews),
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.favorite,
                      label: 'Favorit',
                      value: _formatNumber(engagement.favorites),
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.share,
                      label: 'Dibagikan',
                      value: _formatNumber(engagement.shares),
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.star,
                      label: 'Rating',
                      value: engagement.averageRating > 0 
                          ? engagement.averageRating.toStringAsFixed(1)
                          : '-',
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
              if (engagement.engagementRate > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getEngagementColor(engagement.engagementRate).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getEngagementColor(engagement.engagementRate).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 16,
                        color: _getEngagementColor(engagement.engagementRate),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Engagement Rate: ${engagement.engagementRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getEngagementColor(engagement.engagementRate),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Color _getEngagementColor(double rate) {
    if (rate >= 5.0) return Colors.green;
    if (rate >= 2.0) return Colors.orange;
    return Colors.red;
  }
}
