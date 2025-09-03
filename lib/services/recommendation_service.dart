import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/session_manager.dart';

class RecommendationService {
  static const String baseUrl = 'https://sokofiti.ke/api';

  // Track when user views a listing
  static Future<void> trackListingView({
    required String listingId,
    required String categoryId,
    String? subcategoryId,
    String? location,
    String? priceRange,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) return;

      final response = await http.post(
        Uri.parse('$baseUrl/track-view'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user['id'],
          'listing_id': listingId,
          'category_id': categoryId,
          'subcategory_id': subcategoryId,
          'location': location,
          'price_range': priceRange,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        // Successfully tracked view
        debugPrint('Listing view tracked: $listingId');
      }
    } catch (e) {
      debugPrint('Error tracking listing view: $e');
    }
  }

  // Get personalized recommendations based on user's viewing history
  static Future<List<Map<String, dynamic>>> getPersonalizedRecommendations({
    int limit = 10,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) return [];

      final response = await http.get(
        Uri.parse(
          '$baseUrl/recommendations?user_id=${user['id']}&limit=$limit',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['recommendations'] ?? []);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting recommendations: $e');
      return [];
    }
  }

  // Send push notification for similar ads
  static Future<void> sendSimilarAdsNotification({
    required String userId,
    required Map<String, dynamic> newListing,
    required List<String> interestedUserIds,
  }) async {
    try {
      for (String targetUserId in interestedUserIds) {
        if (targetUserId == userId) continue; // Don't notify the poster

        // Get user's FCM token
        final userToken = await _getUserFCMToken(targetUserId);
        if (userToken == null) continue;

        // Create notification payload with photo
        final photoUrl =
            newListing['photo_url'] ?? newListing['photos']?[0] ?? '';
        final notificationData = {
          'title': 'You might also like this! 🔥',
          'body':
              '${newListing['title']} - KSh ${_formatPrice(newListing['price'])} in ${newListing['location'] ?? 'Kenya'}',
          'data': {
            'type': 'similar_ad_recommendation',
            'listing_id': newListing['id'].toString(),
            'category_id': newListing['category_id'].toString(),
            'listing_title': newListing['title'].toString(),
            'listing_price': newListing['price'].toString(),
            'listing_location': newListing['location']?.toString() ?? '',
            'photo_url': photoUrl,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
          'image': photoUrl.isNotEmpty ? photoUrl : null,
        };

        // Send notification via Firebase (placeholder - implement in FirebaseService)
        // await FirebaseService.sendPushNotification(
        //   token: userToken,
        //   title: notificationData['title']!,
        //   body: notificationData['body']!,
        //   data: notificationData['data']!,
        //   imageUrl: notificationData['image'],
        // );

        // For now, just log the notification
        debugPrint(
          'Would send notification: ${notificationData['title']} to user $targetUserId',
        );

        // Track notification sent
        await _trackNotificationSent(
          targetUserId,
          newListing['id'].toString(),
          'similar_ad_recommendation',
        );
      }
    } catch (e) {
      debugPrint('Error sending similar ads notifications: $e');
    }
  }

  // Find users who might be interested in a new listing
  static Future<List<String>> findInterestedUsers({
    required String categoryId,
    String? subcategoryId,
    String? location,
    String? priceRange,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/find-interested-users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'category_id': categoryId,
          'subcategory_id': subcategoryId,
          'location': location,
          'price_range': priceRange,
          'lookback_days': 30, // Look at views from last 30 days
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<String>.from(data['user_ids'] ?? []);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error finding interested users: $e');
      return [];
    }
  }

  // Process new listing and send notifications
  static Future<void> processNewListingForRecommendations({
    required Map<String, dynamic> listing,
  }) async {
    try {
      // Find users who might be interested
      final interestedUsers = await findInterestedUsers(
        categoryId: listing['category_id'].toString(),
        subcategoryId: listing['subcategory_id']?.toString(),
        location: listing['location'],
        priceRange: _getPriceRange(listing['price']),
      );

      if (interestedUsers.isNotEmpty) {
        // Send notifications to interested users
        await sendSimilarAdsNotification(
          userId: listing['seller_id'].toString(),
          newListing: listing,
          interestedUserIds: interestedUsers,
        );
      }
    } catch (e) {
      debugPrint('Error processing new listing for recommendations: $e');
    }
  }

  // Get user's FCM token
  static Future<String?> _getUserFCMToken(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user-fcm-token?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['fcm_token'];
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user FCM token: $e');
      return null;
    }
  }

  // Track notification sent
  static Future<void> _trackNotificationSent(
    String userId,
    String listingId,
    String notificationType,
  ) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/track-notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'listing_id': listingId,
          'notification_type': notificationType,
          'sent_at': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('Error tracking notification: $e');
    }
  }

  // Helper to determine price range
  static String _getPriceRange(dynamic price) {
    final priceInt = int.tryParse(price.toString()) ?? 0;

    if (priceInt < 1000) return 'under_1k';
    if (priceInt < 5000) return '1k_5k';
    if (priceInt < 10000) return '5k_10k';
    if (priceInt < 50000) return '10k_50k';
    if (priceInt < 100000) return '50k_100k';
    return 'over_100k';
  }

  // Helper to format price with commas
  static String _formatPrice(dynamic price) {
    if (price == null) return '0';
    final priceStr = price.toString();
    final priceInt = int.tryParse(priceStr) ?? 0;
    return priceInt.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // Get user's viewing preferences for notifications
  static Future<Map<String, dynamic>> getUserNotificationPreferences() async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) return {};

      final response = await http.get(
        Uri.parse(
          '$baseUrl/user-notification-preferences?user_id=${user['id']}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['preferences'] ?? {};
      }
      return {};
    } catch (e) {
      debugPrint('Error getting notification preferences: $e');
      return {};
    }
  }

  // Update user's notification preferences
  static Future<bool> updateNotificationPreferences({
    required bool enableSimilarAds,
    required bool enablePriceDrops,
    required bool enableNewInCategory,
    List<String>? preferredCategories,
    String? maxDistance,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/update-notification-preferences'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user['id'],
          'enable_similar_ads': enableSimilarAds,
          'enable_price_drops': enablePriceDrops,
          'enable_new_in_category': enableNewInCategory,
          'preferred_categories': preferredCategories,
          'max_distance': maxDistance,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
      return false;
    }
  }
}
