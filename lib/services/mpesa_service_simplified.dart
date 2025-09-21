import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../utils/session_manager.dart';

class MpesaServiceSimplified {
  /// Format phone number to M-Pesa format (254XXXXXXXXX)
  static String formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Handle different formats
    if (cleaned.startsWith('254')) {
      return cleaned;
    } else if (cleaned.startsWith('0')) {
      return '254${cleaned.substring(1)}';
    } else if (cleaned.startsWith('7') || cleaned.startsWith('1')) {
      return '254$cleaned';
    }
    
    return cleaned;
  }

  /// Initiate STK Push payment
  static Future<Map<String, dynamic>> initiatePayment({
    required String phoneNumber,
    required double amount,
    required String planId,
    required int userId,
    required String accountReference,
  }) async {
    try {
      // Get user token from session
      final token = await SessionManager.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'User not authenticated. Please login again.',
        };
      }

      // Format phone number
      final formattedPhone = formatPhoneNumber(phoneNumber);

      // Prepare request payload
      final requestData = {
        'token': token,
        'plan_id': planId,
        'phone_number': formattedPhone,
        'amount': amount.toInt(),
        'user_id': userId,
        'account_reference': accountReference,
        'transaction_desc': 'Payment for $accountReference',
      };

      debugPrint('STK Push request: $requestData');

      // Send request to backend
      final response = await http.post(
        Uri.parse('${Api.baseUrl}/api/stk-push.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      debugPrint('STK Push response status: ${response.statusCode}');
      debugPrint('STK Push response: ${response.body}');

      // Parse response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Show customer_message from backend if available
        return {
          'success': data['success'] ?? false,
          'message': data['customer_message'] ?? data['message'] ?? 'Payment failed',
          'checkout_request_id': data['checkout_request_id'],
          'merchant_request_id': data['merchant_request_id'],
          'response_code': data['response_code'],
          'response_description': data['response_description'],
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('STK Push error: $e');
      return {
        'success': false,
        'message': 'Payment failed: Network error',
      };
    }
  }

  /// Check payment status
  static Future<Map<String, dynamic>> checkPaymentStatus({
    required String checkoutRequestId,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      final response = await http.post(
        Uri.parse('${Api.baseUrl}/api/mpesa/query-status.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'checkout_request_id': checkoutRequestId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Status check failed',
          'status': data['status'],
          'result_code': data['result_code'],
          'result_desc': data['result_desc'],
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Payment status check error: $e');
      return {
        'success': false,
        'message': 'Status check failed: Network error',
      };
    }
  }

  /// Save phone number to user session for future use
  static Future<void> savePhoneNumberToSession(String phoneNumber) async {
    try {
      final user = await SessionManager.getUser();
      if (user != null) {
        user['mpesa_phone'] = phoneNumber;
        await SessionManager.saveUser(user);
      }
    } catch (e) {
      debugPrint('Error saving phone number: $e');
    }
  }

  /// Get user-friendly error message
  static String getErrorMessage(String? errorCode, String fallbackMessage) {
    switch (errorCode) {
      case 'INSUFFICIENT_FUNDS':
        return 'Insufficient funds in your M-Pesa account. Please top up and try again.';
      case 'INVALID_PHONE':
        return 'Invalid phone number. Please check and try again.';
      case 'USER_CANCELLED':
        return 'Payment was cancelled. Please try again.';
      case 'TIMEOUT':
        return 'Payment request timed out. Please try again.';
      case 'NETWORK_ERROR':
        return 'Network error. Please check your connection and try again.';
      case 'AUTH_REQUIRED':
        return 'Please login again to continue.';
      default:
        return fallbackMessage.isNotEmpty ? fallbackMessage : 'Payment failed. Please try again.';
    }
  }
}
