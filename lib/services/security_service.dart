import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

/// Comprehensive security service for the Sokofiti app
class SecurityService {
  static const String _apiKeyHeader = 'X-API-Key';
  static const String _timestampHeader = 'X-Timestamp';
  static const String _signatureHeader = 'X-Signature';

  // API security keys (in production, these should be from secure storage)
  static const String _apiKey = 'sokofiti_mobile_app_2024';
  static const String _secretKey = 'sk_live_sokofiti_secure_2024';

  /// Generate secure headers for API requests
  static Map<String, String> generateSecureHeaders() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final signature = _generateSignature(timestamp);

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      _apiKeyHeader: _apiKey,
      _timestampHeader: timestamp,
      _signatureHeader: signature,
      'User-Agent': 'SokofitiApp/1.0.0 (${kIsWeb ? 'Web' : 'Mobile'})',
    };
  }

  /// Generate HMAC signature for request authentication
  static String _generateSignature(String timestamp) {
    final message = '$_apiKey:$timestamp';
    final key = utf8.encode(_secretKey);
    final bytes = utf8.encode(message);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  /// Validate API response integrity
  static bool validateResponse(Map<String, dynamic> response) {
    try {
      // Check required fields
      if (!response.containsKey('status') || !response.containsKey('data')) {
        debugPrint('Security: Invalid response structure');
        return false;
      }

      // Check status
      if (response['status'] != 'success' && response['status'] != 'error') {
        debugPrint('Security: Invalid status value');
        return false;
      }

      // Additional validation can be added here
      return true;
    } catch (e) {
      debugPrint('Security: Response validation error: $e');
      return false;
    }
  }

  /// Sanitize user input to prevent injection attacks
  static String sanitizeInput(String input) {
    if (input.isEmpty) return input;

    // Remove potentially dangerous characters
    String sanitized = input
        .replaceAll(RegExp(r'[<>"\x27]'), '')
        .replaceAll(RegExp(r'script', caseSensitive: false), '')
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'data:', caseSensitive: false), '')
        .trim();

    // Limit length
    if (sanitized.length > 1000) {
      sanitized = sanitized.substring(0, 1000);
    }

    return sanitized;
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate phone number format (Kenyan format)
  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^(\+254|0)[17]\d{8}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'\s+'), ''));
  }

  /// Generate secure random token
  static String generateSecureToken([int length = 32]) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(
      length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Hash password securely
  static String hashPassword(String password) {
    final salt = generateSecureToken(16);
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return '$salt:${digest.toString()}';
  }

  /// Verify password against hash
  static bool verifyPassword(String password, String hash) {
    try {
      final parts = hash.split(':');
      if (parts.length != 2) return false;

      final salt = parts[0];
      final expectedHash = parts[1];

      final bytes = utf8.encode(password + salt);
      final digest = sha256.convert(bytes);

      return digest.toString() == expectedHash;
    } catch (e) {
      debugPrint('Security: Password verification error: $e');
      return false;
    }
  }

  /// Check password strength
  static Map<String, dynamic> checkPasswordStrength(String password) {
    int score = 0;
    List<String> feedback = [];

    if (password.length >= 8) {
      score += 1;
    } else {
      feedback.add('Password should be at least 8 characters long');
    }

    if (RegExp(r'[a-z]').hasMatch(password)) {
      score += 1;
    } else {
      feedback.add('Password should contain lowercase letters');
    }

    if (RegExp(r'[A-Z]').hasMatch(password)) {
      score += 1;
    } else {
      feedback.add('Password should contain uppercase letters');
    }

    if (RegExp(r'[0-9]').hasMatch(password)) {
      score += 1;
    } else {
      feedback.add('Password should contain numbers');
    }

    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      score += 1;
    } else {
      feedback.add('Password should contain special characters');
    }

    String strength;
    if (score <= 2) {
      strength = 'weak';
    } else if (score <= 3) {
      strength = 'medium';
    } else if (score <= 4) {
      strength = 'strong';
    } else {
      strength = 'very_strong';
    }

    return {
      'score': score,
      'strength': strength,
      'feedback': feedback,
      'isValid': score >= 3,
    };
  }

  /// Rate limiting check
  static final Map<String, List<int>> _rateLimitMap = {};

  static bool checkRateLimit(
    String identifier, {
    int maxRequests = 10,
    int windowMinutes = 1,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final windowStart = now - (windowMinutes * 60 * 1000);

    _rateLimitMap[identifier] ??= [];

    // Remove old requests outside the window
    _rateLimitMap[identifier]!.removeWhere(
      (timestamp) => timestamp < windowStart,
    );

    // Check if limit exceeded
    if (_rateLimitMap[identifier]!.length >= maxRequests) {
      debugPrint('Security: Rate limit exceeded for $identifier');
      return false;
    }

    // Add current request
    _rateLimitMap[identifier]!.add(now);
    return true;
  }

  /// Log security events
  static void logSecurityEvent(String event, Map<String, dynamic> details) {
    debugPrint('Security Event: $event - ${jsonEncode(details)}');
    // In production, send to security monitoring service
  }

  /// Validate URL to prevent open redirect attacks
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);

      // Only allow HTTPS and specific domains
      if (uri.scheme != 'https') return false;

      final allowedDomains = [
        'sokofiti.ke',
        'www.sokofiti.ke',
        'api.sokofiti.ke',
      ];

      return allowedDomains.contains(uri.host);
    } catch (e) {
      debugPrint('Security: URL validation error: $e');
      return false;
    }
  }

  /// Encrypt sensitive data (simple implementation)
  static String encryptData(String data) {
    // In production, use proper encryption library
    final bytes = utf8.encode(data);
    final encoded = base64.encode(bytes);
    return encoded;
  }

  /// Decrypt sensitive data (simple implementation)
  static String decryptData(String encryptedData) {
    try {
      final decoded = base64.decode(encryptedData);
      return utf8.decode(decoded);
    } catch (e) {
      debugPrint('Security: Decryption error: $e');
      return '';
    }
  }
}
