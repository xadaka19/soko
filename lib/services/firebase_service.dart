import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../firebase_options.dart';
import '../utils/session_manager.dart';

/// Firebase service for web and mobile compatibility
class FirebaseService {
  static FirebaseAnalytics? _analytics;
  static FirebaseMessaging? _messaging;
  static FlutterLocalNotificationsPlugin? _localNotifications;
  static bool _isInitialized = false;
  static bool _notificationsInitialized = false;

  /// Initialize Firebase services
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase Core
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase Core initialized');

      // Initialize Firebase Analytics
      await _initializeAnalytics();

      // Initialize Firebase Messaging and Notifications
      await _initializeNotifications();

      _isInitialized = true;
      debugPrint('Firebase services initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase services: $e');
      // Don't throw - allow app to continue without Firebase
    }
  }

  /// Initialize Firebase Analytics
  static Future<void> _initializeAnalytics() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      await _analytics!.setAnalyticsCollectionEnabled(true);
      debugPrint('Firebase Analytics initialized');
    } catch (e) {
      debugPrint('Error initializing Firebase Analytics: $e');
    }
  }

  /// Initialize Firebase Messaging and Local Notifications
  static Future<void> _initializeNotifications() async {
    if (_notificationsInitialized) return;

    try {
      // Initialize Firebase Messaging
      _messaging = FirebaseMessaging.instance;

      // Request notification permissions automatically
      await requestNotificationPermissions();

      // Initialize local notifications for foreground messages
      await _initializeLocalNotifications();

      // Set up message handlers
      await _setupMessageHandlers();

      _notificationsInitialized = true;
      debugPrint('Firebase Messaging and Notifications initialized');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  /// Request notification permissions automatically
  static Future<void> requestNotificationPermissions() async {
    try {
      if (_messaging == null) return;

      // Request permission for notifications
      NotificationSettings settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint(
        'Notification permission status: ${settings.authorizationStatus}',
      );

      // Save FCM token for the user
      await _saveFCMToken();
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  /// Initialize local notifications for foreground messages
  static Future<void> _initializeLocalNotifications() async {
    try {
      _localNotifications = FlutterLocalNotificationsPlugin();

      // Android initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      // Combined initialization settings
      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _localNotifications!.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      debugPrint('Local notifications initialized');
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }
  }

  /// Set up message handlers for foreground and background notifications
  static Future<void> _setupMessageHandlers() async {
    try {
      if (_messaging == null) return;

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background message taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

      // Handle app launch from terminated state
      RemoteMessage? initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessageTap(initialMessage);
      }

      debugPrint('Message handlers set up');
    } catch (e) {
      debugPrint('Error setting up message handlers: $e');
    }
  }

  /// Handle foreground messages by showing local notification
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      debugPrint('Received foreground message: ${message.messageId}');

      // Show local notification for foreground messages
      await _showLocalNotification(message);
    } catch (e) {
      debugPrint('Error handling foreground message: $e');
    }
  }

  /// Handle background message tap
  static void _handleBackgroundMessageTap(RemoteMessage message) {
    try {
      debugPrint('Background message tapped: ${message.messageId}');

      // Navigate to appropriate screen based on message data
      _navigateFromNotification(message.data);
    } catch (e) {
      debugPrint('Error handling background message tap: $e');
    }
  }

  /// Show local notification for foreground messages
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      if (_localNotifications == null) return;

      // Create notification details
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'sokofiti_channel',
            'SokoFiti Notifications',
            channelDescription: 'Notifications for SokoFiti app',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show notification
      await _localNotifications!.show(
        message.hashCode,
        message.notification?.title ?? 'SokoFiti',
        message.notification?.body ?? 'You have a new notification',
        notificationDetails,
        payload: message.data.toString(),
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    try {
      debugPrint('Notification tapped: ${response.payload}');

      // Parse payload and navigate
      if (response.payload != null) {
        try {
          // Parse the payload as JSON-like string
          final payload = response.payload!;
          debugPrint('Notification payload: $payload');

          // For now, just log the payload
          // Navigation will be handled by the app's navigation system
          // when the user taps the notification
        } catch (e) {
          debugPrint('Error parsing notification payload: $e');
        }
      }
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  /// Navigate from notification based on data
  static void _navigateFromNotification(Map<String, dynamic> data) {
    try {
      final type = data['type'];

      switch (type) {
        case 'similar_ad_recommendation':
          // Navigate to listing detail
          final listingId = data['listing_id'];
          debugPrint('Navigate to listing: $listingId');
          break;
        case 'new_message':
          // Navigate to chat
          final conversationId = data['conversation_id'];
          debugPrint('Navigate to chat: $conversationId');
          break;
        case 'price_drop':
          // Navigate to listing detail
          final listingId = data['listing_id'];
          debugPrint('Navigate to price drop listing: $listingId');
          break;
        default:
          debugPrint('Unknown notification type: $type');
      }
    } catch (e) {
      debugPrint('Error navigating from notification: $e');
    }
  }

  /// Save FCM token for the current user
  static Future<void> _saveFCMToken() async {
    try {
      if (_messaging == null) return;

      final token = await _messaging!.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');

        // Save token to user session and send to server
        final user = await SessionManager.getUser();
        if (user != null) {
          await _sendTokenToServer(token, user['id'].toString());
        } else {
          // Save token locally for when user logs in
          await SessionManager.saveFCMToken(token);
        }
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Send FCM token to server
  static Future<void> _sendTokenToServer(String token, String userId) async {
    try {
      // Send token to server API
      final response = await http.post(
        Uri.parse('https://sokofiti.ke/api/save-fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'fcm_token': token,
          'platform': kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : 'ios'),
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM token saved to server successfully');
      } else {
        debugPrint(
          'Failed to save FCM token to server: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error sending FCM token to server: $e');
    }
  }

  /// Get Firebase Analytics instance
  static FirebaseAnalytics? get analytics => _analytics;

  /// Log an event to Firebase Analytics
  static Future<void> logEvent(
    String name,
    Map<String, dynamic>? parameters,
  ) async {
    try {
      // Convert dynamic values to Object for Firebase Analytics
      final Map<String, Object>? convertedParams = parameters?.map(
        (key, value) => MapEntry(key, value as Object),
      );
      await _analytics?.logEvent(name: name, parameters: convertedParams);
    } catch (e) {
      debugPrint('Error logging event: $e');
    }
  }

  /// Track screen view
  static Future<void> trackScreenView(String screenName) async {
    try {
      await _analytics?.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint('Error tracking screen view: $e');
    }
  }

  /// Log error (compatible with existing code)
  static Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? customKeys,
  }) async {
    try {
      debugPrint('Error logged: $error');
      if (reason != null) {
        debugPrint('Reason: $reason');
      }
      if (customKeys != null) {
        debugPrint('Custom keys: $customKeys');
      }
      // In production, you might send this to a logging service
    } catch (e) {
      debugPrint('Error logging error: $e');
    }
  }

  /// Start trace (compatible with existing code)
  static dynamic startTrace(String name) {
    debugPrint('Starting trace: $name');
    return DateTime.now(); // Return timestamp as simple trace
  }

  /// Stop trace (compatible with existing code)
  static Future<void> stopTrace(dynamic trace) async {
    if (trace is DateTime) {
      final duration = DateTime.now().difference(trace);
      debugPrint('Trace completed in ${duration.inMilliseconds}ms');
    }
  }

  /// Subscribe to topic (compatible with existing code)
  static Future<void> subscribeToTopic(String topic) async {
    debugPrint('Subscribing to topic: $topic');
    // In production, you might use Firebase Cloud Messaging
  }

  /// Unsubscribe from topic (compatible with existing code)
  static Future<void> unsubscribeFromTopic(String topic) async {
    debugPrint('Unsubscribing from topic: $topic');
    // In production, you might use Firebase Cloud Messaging
  }

  /// Log message (compatible with existing code)
  static Future<void> logMessage(String message) async {
    debugPrint('Firebase message: $message');
  }

  /// Set crash user info (compatible with existing code)
  static Future<void> setCrashUserInfo({
    String? userId,
    String? email,
    String? name,
    Map<String, dynamic>? customAttributes,
    Map<String, dynamic>? customKeys,
  }) async {
    debugPrint('Setting crash user info for: $userId');
    if (customKeys != null) {
      debugPrint('Custom keys: $customKeys');
    }
  }

  /// Test crash (compatible with existing code)
  static void testCrash() {
    if (kDebugMode) {
      debugPrint('Test crash initiated');
    }
  }
}
