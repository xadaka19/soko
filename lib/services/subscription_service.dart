import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../utils/session_manager.dart';

class SubscriptionService {
  /// Activate user subscription after successful payment
  static Future<Map<String, dynamic>> activateSubscription({
    required String planId,
    required int userId,
    required String transactionId,
    required double amount,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/activate-subscription.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': userId,
              'plan_id': planId,
              'transaction_id': transactionId,
              'amount': amount,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success']) {
          // Update local user session with subscription info
          await _updateUserSessionWithSubscription(data['subscription']);
        }

        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Unknown error',
          'subscription': data['subscription'],
          'credits_added': data['credits_added'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Activate free plan subscription
  static Future<Map<String, dynamic>> activateFreePlan({
    required int userId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/activate-free-plan.php'),
            headers: Api.headers,
            body: jsonEncode({'user_id': userId}),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success']) {
          // Update local user session with subscription info
          await _updateUserSessionWithSubscription(data['subscription']);
        }

        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Unknown error',
          'subscription': data['subscription'],
          'credits_added': data['credits_added'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get user's current subscription and credits
  static Future<Map<String, dynamic>?> getUserSubscription({
    required int userId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${Api.baseUrl}/api/get-user-subscription.php',
            ).replace(queryParameters: {'user_id': userId.toString()}),
            headers: Api.headers,
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['subscription'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('Get user subscription error: $e');
      return null;
    }
  }

  /// Check if user can create a listing (has credits)
  static Future<Map<String, dynamic>> checkListingEligibility({
    required int userId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${Api.baseUrl}/api/check-listing-eligibility.php',
            ).replace(queryParameters: {'user_id': userId.toString()}),
            headers: Api.headers,
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'can_create': data['can_create'] ?? false,
          'credits_remaining': data['credits_remaining'] ?? 0,
          'plan_name': data['plan_name'] ?? 'No Plan',
          'plan_status': data['plan_status'] ?? 'inactive',
          'message': data['message'] ?? '',
        };
      } else {
        return {
          'can_create': false,
          'credits_remaining': 0,
          'plan_name': 'No Plan',
          'plan_status': 'inactive',
          'message': 'Unable to check eligibility',
        };
      }
    } catch (e) {
      return {
        'can_create': false,
        'credits_remaining': 0,
        'plan_name': 'No Plan',
        'plan_status': 'inactive',
        'message': 'Network error: $e',
      };
    }
  }

  /// Consume a credit when creating a listing
  static Future<bool> consumeCredit({
    required int userId,
    required int listingId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/consume-credit.php'),
            headers: Api.headers,
            body: jsonEncode({'user_id': userId, 'listing_id': listingId}),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success']) {
          // Update local user session with new credit count
          await _updateUserCredits(data['credits_remaining'] ?? 0);
        }

        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Consume credit error: $e');
      return false;
    }
  }

  /// Get user's credit history
  static Future<List<Map<String, dynamic>>> getCreditHistory({
    required int userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('${Api.baseUrl}/api/get-credit-history.php').replace(
              queryParameters: {
                'user_id': userId.toString(),
                'page': page.toString(),
                'limit': limit.toString(),
              },
            ),
            headers: Api.headers,
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['history'] ?? []);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Get credit history error: $e');
      return [];
    }
  }

  /// Update user session with subscription info
  static Future<void> _updateUserSessionWithSubscription(
    Map<String, dynamic>? subscription,
  ) async {
    try {
      final user = await SessionManager.getUser();
      if (user != null && subscription != null) {
        user['subscription'] = subscription;
        user['credits_remaining'] = subscription['credits_remaining'] ?? 0;
        user['plan_name'] = subscription['plan_name'] ?? 'No Plan';
        user['plan_status'] = subscription['status'] ?? 'inactive';
        await SessionManager.saveUser(user);
      }
    } catch (e) {
      debugPrint('Failed to update user session: $e');
    }
  }

  /// Update user credits in session
  static Future<void> _updateUserCredits(int creditsRemaining) async {
    try {
      final user = await SessionManager.getUser();
      if (user != null) {
        user['credits_remaining'] = creditsRemaining;
        if (user['subscription'] != null) {
          user['subscription']['credits_remaining'] = creditsRemaining;
        }
        await SessionManager.saveUser(user);
      }
    } catch (e) {
      debugPrint('Failed to update user credits: $e');
    }
  }

  /// Get credits from local session (for quick access)
  static Future<int> getLocalCredits() async {
    try {
      final user = await SessionManager.getUser();
      return user?['credits_remaining'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get plan name from local session
  static Future<String> getLocalPlanName() async {
    try {
      final user = await SessionManager.getUser();
      return user?['plan_name'] ?? 'No Plan';
    } catch (e) {
      return 'No Plan';
    }
  }

  /// Check if user has active subscription locally
  static Future<bool> hasActiveSubscription() async {
    try {
      final user = await SessionManager.getUser();
      final status = user?['plan_status'] ?? 'inactive';
      return status == 'active';
    } catch (e) {
      return false;
    }
  }
}
