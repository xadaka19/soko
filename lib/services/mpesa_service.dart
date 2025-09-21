import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
// import 'package:device_info_plus/device_info_plus.dart'; // Removed for web compatibility
import '../config/api.dart';
import '../config/environment.dart';
import '../utils/session_manager.dart';

class MpesaService {
  // Security constants from environment
  static String get _hmacSecret => Environment.mpesaHmacSecret;
  static int get _maxRequestsPerMinute => Environment.maxRequestsPerMinute;
  static const int _maxFailedAttempts = 5;
  static const Duration _banDuration = Duration(hours: 1);

  // Rate limiting and security storage
  static final Map<String, List<DateTime>> _requestHistory = {};
  static final Map<String, int> _failedAttempts = {};
  static final Set<String> _bannedIPs = {};
  static final Map<String, DateTime> _banTimestamps = {};

  /// Generate HMAC signature (kept for callback validation)
  static String _generateHMACSignature(String data) {
    final key = utf8.encode(_hmacSecret);
    final bytes = utf8.encode(data);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
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

  /// Check rate limiting
  static bool _checkRateLimit(String identifier) {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));

    // Clean old requests
    _requestHistory[identifier]?.removeWhere(
      (time) => time.isBefore(oneMinuteAgo),
    );

    // Check current request count
    final currentRequests = _requestHistory[identifier]?.length ?? 0;
    if (currentRequests >= _maxRequestsPerMinute) {
      return false;
    }

    // Add current request
    _requestHistory[identifier] ??= [];
    _requestHistory[identifier]!.add(now);

