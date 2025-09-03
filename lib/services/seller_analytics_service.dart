import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../utils/session_manager.dart';

class SellerAnalyticsService {
  /// Get seller dashboard analytics
  static Future<Map<String, dynamic>> getSellerAnalytics() async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/seller/analytics.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': user['id'],
              'token': user['token'],
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['analytics'];
        } else {
          throw Exception(data['message'] ?? 'Failed to get seller analytics');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get seller analytics error: $e');
      rethrow;
    }
  }

  /// Get listing views and engagement data
  static Future<Map<String, dynamic>> getListingEngagement(int listingId) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/seller/listing-engagement.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': user['id'],
              'token': user['token'],
              'listing_id': listingId,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['engagement'];
        } else {
          throw Exception(data['message'] ?? 'Failed to get listing engagement');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get listing engagement error: $e');
      rethrow;
    }
  }

  /// Get CTR (Click-Through Rate) analytics
  static Future<Map<String, dynamic>> getCTRAnalytics({
    String period = 'week',
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/seller/ctr-analytics.php'),
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
          return data['ctr_data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to get CTR analytics');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get CTR analytics error: $e');
      rethrow;
    }
  }

  /// Get seller performance summary
  static Future<Map<String, dynamic>> getPerformanceSummary() async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/seller/performance-summary.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': user['id'],
              'token': user['token'],
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['performance'];
        } else {
          throw Exception(data['message'] ?? 'Failed to get performance summary');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get performance summary error: $e');
      rethrow;
    }
  }

  /// Get in-app announcements for seller
  static Future<List<dynamic>> getSellerAnnouncements() async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/seller/announcements.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': user['id'],
              'token': user['token'],
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['announcements'] ?? [];
        } else {
          throw Exception(data['message'] ?? 'Failed to get announcements');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get seller announcements error: $e');
      return [];
    }
  }

  /// Mark announcement as read
  static Future<bool> markAnnouncementAsRead(int announcementId) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/seller/mark-announcement-read.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': user['id'],
              'token': user['token'],
              'announcement_id': announcementId,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Mark announcement as read error: $e');
      return false;
    }
  }

  /// Get listing views trend data
  static Future<List<dynamic>> getViewsTrend({
    String period = 'week',
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/seller/views-trend.php'),
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
          return data['trend_data'] ?? [];
        } else {
          throw Exception(data['message'] ?? 'Failed to get views trend');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get views trend error: $e');
      return [];
    }
  }

  /// Get top performing listings
  static Future<List<dynamic>> getTopPerformingListings({
    int limit = 5,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/seller/top-listings.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': user['id'],
              'token': user['token'],
              'limit': limit,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['top_listings'] ?? [];
        } else {
          throw Exception(data['message'] ?? 'Failed to get top listings');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get top performing listings error: $e');
      return [];
    }
  }

  /// Get seller response time analytics
  static Future<Map<String, dynamic>> getResponseTimeAnalytics() async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/seller/response-time.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': user['id'],
              'token': user['token'],
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['response_time'];
        } else {
          throw Exception(data['message'] ?? 'Failed to get response time analytics');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get response time analytics error: $e');
      rethrow;
    }
  }
}
