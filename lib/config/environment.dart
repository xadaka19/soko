/// Environment configuration for Sokofiti app
/// This file contains environment-specific settings and secrets
class Environment {
  // Environment type
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  );

  // Google Sign-In Client ID
  static const String googleSignInClientId = String.fromEnvironment(
    'GOOGLE_SIGNIN_CLIENT_ID',
    defaultValue:
        '288767792538-5p2tlebpnbig2593tiel6be5qdnmssop.apps.googleusercontent.com',
  );

  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';

  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://sokofiti.ke',
  );

  // M-Pesa Configuration
  static const String mpesaHmacSecret = String.fromEnvironment(
    'MPESA_HMAC_SECRET',
    defaultValue: 'sokofiti_secure_hmac_key_2024_v1',
  );

  static const String mpesaConsumerKey = String.fromEnvironment(
    'MPESA_CONSUMER_KEY',
    defaultValue: '',
  );

  static const String mpesaConsumerSecret = String.fromEnvironment(
    'MPESA_CONSUMER_SECRET',
    defaultValue: '',
  );

  static const String mpesaShortcode = String.fromEnvironment(
    'MPESA_SHORTCODE',
    defaultValue: '',
  );

  static const String mpesaPasskey = String.fromEnvironment(
    'MPESA_PASSKEY',
    defaultValue: '',
  );

  // Firebase Configuration
  static const String firebaseWebApiKey = String.fromEnvironment(
    'FIREBASE_WEB_API_KEY',
    defaultValue: 'AIzaSyAqK2VYsRaBG4tgrz5rW2QIArC8JLzit1I',
  );

  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'sokofiti-2d6ca',
  );

  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '288767792538',
  );

  static const String firebaseAppId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '1:288767792538:android:e005df3bd503e76d2b5623',
  );

  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'sokofiti-2d6ca.firebasestorage.app',
  );

  // Security Configuration
  static const String appSecretKey = String.fromEnvironment(
    'APP_SECRET_KEY',
    defaultValue: 'sokofiti_app_secret_2024',
  );

  static const String encryptionKey = String.fromEnvironment(
    'ENCRYPTION_KEY',
    defaultValue: 'sokofiti_encryption_key_32_chars',
  );

  // Feature Flags
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );

  static const bool enableCrashReporting = bool.fromEnvironment(
    'ENABLE_CRASH_REPORTING',
    defaultValue: true,
  );

  static const bool enablePushNotifications = bool.fromEnvironment(
    'ENABLE_PUSH_NOTIFICATIONS',
    defaultValue: true,
  );

  static const bool enableBiometricAuth = bool.fromEnvironment(
    'ENABLE_BIOMETRIC_AUTH',
    defaultValue: true,
  );

  // Rate Limiting Configuration
  static const int maxRequestsPerMinute = int.fromEnvironment(
    'MAX_REQUESTS_PER_MINUTE',
    defaultValue: 60,
  );

  static const int maxLoginAttempts = int.fromEnvironment(
    'MAX_LOGIN_ATTEMPTS',
    defaultValue: 5,
  );

  static const int sessionTimeoutMinutes = int.fromEnvironment(
    'SESSION_TIMEOUT_MINUTES',
    defaultValue: 30,
  );

  // Cache Configuration
  static const int cacheExpiryHours = int.fromEnvironment(
    'CACHE_EXPIRY_HOURS',
    defaultValue: 24,
  );

  static const int maxCacheSize = int.fromEnvironment(
    'MAX_CACHE_SIZE_MB',
    defaultValue: 100,
  );

  // Image Configuration
  static const int maxImageSizeMB = int.fromEnvironment(
    'MAX_IMAGE_SIZE_MB',
    defaultValue: 5,
  );

  static const int imageQuality = int.fromEnvironment(
    'IMAGE_QUALITY',
    defaultValue: 85,
  );

  static const int maxImagesPerListing = int.fromEnvironment(
    'MAX_IMAGES_PER_LISTING',
    defaultValue: 10,
  );

  // Search Configuration
  static const int searchResultsPerPage = int.fromEnvironment(
    'SEARCH_RESULTS_PER_PAGE',
    defaultValue: 20,
  );

  static const int maxSearchHistoryItems = int.fromEnvironment(
    'MAX_SEARCH_HISTORY_ITEMS',
    defaultValue: 20,
  );

  // Notification Configuration
  static const int maxNotificationsPerDay = int.fromEnvironment(
    'MAX_NOTIFICATIONS_PER_DAY',
    defaultValue: 5,
  );

  static const int notificationRetryAttempts = int.fromEnvironment(
    'NOTIFICATION_RETRY_ATTEMPTS',
    defaultValue: 3,
  );

  // Verification Configuration
  static const int minSpendingForVerification = int.fromEnvironment(
    'MIN_SPENDING_FOR_VERIFICATION',
    defaultValue: 5000,
  );

  static const int verificationProcessingDays = int.fromEnvironment(
    'VERIFICATION_PROCESSING_DAYS',
    defaultValue: 3,
  );

  // Auto-renewal Configuration
  static const Map<String, int> autoRenewalIntervals = {
    'free': 48, // 48 hours
    'starter': 12, // 12 hours
    'basic': 10, // 10 hours
    'premium': 8, // 8 hours
    'business': 6, // 6 hours
    'top_featured': 16, // 16 hours
    'top': 24, // 24 hours
  };

  // Debug Configuration
  static const bool enableDebugMode = bool.fromEnvironment(
    'ENABLE_DEBUG_MODE',
    defaultValue: false,
  );

  static const bool enableVerboseLogging = bool.fromEnvironment(
    'ENABLE_VERBOSE_LOGGING',
    defaultValue: false,
  );

  static const bool enablePerformanceMonitoring = bool.fromEnvironment(
    'ENABLE_PERFORMANCE_MONITORING',
    defaultValue: true,
  );

  // Helper methods
  static String get currentEnvironment => environment;

  static Map<String, dynamic> get environmentInfo => {
    'environment': environment,
    'api_base_url': apiBaseUrl,
    'firebase_project_id': firebaseProjectId,
    'enable_analytics': enableAnalytics,
    'enable_push_notifications': enablePushNotifications,
    'debug_mode': enableDebugMode,
  };

  /// Validate that all required environment variables are set
  static bool validateEnvironment() {
    if (isProduction) {
      // In production, ensure critical secrets are not using defaults
      if (mpesaHmacSecret == 'sokofiti_secure_hmac_key_2024_v1') {
        throw Exception('Production MPESA_HMAC_SECRET must be set');
      }
      if (appSecretKey == 'sokofiti_app_secret_2024') {
        throw Exception('Production APP_SECRET_KEY must be set');
      }
    }
    return true;
  }

  /// Get configuration for current environment
  static Map<String, dynamic> getConfig() {
    return {
      'api': {'base_url': apiBaseUrl, 'timeout_seconds': 30, 'max_retries': 3},
      'security': {
        'hmac_secret': mpesaHmacSecret,
        'app_secret': appSecretKey,
        'encryption_key': encryptionKey,
        'max_login_attempts': maxLoginAttempts,
        'session_timeout_minutes': sessionTimeoutMinutes,
      },
      'features': {
        'analytics': enableAnalytics,
        'crash_reporting': enableCrashReporting,
        'push_notifications': enablePushNotifications,
        'biometric_auth': enableBiometricAuth,
      },
      'limits': {
        'max_requests_per_minute': maxRequestsPerMinute,
        'max_image_size_mb': maxImageSizeMB,
        'max_images_per_listing': maxImagesPerListing,
        'search_results_per_page': searchResultsPerPage,
        'max_notifications_per_day': maxNotificationsPerDay,
      },
    };
  }
}
