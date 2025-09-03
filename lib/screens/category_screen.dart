import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/firebase_service.dart';
import '../utils/image_utils.dart';
import '../widgets/ellipsis_loader.dart';
import '../config/api.dart';
import 'listing_detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  final Map<String, dynamic> category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<dynamic> _subcategories = [];
  List<dynamic> _listings = [];
  bool _isLoading = true;
  bool _showSubcategories = true;
  String? _currentSubcategoryName;

  @override
  void initState() {
    super.initState();
    debugPrint(
      'CategoryScreen initialized for category: ${widget.category['name']}',
    );
    debugPrint('Category ID: ${widget.category['id']}');
    _loadSubcategories();
    FirebaseService.trackScreenView('category_screen');
  }

  Future<void> _loadSubcategories() async {
    try {
      final url =
          '${Api.baseUrl}${Api.getCategoriesEndpoint}?parent_id=${widget.category['id']}';
      debugPrint('Loading subcategories from: $url');

      final response = await http
          .get(Uri.parse(url), headers: Api.headers)
          .timeout(Api.timeout);

      debugPrint('Subcategories response status: ${response.statusCode}');
      debugPrint('Subcategories response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final subcategories = data['data'] ?? [];
          debugPrint('Found ${subcategories.length} subcategories');

          setState(() {
            _subcategories = subcategories;
            _isLoading = false;
          });

          // If no subcategories, load listings directly
          if (_subcategories.isEmpty) {
            debugPrint('No subcategories found, loading listings directly');
            setState(() {
              _showSubcategories = false;
            });
            _loadListings();
          } else {
            debugPrint('Showing ${_subcategories.length} subcategories');
          }
        } else {
          debugPrint('API returned error status: ${data['status']}');
          // Show error message instead of falling back to listings
          setState(() {
            _isLoading = false;
            _showSubcategories = true; // Keep showing subcategories view
            _subcategories = []; // Empty subcategories
          });
        }
      } else {
        debugPrint('HTTP error: ${response.statusCode}');
        // Show error message instead of falling back to listings
        setState(() {
          _isLoading = false;
          _showSubcategories = true; // Keep showing subcategories view
          _subcategories = []; // Empty subcategories
        });
      }
    } catch (e) {
      debugPrint('Failed to load subcategories: $e');
      // Show error message instead of falling back to listings
      setState(() {
        _isLoading = false;
        _showSubcategories = true; // Keep showing subcategories view
        _subcategories = []; // Empty subcategories
      });
    }
  }

  Future<void> _loadListings([
    String? subcategoryId,
    String? subcategoryName,
  ]) async {
    try {
      setState(() => _isLoading = true);

      // Track current subcategory
      _currentSubcategoryName = subcategoryName;

      final categoryParam = subcategoryId ?? widget.category['id'].toString();
      final url =
          '${Api.baseUrl}${Api.getListingsEndpoint}?category_id=$categoryParam';
      debugPrint('Loading listings from: $url');

      final response = await http
          .get(Uri.parse(url), headers: Api.headers)
          .timeout(Api.timeout);

      debugPrint('Listings response status: ${response.statusCode}');
      debugPrint('Listings response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final listings = data['listings'] ?? [];
          debugPrint('Found ${listings.length} listings');

          setState(() {
            _listings = listings;
            _isLoading = false;
            _showSubcategories = false;
          });
        } else {
          debugPrint(
            'API returned error: ${data['message'] ?? 'Unknown error'}',
          );
          setState(() {
            _listings = [];
            _isLoading = false;
            _showSubcategories = false;
          });
        }
      } else {
        debugPrint('HTTP error: ${response.statusCode}');
        setState(() {
          _listings = [];
          _isLoading = false;
          _showSubcategories = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load listings: $e');
      setState(() {
        _listings = [];
        _isLoading = false;
      });
    }
  }

  Widget _buildSubcategoryImage(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return const Icon(Icons.category, color: Color(0xFF5BE206), size: 30);
    }

    // Remove file extension if present and ensure we have the right format
    final cleanIconName = iconName
        .replaceAll('.png', '')
        .replaceAll('.jpg', '');
    final assetPath = 'images/categories/$cleanIconName.png';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        assetPath,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to default icon if asset not found
          return const Icon(Icons.category, color: Color(0xFF5BE206), size: 30);
        },
      ),
    );
  }

  Widget _buildSubcategoryCard(Map<String, dynamic> subcategory) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            debugPrint(
              'Subcategory tapped: ${subcategory['name']} (ID: ${subcategory['id']})',
            );
            // Smooth transition to listings
            setState(() => _isLoading = true);
            Future.delayed(const Duration(milliseconds: 200), () {
              _loadListings(
                subcategory['id'].toString(),
                subcategory['name'].toString(),
              );
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Subcategory Icon/Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF5BE206).withValues(alpha: 0.1),
                        const Color(0xFF5BE206).withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF5BE206).withValues(alpha: 0.2),
                    ),
                  ),
                  child: _buildSubcategoryImage(subcategory['icon']),
                ),
                const SizedBox(width: 16),

                // Subcategory Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subcategory['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to view listings',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5BE206).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFF5BE206),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: ImageUtils.buildListingImage(
          listing: listing,
          width: 60,
          height: 60,
          borderRadius: BorderRadius.circular(8),
        ),
        title: Text(
          listing['title'] ?? 'No Title',
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KES ${listing['price'] ?? '0'}',
              style: const TextStyle(
                color: Color(0xFF5BE206),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (listing['location'] != null)
              Text(
                listing['location'],
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListingDetailScreen(listing: listing),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category['name'] ?? 'Category'),
        backgroundColor: const Color(0xFF5BE206),
        foregroundColor: Colors.white,
        actions: [
          if (!_showSubcategories && _subcategories.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.category),
              onPressed: () {
                setState(() {
                  _showSubcategories = true;
                  _listings.clear();
                  _currentSubcategoryName = null;
                });
              },
            ),
          if (_showSubcategories)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadSubcategories,
              tooltip: 'Refresh subcategories',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: BouncingEllipsisLoader())
          : _showSubcategories
          ? _subcategories.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No subcategories available',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This category doesn\'t have any subcategories. You can browse listings directly.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showSubcategories = false;
                              });
                              _loadListings();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5BE206),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Browse Listings'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _subcategories.length,
                    itemBuilder: (context, index) {
                      return _buildSubcategoryCard(_subcategories[index]);
                    },
                  )
          : _listings.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentSubcategoryName != null
                          ? 'No listings available in $_currentSubcategoryName'
                          : 'No listings found in this category',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentSubcategoryName != null
                          ? 'This subcategory doesn\'t have any listings yet. Try browsing other subcategories or check back later.'
                          : 'This category doesn\'t have any listings yet. Try browsing other categories or check back later.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              itemCount: _listings.length,
              itemBuilder: (context, index) {
                return _buildListingCard(_listings[index]);
              },
            ),
    );
  }
}
