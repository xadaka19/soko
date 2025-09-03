import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../widgets/plan_badge.dart';
import '../../utils/image_utils.dart';

class AdminListingsScreen extends StatefulWidget {
  const AdminListingsScreen({super.key});

  @override
  State<AdminListingsScreen> createState() => _AdminListingsScreenState();
}

class _AdminListingsScreenState extends State<AdminListingsScreen> {
  List<dynamic> _listings = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMoreData = true;
  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedCategory = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadListings({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreData = true;
        _listings.clear();
      });
    }

    setState(() => _isLoading = true);

    try {
      final response = await AdminService.getListings(
        page: _currentPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _selectedStatus != 'all' ? _selectedStatus : null,
        category: _selectedCategory != 'all' ? _selectedCategory : null,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _listings = response['listings'] ?? [];
          } else {
            _listings.addAll(response['listings'] ?? []);
          }
          _hasMoreData = (response['listings'] ?? []).length >= 20;
          _currentPage++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load listings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateListingStatus(
    int listingId,
    String status,
    String reason,
  ) async {
    try {
      final success = await AdminService.updateListingStatus(
        listingId: listingId,
        status: status,
        reason: reason,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Listing status updated to $status'),
            backgroundColor: Colors.green,
          ),
        );
        _loadListings(refresh: true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update listing status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showListingActionDialog(Map<String, dynamic> listing) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Manage Listing'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Title: ${listing['title']}'),
              Text('Price: KES ${listing['price']}'),
              Text('Seller: ${listing['seller_name']}'),
              Text('Status: ${listing['status']}'),
              Text('Category: ${listing['category_name']}'),
              Text('Created: ${_formatDate(listing['created_at'])}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            if (listing['status'] != 'approved')
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _updateListingStatus(
                    listing['id'],
                    'approved',
                    'Approved by admin',
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                child: const Text('Approve'),
              ),
            if (listing['status'] != 'rejected')
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showReasonDialog('rejected', listing['id']);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Reject'),
              ),
            if (listing['status'] != 'hidden')
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showReasonDialog('hidden', listing['id']);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                child: const Text('Hide'),
              ),
          ],
        );
      },
    );
  }

  void _showReasonDialog(String action, int listingId) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${action.toUpperCase()} Listing'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please provide a reason for ${action}ing this listing:'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateListingStatus(listingId, action, reasonController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: action == 'rejected'
                    ? Colors.red
                    : Colors.orange,
              ),
              child: Text(action.toUpperCase()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Listings'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search listings by title...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (value) {
                    setState(() => _searchQuery = value);
                    _loadListings(refresh: true);
                  },
                ),
                const SizedBox(height: 12),

                // Filters row
                Row(
                  children: [
                    // Status filter
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Status:', style: TextStyle(fontSize: 12)),
                          DropdownButton<String>(
                            value: _selectedStatus,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All'),
                              ),
                              DropdownMenuItem(
                                value: 'pending',
                                child: Text('Pending'),
                              ),
                              DropdownMenuItem(
                                value: 'approved',
                                child: Text('Approved'),
                              ),
                              DropdownMenuItem(
                                value: 'rejected',
                                child: Text('Rejected'),
                              ),
                              DropdownMenuItem(
                                value: 'hidden',
                                child: Text('Hidden'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedStatus = value!);
                              _loadListings(refresh: true);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Category filter
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Category:',
                            style: TextStyle(fontSize: 12),
                          ),
                          DropdownButton<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All'),
                              ),
                              DropdownMenuItem(
                                value: 'vehicles',
                                child: Text('Vehicles'),
                              ),
                              DropdownMenuItem(
                                value: 'electronics',
                                child: Text('Electronics'),
                              ),
                              DropdownMenuItem(
                                value: 'fashion',
                                child: Text('Fashion'),
                              ),
                              DropdownMenuItem(
                                value: 'home',
                                child: Text('Home & Garden'),
                              ),
                              DropdownMenuItem(
                                value: 'services',
                                child: Text('Services'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedCategory = value!);
                              _loadListings(refresh: true);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Listings list
          Expanded(
            child: _isLoading && _listings.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _listings.isEmpty
                ? const Center(
                    child: Text(
                      'No listings found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadListings(refresh: true),
                    child: ListView.builder(
                      itemCount: _listings.length + (_hasMoreData ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _listings.length) {
                          // Load more indicator
                          if (!_isLoading) {
                            _loadListings();
                          }
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final listing = _listings[index];
                        return _buildListingCard(listing);
                      },
                    ),
                  ),
          ),
        ],
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                listing['title'] ?? 'No title',
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (listing['plan_type'] != null)
              PlanBadgeIcon(planType: listing['plan_type'], size: 16),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('KES ${listing['price'] ?? '0'}'),
            Text('Seller: ${listing['seller_name'] ?? 'Unknown'}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(listing['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    listing['status']?.toUpperCase() ?? 'UNKNOWN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(listing['created_at']),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: () => _showListingActionDialog(listing),
          icon: const Icon(Icons.more_vert),
        ),
        onTap: () => _showListingActionDialog(listing),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'hidden':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
