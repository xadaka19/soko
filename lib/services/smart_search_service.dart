import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';
import '../utils/session_manager.dart';

class SmartSearchService {
  static const String _localSearchHistoryKey = 'local_search_history';
  static const int _maxLocalHistory = 20;

  /// Get autocomplete suggestions
  static Future<List<Map<String, dynamic>>> getAutocompleteSuggestions(String query) async {
    if (query.length < 2) return [];

    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/search/autocomplete.php'),
            headers: Api.headers,
            body: jsonEncode({
              'query': query,
              'limit': 10,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['suggestions'] ?? []);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Autocomplete suggestions error: $e');
      return [];
    }
  }

  /// Get category-specific suggestions
  static Future<List<Map<String, dynamic>>> getCategorySuggestions({
    required String query,
    String? categoryId,
  }) async {
    if (query.length < 2) return [];

    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/search/category-suggestions.php'),
            headers: Api.headers,
            body: jsonEncode({
              'query': query,
              'category_id': categoryId,
              'limit': 8,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['suggestions'] ?? []);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Category suggestions error: $e');
      return [];
    }
  }

  /// Get trending searches
  static Future<List<String>> getTrendingSearches() async {
    try {
      final response = await http
          .get(
            Uri.parse('${Api.baseUrl}/api/search/trending.php'),
            headers: Api.headers,
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return List<String>.from(data['trending'] ?? []);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Trending searches error: $e');
      return [];
    }
  }

  /// Save search to local history
  static Future<void> saveToLocalHistory(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList(_localSearchHistoryKey) ?? [];
      
      // Remove if already exists to avoid duplicates
      history.remove(query);
      
      // Add to beginning
      history.insert(0, query);
      
      // Limit history size
      if (history.length > _maxLocalHistory) {
        history = history.take(_maxLocalHistory).toList();
      }
      
      await prefs.setStringList(_localSearchHistoryKey, history);
    } catch (e) {
      debugPrint('Save to local history error: $e');
    }
  }

  /// Get local search history
  static Future<List<String>> getLocalSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_localSearchHistoryKey) ?? [];
    } catch (e) {
      debugPrint('Get local history error: $e');
      return [];
    }
  }

  /// Clear local search history
  static Future<void> clearLocalHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localSearchHistoryKey);
    } catch (e) {
      debugPrint('Clear local history error: $e');
    }
  }

  /// Save search to server history (for logged-in users)
  static Future<void> saveToServerHistory(String query) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) return;

      await http
          .post(
            Uri.parse('${Api.baseUrl}/api/search/save-history.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': user['id'],
              'token': user['token'],
              'query': query,
            }),
          )
          .timeout(Api.timeout);
    } catch (e) {
      debugPrint('Save to server history error: $e');
    }
  }

  /// Get server search history (for logged-in users)
  static Future<List<String>> getServerSearchHistory() async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) return [];

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/search/get-history.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': user['id'],
              'token': user['token'],
              'limit': 20,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return List<String>.from(data['history'] ?? []);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Get server history error: $e');
      return [];
    }
  }

  /// Get combined search suggestions (autocomplete + history + trending)
  static Future<Map<String, List<dynamic>>> getCombinedSuggestions(String query) async {
    try {
      // Get all suggestions concurrently
      final futures = await Future.wait([
        getAutocompleteSuggestions(query),
        getLocalSearchHistory(),
        getServerSearchHistory(),
        getTrendingSearches(),
      ]);

      final autocomplete = futures[0] as List<Map<String, dynamic>>;
      final localHistory = futures[1] as List<String>;
      final serverHistory = futures[2] as List<String>;
      final trending = futures[3] as List<String>;

      // Filter history based on query
      final filteredLocalHistory = localHistory
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .take(5)
          .toList();

      final filteredServerHistory = serverHistory
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .take(5)
          .toList();

      return {
        'autocomplete': autocomplete,
        'local_history': filteredLocalHistory,
        'server_history': filteredServerHistory,
        'trending': query.isEmpty ? trending.take(5).toList() : [],
      };
    } catch (e) {
      debugPrint('Get combined suggestions error: $e');
      return {
        'autocomplete': <Map<String, dynamic>>[],
        'local_history': <String>[],
        'server_history': <String>[],
        'trending': <String>[],
      };
    }
  }

  /// Perform smart search with filters
  static Future<Map<String, dynamic>> performSmartSearch({
    required String query,
    String? categoryId,
    String? location,
    double? minPrice,
    double? maxPrice,
    String? condition,
    String? sortBy,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Save search to history
      if (query.isNotEmpty) {
        await saveToLocalHistory(query);
        await saveToServerHistory(query);
      }

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/search/smart-search.php'),
            headers: Api.headers,
            body: jsonEncode({
              'query': query,
              'category_id': categoryId,
              'location': location,
              'min_price': minPrice,
              'max_price': maxPrice,
              'condition': condition,
              'sort_by': sortBy ?? 'relevance',
              'page': page,
              'limit': limit,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return {
            'listings': data['listings'] ?? [],
            'total_count': data['total_count'] ?? 0,
            'has_more': data['has_more'] ?? false,
            'search_time': data['search_time'] ?? 0,
            'suggestions': data['suggestions'] ?? [],
            'filters': data['available_filters'] ?? {},
          };
        } else {
          throw Exception(data['message'] ?? 'Search failed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Smart search error: $e');
      return {
        'listings': [],
        'total_count': 0,
        'has_more': false,
        'search_time': 0,
        'suggestions': [],
        'filters': {},
      };
    }
  }

  /// Get search analytics for admin
  static Future<Map<String, dynamic>> getSearchAnalytics() async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not logged in');

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/admin/search-analytics.php'),
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
          return {
            'total_searches': data['total_searches'] ?? 0,
            'unique_queries': data['unique_queries'] ?? 0,
            'avg_results_per_search': data['avg_results_per_search'] ?? 0,
            'top_searches': data['top_searches'] ?? [],
            'search_trends': data['search_trends'] ?? [],
            'zero_result_queries': data['zero_result_queries'] ?? [],
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to get analytics');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get search analytics error: $e');
      return {};
    }
  }

  /// Get popular categories for search suggestions
  static Future<List<Map<String, dynamic>>> getPopularCategories() async {
    try {
      final response = await http
          .get(
            Uri.parse('${Api.baseUrl}/api/search/popular-categories.php'),
            headers: Api.headers,
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['categories'] ?? []);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Get popular categories error: $e');
      return [];
    }
  }

  /// Track search interaction (click, view, etc.)
  static Future<void> trackSearchInteraction({
    required String query,
    required String action,
    String? listingId,
    int? position,
  }) async {
    try {
      final user = await SessionManager.getUser();
      
      await http
          .post(
            Uri.parse('${Api.baseUrl}/api/search/track-interaction.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': user?['id'],
              'query': query,
              'action': action,
              'listing_id': listingId,
              'position': position,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(Api.timeout);
    } catch (e) {
      debugPrint('Track search interaction error: $e');
    }
  }
}
