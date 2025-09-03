import 'package:flutter/material.dart';
import '../../services/push_notification_service.dart';
import '../../widgets/ellipsis_loader.dart';

class PushNotificationsScreen extends StatefulWidget {
  const PushNotificationsScreen({super.key});

  @override
  State<PushNotificationsScreen> createState() =>
      _PushNotificationsScreenState();
}

class _PushNotificationsScreenState extends State<PushNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Send notification form
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _deepLinkController = TextEditingController();
  String _selectedTarget = 'all';
  DateTime? _scheduledTime;
  bool _isSending = false;

  // Analytics data
  Map<String, dynamic>? _analytics;
  List<dynamic> _notificationHistory = [];
  bool _isLoadingAnalytics = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    _imageUrlController.dispose();
    _deepLinkController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoadingAnalytics = true);

    try {
      final analytics =
          await PushNotificationService.getNotificationAnalytics();
      final history = await PushNotificationService.getNotificationHistory();

      setState(() {
        _analytics = analytics;
        _notificationHistory = history;
        _isLoadingAnalytics = false;
      });
    } catch (e) {
      setState(() => _isLoadingAnalytics = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load analytics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in title and message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      Map<String, dynamic> result;

      if (_scheduledTime != null) {
        // Schedule notification
        result = await PushNotificationService.scheduleNotification(
          title: _titleController.text,
          message: _messageController.text,
          scheduledTime: _scheduledTime!,
          targetType: _selectedTarget,
          imageUrl: _imageUrlController.text.isNotEmpty
              ? _imageUrlController.text
              : null,
          deepLink: _deepLinkController.text.isNotEmpty
              ? _deepLinkController.text
              : null,
        );
      } else {
        // Send immediately
        result = await PushNotificationService.sendTargetedNotification(
          title: _titleController.text,
          message: _messageController.text,
          targetType: _selectedTarget,
          imageUrl: _imageUrlController.text.isNotEmpty
              ? _imageUrlController.text
              : null,
          deepLink: _deepLinkController.text.isNotEmpty
              ? _deepLinkController.text
              : null,
        );
      }

      setState(() => _isSending = false);

      if (result['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _scheduledTime != null
                  ? 'Notification scheduled successfully'
                  : 'Notification sent to ${result['recipients_count']} users',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _titleController.clear();
        _messageController.clear();
        _imageUrlController.clear();
        _deepLinkController.clear();
        _scheduledTime = null;

        // Reload analytics
        _loadAnalytics();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to send notification'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectScheduledTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _scheduledTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push Notifications'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Send', icon: Icon(Icons.send)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSendTab(), _buildAnalyticsTab(), _buildHistoryTab()],
      ),
    );
  }

  Widget _buildSendTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title field
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Notification Title',
              border: OutlineInputBorder(),
              helperText: 'Keep it short and engaging (max 60 characters)',
            ),
            maxLength: 60,
          ),
          const SizedBox(height: 16),

          // Message field
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Message',
              border: OutlineInputBorder(),
              helperText: 'Clear and actionable message (max 120 characters)',
            ),
            maxLines: 3,
            maxLength: 120,
          ),
          const SizedBox(height: 16),

          // Target audience
          DropdownButtonFormField<String>(
            value: _selectedTarget,
            decoration: const InputDecoration(
              labelText: 'Target Audience',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Users')),
              DropdownMenuItem(value: 'premium', child: Text('Premium Users')),
              DropdownMenuItem(value: 'sellers', child: Text('Active Sellers')),
              DropdownMenuItem(value: 'buyers', child: Text('Active Buyers')),
            ],
            onChanged: (value) {
              setState(() => _selectedTarget = value!);
            },
          ),
          const SizedBox(height: 16),

          // Optional fields
          ExpansionTile(
            title: const Text('Advanced Options'),
            children: [
              const SizedBox(height: 8),
              TextField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL (Optional)',
                  border: OutlineInputBorder(),
                  helperText: 'URL to an image for rich notifications',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _deepLinkController,
                decoration: const InputDecoration(
                  labelText: 'Deep Link (Optional)',
                  border: OutlineInputBorder(),
                  helperText: 'Where to navigate when notification is tapped',
                ),
              ),
              const SizedBox(height: 16),

              // Schedule option
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _scheduledTime == null
                          ? 'Send immediately'
                          : 'Scheduled: ${_scheduledTime!.toString().substring(0, 16)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _selectScheduledTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(_scheduledTime == null ? 'Schedule' : 'Change'),
                  ),
                  if (_scheduledTime != null)
                    IconButton(
                      onPressed: () => setState(() => _scheduledTime = null),
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear schedule',
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Send button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendNotification,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _scheduledTime == null ? Icons.send : Icons.schedule_send,
                    ),
              label: Text(
                _isSending
                    ? 'Sending...'
                    : _scheduledTime == null
                    ? 'Send Notification'
                    : 'Schedule Notification',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (_isLoadingAnalytics) {
      return const Center(child: BouncingEllipsisLoader());
    }

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analytics cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildAnalyticsCard(
                  'Total Sent',
                  _analytics?['total_sent']?.toString() ?? '0',
                  Icons.send,
                  Colors.blue,
                ),
                _buildAnalyticsCard(
                  'Delivery Rate',
                  '${_analytics?['delivery_rate']?.toStringAsFixed(1) ?? '0.0'}%',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildAnalyticsCard(
                  'Open Rate',
                  '${_analytics?['open_rate']?.toStringAsFixed(1) ?? '0.0'}%',
                  Icons.open_in_new,
                  Colors.orange,
                ),
                _buildAnalyticsCard(
                  'Click Rate',
                  '${_analytics?['click_rate']?.toStringAsFixed(1) ?? '0.0'}%',
                  Icons.mouse,
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Performance chart placeholder
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Performance Trends',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Performance Chart\n(Chart implementation needed)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
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

  Widget _buildHistoryTab() {
    if (_isLoadingAnalytics) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: _notificationHistory.isEmpty
          ? const Center(
              child: Text(
                'No notification history',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notificationHistory.length,
              itemBuilder: (context, index) {
                final notification = _notificationHistory[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(notification['status']),
                      child: Icon(
                        _getStatusIcon(notification['status']),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      notification['title'] ?? 'No title',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification['message'] ?? ''),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Target: ${notification['target_type'] ?? 'Unknown'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Sent: ${notification['recipients_count'] ?? 0}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          notification['status']?.toUpperCase() ?? 'UNKNOWN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(notification['status']),
                          ),
                        ),
                        Text(
                          _formatDate(notification['created_at']),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
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

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'sent':
        return Colors.green;
      case 'scheduled':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'sent':
        return Icons.check_circle;
      case 'scheduled':
        return Icons.schedule;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}
