import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/session_manager.dart';

class MessagingService {
  static const String baseUrl = 'https://sokofiti.ke/api';

  // Get all conversations for a user
  static Future<Map<String, dynamic>> getConversations() async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) {
        return {
          'success': false,
          'message': 'User not logged in',
          'conversations': [],
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/messages/conversations?user_id=${user['id']}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'conversations': data['conversations'] ?? [],
          'total_unread': data['total_unread'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load conversations',
          'conversations': [],
        };
      }
    } catch (e) {
      debugPrint('Error getting conversations: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'conversations': [],
      };
    }
  }

  // Get messages for a specific conversation
  static Future<Map<String, dynamic>> getMessages({
    required String conversationId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) {
        return {
          'success': false,
          'message': 'User not logged in',
          'messages': [],
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/messages/$conversationId?page=$page&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'messages': data['messages'] ?? [],
          'has_more': data['has_more'] ?? false,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load messages',
          'messages': [],
        };
      }
    } catch (e) {
      debugPrint('Error getting messages: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'messages': [],
      };
    }
  }

  // Send a message
  static Future<Map<String, dynamic>> sendMessage({
    required String recipientId,
    required String message,
    String? listingId,
    String? messageType,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/messages/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_id': user['id'],
          'recipient_id': recipientId,
          'message': message,
          'listing_id': listingId,
          'message_type': messageType ?? 'text',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message_id': data['message_id'],
          'conversation_id': data['conversation_id'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send message',
        };
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Mark conversation as read
  static Future<bool> markConversationAsRead(String conversationId) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/messages/$conversationId/mark-read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user['id'],
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking conversation as read: $e');
      return false;
    }
  }

  // Report spam message
  static Future<bool> reportSpam({
    required String conversationId,
    required String messageId,
    String? reason,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/messages/report-spam'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reporter_id': user['id'],
          'conversation_id': conversationId,
          'message_id': messageId,
          'reason': reason ?? 'Spam',
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error reporting spam: $e');
      return false;
    }
  }

  // Block user
  static Future<bool> blockUser(String userId) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/users/block'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'blocker_id': user['id'],
          'blocked_id': userId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error blocking user: $e');
      return false;
    }
  }

  // Start conversation with seller about a listing
  static Future<Map<String, dynamic>> startConversationWithSeller({
    required String sellerId,
    required String listingId,
    required String initialMessage,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/messages/start-conversation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'buyer_id': user['id'],
          'seller_id': sellerId,
          'listing_id': listingId,
          'initial_message': initialMessage,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'conversation_id': data['conversation_id'],
          'message': 'Conversation started successfully',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to start conversation',
        };
      }
    } catch (e) {
      debugPrint('Error starting conversation: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get unread message count
  static Future<int> getUnreadCount() async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) return 0;

      final response = await http.get(
        Uri.parse('$baseUrl/messages/unread-count?user_id=${user['id']}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unread_count'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }
}
