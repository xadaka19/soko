import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/session_manager.dart';
import '../config/api.dart';

class ReviewService {
  // Get reviews for a seller
  static Future<Map<String, dynamic>> getSellerReviews(String sellerId) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${Api.baseUrl}${Api.getReviewsEndpoint}?seller_id=$sellerId',
            ),
            headers: Api.headers,
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'reviews': data['reviews'] ?? [],
          'average_rating': data['average_rating'] ?? 0.0,
          'total_reviews': data['total_reviews'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load reviews',
          'reviews': [],
          'average_rating': 0.0,
          'total_reviews': 0,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'reviews': [],
        'average_rating': 0.0,
        'total_reviews': 0,
      };
    }
  }

  // Submit a review for a seller
  static Future<Map<String, dynamic>> submitReview({
    required String sellerId,
    required int rating,
    required String comment,
    bool isPrivate = false,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}${Api.submitReviewEndpoint}'),
            headers: Api.headers,
            body: jsonEncode({
              'seller_id': sellerId,
              'reviewer_id': user['id'],
              'rating': rating,
              'comment': comment,
              'is_private': isPrivate,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Review submitted successfully',
          'review': data['review'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to submit review',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Like a review
  static Future<Map<String, dynamic>> likeReview(String reviewId) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}${Api.likeReviewEndpoint}'),
            headers: Api.headers,
            body: jsonEncode({'review_id': reviewId, 'user_id': user['id']}),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'likes_count': data['likes_count'],
          'is_liked': data['is_liked'],
        };
      } else {
        return {'success': false, 'message': 'Failed to like review'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Add comment to a review
  static Future<Map<String, dynamic>> addComment({
    required String reviewId,
    required String comment,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}${Api.reviewCommentsEndpoint}'),
            headers: Api.headers,
            body: jsonEncode({
              'review_id': reviewId,
              'user_id': user['id'],
              'comment': comment,
              'action': 'add',
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'comment': data['comment']};
      } else {
        return {'success': false, 'message': 'Failed to add comment'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get comments for a review
  static Future<Map<String, dynamic>> getReviewComments(String reviewId) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${Api.baseUrl}${Api.reviewCommentsEndpoint}?review_id=$reviewId',
            ),
            headers: Api.headers,
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'comments': data['comments'] ?? []};
      } else {
        return {
          'success': false,
          'message': 'Failed to load comments',
          'comments': [],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e', 'comments': []};
    }
  }
}
