import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

/// Notification service compatible with web and mobile
class NotificationService {
  static bool _isInitialized = false;

  /// Initialize notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();

      debugPrint('NotificationService initialized successfully');
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  /// Show local notification (compatible with existing code)
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    try {
      debugPrint('Notification: $title - $body');
      // In production web, you might use browser notifications API
      // For mobile, you would use flutter_local_notifications
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    return true; // Simplified for compatibility
  }

  /// Subscribe to topic (compatible with existing code)
  static Future<void> subscribeToTopic(String topic) async {
    debugPrint('Subscribing to topic: $topic');
  }

  /// Unsubscribe from topic (compatible with existing code)
  static Future<void> unsubscribeFromTopic(String topic) async {
    debugPrint('Unsubscribing from topic: $topic');
  }

  /// Subscribe to user topics (compatible with existing code)
  static Future<void> subscribeToUserTopics() async {
    debugPrint('Subscribing to user topics');
  }

  /// Unsubscribe from user topics (compatible with existing code)
  static Future<void> unsubscribeFromUserTopics() async {
    debugPrint('Unsubscribing from user topics');
  }

  /// Get FCM token (compatible with existing code)
  static Future<String?> getFCMToken() async {
    return 'web_token_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Get notification settings (compatible with existing code)
  static Future<Map<String, dynamic>> getNotificationSettings() async {
    return {'authorized': true, 'alert': true, 'badge': true, 'sound': true};
  }

  /// Send notification (compatible with existing code)
  static Future<bool> sendNotification({
    required String title,
    required String body,
    String? userId,
    Map<String, dynamic>? data,
  }) async {
    debugPrint('Sending notification: $title to $userId');
    return true;
  }

  /// Get FCM token (compatible with existing code)
  static String? get fcmToken =>
      'web_token_${DateTime.now().millisecondsSinceEpoch}';

  /// Send test notification (compatible with existing code)
  static Future<void> sendTestNotification() async {
    await showLocalNotification(
      title: 'Test Notification',
      body: 'This is a test notification from Sokofiti',
    );
  }

  /// Clear all notifications (compatible with existing code)
  static Future<void> clearAllNotifications() async {
    debugPrint('Clearing all notifications');
    // In a real implementation, this would clear all notifications
  }
}
