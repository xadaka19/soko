import 'package:flutter/material.dart';
import '../services/smart_search_service.dart';
import '../screens/search_results_screen.dart';
import 'ellipsis_loader.dart';

class SmartSearchWidget extends StatefulWidget {
  final String? initialQuery;
  final Function(String)? onSearchSubmitted;

  const SmartSearchWidget({
    super.key,
    this.initialQuery,
    this.onSearchSubmitted,
  });

  @override
  State<SmartSearchWidget> createState() => _SmartSearchWidgetState();
}

class _SmartSearchWidgetState extends State<SmartSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Map<String, List<dynamic>> _suggestions = {};
  bool _showSuggestions = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _loadSuggestions(_searchController.text);
    } else {
      setState(() => _showSuggestions = false);
    }
  }

  Future<void> _loadSuggestions(String query) async {
    setState(() => _isLoading = true);

    try {
      final suggestions = await SmartSearchService.getCombinedSuggestions(
        query,
      );
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (query.length >= 2 || query.isEmpty) {
      _loadSuggestions(query);
    }
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;

    _focusNode.unfocus();
    setState(() => _showSuggestions = false);

    if (widget.onSearchSubmitted != null) {
      widget.onSearchSubmitted!(query);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsScreen(query: query),
        ),
      );
    }
  }

  void _onSuggestionTapped(String suggestion) {
    _searchController.text = suggestion;
    _onSearchSubmitted(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: 'Search for anything...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _loadSuggestions('');
                      },
                      icon: const Icon(Icons.clear, color: Colors.grey),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            onChanged: _onSearchChanged,
            onSubmitted: _onSearchSubmitted,
            textInputAction: TextInputAction.search,
          ),
        ),

        // Suggestions dropdown
        if (_showSuggestions && (_suggestions.isNotEmpty || _isLoading))
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Loading indicator
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: BouncingEllipsisLoader()),
                  ),

                // Autocomplete suggestions
                if (_suggestions['autocomplete']?.isNotEmpty == true)
                  _buildSuggestionSection(
                    'Suggestions',
                    _suggestions['autocomplete']!
                        .map((item) => item['title'] as String)
                        .toList(),
                    Icons.search,
                  ),

                // Recent searches
                if (_suggestions['local_history']?.isNotEmpty == true ||
                    _suggestions['server_history']?.isNotEmpty == true)
                  _buildSuggestionSection(
                    'Recent Searches',
                    [
                      ..._suggestions['local_history'] ?? [],
                      ..._suggestions['server_history'] ?? [],
                    ].take(5).toList().cast<String>(),
                    Icons.history,
                  ),

                // Trending searches
                if (_suggestions['trending']?.isNotEmpty == true)
                  _buildSuggestionSection(
                    'Trending',
                    _suggestions['trending']!.cast<String>(),
                    Icons.trending_up,
                  ),

                // Clear history option
                if (_suggestions['local_history']?.isNotEmpty == true ||
                    _suggestions['server_history']?.isNotEmpty == true)
                  _buildClearHistoryOption(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionSection(
    String title,
    List<String> items,
    IconData icon,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        ...items.map(
          (item) => InkWell(
            onTap: () => _onSuggestionTapped(item),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const SizedBox(width: 24), // Align with section title
                  Expanded(
                    child: Text(item, style: const TextStyle(fontSize: 14)),
                  ),
                  Icon(Icons.north_west, size: 16, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        ),
        if (items != _suggestions.values.last)
          Divider(height: 1, color: Colors.grey[200]),
      ],
    );
  }

  Widget _buildClearHistoryOption() {
    return Column(
      children: [
        Divider(height: 1, color: Colors.grey[200]),
        InkWell(
          onTap: () async {
            await SmartSearchService.clearLocalHistory();
            _loadSuggestions(_searchController.text);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.clear_all, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Clear search history',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class QuickSearchChips extends StatelessWidget {
  final Function(String) onChipTapped;

  const QuickSearchChips({super.key, required this.onChipTapped});

  @override
  Widget build(BuildContext context) {
    final quickSearches = [
      'Electronics',
      'Fashion',
      'Vehicles',
      'Home & Garden',
      'Sports',
      'Books',
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: quickSearches.length,
        itemBuilder: (context, index) {
          final search = quickSearches[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(search, style: const TextStyle(fontSize: 12)),
              onPressed: () => onChipTapped(search),
              backgroundColor: Colors.grey[100],
              side: BorderSide(color: Colors.grey[300]!),
            ),
          );
        },
      ),
    );
  }
}

class SearchFiltersWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onFiltersChanged;
  final Map<String, dynamic> initialFilters;

  const SearchFiltersWidget({
    super.key,
    required this.onFiltersChanged,
    this.initialFilters = const {},
  });

  @override
  State<SearchFiltersWidget> createState() => _SearchFiltersWidgetState();
}

class _SearchFiltersWidgetState extends State<SearchFiltersWidget> {
  late Map<String, dynamic> _filters;

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.initialFilters);
  }

  void _updateFilter(String key, dynamic value) {
    setState(() {
      if (value == null || value == '' || value == 0.0) {
        _filters.remove(key);
      } else {
        _filters[key] = value;
      }
    });
    widget.onFiltersChanged(_filters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() => _filters.clear());
                  widget.onFiltersChanged(_filters);
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Price range
          const Text(
            'Price Range (KES)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Min',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) =>
                      _updateFilter('min_price', double.tryParse(value)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Max',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) =>
                      _updateFilter('max_price', double.tryParse(value)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Condition
          const Text(
            'Condition',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['New', 'Like New', 'Good', 'Fair'].map((condition) {
              final isSelected =
                  _filters['condition'] == condition.toLowerCase();
              return FilterChip(
                label: Text(condition),
                selected: isSelected,
                onSelected: (selected) => _updateFilter(
                  'condition',
                  selected ? condition.toLowerCase() : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Sort by
          const Text('Sort By', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _filters['sort_by'],
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: null, child: Text('Relevance')),
              DropdownMenuItem(
                value: 'price_low',
                child: Text('Price: Low to High'),
              ),
              DropdownMenuItem(
                value: 'price_high',
                child: Text('Price: High to Low'),
              ),
              DropdownMenuItem(value: 'newest', child: Text('Newest First')),
              DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
            ],
            onChanged: (value) => _updateFilter('sort_by', value),
          ),
        ],
      ),
    );
  }
}
