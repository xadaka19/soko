import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../utils/session_manager.dart';

class VerificationService {
  /// Submit National ID for verification
  static Future<Map<String, dynamic>> submitNationalIDVerification({
    required String nationalId,
    required File frontIdImage,
    required File backIdImage,
    required File selfieImage,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Api.baseUrl}/api/verification/submit-national-id.php'),
      );

      // Add headers
      request.headers.addAll(Api.headers);

      // Add fields
      request.fields['user_id'] = user['id'].toString();
      request.fields['token'] = user['token'];
      request.fields['national_id'] = nationalId;

      // Add files
      request.files.add(
        await http.MultipartFile.fromPath('front_id_image', frontIdImage.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('back_id_image', backIdImage.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('selfie_image', selfieImage.path),
      );

      final streamedResponse = await request.send().timeout(Api.timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Unknown error',
          'verification_id': data['verification_id'],
          'status': data['status'] ?? 'pending',
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Submit National ID verification error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get verification status
  static Future<Map<String, dynamic>> getVerificationStatus() async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/verification/status.php'),
            headers: Api.headers,
            body: jsonEncode({'user_id': user['id'], 'token': user['token']}),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return {
            'is_verified': data['is_verified'] ?? false,
            'verification_status': data['verification_status'] ?? 'none',
            'verification_level': data['verification_level'] ?? 'none',
            'submitted_at': data['submitted_at'],
            'verified_at': data['verified_at'],
            'rejection_reason': data['rejection_reason'],
            'spending_requirement_met':
                data['spending_requirement_met'] ?? false,
            'total_spent': data['total_spent'] ?? 0,
            'required_spending': data['required_spending'] ?? 1000,
          };
        } else {
          throw Exception(
            data['message'] ?? 'Failed to get verification status',
          );
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get verification status error: $e');
      rethrow;
    }
  }

  /// Check if user meets spending requirements
  static Future<Map<String, dynamic>> checkSpendingRequirements() async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/verification/spending-check.php'),
            headers: Api.headers,
            body: jsonEncode({'user_id': user['id'], 'token': user['token']}),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return {
            'meets_requirement': data['meets_requirement'] ?? false,
            'total_spent': data['total_spent'] ?? 0,
            'required_amount': data['required_amount'] ?? 1000,
            'remaining_amount': data['remaining_amount'] ?? 1000,
            'transactions_count': data['transactions_count'] ?? 0,
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to check spending');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Check spending requirements error: $e');
      rethrow;
    }
  }

  /// Get verification requirements
  static Future<Map<String, dynamic>> getVerificationRequirements() async {
    try {
      final response = await http
          .get(
            Uri.parse('${Api.baseUrl}/api/verification/requirements.php'),
            headers: Api.headers,
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return {
            'minimum_spending': data['minimum_spending'] ?? 1000,
            'required_documents': data['required_documents'] ?? [],
            'verification_levels': data['verification_levels'] ?? [],
            'processing_time': data['processing_time'] ?? '2-3 business days',
            'benefits': data['benefits'] ?? [],
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to get requirements');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get verification requirements error: $e');
      return {
        'minimum_spending': 1000,
        'required_documents': ['National ID', 'Selfie'],
        'verification_levels': ['Basic', 'Premium'],
        'processing_time': '2-3 business days',
        'benefits': ['Verified badge', 'Priority support', 'Higher trust'],
      };
    }
  }

  /// Report fraudulent verification attempt
  static Future<bool> reportFraudulentVerification({
    required int reportedUserId,
    required String reason,
    String? evidence,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/verification/report-fraud.php'),
            headers: Api.headers,
            body: jsonEncode({
              'reporter_id': user['id'],
              'token': user['token'],
              'reported_user_id': reportedUserId,
              'reason': reason,
              'evidence': evidence,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Report fraudulent verification error: $e');
      return false;
    }
  }

  /// Admin: Get pending verifications
  static Future<List<dynamic>> getPendingVerifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/pending-verifications.php'),
            headers: Api.headers,
            body: jsonEncode({
              'admin_id': user['id'],
              'token': user['token'],
              'page': page,
              'limit': limit,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['verifications'] ?? [];
        } else {
          throw Exception(
            data['message'] ?? 'Failed to get pending verifications',
          );
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get pending verifications error: $e');
      return [];
    }
  }

  /// Admin: Approve verification
  static Future<bool> approveVerification({
    required int verificationId,
    required String verificationLevel,
    String? adminNotes,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/approve-verification.php'),
            headers: Api.headers,
            body: jsonEncode({
              'admin_id': user['id'],
              'token': user['token'],
              'verification_id': verificationId,
              'verification_level': verificationLevel,
              'admin_notes': adminNotes,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Approve verification error: $e');
      return false;
    }
  }

  /// Admin: Reject verification
  static Future<bool> rejectVerification({
    required int verificationId,
    required String reason,
    String? adminNotes,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/reject-verification.php'),
            headers: Api.headers,
            body: jsonEncode({
              'admin_id': user['id'],
              'token': user['token'],
              'verification_id': verificationId,
              'reason': reason,
              'admin_notes': adminNotes,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Reject verification error: $e');
      return false;
    }
  }

  /// Get verification statistics
  static Future<Map<String, dynamic>> getVerificationStats() async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/verification-stats.php'),
            headers: Api.headers,
            body: jsonEncode({'admin_id': user['id'], 'token': user['token']}),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return {
            'total_verified': data['total_verified'] ?? 0,
            'pending_verifications': data['pending_verifications'] ?? 0,
            'rejected_verifications': data['rejected_verifications'] ?? 0,
            'verification_rate': data['verification_rate'] ?? 0,
            'fraud_reports': data['fraud_reports'] ?? 0,
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to get stats');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get verification stats error: $e');
      return {};
    }
  }

  /// Helper: Pick image for verification (web-compatible)
  static Future<File?> pickVerificationImage(String source) async {
    try {
      if (kIsWeb) {
        // Web-compatible placeholder
        debugPrint(
          'Image picker not available on web for verification: $source',
        );
        return null;
      }

      // For mobile platforms, this would use actual image picker
      debugPrint('Image picker requested for verification: $source');
      return null;
    } catch (e) {
      debugPrint('Pick verification image error: $e');
      return null;
    }
  }
}
