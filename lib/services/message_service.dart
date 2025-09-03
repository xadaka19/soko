import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../utils/session_manager.dart';
import 'crash_reporting_service.dart';
import 'firebase_service.dart';

class MessageService {
  // Real-time message listeners
  static final Map<String, StreamController<List<dynamic>>> _messageStreams =
      {};
  static Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 5);

  /// Get inbox messages for a user with real-time updates
  static Future<List<dynamic>> getInbox(int userId) async {
    final trace = FirebaseService.startTrace('get_inbox');

    try {
      CrashReportingService.addBreadcrumb('Getting inbox for user: $userId');

      final user = await SessionManager.getUser();
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/messages/inbox.php'),
            headers: Api.headers,
            body: jsonEncode({'user_id': userId, 'token': user['token']}),
          )
          .timeout(Api.timeout);

      await FirebaseService.stopTrace(trace);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          CrashReportingService.addBreadcrumb(
            'Inbox loaded: ${data['messages']?.length ?? 0} messages',
          );
          return data['messages'] ?? [];
        } else {
          throw Exception(data['message'] ?? 'Failed to get inbox');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      await FirebaseService.stopTrace(trace);

      await CrashReportingService.logError(
        e,
        stackTrace,
        reason: 'Get inbox failed',
      );
      await CrashReportingService.recordNetworkError(
        url: '${Api.baseUrl}/api/messages/inbox.php',
        method: 'POST',
        errorMessage: e.toString(),
        additionalData: {'user_id': userId},
      );

      debugPrint('Get inbox error: $e');
      rethrow;
    }
  }

  /// Get message thread between two users with enhanced error handling
  static Future<List<dynamic>> getThread(int userId, int otherUserId) async {
    final trace = FirebaseService.startTrace('get_thread');

    try {
      CrashReportingService.addBreadcrumb(
        'Getting thread: $userId <-> $otherUserId',
      );

      final user = await SessionManager.getUser();
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/messages/thread.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': userId,
              'other_user_id': otherUserId,
              'token': user['token'],
            }),
          )
          .timeout(Api.timeout);

      await FirebaseService.stopTrace(trace);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          CrashReportingService.addBreadcrumb(
            'Thread loaded: ${data['messages']?.length ?? 0} messages',
          );
          return data['messages'] ?? [];
        } else {
          throw Exception(data['message'] ?? 'Failed to get thread');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      await FirebaseService.stopTrace(trace);

      await CrashReportingService.logError(
        e,
        stackTrace,
        reason: 'Get thread failed',
      );
      await CrashReportingService.recordNetworkError(
        url: '${Api.baseUrl}/api/messages/thread.php',
        method: 'POST',
        errorMessage: e.toString(),
        additionalData: {'user_id': userId, 'other_user_id': otherUserId},
      );

      debugPrint('Get thread error: $e');
      rethrow;
    }
  }

  /// Send a message with enhanced tracking and error handling
  static Future<bool> sendMessage(
    int senderId,
    int receiverId,
    String message,
  ) async {
    final trace = FirebaseService.startTrace('send_message');

    try {
      CrashReportingService.addBreadcrumb(
        'Sending message: $senderId -> $receiverId',
      );

      final user = await SessionManager.getUser();
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/messages/send.php'),
            headers: Api.headers,
            body: jsonEncode({
              'sender_id': senderId,
              'receiver_id': receiverId,
              'message': message,
              'token': user['token'],
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(Api.timeout);

      await FirebaseService.stopTrace(trace);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          CrashReportingService.addBreadcrumb('Message sent successfully');

          // Track message sent analytics
          await FirebaseService.logEvent('message_sent', {
            'sender_id': senderId.toString(),
            'receiver_id': receiverId.toString(),
            'message_length': message.length,
          });

          return true;
        } else {
          throw Exception(data['message'] ?? 'Failed to send message');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      await FirebaseService.stopTrace(trace);

      await CrashReportingService.logError(
        e,
        stackTrace,
        reason: 'Send message failed',
      );
      await CrashReportingService.recordNetworkError(
        url: '${Api.baseUrl}/api/messages/send.php',
        method: 'POST',
        errorMessage: e.toString(),
        additionalData: {
          'sender_id': senderId,
          'receiver_id': receiverId,
          'message_length': message.length,
        },
      );

      debugPrint('Send message error: $e');
      return false;
    }
  }

  /// Mark message as read
  static Future<bool> markAsRead(int messageId, int userId) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/mark-message-read.php'),
            headers: Api.headers,
            body: jsonEncode({'message_id': messageId, 'user_id': userId}),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Mark as read error: $e');
      return false;
    }
  }

  /// Get unread message count
  static Future<int> getUnreadCount(int userId) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/get-unread-count.php'),
            headers: Api.headers,
            body: jsonEncode({'user_id': userId}),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ? (data['count'] ?? 0) : 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Get unread count error: $e');
      return 0;
    }
  }

  /// Get real-time message stream for a conversation
  static Stream<List<dynamic>> getMessageStream(int userId, int otherUserId) {
    final streamKey = '${userId}_$otherUserId';

    if (!_messageStreams.containsKey(streamKey)) {
      _messageStreams[streamKey] = StreamController<List<dynamic>>.broadcast();
      _startPollingForMessages(userId, otherUserId, streamKey);
    }

    return _messageStreams[streamKey]!.stream;
  }

  /// Start polling for new messages
  static void _startPollingForMessages(
    int userId,
    int otherUserId,
    String streamKey,
  ) {
    _pollingTimer?.cancel();

    _pollingTimer = Timer.periodic(_pollingInterval, (timer) async {
      try {
        final messages = await getThread(userId, otherUserId);
        if (_messageStreams.containsKey(streamKey) &&
            !_messageStreams[streamKey]!.isClosed) {
          _messageStreams[streamKey]!.add(messages);
        }
      } catch (e) {
        debugPrint('Polling error: $e');
        if (_messageStreams.containsKey(streamKey) &&
            !_messageStreams[streamKey]!.isClosed) {
          _messageStreams[streamKey]!.addError(e);
        }
      }
    });
  }

  /// Stop message stream
  static void stopMessageStream(int userId, int otherUserId) {
    final streamKey = '${userId}_$otherUserId';

    if (_messageStreams.containsKey(streamKey)) {
      _messageStreams[streamKey]!.close();
      _messageStreams.remove(streamKey);
    }

    if (_messageStreams.isEmpty) {
      _pollingTimer?.cancel();
      _pollingTimer = null;
    }
  }

  /// Cleanup all streams and timers
  static void dispose() {
    _pollingTimer?.cancel();
    _pollingTimer = null;

    for (final stream in _messageStreams.values) {
      stream.close();
    }
    _messageStreams.clear();

    CrashReportingService.addBreadcrumb('MessageService disposed');
  }
}
