import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = true;
  bool _notificationsEnabled = false;
  Map<String, dynamic> _notificationSettings = {};
  String? _fcmToken;

  // Notification preferences
  bool _newMessagesEnabled = true;
  bool _listingInquiriesEnabled = true;
  bool _priceDropsEnabled = true;
  bool _newListingsEnabled = false;
  bool _marketingEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() => _isLoading = true);

    try {
      final enabled = await NotificationService.areNotificationsEnabled();
      final settings = await NotificationService.getNotificationSettings();
      final token = NotificationService.fcmToken;

      setState(() {
        _notificationsEnabled = enabled;
        _notificationSettings = settings;
        _fcmToken = token;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      await NotificationService.sendTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending test notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      await NotificationService.clearAllNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications cleared'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing notifications: $e'),
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
        title: const Text('Notification Settings'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Notification Status Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _notificationsEnabled 
                                  ? Icons.notifications_active 
                                  : Icons.notifications_off,
                              color: _notificationsEnabled 
                                  ? Colors.green 
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Notification Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        _buildStatusRow(
                          'Notifications Enabled',
                          _notificationsEnabled,
                        ),
                        _buildStatusRow(
                          'Alert Permissions',
                          _notificationSettings['alert'] ?? false,
                        ),
                        _buildStatusRow(
                          'Badge Permissions',
                          _notificationSettings['badge'] ?? false,
                        ),
                        _buildStatusRow(
                          'Sound Permissions',
                          _notificationSettings['sound'] ?? false,
                        ),
                        
                        if (_fcmToken != null) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            'Device Token',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _fcmToken!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Notification Preferences Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.tune,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Notification Preferences',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        _buildPreferenceSwitch(
                          'New Messages',
                          'Get notified when you receive new messages',
                          Icons.message,
                          _newMessagesEnabled,
                          (value) => setState(() => _newMessagesEnabled = value),
                        ),
                        
                        _buildPreferenceSwitch(
                          'Listing Inquiries',
                          'Get notified when someone inquires about your listings',
                          Icons.help_outline,
                          _listingInquiriesEnabled,
                          (value) => setState(() => _listingInquiriesEnabled = value),
                        ),
                        
                        _buildPreferenceSwitch(
                          'Price Drops',
                          'Get notified when items you\'re watching drop in price',
                          Icons.trending_down,
                          _priceDropsEnabled,
                          (value) => setState(() => _priceDropsEnabled = value),
                        ),
                        
                        _buildPreferenceSwitch(
                          'New Listings',
                          'Get notified about new listings in your area',
                          Icons.new_releases,
                          _newListingsEnabled,
                          (value) => setState(() => _newListingsEnabled = value),
                        ),
                        
                        _buildPreferenceSwitch(
                          'Marketing & Promotions',
                          'Get notified about special offers and promotions',
                          Icons.local_offer,
                          _marketingEnabled,
                          (value) => setState(() => _marketingEnabled = value),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Actions Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.settings,
                              color: Colors.orange.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Actions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.send, color: Colors.blue),
                          title: const Text('Send Test Notification'),
                          subtitle: const Text('Test if notifications are working'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: _sendTestNotification,
                        ),
                        
                        const Divider(),
                        
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.clear_all, color: Colors.orange),
                          title: const Text('Clear All Notifications'),
                          subtitle: const Text('Remove all pending notifications'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: _clearAllNotifications,
                        ),
                        
                        const Divider(),
                        
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.refresh, color: Colors.green),
                          title: const Text('Refresh Settings'),
                          subtitle: const Text('Reload notification settings'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: _loadNotificationSettings,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            color: status ? Colors.green : Colors.red,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceSwitch(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.green),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green,
      ),
    );
  }
}
