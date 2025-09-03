import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../config/api.dart';
import '../utils/session_manager.dart';

class MonthlyReportsService {
  /// Generate comprehensive monthly revenue report
  static Future<Map<String, dynamic>> generateMonthlyReport({
    required int year,
    required int month,
    String format = 'json', // json, pdf, excel
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/monthly-report.php'),
            headers: Api.headers,
            body: jsonEncode({
              'admin_id': user['id'],
              'token': user['token'],
              'year': year,
              'month': month,
              'format': format,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['report'];
        } else {
          throw Exception(data['message'] ?? 'Failed to generate report');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Generate monthly report error: $e');
      rethrow;
    }
  }

  /// Get revenue analytics with bar graph data
  static Future<Map<String, dynamic>> getRevenueAnalytics({
    required int year,
    required int month,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/revenue-analytics.php'),
            headers: Api.headers,
            body: jsonEncode({
              'admin_id': user['id'],
              'token': user['token'],
              'year': year,
              'month': month,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return {
            'daily_revenue': data['daily_revenue'] ?? [],
            'weekly_revenue': data['weekly_revenue'] ?? [],
            'total_revenue': data['total_revenue'] ?? 0,
            'revenue_growth': data['revenue_growth'] ?? 0,
            'top_plans': data['top_plans'] ?? [],
            'payment_methods': data['payment_methods'] ?? [],
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to get analytics');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get revenue analytics error: $e');
      rethrow;
    }
  }

  /// Get category leaderboard
  static Future<List<dynamic>> getCategoryLeaderboard({
    required int year,
    required int month,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/category-leaderboard.php'),
            headers: Api.headers,
            body: jsonEncode({
              'admin_id': user['id'],
              'token': user['token'],
              'year': year,
              'month': month,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['categories'] ?? [];
        } else {
          throw Exception(data['message'] ?? 'Failed to get leaderboard');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get category leaderboard error: $e');
      return [];
    }
  }

  /// Get top sellers for the month
  static Future<List<dynamic>> getTopSellers({
    required int year,
    required int month,
    int limit = 10,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/top-sellers.php'),
            headers: Api.headers,
            body: jsonEncode({
              'admin_id': user['id'],
              'token': user['token'],
              'year': year,
              'month': month,
              'limit': limit,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['sellers'] ?? [];
        } else {
          throw Exception(data['message'] ?? 'Failed to get top sellers');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get top sellers error: $e');
      return [];
    }
  }

  /// Download report as PDF
  static Future<String?> downloadPDFReport({
    required int year,
    required int month,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/download-pdf-report.php'),
            headers: Api.headers,
            body: jsonEncode({
              'admin_id': user['id'],
              'token': user['token'],
              'year': year,
              'month': month,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        // Save PDF to device
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'monthly_report_${year}_${month.toString().padLeft(2, '0')}.pdf';
        final file = File('${directory.path}/$fileName');
        
        await file.writeAsBytes(response.bodyBytes);
        
        debugPrint('PDF report saved: ${file.path}');
        return file.path;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Download PDF report error: $e');
      return null;
    }
  }

  /// Download report as Excel
  static Future<String?> downloadExcelReport({
    required int year,
    required int month,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/download-excel-report.php'),
            headers: Api.headers,
            body: jsonEncode({
              'admin_id': user['id'],
              'token': user['token'],
              'year': year,
              'month': month,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        // Save Excel to device
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'monthly_report_${year}_${month.toString().padLeft(2, '0')}.xlsx';
        final file = File('${directory.path}/$fileName');
        
        await file.writeAsBytes(response.bodyBytes);
        
        debugPrint('Excel report saved: ${file.path}');
        return file.path;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Download Excel report error: $e');
      return null;
    }
  }

  /// Get available report months
  static Future<List<Map<String, dynamic>>> getAvailableReports() async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/available-reports.php'),
            headers: Api.headers,
            body: jsonEncode({
              'admin_id': user['id'],
              'token': user['token'],
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['reports'] ?? []);
        } else {
          throw Exception(data['message'] ?? 'Failed to get available reports');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get available reports error: $e');
      return [];
    }
  }

  /// Schedule automatic report generation
  static Future<bool> scheduleAutomaticReports({
    required bool enabled,
    required List<String> recipients,
    required String frequency, // monthly, weekly
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/schedule-reports.php'),
            headers: Api.headers,
            body: jsonEncode({
              'admin_id': user['id'],
              'token': user['token'],
              'enabled': enabled,
              'recipients': recipients,
              'frequency': frequency,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Schedule automatic reports error: $e');
      return false;
    }
  }

  /// Get report summary statistics
  static Future<Map<String, dynamic>> getReportSummary({
    required int year,
    required int month,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/report-summary.php'),
            headers: Api.headers,
            body: jsonEncode({
              'admin_id': user['id'],
              'token': user['token'],
              'year': year,
              'month': month,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return {
            'total_revenue': data['total_revenue'] ?? 0,
            'total_transactions': data['total_transactions'] ?? 0,
            'new_users': data['new_users'] ?? 0,
            'active_listings': data['active_listings'] ?? 0,
            'top_category': data['top_category'] ?? 'N/A',
            'growth_rate': data['growth_rate'] ?? 0,
            'avg_transaction_value': data['avg_transaction_value'] ?? 0,
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to get summary');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get report summary error: $e');
      return {};
    }
  }
}
