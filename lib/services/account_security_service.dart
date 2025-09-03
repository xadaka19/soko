import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
// import 'package:device_info_plus/device_info_plus.dart'; // Removed for web compatibility
import '../config/api.dart';
import '../utils/session_manager.dart';

class AccountSecurityService {
  /// Detect duplicate accounts
  static Future<Map<String, dynamic>> checkDuplicateAccounts({
    required String email,
    required String phoneNumber,
  }) async {
    try {
      final deviceFingerprint = await _getDeviceFingerprint();

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/security/check-duplicates.php'),
            headers: Api.headers,
            body: jsonEncode({
              'email': email,
              'phone_number': phoneNumber,
              'device_fingerprint': deviceFingerprint,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'has_duplicates': data['has_duplicates'] ?? false,
          'duplicate_types': data['duplicate_types'] ?? [],
          'existing_accounts': data['existing_accounts'] ?? [],
          'risk_score': data['risk_score'] ?? 0,
          'recommendations': data['recommendations'] ?? [],
        };
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Check duplicate accounts error: $e');
      return {
        'has_duplicates': false,
        'duplicate_types': [],
        'existing_accounts': [],
        'risk_score': 0,
        'recommendations': [],
      };
    }
  }

  /// Report suspicious account activity
  static Future<bool> reportSuspiciousActivity({
    required int suspiciousUserId,
    required String activityType,
    required String description,
    String? evidence,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/security/report-suspicious.php'),
            headers: Api.headers,
            body: jsonEncode({
              'reporter_id': user['id'],
              'token': user['token'],
              'suspicious_user_id': suspiciousUserId,
              'activity_type': activityType,
              'description': description,
              'evidence': evidence,
              'device_fingerprint': await _getDeviceFingerprint(),
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Report suspicious activity error: $e');
      return false;
    }
  }

  /// Check if user/device is banned
  static Future<Map<String, dynamic>> checkBanStatus() async {
    try {
      final user = await SessionManager.getUser();
      final deviceFingerprint = await _getDeviceFingerprint();

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/security/check-ban-status.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': user?['id'],
              'device_fingerprint': deviceFingerprint,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'is_banned': data['is_banned'] ?? false,
          'ban_type': data['ban_type'], // account, device, network
          'ban_reason': data['ban_reason'],
          'ban_expires': data['ban_expires'],
          'can_appeal': data['can_appeal'] ?? false,
        };
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Check ban status error: $e');
      return {
        'is_banned': false,
        'ban_type': null,
        'ban_reason': null,
        'ban_expires': null,
        'can_appeal': false,
      };
    }
  }

  /// Submit ban appeal
  static Future<bool> submitBanAppeal({
    required String reason,
    required String explanation,
    String? evidence,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/security/submit-appeal.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': user['id'],
              'token': user['token'],
              'reason': reason,
              'explanation': explanation,
              'evidence': evidence,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Submit ban appeal error: $e');
      return false;
    }
  }

  /// Admin: Get security reports
  static Future<List<dynamic>> getSecurityReports({
    String? reportType,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/security-reports.php'),
            headers: Api.headers,
            body: jsonEncode({
              'admin_id': user['id'],
              'token': user['token'],
              'report_type': reportType,
              'status': status,
              'page': page,
              'limit': limit,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['reports'] ?? [];
        } else {
          throw Exception(data['message'] ?? 'Failed to get reports');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get security reports error: $e');
      return [];
    }
  }

  /// Admin: Ban user/device/network
  static Future<bool> banEntity({
    required String banType, // user, device, network
    required String entityId,
    required String reason,
    required Duration duration,
    String? adminNotes,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/ban-entity.php'),
            headers: Api.headers,
            body: jsonEncode({
              'admin_id': user['id'],
              'token': user['token'],
              'ban_type': banType,
              'entity_id': entityId,
              'reason': reason,
              'duration_hours': duration.inHours,
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
      debugPrint('Ban entity error: $e');
      return false;
    }
  }

  /// Admin: Unban entity
  static Future<bool> unbanEntity({
    required String banType,
    required String entityId,
    String? reason,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/unban-entity.php'),
            headers: Api.headers,
            body: jsonEncode({
              'admin_id': user['id'],
              'token': user['token'],
              'ban_type': banType,
              'entity_id': entityId,
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
      debugPrint('Unban entity error: $e');
      return false;
    }
  }

  /// Get security analytics
  static Future<Map<String, dynamic>> getSecurityAnalytics() async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/security-analytics.php'),
            headers: Api.headers,
            body: jsonEncode({'admin_id': user['id'], 'token': user['token']}),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return {
            'total_reports': data['total_reports'] ?? 0,
            'pending_reports': data['pending_reports'] ?? 0,
            'active_bans': data['active_bans'] ?? 0,
            'duplicate_accounts_detected':
                data['duplicate_accounts_detected'] ?? 0,
            'fraud_prevention_saves': data['fraud_prevention_saves'] ?? 0,
            'security_trends': data['security_trends'] ?? [],
            'top_violation_types': data['top_violation_types'] ?? [],
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to get analytics');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get security analytics error: $e');
      return {};
    }
  }

  /// Block phone number
  static Future<bool> blockPhoneNumber({
    required String phoneNumber,
    required String reason,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/block-phone.php'),
            headers: Api.headers,
            body: jsonEncode({
              'admin_id': user['id'],
              'token': user['token'],
              'phone_number': phoneNumber,
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
      debugPrint('Block phone number error: $e');
      return false;
    }
  }

  /// Block email address
  static Future<bool> blockEmailAddress({
    required String email,
    required String reason,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/block-email.php'),
            headers: Api.headers,
            body: jsonEncode({
              'admin_id': user['id'],
              'token': user['token'],
              'email': email,
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
      debugPrint('Block email address error: $e');
      return false;
    }
  }

  /// Get device fingerprint (simplified for web compatibility)
  static Future<String> _getDeviceFingerprint() async {
    try {
      // Simplified device fingerprint for web compatibility
      String fingerprint = '';

      if (kIsWeb) {
        // Web-specific fingerprint
        fingerprint = 'web_${DateTime.now().millisecondsSinceEpoch}';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        // Android-specific fingerprint (simplified)
        fingerprint = 'android_${DateTime.now().millisecondsSinceEpoch}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS-specific fingerprint (simplified)
        fingerprint = 'ios_${DateTime.now().millisecondsSinceEpoch}';
      }

      return fingerprint.isNotEmpty ? fingerprint : 'unknown_device';
    } catch (e) {
      debugPrint('Device fingerprint error: $e');
      return 'unknown_device';
    }
  }
}
