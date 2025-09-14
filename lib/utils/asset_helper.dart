import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AssetHelper {
  /// Check if an asset exists
  static Future<bool> assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (e) {
      debugPrint('Asset not found: $assetPath - $e');
      return false;
    }
  }

  /// Get a safe asset widget with fallback
  static Widget safeAssetImage({
    required String assetPath,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    Widget? fallback,
    BorderRadius? borderRadius,
  }) {
    final imageWidget = Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Failed to load asset: $assetPath - $error');
        return fallback ?? _defaultFallback(width, height);
      },
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// Default fallback widget for failed asset loads
  static Widget _defaultFallback(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF5BE206).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF5BE206).withValues(alpha: 0.3),
        ),
      ),
      child: const Icon(
        Icons.image_not_supported,
        color: Color(0xFF5BE206),
        size: 30,
      ),
    );
  }

  /// Get category image with proper fallback
  static Widget getCategoryImage({
    required String? categoryName,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    // Map category names to available icon files
    final categoryIconMap = {
      'electronics': 'electronics.png',
      'mobile phones': 'mobile-tablet.png',
      'phones': 'mobile-tablet.png',
      'fashion': 'fashion.png',
      'fashion & beauty': 'fashion.png',
      'beauty': 'beauty-health.png',
      'home': 'home-furniture.png',
      'home & garden': 'home-furniture.png',
      'furniture': 'home-furniture.png',
      'vehicles': 'vehicles.png',
      'cars': 'vehicles.png',
      'services': 'services.png',
      'property': 'property.png',
      'real estate': 'property.png',
      'babies': 'babies-kids.png',
      'kids': 'babies-kids.png',
      'baby': 'babies-kids.png',
      'pets': 'pets-animals.png',
      'animals': 'pets-animals.png',
      'agriculture': 'agriculture-farming.png',
      'farming': 'agriculture-farming.png',
      'commercial': 'commercial-equipment-tools.png',
      'equipment': 'commercial-equipment-tools.png',
      'tools': 'commercial-equipment-tools.png',
      'leisure': 'leisure-activities.png',
      'activities': 'leisure-activities.png',
      'repair': 'repair-construction.png',
      'construction': 'repair-construction.png',
      'work': 'seeking-work-cvs.png',
      'jobs': 'seeking-work-cvs.png',
      'cvs': 'seeking-work-cvs.png',
    };

    // Get category name and try to find matching icon
    final categoryNameLower = (categoryName ?? '').toLowerCase();
    String iconFileName = 'default.png';

    // Try exact match first
    if (categoryIconMap.containsKey(categoryNameLower)) {
      iconFileName = categoryIconMap[categoryNameLower]!;
    } else {
      // Try partial matches
      for (final key in categoryIconMap.keys) {
        if (categoryNameLower.contains(key) || key.contains(categoryNameLower)) {
          iconFileName = categoryIconMap[key]!;
          break;
        }
      }
    }

    final assetPath = 'assets/images/categories/$iconFileName';

    return safeAssetImage(
      assetPath: assetPath,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      fallback: safeAssetImage(
        assetPath: 'assets/images/categories/default.png',
        width: width,
        height: height,
        fit: fit,
        borderRadius: borderRadius,
        fallback: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF5BE206).withValues(alpha: 0.1),
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF5BE206).withValues(alpha: 0.3),
            ),
          ),
          child: const Icon(
            Icons.category,
            color: Color(0xFF5BE206),
            size: 30,
          ),
        ),
      ),
    );
  }

  /// Debug function to list all available category assets
  static Future<void> debugCategoryAssets() async {
    final categoryAssets = [
      'agriculture-farming.png',
      'babies-kids.png',
      'beauty-health.png',
      'commercial-equipment-tools.png',
      'default.png',
      'electronics.png',
      'fashion.png',
      'home-furniture.png',
      'leisure-activities.png',
      'mobile-tablet.png',
      'pets-animals.png',
      'property.png',
      'repair-construction.png',
      'seeking-work-cvs.png',
      'services.png',
      'vehicles.png',
    ];

    debugPrint('=== Category Assets Debug ===');
    for (final asset in categoryAssets) {
      final path = 'assets/images/categories/$asset';
      final exists = await assetExists(path);
      debugPrint('$path: ${exists ? "✓ EXISTS" : "✗ MISSING"}');
    }
    debugPrint('=== End Category Assets Debug ===');
  }
}
