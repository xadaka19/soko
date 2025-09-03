import 'package:flutter/material.dart';
import '../services/review_service.dart';
import '../utils/session_manager.dart';
import 'ellipsis_loader.dart';

class SellerReviewsWidget extends StatefulWidget {
  final String sellerId;
  final String sellerName;

  const SellerReviewsWidget({
    super.key,
    required this.sellerId,
    required this.sellerName,
  });

  @override
  State<SellerReviewsWidget> createState() => _SellerReviewsWidgetState();
}

class _SellerReviewsWidgetState extends State<SellerReviewsWidget> {
  List<dynamic> _reviews = [];
  double _averageRating = 0.0;
  int _totalReviews = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _currentUser;

  // Review form controllers
  final TextEditingController _reviewController = TextEditingController();
  int _selectedRating = 5;
  bool _isPrivate = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadReviews();
  }

  Future<void> _loadCurrentUser() async {
    _currentUser = await SessionManager.getUser();
    if (mounted) setState(() {});
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);

    final result = await ReviewService.getSellerReviews(widget.sellerId);

    if (mounted) {
      setState(() {
        _reviews = result['reviews'] ?? [];
        _averageRating = (result['average_rating'] ?? 0.0).toDouble();
        _totalReviews = result['total_reviews'] ?? 0;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a review comment')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await ReviewService.submitReview(
      sellerId: widget.sellerId,
      rating: _selectedRating,
      comment: _reviewController.text.trim(),
      isPrivate: _isPrivate,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (result['success']) {
        _reviewController.clear();
        _selectedRating = 5;
        _isPrivate = false;
        _loadReviews(); // Reload reviews
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to submit review'),
          ),
        );
      }
    }
  }

  Future<void> _likeReview(String reviewId, int index) async {
    final result = await ReviewService.likeReview(reviewId);

    if (result['success'] && mounted) {
      setState(() {
        _reviews[index]['likes_count'] = result['likes_count'];
        _reviews[index]['is_liked'] = result['is_liked'];
      });
    }
  }

  Widget _buildRatingStars(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }

  Widget _buildRatingSelector() {
    return Row(
      children: [
        const Text('Rating: ', style: TextStyle(fontWeight: FontWeight.w500)),
        ...List.generate(5, (index) {
          final rating = index + 1;
          return GestureDetector(
            onTap: () => setState(() => _selectedRating = rating),
            child: Icon(
              rating <= _selectedRating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 24,
            ),
          );
        }),
        const SizedBox(width: 8),
        Text('($_selectedRating/5)'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reviews Header
        Row(
          children: [
            const Text(
              'Reviews & Ratings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (_totalReviews > 0) ...[
              _buildRatingStars(_averageRating, size: 18),
              const SizedBox(width: 8),
              Text(
                '${_averageRating.toStringAsFixed(1)} ($_totalReviews)',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Add Review Form (only for logged-in users)
        if (_currentUser != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Write a review for ${widget.sellerName}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                _buildRatingSelector(),
                const SizedBox(height: 12),
                TextField(
                  controller: _reviewController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Share your experience with this seller...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _isPrivate,
                      onChanged: (value) =>
                          setState(() => _isPrivate = value ?? false),
                    ),
                    const Text('Hide this review from other users'),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5BE206),
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit Review'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Reviews List
        if (_isLoading)
          const Center(child: BouncingEllipsisLoader())
        else if (_reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            child: const Center(
              child: Text(
                'No reviews yet. Be the first to review this seller!',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final review = _reviews[index];
              return _buildReviewItem(review, index);
            },
          ),
      ],
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review, int index) {
    final isPrivate = review['is_private'] == true;
    final likesCount = review['likes_count'] ?? 0;
    final isLiked = review['is_liked'] == true;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF5BE206),
                child: Text(
                  (review['reviewer_name'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review['reviewer_name'] ?? 'Anonymous',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (isPrivate) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Private',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        _buildRatingStars((review['rating'] ?? 0).toDouble()),
                        const SizedBox(width: 8),
                        Text(
                          review['created_at'] ?? '',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review['comment'] ?? ''),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: _currentUser != null
                    ? () => _likeReview(review['id'], index)
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                      size: 16,
                      color: isLiked ? const Color(0xFF5BE206) : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$likesCount',
                      style: TextStyle(
                        color: isLiked ? const Color(0xFF5BE206) : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _currentUser != null
                    ? () => _showCommentDialog(review['id'])
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 16,
                      color: _currentUser != null
                          ? Colors.grey[600]
                          : Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Comment',
                      style: TextStyle(
                        color: _currentUser != null
                            ? Colors.grey[600]
                            : Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCommentDialog(String reviewId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Comment'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Write your comment...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Comment submission placeholder
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Comment feature coming soon!')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}
