import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';

class ListingService {
  /// Get all listings with optional filters
  static Future<List<dynamic>> getListings({
    String? category,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse(
        '${Api.baseUrl}${Api.getListingsEndpoint}',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri).timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ? data['listings'] : [];
      }
      return [];
    } catch (e) {
      debugPrint('Get listings error: $e');
      return [];
    }
  }

  /// Get single listing by ID
  static Future<Map<String, dynamic>?> getListing(int id) async {
    try {
      final uri = Uri.parse(
        '${Api.baseUrl}${Api.getListingEndpoint}',
      ).replace(queryParameters: {'id': id.toString()});

      final response = await http.get(uri).timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ? data['listing'] : null;
      }
      return null;
    } catch (e) {
      debugPrint('Get listing error: $e');
      return null;
    }
  }

  /// Create new listing
  /// Returns a Map with 'success' (bool) and 'listing_id' (int?) keys
  static Future<Map<String, dynamic>> createListing({
    required int userId,
    required String title,
    required String description,
    required double price,
    required int categoryId,
    required String cityName,
    List<File>? photos,
    String condition = 'used', // Default to 'used'
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Api.baseUrl}${Api.createListingEndpoint}'),
      );

      // Add headers
      request.headers.addAll(Api.multipartHeaders);

      // Add fields
      request.fields['user_id'] = userId.toString();
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['category_id'] = categoryId.toString();
      request.fields['city_name'] = cityName;
      request.fields['condition'] = condition;

      // Add photos if provided
      if (photos != null && photos.isNotEmpty) {
        for (var photo in photos) {
          request.files.add(
            await http.MultipartFile.fromPath('photos[]', photo.path),
          );
        }
      }

      final response = await request.send().timeout(Api.timeout);
      final responseString = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseString);
        return {
          'success': data['success'] == true,
          'listing_id': data['listing_id'],
          'message': data['message'] ?? 'Listing created successfully',
        };
      }
      return {
        'success': false,
        'listing_id': null,
        'message': 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      debugPrint('Create listing error: $e');
      return {
        'success': false,
        'listing_id': null,
        'message': 'Network error: $e',
      };
    }
  }

  /// Update listing
  static Future<bool> updateListing({
    required int listingId,
    required int userId,
    required String title,
    required String description,
    required double price,
    required int categoryId,
    required String cityName,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/update-listing.php'),
            headers: Api.headers,
            body: jsonEncode({
              'listing_id': listingId,
              'user_id': userId,
              'title': title,
              'description': description,
              'price': price,
              'category_id': categoryId,
              'city_name': cityName,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Update listing error: $e');
      return false;
    }
  }

  /// Delete listing
  static Future<bool> deleteListing(int listingId, int userId) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/delete-listing.php'),
            headers: Api.headers,
            body: jsonEncode({'listing_id': listingId, 'user_id': userId}),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Delete listing error: $e');
      return false;
    }
  }
}
