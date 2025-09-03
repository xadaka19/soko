import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../utils/session_manager.dart';
import 'firebase_service.dart';

class PushNotificationService {
  /// Send targeted push notification
  static Future<Map<String, dynamic>> sendTargetedNotification({
    required String title,
    required String message,
    String? targetType,
    List<int>? userIds,
    String? imageUrl,
    String? deepLink,
    Map<String, String>? customData,
    DateTime? scheduledTime,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/send-push-notification.php'),
            headers: Api.headers,
            body: jsonEncode({
              'admin_id': user['id'],
              'token': user['token'],
              'title': title,
              'message': message,
              'target_type': targetType,
              'user_ids': userIds,
              'image_url': imageUrl,
              'deep_link': deepLink,
              'custom_data': customData,
              'scheduled_time': scheduledTime?.toIso8601String(),
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return {
            'success': true,
            'notification_id': data['notification_id'],
            'recipients_count': data['recipients_count'],
            'message': 'Notification sent successfully',
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to send notification');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Send push notification error: $e');
      return {
        'success': false,
        'message': 'Failed to send notification: $e',
      };
    }
  }

  /// Send notification to all users
  static Future<Map<String, dynamic>> sendToAllUsers({
    required String title,
    required String message,
    String? imageUrl,
    String? deepLink,
  }) async {
    return await sendTargetedNotification(
      title: title,
      message: message,
      targetType: 'all',
      imageUrl: imageUrl,
      deepLink: deepLink,
    );
  }

  /// Send notification to premium users only
  static Future<Map<String, dynamic>> sendToPremiumUsers({
    required String title,
    required String message,
    String? imageUrl,
    String? deepLink,
  }) async {
    return await sendTargetedNotification(
      title: title,
      message: message,
      targetType: 'premium',
      imageUrl: imageUrl,
      deepLink: deepLink,
    );
  }

  /// Send notification to active sellers
  static Future<Map<String, dynamic>> sendToActiveSellers({
    required String title,
    required String message,
    String? imageUrl,
    String? deepLink,
  }) async {
    return await sendTargetedNotification(
      title: title,
      message: message,
      targetType: 'sellers',
      imageUrl: imageUrl,
      deepLink: deepLink,
    );
  }

  /// Send notification to specific users
  static Future<Map<String, dynamic>> sendToSpecificUsers({
    required String title,
    required String message,
    required List<int> userIds,
    String? imageUrl,
    String? deepLink,
  }) async {
    return await sendTargetedNotification(
      title: title,
      message: message,
      targetType: 'specific',
      userIds: userIds,
      imageUrl: imageUrl,
      deepLink: deepLink,
    );
  }

  /// Schedule notification for later
  static Future<Map<String, dynamic>> scheduleNotification({
    required String title,
    required String message,
    required DateTime scheduledTime,
    String? targetType,
    List<int>? userIds,
    String? imageUrl,
    String? deepLink,
  }) async {
    return await sendTargetedNotification(
      title: title,
      message: message,
      targetType: targetType,
      userIds: userIds,
      imageUrl: imageUrl,
      deepLink: deepLink,
      scheduledTime: scheduledTime,
    );
  }

  /// Send listing-related notifications
  static Future<Map<String, dynamic>> sendListingNotification({
    required String type,
    required Map<String, dynamic> listing,
    List<int>? targetUserIds,
  }) async {
    String title = '';
    String message = '';
    String? deepLink;

    switch (type) {
      case 'new_listing':
        title = 'New Listing in ${listing['category_name']}';
        message = '${listing['title']} - KES ${listing['price']}';
        deepLink = '/listing/${listing['id']}';
        break;
      case 'price_drop':
        title = 'Price Drop Alert!';
        message = '${listing['title']} price reduced to KES ${listing['price']}';
        deepLink = '/listing/${listing['id']}';
        break;
      case 'listing_approved':
        title = 'Listing Approved';
        message = 'Your listing "${listing['title']}" has been approved and is now live!';
        deepLink = '/listing/${listing['id']}';
        break;
      case 'listing_rejected':
        title = 'Listing Needs Attention';
        message = 'Your listing "${listing['title']}" needs some updates.';
        deepLink = '/my-listings';
        break;
      default:
        title = 'Sokofiti Update';
        message = 'Check out the latest updates on Sokofiti';
    }

    return await sendTargetedNotification(
      title: title,
      message: message,
      targetType: targetUserIds != null ? 'specific' : 'all',
      userIds: targetUserIds,
      deepLink: deepLink,
      customData: {
        'type': type,
        'listing_id': listing['id'].toString(),
      },
    );
  }

  /// Send promotional notifications
  static Future<Map<String, dynamic>> sendPromotionalNotification({
    required String title,
    required String message,
    String? promoCode,
    String? imageUrl,
    String? targetType,
  }) async {
    return await sendTargetedNotification(
      title: title,
      message: message,
      targetType: targetType ?? 'all',
      imageUrl: imageUrl,
      deepLink: promoCode != null ? '/promo/$promoCode' : '/home',
      customData: {
        'type': 'promotion',
        'promo_code': promoCode ?? '',
      },
    );
  }

  /// Get notification analytics
  static Future<Map<String, dynamic>> getNotificationAnalytics({
    String period = 'week',
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/notification-analytics.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': user['id'],
              'token': user['token'],
              'period': period,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['analytics'];
        } else {
          throw Exception(data['message'] ?? 'Failed to get analytics');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get notification analytics error: $e');
      return {};
    }
  }

  /// Get notification history
  static Future<List<dynamic>> getNotificationHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/notification-history.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': user['id'],
              'token': user['token'],
              'page': page,
              'limit': limit,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['notifications'] ?? [];
        } else {
          throw Exception(data['message'] ?? 'Failed to get history');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get notification history error: $e');
      return [];
    }
  }

  /// Subscribe user to topic
  static Future<bool> subscribeToTopic(String topic) async {
    try {
      await FirebaseService.subscribeToTopic(topic);
      
      // Also update server-side subscription
      final user = await SessionManager.getUser();
      if (user != null) {
        await http.post(
          Uri.parse('${Api.baseUrl}/api/subscribe-topic.php'),
          headers: Api.headers,
          body: jsonEncode({
            'user_id': user['id'],
            'topic': topic,
          }),
        );
      }
      
      return true;
    } catch (e) {
      debugPrint('Subscribe to topic error: $e');
      return false;
    }
  }

  /// Unsubscribe user from topic
  static Future<bool> unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseService.unsubscribeFromTopic(topic);
      
      // Also update server-side subscription
      final user = await SessionManager.getUser();
      if (user != null) {
        await http.post(
          Uri.parse('${Api.baseUrl}/api/unsubscribe-topic.php'),
          headers: Api.headers,
          body: jsonEncode({
            'user_id': user['id'],
            'topic': topic,
          }),
        );
      }
      
      return true;
    } catch (e) {
      debugPrint('Unsubscribe from topic error: $e');
      return false;
    }
  }

  /// Auto-subscribe user to relevant topics based on their activity
  static Future<void> autoSubscribeToTopics() async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) return;

      // Subscribe to general topics
      await subscribeToTopic('all_users');
      
      // Subscribe based on user role
      if (user['role'] == 'admin') {
        await subscribeToTopic('admin_notifications');
      }
      
      // Subscribe to location-based topics if available
      if (user['county'] != null) {
        await subscribeToTopic('county_${user['county']}');
      }
      
      debugPrint('Auto-subscribed to relevant topics');
    } catch (e) {
      debugPrint('Auto-subscribe error: $e');
    }
  }
}
