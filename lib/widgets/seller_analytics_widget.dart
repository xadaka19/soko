import 'package:flutter/material.dart';
import '../services/seller_analytics_service.dart';
import '../screens/seller_dashboard_screen.dart';

class SellerAnalyticsWidget extends StatefulWidget {
  const SellerAnalyticsWidget({super.key});

  @override
  State<SellerAnalyticsWidget> createState() => _SellerAnalyticsWidgetState();
}

class _SellerAnalyticsWidgetState extends State<SellerAnalyticsWidget> {
  Map<String, dynamic>? _analytics;
  List<dynamic> _announcements = [];
  bool _isLoading = true;
  bool _hasListings = false;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final analytics = await SellerAnalyticsService.getSellerAnalytics();
      final announcements =
          await SellerAnalyticsService.getSellerAnnouncements();

      setState(() {
        _analytics = analytics;
        _announcements = announcements;
        _hasListings = (analytics['total_listings'] ?? 0) > 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Don't show error for analytics - it's optional
    }
  }

  void _showAnnouncementsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.campaign, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Announcements'),
              const Spacer(),
              if (_announcements.where((a) => !a['is_read']).isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_announcements.where((a) => !a['is_read']).length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: _announcements.isEmpty
                ? const Center(
                    child: Text(
                      'No announcements',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _announcements.length,
                    itemBuilder: (context, index) {
                      final announcement = _announcements[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: announcement['is_read']
                                ? Colors.grey[300]
                                : Colors.blue[100],
                            child: Icon(
                              announcement['is_read']
                                  ? Icons.mark_email_read
                                  : Icons.mark_email_unread,
                              color: announcement['is_read']
                                  ? Colors.grey[600]
                                  : Colors.blue,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            announcement['title'] ?? 'Announcement',
                            style: TextStyle(
                              fontWeight: announcement['is_read']
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(announcement['message'] ?? ''),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(announcement['created_at']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          onTap: () async {
                            if (!announcement['is_read']) {
                              await SellerAnalyticsService.markAnnouncementAsRead(
                                announcement['id'],
                              );
                              setState(() {
                                announcement['is_read'] = true;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!_hasListings) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.store_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              const Text(
                'Start Selling to See Analytics',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first listing to track views, engagement, and performance.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with announcements
        Row(
          children: [
            const Icon(Icons.analytics, color: Colors.blue),
            const SizedBox(width: 8),
            const Text(
              'Seller Analytics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            // View detailed dashboard button
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SellerDashboardScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.analytics, size: 16),
              label: const Text('View Details'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
            // Announcements icon
            Stack(
              children: [
                IconButton(
                  onPressed: _showAnnouncementsDialog,
                  icon: const Icon(Icons.campaign),
                  tooltip: 'Announcements',
                ),
                if (_announcements.where((a) => !a['is_read']).isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Analytics cards
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildAnalyticsCard(
              'Total Views',
              _analytics?['total_views']?.toString() ?? '0',
              Icons.visibility,
              Colors.blue,
            ),
            _buildAnalyticsCard(
              'Active Listings',
              _analytics?['total_listings']?.toString() ?? '0',
              Icons.list_alt,
              Colors.green,
            ),
            _buildAnalyticsCard(
              'CTR',
              '${_analytics?['ctr']?.toStringAsFixed(1) ?? '0.0'}%',
              Icons.mouse,
              Colors.orange,
            ),
            _buildAnalyticsCard(
              'Avg Response',
              _analytics?['avg_response_time'] ?? 'N/A',
              Icons.schedule,
              Colors.purple,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Performance summary
        if (_analytics?['performance_summary'] != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This Week\'s Performance',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPerformanceItem(
                        'Views',
                        _analytics?['performance_summary']?['weekly_views']
                                ?.toString() ??
                            '0',
                        _analytics?['performance_summary']?['views_change'] ??
                            0,
                      ),
                      _buildPerformanceItem(
                        'Contacts',
                        _analytics?['performance_summary']?['weekly_contacts']
                                ?.toString() ??
                            '0',
                        _analytics?['performance_summary']?['contacts_change'] ??
                            0,
                      ),
                      _buildPerformanceItem(
                        'Favorites',
                        _analytics?['performance_summary']?['weekly_favorites']
                                ?.toString() ??
                            '0',
                        _analytics?['performance_summary']?['favorites_change'] ??
                            0,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceItem(String label, String value, double change) {
    final isPositive = change >= 0;
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
              size: 12,
              color: isPositive ? Colors.green : Colors.red,
            ),
            Text(
              '${change.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 10,
                color: isPositive ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
