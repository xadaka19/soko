import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../utils/session_manager.dart';

class PhoneVerificationService {
  /// Send OTP to phone number for verification
  static Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/verification/send-phone-otp.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': user['id'],
              'phone_number': phoneNumber,
              'token': user['token'],
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Unknown error',
          'verification_id': data['verification_id'],
          'expires_at': data['expires_at'],
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Send OTP error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Verify OTP code
  static Future<Map<String, dynamic>> verifyOTP({
    required String phoneNumber,
    required String otpCode,
    required String verificationId,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/verification/verify-phone-otp.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': user['id'],
              'phone_number': phoneNumber,
              'otp_code': otpCode,
              'verification_id': verificationId,
              'token': user['token'],
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Update user session with verified phone
          await _updateUserPhoneVerificationStatus(phoneNumber, true);
        }
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Unknown error',
          'verified': data['verified'] ?? false,
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Verify OTP error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Check if user's phone number is verified
  static Future<bool> isPhoneVerified() async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) return false;

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/verification/phone-status.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': user['id'],
              'token': user['token'],
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['phone_verified'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Check phone verification status error: $e');
      return false;
    }
  }

  /// Get user's verified phone number
  static Future<String?> getVerifiedPhoneNumber() async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) return null;

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/verification/phone-status.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': user['id'],
              'token': user['token'],
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['phone_verified'] == true) {
          return data['verified_phone_number'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('Get verified phone number error: $e');
      return null;
    }
  }

  /// Update user session with phone verification status
  static Future<void> _updateUserPhoneVerificationStatus(
    String phoneNumber,
    bool isVerified,
  ) async {
    try {
      final user = await SessionManager.getUser();
      if (user != null) {
        user['phone_verified'] = isVerified;
        user['verified_phone_number'] = isVerified ? phoneNumber : null;
        await SessionManager.saveUser(user);
      }
    } catch (e) {
      debugPrint('Update phone verification status error: $e');
    }
  }

  /// Resend OTP (with rate limiting)
  static Future<Map<String, dynamic>> resendOTP({
    required String phoneNumber,
    required String verificationId,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/verification/resend-phone-otp.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': user['id'],
              'phone_number': phoneNumber,
              'verification_id': verificationId,
              'token': user['token'],
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Unknown error',
          'can_resend_at': data['can_resend_at'],
          'attempts_remaining': data['attempts_remaining'],
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Resend OTP error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Format phone number for display
  static String formatPhoneForDisplay(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\+]'), '');
    
    if (cleaned.startsWith('254')) {
      return '+254 ${cleaned.substring(3, 6)} ${cleaned.substring(6, 9)} ${cleaned.substring(9)}';
    } else if (cleaned.startsWith('0')) {
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 7)} ${cleaned.substring(7)}';
    }
    
    return phone;
  }

  /// Validate Kenyan phone number
  static bool isValidKenyanPhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\+]'), '');
    
    RegExp kenyaMobileRegex = RegExp(r'^254[0-9]{9}$');
    RegExp localMobileRegex = RegExp(r'^0[0-9]{9}$');
    
    return kenyaMobileRegex.hasMatch(cleaned) || localMobileRegex.hasMatch(cleaned);
  }

  /// Format phone to international format
  static String formatToInternational(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\+]'), '');
    
    if (cleaned.startsWith('0')) {
      return '254${cleaned.substring(1)}';
    } else if (cleaned.startsWith('254')) {
      return cleaned;
    }
    
    return phone;
  }
}
