import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../utils/session_manager.dart';

class AdminService {
  /// Get dashboard statistics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/dashboard-stats.php'),
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
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to get dashboard stats');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get dashboard stats error: $e');
      rethrow;
    }
  }

  /// Get all users with pagination
  static Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/get-users.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': user['id'],
              'token': user['token'],
              'page': page,
              'limit': limit,
              'search': search,
              'status': status,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Failed to get users');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get users error: $e');
      rethrow;
    }
  }

  /// Update user status (ban/unban/suspend)
  static Future<bool> updateUserStatus({
    required int userId,
    required String status,
    String? reason,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/update-user-status.php'),
            headers: Api.headers,
            body: jsonEncode({
              'admin_id': user['id'],
              'token': user['token'],
              'user_id': userId,
              'status': status,
              'reason': reason,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Update user status error: $e');
      return false;
    }
  }

  /// Get all listings with admin filters
  static Future<Map<String, dynamic>> getListings({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? category,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/get-listings.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': user['id'],
              'token': user['token'],
              'page': page,
              'limit': limit,
              'search': search,
              'status': status,
              'category': category,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Failed to get listings');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get listings error: $e');
      rethrow;
    }
  }

  /// Update listing status (approve/reject/hide)
  static Future<bool> updateListingStatus({
    required int listingId,
    required String status,
    String? reason,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/update-listing-status.php'),
            headers: Api.headers,
            body: jsonEncode({
              'admin_id': user['id'],
              'token': user['token'],
              'listing_id': listingId,
              'status': status,
              'reason': reason,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Update listing status error: $e');
      return false;
    }
  }

  /// Get reports with filters
  static Future<Map<String, dynamic>> getReports({
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/get-reports.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': user['id'],
              'token': user['token'],
              'page': page,
              'limit': limit,
              'status': status,
              'type': type,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Failed to get reports');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get reports error: $e');
      rethrow;
    }
  }

  /// Update report status
  static Future<bool> updateReportStatus({
    required int reportId,
    required String status,
    String? adminNotes,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/update-report-status.php'),
            headers: Api.headers,
            body: jsonEncode({
              'admin_id': user['id'],
              'token': user['token'],
              'report_id': reportId,
              'status': status,
              'admin_notes': adminNotes,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Update report status error: $e');
      return false;
    }
  }

  /// Get revenue analytics
  static Future<Map<String, dynamic>> getRevenueAnalytics({
    String period = 'monthly',
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/revenue-analytics.php'),
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
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to get revenue analytics');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get revenue analytics error: $e');
      rethrow;
    }
  }

  /// Send push notification
  static Future<bool> sendPushNotification({
    required String title,
    required String message,
    String? targetType,
    List<int>? userIds,
    String? imageUrl,
    String? deepLink,
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
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Send push notification error: $e');
      return false;
    }
  }

  /// Get system settings
  static Future<Map<String, dynamic>> getSystemSettings() async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/get-system-settings.php'),
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
          return data['settings'];
        } else {
          throw Exception(data['message'] ?? 'Failed to get system settings');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get system settings error: $e');
      rethrow;
    }
  }

  /// Update system settings
  static Future<bool> updateSystemSettings(Map<String, dynamic> settings) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/update-system-settings.php'),
            headers: Api.headers,
            body: jsonEncode({
              'admin_id': user['id'],
              'token': user['token'],
              'settings': settings,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Update system settings error: $e');
      return false;
    }
  }
}
