import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/user_engagement_provider.dart';

class ContentRatingWidget extends StatefulWidget {
  final String contentId;
  final String contentType;
  final bool showRatingDialog;
  final VoidCallback? onRated;

  const ContentRatingWidget({
    super.key,
    required this.contentId,
    required this.contentType,
    this.showRatingDialog = true,
    this.onRated,
  });

  @override
  State<ContentRatingWidget> createState() => _ContentRatingWidgetState();
}

class _ContentRatingWidgetState extends State<ContentRatingWidget> {
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserEngagementProvider>(
      builder: (context, engagementProvider, child) {
        final userRating = engagementProvider.getUserRating(widget.contentId);
        final contentEngagement = engagementProvider.getContentEngagement(widget.contentId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Rating Display
            if (contentEngagement != null) ...[
              Row(
                children: [
                  _buildStarRating(contentEngagement.averageRating, readOnly: true),
                  const SizedBox(width: 8),
                  Text(
                    // FIX: Removed unnecessary string interpolation.
                    contentEngagement.averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    ' (${contentEngagement.ratingCount} ulasan)',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // User's Rating
            if (userRating != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Ulasan Anda:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        _buildStarRating(userRating.rating.toDouble(), readOnly: true),
                      ],
                    ),
                    if (userRating.comment != null && userRating.comment!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        userRating.comment!,
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (userRating.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Terverifikasi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _showRatingDialog(context, userRating),
                          child: const Text('Edit Ulasan'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Rate Content Button
              if (widget.showRatingDialog)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showRatingDialog(context, null),
                    icon: const Icon(Icons.star_border),
                    label: const Text('Beri Ulasan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStarRating(double rating, {bool readOnly = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        // This logic is slightly adjusted to handle half-star selection in the dialog correctly.
        final starIcon = readOnly
          ? (rating >= starValue
              ? Icons.star
              : rating >= starValue - 0.5
                  ? Icons.star_half
                  : Icons.star_border)
          : (_selectedRating >= starValue
              ? Icons.star
              : Icons.star_border);

        return GestureDetector(
          onTap: readOnly
              ? null
              : () {
                  // The StatefulBuilder in the dialog will handle its own state update.
                  // This setState is for the dialog's star selection.
                  (context as Element).markNeedsBuild();
                  _selectedRating = starValue;
                },
          child: Icon(
            starIcon,
            color: Colors.amber,
            size: readOnly ? 20 : 32,
          ),
        );
      }),
    );
  }

  void _showRatingDialog(BuildContext context, userRating) {
    _selectedRating = userRating?.rating ?? 0;
    _commentController.text = userRating?.comment ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(userRating != null ? 'Edit Ulasan' : 'Beri Ulasan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rating:'),
            const SizedBox(height: 8),
            // Use StatefulBuilder so only the stars rebuild on tap, not the whole dialog.
            StatefulBuilder(
              builder: (context, setState) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRating = starValue;
                        });
                      },
                      child: Icon(
                        _selectedRating >= starValue ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text('Komentar (opsional):'),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Bagikan pengalaman Anda...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: _selectedRating > 0 ? () => _submitRating(context) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _submitRating(BuildContext context) async {
    final engagementProvider = Provider.of<UserEngagementProvider>(
      context,
      listen: false,
    );

    // FIX: Store context-dependent objects before the async gap.
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final success = await engagementProvider.rateContent(
        contentId: widget.contentId,
        contentType: widget.contentType,
        rating: _selectedRating,
        comment: _commentController.text.trim().isEmpty 
            ? null 
            : _commentController.text.trim(),
        isVerified: false, // Could be enhanced with verification logic
      );
      
      if (!mounted) return; // Always check if the widget is still in the tree.

      if (success) {
        navigator.pop();
        
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check, color: Colors.white),
                SizedBox(width: 12),
                Text('Ulasan berhasil disimpan'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        widget.onRated?.call();
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('Gagal menyimpan ulasan'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              // It's often better not to show the full error to the user.
              // Consider a generic message or logging the error.
              Text('Terjadi kesalahan: ${e.toString()}'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}