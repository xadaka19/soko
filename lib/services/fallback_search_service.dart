import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';

/// Fallback search service that uses basic API endpoints
/// when smart search endpoints are not available
class FallbackSearchService {
  /// Perform basic search using the listings endpoint
  static Future<Map<String, dynamic>> performBasicSearch({
    required String query,
    String? categoryId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Build search URL with query parameters
      final uri = Uri.parse('${Api.baseUrl}${Api.getListingsEndpoint}');
      final queryParams = <String, String>{};
      
      if (query.isNotEmpty) {
        queryParams['search'] = query;
      }
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['category_id'] = categoryId;
      }
      queryParams['page'] = page.toString();
      queryParams['limit'] = limit.toString();
      
      final searchUri = uri.replace(queryParameters: queryParams);
      
      debugPrint('Fallback search URL: $searchUri');
      
      final response = await http
          .get(searchUri, headers: Api.headers)
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final listings = data['listings'] ?? [];
          return {
            'listings': listings,
            'total_count': listings.length,
            'has_more': listings.length >= limit,
            'search_time': 0,
            'suggestions': [],
            'filters': {},
          };
        } else {
          throw Exception(data['message'] ?? 'Search failed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Fallback search error: $e');
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

  /// Get basic autocomplete suggestions from local data
  static Future<List<Map<String, dynamic>>> getBasicSuggestions(String query) async {
    if (query.length < 2) return [];
    
    // Basic suggestions based on common search terms
    final suggestions = <String>[
      'Electronics',
      'Fashion',
      'Vehicles',
      'Home & Garden',
      'Sports',
      'Books',
      'Phones',
      'Laptops',
      'Cars',
      'Furniture',
      'Clothes',
      'Shoes',
      'Watches',
      'Jewelry',
      'Appliances',
    ];
    
    final filtered = suggestions
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .map((item) => {'title': item, 'type': 'suggestion'})
        .toList();
    
    return filtered;
  }

  /// Check if smart search is available
  static Future<bool> isSmartSearchAvailable() async {
    try {
      final response = await http
          .get(
            Uri.parse('${Api.baseUrl}${Api.smartSearchEndpoint}'),
            headers: Api.headers,
          )
          .timeout(const Duration(seconds: 5));
      
      return response.statusCode != 404;
    } catch (e) {
      debugPrint('Smart search availability check failed: $e');
      return false;
    }
  }
}
