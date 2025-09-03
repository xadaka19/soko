import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api.dart';

class PhotoDetectionService {
  /// Generate perceptual hash (pHash) for an image
  static String generatePerceptualHash(File imageFile) {
    try {
      // Read image bytes
      final bytes = imageFile.readAsBytesSync();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize to 32x32 for pHash calculation
      final resized = img.copyResize(image, width: 32, height: 32);

      // Convert to grayscale
      final grayscale = img.grayscale(resized);

      // Calculate DCT (Discrete Cosine Transform) simplified version
      // For production, you'd want a proper DCT implementation
      final pixels = <int>[];
      for (int y = 0; y < 32; y++) {
        for (int x = 0; x < 32; x++) {
          final pixel = grayscale.getPixel(x, y);
          pixels.add(img.getLuminance(pixel).toInt());
        }
      }

      // Calculate average
      final average = pixels.reduce((a, b) => a + b) / pixels.length;

      // Generate hash based on whether each pixel is above or below average
      String hash = '';
      for (int i = 0; i < pixels.length; i++) {
        hash += pixels[i] > average ? '1' : '0';
      }

      return hash;
    } catch (e) {
      debugPrint('Error generating perceptual hash: $e');
      return '';
    }
  }

  /// Calculate similarity between two hashes (Hamming distance)
  static double calculateSimilarity(String hash1, String hash2) {
    if (hash1.length != hash2.length) return 0.0;

    int differences = 0;
    for (int i = 0; i < hash1.length; i++) {
      if (hash1[i] != hash2[i]) {
        differences++;
      }
    }

    // Return similarity percentage
    return ((hash1.length - differences) / hash1.length) * 100;
  }

  /// Check if photo is duplicate/stolen
  static Future<Map<String, dynamic>> checkPhotoUniqueness(
    File imageFile,
  ) async {
    try {
      // Generate hash for the uploaded image
      final newHash = generatePerceptualHash(imageFile);

      if (newHash.isEmpty) {
        return {
          'is_duplicate': false,
          'similarity': 0.0,
          'message': 'Could not process image',
        };
      }

      // Send hash to backend for comparison
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/check-photo-duplicate.php'),
            headers: Api.headers,
            body: jsonEncode({
              'photo_hash': newHash,
              'similarity_threshold': 90.0, // 90% similarity threshold
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'is_duplicate': data['is_duplicate'] ?? false,
          'similarity': data['max_similarity'] ?? 0.0,
          'existing_listing_id': data['existing_listing_id'],
          'existing_seller': data['existing_seller'],
          'message': data['message'] ?? '',
          'hash': newHash,
        };
      }

      return {
        'is_duplicate': false,
        'similarity': 0.0,
        'message': 'Server error: ${response.statusCode}',
        'hash': newHash,
      };
    } catch (e) {
      debugPrint('Photo uniqueness check error: $e');
      return {
        'is_duplicate': false,
        'similarity': 0.0,
        'message': 'Network error: $e',
      };
    }
  }

  /// Store photo hash after successful upload
  static Future<bool> storePhotoHash({
    required String hash,
    required int listingId,
    required int userId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/store-photo-hash.php'),
            headers: Api.headers,
            body: jsonEncode({
              'photo_hash': hash,
              'listing_id': listingId,
              'user_id': userId,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Store photo hash error: $e');
      return false;
    }
  }

  /// Report stolen photo attempt
  static Future<bool> reportStolenPhotoAttempt({
    required int userId,
    required String originalListingId,
    required double similarity,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/report-stolen-photo.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': userId,
              'original_listing_id': originalListingId,
              'similarity': similarity,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Report stolen photo error: $e');
      return false;
    }
  }

  /// Get user's photo violation strikes
  static Future<int> getUserPhotoStrikes(int userId) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/get-photo-strikes.php'),
            headers: Api.headers,
            body: jsonEncode({'user_id': userId}),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['strikes'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Get photo strikes error: $e');
      return 0;
    }
  }

  /// Show duplicate photo warning dialog
  static void showDuplicatePhotoDialog({
    required BuildContext context,
    required String existingSeller,
    required double similarity,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Duplicate Photo Detected'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This photo appears to be already posted on Sokofiti by another seller.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text('Original seller: $existingSeller'),
              Text('Similarity: ${similarity.toStringAsFixed(1)}%'),
              const SizedBox(height: 12),
              const Text(
                'Please use your own photos to maintain trust and authenticity on our platform.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('I Understand'),
            ),
          ],
        );
      },
    );
  }

  /// Check if user should be auto-suspended for repeated violations
  static Future<bool> checkAutoSuspension(int userId) async {
    try {
      final strikes = await getUserPhotoStrikes(userId);

      // Auto-suspend after 3 strikes
      if (strikes >= 3) {
        final response = await http
            .post(
              Uri.parse('${Api.baseUrl}/api/auto-suspend-user.php'),
              headers: Api.headers,
              body: jsonEncode({
                'user_id': userId,
                'reason': 'Repeated stolen photo attempts',
                'strikes': strikes,
              }),
            )
            .timeout(Api.timeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['suspended'] == true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Auto suspension check error: $e');
      return false;
    }
  }
}
