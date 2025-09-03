import 'package:flutter/material.dart';
import '../services/smart_search_service.dart';
import '../widgets/smart_search_widget.dart';
import '../widgets/ellipsis_loader.dart';
import '../utils/image_utils.dart';
import 'listing_detail_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final String? categoryId;
  final Map<String, dynamic>? initialFilters;

  const SearchResultsScreen({
    super.key,
    required this.query,
    this.categoryId,
    this.initialFilters,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<dynamic> _searchResults = [];
  Map<String, dynamic> _filters = {};
  bool _isLoading = false;
  bool _hasMore = false;
  int _currentPage = 1;
  int _totalCount = 0;
  String _sortBy = 'relevance';

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.initialFilters ?? {});
    _performSearch();
  }

  Future<void> _performSearch({bool loadMore = false}) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await SmartSearchService.performSmartSearch(
        query: widget.query,
        categoryId: widget.categoryId,
        minPrice: _filters['min_price'],
        maxPrice: _filters['max_price'],
        condition: _filters['condition'],
        sortBy: _sortBy,
        page: loadMore ? _currentPage + 1 : 1,
      );

      setState(() {
        if (loadMore) {
          _searchResults.addAll(result['listings'] ?? []);
          _currentPage++;
        } else {
          _searchResults = result['listings'] ?? [];
          _currentPage = 1;
        }
        _hasMore = result['has_more'] ?? false;
        _totalCount = result['total_count'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onFiltersChanged(Map<String, dynamic> newFilters) {
    setState(() => _filters = newFilters);
    _performSearch();
  }

  void _onSortChanged(String? newSort) {
    if (newSort != null && newSort != _sortBy) {
      setState(() => _sortBy = newSort);
      _performSearch();
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SearchFiltersWidget(
        initialFilters: _filters,
        onFiltersChanged: _onFiltersChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search: "${widget.query}"'),
        backgroundColor: const Color(0xFF5BE206),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showFilters,
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: SmartSearchWidget(
              initialQuery: widget.query,
              onSearchSubmitted: (query) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchResultsScreen(query: query),
                  ),
                );
              },
            ),
          ),

          // Results info and sort
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$_totalCount results found',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
                DropdownButton<String>(
                  value: _sortBy,
                  onChanged: _onSortChanged,
                  items: const [
                    DropdownMenuItem(
                      value: 'relevance',
                      child: Text('Relevance'),
                    ),
                    DropdownMenuItem(
                      value: 'price_low',
                      child: Text('Price: Low to High'),
                    ),
                    DropdownMenuItem(
                      value: 'price_high',
                      child: Text('Price: High to Low'),
                    ),
                    DropdownMenuItem(
                      value: 'newest',
                      child: Text('Newest First'),
                    ),
                    DropdownMenuItem(
                      value: 'oldest',
                      child: Text('Oldest First'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(),

          // Results list
          Expanded(
            child: _isLoading && _searchResults.isEmpty
                ? const Center(child: BouncingEllipsisLoader())
                : _searchResults.isEmpty
                ? _buildEmptyState()
                : NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (!_isLoading &&
                          _hasMore &&
                          scrollInfo.metrics.pixels ==
                              scrollInfo.metrics.maxScrollExtent) {
                        _performSearch(loadMore: true);
                      }
                      return false;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _searchResults.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _searchResults.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: BouncingEllipsisLoader(),
                            ),
                          );
                        }
                        return _buildListingCard(_searchResults[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No results found for "${widget.query}"',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms or filters',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // Track search interaction
          SmartSearchService.trackSearchInteraction(
            query: widget.query,
            action: 'click',
            listingId: listing['id'].toString(),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListingDetailScreen(listing: listing),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ImageUtils.buildListingImage(
                listing: listing,
                width: 80,
                height: 80,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing['title'] ?? 'No title',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'KES ${listing['price'] ?? '0'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            listing['location'] ?? 'Unknown location',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing['created_at'] ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
