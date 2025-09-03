import 'package:flutter/material.dart';

class ImageUtils {
  static const String baseUrl = 'https://sokofiti.ke';

  /// Normalize image URL to ensure it's a complete, valid URL
  static String normalizeImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }

    final url = imageUrl.trim();

    // If already a complete URL, return as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // If starts with /, remove it and prepend base URL
    if (url.startsWith('/')) {
      return '$baseUrl$url';
    }

    // Otherwise, prepend base URL with /
    return '$baseUrl/$url';
  }

  /// Normalize a list of image URLs
  static List<String> normalizeImageUrls(List<dynamic>? imageUrls) {
    if (imageUrls == null || imageUrls.isEmpty) {
      return [];
    }

    return imageUrls
        .map((url) => normalizeImageUrl(url?.toString()))
        .where((url) => url.isNotEmpty)
        .toList();
  }

  /// Get the first image URL from a listing, normalized
  static String getListingImageUrl(Map<String, dynamic> listing) {
    // Try different possible image field names
    final imageFields = [
      'image_url',
      'image',
      'photo_url',
      'photo',
      'thumbnail',
      'main_image',
    ];

    for (final field in imageFields) {
      final imageUrl = listing[field];
      if (imageUrl != null && imageUrl.toString().isNotEmpty) {
        return normalizeImageUrl(imageUrl.toString());
      }
    }

    // Try images array
    final images = listing['images'];
    if (images is List && images.isNotEmpty) {
      return normalizeImageUrl(images.first?.toString());
    }

    return '';
  }

  /// Get all image URLs from a listing, normalized
  static List<String> getListingImageUrls(Map<String, dynamic> listing) {
    final List<String> urls = [];

    // Try images array first
    final images = listing['images'];
    if (images is List && images.isNotEmpty) {
      urls.addAll(normalizeImageUrls(images));
    }

    // If no images array, try individual image fields
    if (urls.isEmpty) {
      final imageFields = [
        'image_url',
        'image',
        'photo_url',
        'photo',
        'thumbnail',
        'main_image',
      ];

      for (final field in imageFields) {
        final imageUrl = listing[field];
        if (imageUrl != null && imageUrl.toString().isNotEmpty) {
          final normalized = normalizeImageUrl(imageUrl.toString());
          if (normalized.isNotEmpty && !urls.contains(normalized)) {
            urls.add(normalized);
          }
        }
      }
    }

    return urls;
  }

  /// Build a network image widget with proper error handling and loading
  static Widget buildNetworkImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    final normalizedUrl = normalizeImageUrl(imageUrl);

    if (normalizedUrl.isEmpty) {
      return errorWidget ?? _buildDefaultErrorWidget(width, height);
    }

    Widget imageWidget = Image.network(
      normalizedUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return placeholder ?? _buildDefaultLoadingWidget(width, height);
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _buildDefaultErrorWidget(width, height);
      },
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius, child: imageWidget);
    }

    return imageWidget;
  }

  /// Build a listing image widget with consistent styling
  static Widget buildListingImage({
    required Map<String, dynamic> listing,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    final imageUrl = getListingImageUrl(listing);

    return buildNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
    );
  }

  /// Build a listing image gallery widget with click handlers
  static Widget buildListingImageGallery({
    required Map<String, dynamic> listing,
    double height = 300,
    BorderRadius? borderRadius,
    BuildContext? context,
  }) {
    final imageUrls = getListingImageUrls(listing);

    if (imageUrls.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: borderRadius,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 64, color: Colors.grey),
              SizedBox(height: 8),
              Text('No images available', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (imageUrls.length == 1) {
      return GestureDetector(
        onTap: context != null
            ? () => _openImageViewer(context, imageUrls, 0)
            : null,
        child: buildNetworkImage(
          imageUrl: imageUrls.first,
          height: height,
          fit: BoxFit.cover,
          borderRadius: borderRadius,
        ),
      );
    }

    return SizedBox(
      height: height,
      child: PageView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => _openImageViewer(context, imageUrls, index),
              child: buildNetworkImage(
                imageUrl: imageUrls[index],
                height: height,
                fit: BoxFit.cover,
                borderRadius: borderRadius ?? BorderRadius.circular(8),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Open full-screen image viewer
  static void _openImageViewer(
    BuildContext context,
    List<String> imageUrls,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ImageViewerScreen(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  static Widget _buildDefaultLoadingWidget(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5BE206)),
        ),
      ),
    );
  }

  static Widget _buildDefaultErrorWidget(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey, size: 32),
      ),
    );
  }

  /// Check if an image URL is valid (not empty and properly formatted)
  static bool isValidImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return false;

    final normalized = normalizeImageUrl(imageUrl);
    return normalized.isNotEmpty &&
        (normalized.startsWith('http://') || normalized.startsWith('https://'));
  }

  /// Get a placeholder image URL for testing
  static String getPlaceholderImageUrl({int width = 300, int height = 200}) {
    return 'https://via.placeholder.com/${width}x$height/5BE206/FFFFFF?text=Sokofiti';
  }
}

/// Full-screen image viewer widget
class _ImageViewerScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _ImageViewerScreen({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} of ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: ImageUtils.buildNetworkImage(
                    imageUrl: widget.imageUrls[index],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),

          // Navigation arrows (only show if more than 1 image)
          if (widget.imageUrls.length > 1) ...[
            // Left arrow
            if (_currentIndex > 0)
              Positioned(
                left: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),

            // Right arrow
            if (_currentIndex < widget.imageUrls.length - 1)
              Positioned(
                right: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
          ],

          // Page indicator dots
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
