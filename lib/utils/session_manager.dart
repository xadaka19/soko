import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _userKey = 'user';
  static const String _tokenKey = 'token';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastBiometricLoginKey = 'last_biometric_login';
  static const String _fcmTokenKey = 'fcm_token';

  /// Save user data to local storage
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  /// Get user data from local storage
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userKey);
  }

  /// Validate current session and check if user data is complete
  static Future<bool> isValidSession() async {
    try {
      final user = await getUser();
      if (user == null) return false;

      // Check if essential user data is present
      final hasId = user['id'] != null;
      final hasEmail =
          user['email'] != null && user['email'].toString().isNotEmpty;

      return hasId && hasEmail;
    } catch (e) {
      return false;
    }
  }

  /// Save authentication token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Get authentication token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Clear all session data (logout)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
  }

  /// Get user ID
  static Future<int?> getUserId() async {
    final user = await getUser();
    if (user != null && user['id'] != null) {
      return int.tryParse(user['id'].toString());
    }
    return null;
  }

  /// Get user name
  static Future<String?> getUserName() async {
    final user = await getUser();
    if (user != null) {
      final firstName = user['first_name'] ?? '';
      final lastName = user['last_name'] ?? '';
      return '$firstName $lastName'.trim();
    }
    return null;
  }

  /// Get user email
  static Future<String?> getUserEmail() async {
    final user = await getUser();
    return user?['email'];
  }

  /// Check if biometric authentication is enabled
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Set biometric authentication enabled/disabled
  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  /// Save last biometric login timestamp
  static Future<void> saveLastBiometricLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastBiometricLoginKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Get last biometric login timestamp
  static Future<DateTime?> getLastBiometricLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastBiometricLoginKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Clear biometric settings (on logout)
  static Future<void> clearBiometricSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_biometricEnabledKey);
    await prefs.remove(_lastBiometricLoginKey);
  }

  /// Save FCM token to local storage
  static Future<void> saveFCMToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token);
  }

  /// Get FCM token from local storage
  static Future<String?> getFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fcmTokenKey);
  }

  /// Clear FCM token (on logout)
  static Future<void> clearFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fcmTokenKey);
  }
}