    return true;
  }

  /// Check if IP is banned
  static bool _isIPBanned(String ip) {
    if (!_bannedIPs.contains(ip)) return false;

    final banTime = _banTimestamps[ip];
    if (banTime != null && DateTime.now().difference(banTime) > _banDuration) {
      // Ban expired, remove from banned list
      _bannedIPs.remove(ip);
      _banTimestamps.remove(ip);
      return false;
    }

    return true;
  }

  /// Record failed attempt
  static void _recordFailedAttempt(String identifier) {
    _failedAttempts[identifier] = (_failedAttempts[identifier] ?? 0) + 1;

    if (_failedAttempts[identifier]! >= _maxFailedAttempts) {
      // Auto-ban after max failed attempts
      _bannedIPs.add(identifier);
      _banTimestamps[identifier] = DateTime.now();
      debugPrint('Auto-banned IP: $identifier for excessive failed attempts');
    }
  }

  /// Validate request integrity
  static bool _validateRequestIntegrity(
    Map<String, dynamic> data,
    String signature,
  ) {
    final dataString = jsonEncode(data);
    final expectedSignature = _generateHMACSignature(dataString);
    return signature == expectedSignature;
  }

  /// Validate callback request from M-Pesa
  static bool validateCallback(
    Map<String, dynamic> callbackData,
    String receivedSignature,
  ) {
    return _validateRequestIntegrity(callbackData, receivedSignature);
  }

  /// Initiate STK Push payment with enhanced security
  static Future<Map<String, dynamic>> initiatePayment({
    required String phoneNumber,
    required double amount,
    required String planId,
    required int userId,
    required String accountReference,
  }) async {
    try {
      // Get user token from session
      final user = await SessionManager.getUser();
      final token = await SessionManager.getToken();

      if (user == null || token == null) {
        return {
          'success': false,
          'message': 'User not authenticated. Please login again.',
          'error_code': 'AUTH_REQUIRED',
        };
      }

      // Get device fingerprint for security
      final deviceFingerprint = await _getDeviceFingerprint();

      // Check rate limiting
      if (!_checkRateLimit(phoneNumber)) {
        return {
          'success': false,
          'message': 'Too many requests. Please wait before trying again.',
          'error_code': 'RATE_LIMIT_EXCEEDED',
        };
      }

      // Check if device/IP is banned
      if (_isIPBanned(deviceFingerprint)) {
        return {
          'success': false,
          'message': 'Access temporarily restricted. Please contact support.',
          'error_code': 'ACCESS_RESTRICTED',
        };
      }

      // Prepare request data in the format expected by backend
      final requestData = {
        'token': token,
        'plan_id': planId,
        'phone_number': phoneNumber,
        'amount': amount.toInt(), // Backend expects integer
        'user_id': userId, // Add missing user_id field
        'account_reference': accountReference,
        'transaction_desc': 'Payment for $accountReference',
      };

      debugPrint('STK Push request data: $requestData');
      debugPrint('STK Push URL: ${Api.baseUrl}/api/stk-push.php');
      debugPrint('STK Push headers: ${Api.headers}');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/stk-push.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestData),
          )
          .timeout(Api.timeout);

      debugPrint('STK Push response status: ${response.statusCode}');
      debugPrint('STK Push response headers: ${response.headers}');
      debugPrint('STK Push response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final success = data['success'] ?? false;

        if (!success) {
          // Record failed attempt for security monitoring
          _recordFailedAttempt(deviceFingerprint);
        }

        return {
          'success': success,
          'message':
              data['customer_message'] ?? data['message'] ?? 'Unknown error',
          'checkout_request_id': data['checkout_request_id'],
          'merchant_request_id': data['merchant_request_id'],
          'response_code': data['response_code'],
          'response_description': data['response_description'],
          'customer_message': data['customer_message'],
        };
      } else {
        // Record failed attempt for security monitoring
        _recordFailedAttempt(deviceFingerprint);

        return {
          'success': false,
          'message': 'Server error: ${response.statusCode} - ${response.body}',
          'error_code': 'SERVER_ERROR',
        };
      }
    } catch (e) {
      debugPrint('M-Pesa payment error: $e');

      // Record failed attempt for security monitoring
      final deviceFingerprint = await _getDeviceFingerprint();
      _recordFailedAttempt(deviceFingerprint);

      return {
        'success': false,
        'message': 'Payment failed: Network error - $e',
        'error_code': 'NETWORK_ERROR',
      };
    }
  }

  /// Check payment status
  static Future<Map<String, dynamic>> checkPaymentStatus({
    required String checkoutRequestId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/query-status.php'),
            headers: Api.headers,
            body: jsonEncode({'checkout_request_id': checkoutRequestId}),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Unknown error',
          'result_code': data['result_code'],
          'result_desc': data['result_desc'],
          'transaction_id': data['transaction_id'],
          'amount': data['amount'],
          'phone_number': data['phone_number'],
          'payment_status':
              data['payment_status'], // 'pending', 'completed', 'failed', 'cancelled'
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

  /// Get payment history for user
  static Future<List<Map<String, dynamic>>> getPaymentHistory({
    required int userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('${Api.baseUrl}/api/payment-history.php').replace(
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
          return List<Map<String, dynamic>>.from(data['payments'] ?? []);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Get payment history error: $e');
      return [];
    }
  }

  /// Validate phone number for M-Pesa
  static bool isValidMpesaNumber(String phoneNumber) {
    // Remove any spaces, dashes, or plus signs
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\+]'), '');

    // Check if it's a valid Kenyan mobile number
    // Safaricom: 254700000000-254799999999, 254710000000-254719999999
    // Airtel: 254730000000-254739999999, 254750000000-254759999999
    // Telkom: 254770000000-254779999999

    RegExp kenyaMobileRegex = RegExp(r'^254(7[0-9]{8}|1[0-9]{8})$');

    if (kenyaMobileRegex.hasMatch(cleaned)) {
      return true;
    }

    // Also accept numbers starting with 07 or 01 (will be converted to 254 format)
    RegExp localMobileRegex = RegExp(r'^0(7[0-9]{8}|1[0-9]{8})$');
    return localMobileRegex.hasMatch(cleaned);
  }

  /// Format phone number to M-Pesa format (254XXXXXXXXX)
  static String formatPhoneNumber(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\+]'), '');

    if (cleaned.startsWith('254')) {
      return cleaned;
    } else if (cleaned.startsWith('0')) {
      return '254${cleaned.substring(1)}';
    } else if (cleaned.length == 9) {
      return '254$cleaned';
    }

    return cleaned;
  }

  /// Save phone number to user session for future use
  static Future<void> savePhoneNumberToSession(String phoneNumber) async {
    try {
      // Import SessionManager at the top of the file
      final user = await SessionManager.getUser();
      if (user != null) {
        user['mpesa_phone'] = phoneNumber;
        await SessionManager.saveUser(user);
      }
    } catch (e) {
      // Silently fail - not critical
      debugPrint('Failed to save phone number: $e');
    }
  }

  /// Get formatted error message for user display
  static String getErrorMessage(String? errorCode, String? errorDesc) {
    if (errorCode == null || errorDesc == null) {
      return 'Payment failed. Please try again.';
    }

    switch (errorCode) {
      case '1':
        return 'Insufficient funds in your M-Pesa account.';
      case '1032':
        return 'Payment was cancelled by user.';
      case '1037':
        return 'Payment request timed out. Please try again.';
      case '2001':
        return 'Invalid phone number. Please check and try again.';
      case '2006':
        return 'M-Pesa service is temporarily unavailable.';
      default:
        return errorDesc.isNotEmpty
            ? errorDesc
            : 'Payment failed. Please try again.';
    }
  }
}
