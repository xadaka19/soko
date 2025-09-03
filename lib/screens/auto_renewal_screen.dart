import 'package:flutter/material.dart';
import '../services/auto_renewal_service.dart';
import '../utils/session_manager.dart';

class AutoRenewalScreen extends StatefulWidget {
  const AutoRenewalScreen({super.key});

  @override
  State<AutoRenewalScreen> createState() => _AutoRenewalScreenState();
}

class _AutoRenewalScreenState extends State<AutoRenewalScreen> {
  List<Map<String, dynamic>> _listings = [];
  bool _isLoading = true;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserAndListings();
  }

  Future<void> _loadUserAndListings() async {
    setState(() => _isLoading = true);
    
    try {
      _currentUser = await SessionManager.getUser();
      if (_currentUser != null) {
        final listings = await AutoRenewalService.getUserRenewalStatus(
          int.parse(_currentUser!['id'].toString()),
        );
        setState(() {
          _listings = listings;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAutoRenewal(int listingId, bool enabled) async {
    if (_currentUser == null) return;

    final success = await AutoRenewalService.toggleAutoRenewal(
      listingId,
      int.parse(_currentUser!['id'].toString()),
      enabled,
    );

    if (success) {
      setState(() {
        final index = _listings.indexWhere((l) => l['id'] == listingId);
        if (index != -1) {
          _listings[index]['auto_renewal_enabled'] = enabled;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled 
                ? 'Auto-renewal enabled' 
                : 'Auto-renewal disabled',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update auto-renewal setting'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _renewNow(int listingId) async {
    if (_currentUser == null) return;

    final success = await AutoRenewalService.renewListing(
      listingId,
      int.parse(_currentUser!['id'].toString()),
    );

    if (success) {
      await _loadUserAndListings(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing renewed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to renew listing'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto-Renewal Settings'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _listings.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Info card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[600]),
                              const SizedBox(width: 8),
                              const Text(
                                'Auto-Renewal Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Auto-renewal keeps your listings active and moves them to the top of search results. Renewal frequency depends on your plan type.',
                          ),
                        ],
                      ),
                    ),
                    
                    // Listings
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _listings.length,
                        itemBuilder: (context, index) {
                          final listing = _listings[index];
                          return _buildListingCard(listing);
                        },
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
          Icon(Icons.auto_awesome, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No Active Listings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create some listings to manage auto-renewal settings',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    final isAutoRenewalEnabled = listing['auto_renewal_enabled'] == true;
    final planType = listing['plan_type'] ?? 'free';
    final lastRenewal = DateTime.tryParse(listing['last_renewal'] ?? '') ?? DateTime.now();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    listing['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Switch(
                  value: isAutoRenewalEnabled,
                  onChanged: (value) => _toggleAutoRenewal(listing['id'], value),
                  activeColor: Colors.green,
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Plan and schedule info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    planType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AutoRenewalService.getRenewalScheduleText(planType),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Time until renewal
            Text(
              AutoRenewalService.getTimeUntilRenewal(lastRenewal, planType),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Action button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _renewNow(listing['id']),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Renew Now'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
