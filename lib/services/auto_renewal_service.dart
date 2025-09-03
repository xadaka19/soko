import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api.dart';

class AutoRenewalService {
  // Plan renewal intervals in hours
  static const Map<String, int> planRenewalIntervals = {
    'free': 48,
    'starter': 12,
    'basic': 10,
    'premium': 8,
    'business': 6,
    'top_featured': 16,
    'top': 24,
  };

  /// Get renewal interval for a plan type
  static int getRenewalInterval(String planType) {
    return planRenewalIntervals[planType.toLowerCase()] ?? 48; // Default to free plan
  }

  /// Check if a listing needs renewal
  static bool needsRenewal(DateTime lastRenewal, String planType) {
    final interval = getRenewalInterval(planType);
    final nextRenewal = lastRenewal.add(Duration(hours: interval));
    return DateTime.now().isAfter(nextRenewal);
  }

  /// Get next renewal time for a listing
  static DateTime getNextRenewalTime(DateTime lastRenewal, String planType) {
    final interval = getRenewalInterval(planType);
    return lastRenewal.add(Duration(hours: interval));
  }

  /// Trigger auto-renewal for eligible listings
  static Future<Map<String, dynamic>> triggerAutoRenewal() async {
    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/auto-renewal.php'),
            headers: Api.headers,
            body: jsonEncode({
              'action': 'trigger_renewal',
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? false,
          'renewed_count': data['renewed_count'] ?? 0,
          'message': data['message'] ?? 'Auto-renewal completed',
        };
      }
      return {
        'success': false,
        'renewed_count': 0,
        'message': 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      return {
        'success': false,
        'renewed_count': 0,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get auto-renewal status for user's listings
  static Future<List<Map<String, dynamic>>> getUserRenewalStatus(int userId) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/get-renewal-status.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': userId,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['listings'] ?? []);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Manually renew a specific listing
  static Future<bool> renewListing(int listingId, int userId) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/renew-listing.php'),
            headers: Api.headers,
            body: jsonEncode({
              'listing_id': listingId,
              'user_id': userId,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Enable/disable auto-renewal for a listing
  static Future<bool> toggleAutoRenewal(int listingId, int userId, bool enabled) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/toggle-auto-renewal.php'),
            headers: Api.headers,
            body: jsonEncode({
              'listing_id': listingId,
              'user_id': userId,
              'auto_renewal_enabled': enabled,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get formatted renewal schedule text
  static String getRenewalScheduleText(String planType) {
    final interval = getRenewalInterval(planType);
    
    if (interval < 24) {
      return 'Auto-renews every $interval hours';
    } else {
      final days = (interval / 24).round();
      return 'Auto-renews every $days day${days > 1 ? 's' : ''}';
    }
  }

  /// Calculate time until next renewal
  static String getTimeUntilRenewal(DateTime lastRenewal, String planType) {
    final nextRenewal = getNextRenewalTime(lastRenewal, planType);
    final now = DateTime.now();
    
    if (now.isAfter(nextRenewal)) {
      return 'Due for renewal';
    }
    
    final difference = nextRenewal.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} remaining';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} remaining';
    } else {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} remaining';
    }
  }

  /// Get all plan types with their renewal intervals
  static Map<String, String> getAllPlanSchedules() {
    return planRenewalIntervals.map((plan, hours) {
      if (hours < 24) {
        return MapEntry(plan, 'Every $hours hours');
      } else {
        final days = (hours / 24).round();
        return MapEntry(plan, 'Every $days day${days > 1 ? 's' : ''}');
      }
    });
  }
}
