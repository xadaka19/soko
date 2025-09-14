import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/firebase_service.dart';
import '../widgets/plan_badge.dart';
import '../widgets/ellipsis_loader.dart';
import '../widgets/smart_search_widget.dart';
import '../utils/image_utils.dart';
import '../utils/asset_helper.dart';
import '../config/api.dart';
import 'listing_detail_screen.dart';
import 'category_screen.dart';
import 'search_results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<dynamic> _listings = [];
  bool _isLoading = true;

  // Categories data - will be loaded from API
  List<dynamic> _categories = [];

  final String baseUrl = 'https://sokofiti.ke';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadListings();
    _loadCategories();
    _startAutoRefresh();

    // Debug category assets on first load
    AssetHelper.debugCategoryAssets();

    FirebaseService.trackScreenView('home_screen');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh listings when app comes back to foreground
      _loadListings();
      _loadCategories();
    }
  }

  void _startAutoRefresh() {
    // Refresh listings every 10 minutes to keep them up-to-date
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      if (mounted) {
        _loadListings();
      }
    });
  }

  Future<void> _loadListings() async {
    setState(() => _isLoading = true);

    try {
      final url = '${Api.baseUrl}${Api.getListingsEndpoint}';
      debugPrint('Loading listings from: $url');

      final response = await http
          .get(Uri.parse(url), headers: Api.headers)
          .timeout(const Duration(seconds: 30));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        debugPrint('Parsed JSON: $jsonData');

        if (jsonData['success'] == true) {
          final List<dynamic> data = jsonData['listings'] ?? [];
          debugPrint('Found ${data.length} listings');

          final normalized = data.map((item) {
            try {
              // Handle multiple image formats
              String imageUrl = '';
              if (item['image'] != null &&
                  item['image'].toString().isNotEmpty) {
                imageUrl = ImageUtils.normalizeImageUrl(
                  item['image'].toString(),
                );
              } else if (item['images'] != null &&
                  item['images'] is List &&
                  (item['images'] as List).isNotEmpty) {
                imageUrl = ImageUtils.normalizeImageUrl(
                  (item['images'] as List).first.toString(),
                );
              }

              return {
                'id': item['id']?.toString() ?? '0',
                'title': item['title']?.toString() ?? 'No Title',
                'description': item['description']?.toString() ?? '',
                'price': item['price']?.toString() ?? '0',
                'formatted_price':
                    item['formatted_price']?.toString() ??
                    'KES ${item['price'] ?? '0'}',
                'image': imageUrl,
                'images':
                    item['images'] ?? (imageUrl.isNotEmpty ? [imageUrl] : []),
                'location': item['location']?.toString() ?? '',
                'city': item['city']?.toString() ?? '',
                'county': item['county']?.toString() ?? '',
                'plan': item['plan']?.toString() ?? 'free',
                'condition': item['condition']?.toString() ?? 'used',
                'category': item['category']?.toString() ?? '',
                'category_id': item['category_id']?.toString() ?? '',
                'seller_name': item['seller_name']?.toString() ?? '',
                'views': item['views']?.toString() ?? '0',
                'created_at': item['created_at']?.toString() ?? '',
                'updated_at': item['updated_at']?.toString() ?? '',
              };
            } catch (e) {
              debugPrint('Error processing listing item: $e');
              return {
                'id': '0',
                'title': 'Error Loading Item',
                'description': '',
                'price': '0',
                'formatted_price': 'KES 0',
                'image': '',
                'images': [],
                'location': '',
                'city': '',
                'county': '',
                'plan': 'free',
                'condition': 'used',
                'category': '',
                'category_id': '',
                'seller_name': '',
                'views': '0',
                'created_at': '',
                'updated_at': '',
              };
            }
          }).toList();

          if (mounted) {
            setState(() {
              _listings = normalized;
              _isLoading = false;
            });
          }
        } else {
          throw Exception(
            'API returned error: ${jsonData['error'] ?? 'unknown'}',
          );
        }
      } else {
        throw Exception('Failed to load listings: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to load listings: $e');
      if (mounted) {
        setState(() {
          _listings = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to load listings. Please check your network.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final response = await http
          .get(
            Uri.parse('${Api.baseUrl}${Api.getCategoriesEndpoint}'),
            headers: Api.headers,
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'success') {
          setState(() {
            _categories = jsonData['data'];
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load categories: $e');
    }
  }

  Future<void> _onRefresh() async => _loadListings();

  Widget _buildCategoryImage(Map<String, dynamic> category) {
    return AssetHelper.getCategoryImage(
      categoryName: category['name']?.toString(),
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(12),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No listings found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to post an item!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadListings,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5BE206),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return GestureDetector(
                  onTap: () {
                    // Navigate to category screen
                    debugPrint('Category tapped: ${category['name']}');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CategoryScreen(category: category),
                      ),
                    );
                  },
                  child: Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildCategoryImage(category),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: Text(
                            category['name']!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingGridCard(Map<String, dynamic> listing) {
    return GestureDetector(
      onTap: () {
        // Log listing view event
        FirebaseService.logEvent('listing_viewed', {
          'listing_id': listing['id'].toString(),
          'listing_title': listing['title'] ?? '',
          'listing_price': listing['price'] ?? '0',
          'plan_type': listing['plan'] ?? 'free',
          'source': 'home_screen',
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListingDetailScreen(listing: listing),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: SizedBox(
                width: double.infinity,
                child: ImageUtils.buildListingImage(
                  listing: listing,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price (First)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'KES ${_formatPrice(int.tryParse(listing['price']?.toString() ?? '0') ?? 0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5BE206),
                            ),
                          ),
                        ),
                        if (listing['plan'] != null)
                          PlanBadgeIcon(planType: listing['plan'], size: 16),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title (Second)
                    Text(
                      listing['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Location (Third)
                    Text(
                      listing['location'] ?? 'Unknown location',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Condition (Fourth) - Brand new or Used
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: listing['condition'] == 'brand new'
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        listing['condition'] ?? 'used',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: listing['condition'] == 'brand new'
                              ? Colors.green[700]
                              : Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trending Ads',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5BE206),
            ),
          ),
          const SizedBox(height: 12),
          // Show first 4 listings as trending
          _listings.isEmpty
              ? const Text('No trending ads')
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _listings.length > 4 ? 4 : _listings.length,
                  itemBuilder: (context, index) {
                    final listing = _listings[index];
                    return _buildListingGridCard(listing);
                  },
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sokofiti'),
        backgroundColor: const Color(0xFF5BE206),
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SmartSearchWidget(
              onSearchSubmitted: (query) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchResultsScreen(query: query),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: BouncingEllipsisLoader())
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: CustomScrollView(
                slivers: [
                  // Categories Section
                  SliverToBoxAdapter(child: _buildCategoriesSection()),

                  // Trending Ads Section
                  SliverToBoxAdapter(child: _buildTrendingSection()),

                  // Listings Grid (2 per row)
                  _listings.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmptyState())
                      : SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.75,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final listing = _listings[index];
                              return _buildListingGridCard(listing);
                            }, childCount: _listings.length),
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}
