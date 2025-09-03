import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api.dart';

class ValidationService {
  /// Check if email is already registered
  static Future<bool> isEmailUnique(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/check-email.php'),
            headers: Api.headers,
            body: jsonEncode({'email': email}),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unique'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Email validation error: $e');
      return false;
    }
  }

  /// Check if phone number is already used in listings
  static Future<bool> isPhoneUniqueForListing(String phone) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/check-phone-listing.php'),
            headers: Api.headers,
            body: jsonEncode({'phone': phone}),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unique'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Phone validation error: $e');
      return false;
    }
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate Kenyan phone number format
  static bool isValidKenyanPhone(String phone) {
    // Remove any spaces, dashes, or plus signs
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\+]'), '');

    // Check if it's a valid Kenyan mobile number
    RegExp kenyaMobileRegex = RegExp(r'^254[0-9]{9}$');
    RegExp localMobileRegex = RegExp(r'^0[0-9]{9}$');

    return kenyaMobileRegex.hasMatch(cleaned) ||
        localMobileRegex.hasMatch(cleaned);
  }

  /// Format phone number to international format
  static String formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\+]'), '');

    if (cleaned.startsWith('0')) {
      return '254${cleaned.substring(1)}';
    } else if (cleaned.startsWith('254')) {
      return cleaned;
    }

    return phone; // Return original if format is unclear
  }
}
