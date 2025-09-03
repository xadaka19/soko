import 'package:flutter/foundation.dart';
import 'environment.dart';

/// Web-specific configuration handler
class WebConfig {
  static bool _isInitialized = false;
  static Map<String, String> _config = {};

  /// Initialize web configuration
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        // For web, we'll use the environment variables from build time
        // or fallback to default values from Environment class
        _config = {
          'API_BASE_URL': Environment.apiBaseUrl,
          'FIREBASE_PROJECT_ID': Environment.firebaseProjectId,
          'FIREBASE_WEB_API_KEY': Environment.firebaseWebApiKey,
          'FIREBASE_MESSAGING_SENDER_ID': Environment.firebaseMessagingSenderId,
          'FIREBASE_APP_ID': Environment.firebaseAppId,
          'FIREBASE_STORAGE_BUCKET': Environment.firebaseStorageBucket,
          'GOOGLE_SIGNIN_CLIENT_ID': Environment.googleSignInClientId,
        };

        debugPrint('Web configuration initialized');
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing web config: $e');
      _isInitialized = true; // Don't block app startup
    }
  }

  /// Get configuration value
  static String get(String key, {String defaultValue = ''}) {
    if (!_isInitialized) {
      debugPrint('Warning: WebConfig not initialized, using default values');
    }
    return _config[key] ?? defaultValue;
  }

  /// Check if running in web environment
  static bool get isWeb => kIsWeb;

  /// Get API base URL for web
  static String get apiBaseUrl => get('API_BASE_URL', defaultValue: Environment.apiBaseUrl);

  /// Get Firebase project ID for web
  static String get firebaseProjectId => get('FIREBASE_PROJECT_ID', defaultValue: Environment.firebaseProjectId);

  /// Check if configuration is valid
  static bool get isConfigValid {
    if (!kIsWeb) return true;
    
    // Check if essential configuration is present
    final essentialKeys = [
      'API_BASE_URL',
      'FIREBASE_PROJECT_ID',
      'FIREBASE_WEB_API_KEY',
    ];

    for (final key in essentialKeys) {
      final value = _config[key];
      if (value == null || value.isEmpty || value.contains('XXXXXXXXXX')) {
        debugPrint('Invalid or missing configuration for: $key');
        return false;
      }
    }

    return true;
  }

  /// Get all configuration for debugging
  static Map<String, String> getAllConfig() {
    return Map.from(_config);
  }
}
