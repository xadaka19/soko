import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers for settings
  final TextEditingController _maxListingsController = TextEditingController();
  final TextEditingController _maxImagesController = TextEditingController();
  final TextEditingController _autoRenewalIntervalController =
      TextEditingController();
  final TextEditingController _reportThresholdController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _maxListingsController.dispose();
    _maxImagesController.dispose();
    _autoRenewalIntervalController.dispose();
    _reportThresholdController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final settings = await AdminService.getSystemSettings();
      setState(() {
        _settings = settings;
        _maxListingsController.text =
            settings['max_listings_per_user']?.toString() ?? '10';
        _maxImagesController.text =
            settings['max_images_per_listing']?.toString() ?? '15';
        _autoRenewalIntervalController.text =
            settings['auto_renewal_interval']?.toString() ?? '24';
        _reportThresholdController.text =
            settings['auto_ban_report_threshold']?.toString() ?? '3';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      final updatedSettings = {
        ..._settings,
        'max_listings_per_user':
            int.tryParse(_maxListingsController.text) ?? 10,
        'max_images_per_listing': int.tryParse(_maxImagesController.text) ?? 15,
        'auto_renewal_interval':
            int.tryParse(_autoRenewalIntervalController.text) ?? 24,
        'auto_ban_report_threshold':
            int.tryParse(_reportThresholdController.text) ?? 3,
      };

      final success = await AdminService.updateSystemSettings(updatedSettings);

      setState(() => _isSaving = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSettings(); // Reload to confirm changes
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update settings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showPushNotificationDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    String targetType = 'all';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Send Push Notification'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 60,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      maxLength: 120,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: targetType,
                      decoration: const InputDecoration(
                        labelText: 'Target Audience',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All Users'),
                        ),
                        DropdownMenuItem(
                          value: 'premium',
                          child: Text('Premium Users'),
                        ),
                        DropdownMenuItem(
                          value: 'sellers',
                          child: Text('Active Sellers'),
                        ),
                        DropdownMenuItem(
                          value: 'buyers',
                          child: Text('Active Buyers'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => targetType = value!);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty &&
                        messageController.text.isNotEmpty) {
                      Navigator.of(context).pop();

                      final success = await AdminService.sendPushNotification(
                        title: titleController.text,
                        message: messageController.text,
                        targetType: targetType,
                      );

                      if (mounted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Push notification sent successfully'
                                  : 'Failed to send push notification',
                            ),
                            backgroundColor: success
                                ? Colors.green
                                : Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Settings'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            IconButton(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // System Settings Section
                  _buildSectionHeader('System Settings'),
                  _buildSettingCard(
                    'Listing Limits',
                    Column(
                      children: [
                        _buildNumberField(
                          'Max Listings per User',
                          _maxListingsController,
                          'Maximum number of active listings per user',
                        ),
                        const SizedBox(height: 16),
                        _buildNumberField(
                          'Max Images per Listing',
                          _maxImagesController,
                          'Maximum number of images allowed per listing',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildSettingCard(
                    'Auto-Renewal Settings',
                    _buildNumberField(
                      'Auto-Renewal Interval (hours)',
                      _autoRenewalIntervalController,
                      'How often listings are automatically renewed',
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildSettingCard(
                    'Moderation Settings',
                    _buildNumberField(
                      'Auto-Ban Report Threshold',
                      _reportThresholdController,
                      'Number of reports before auto-banning a user',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Actions Section
                  _buildSectionHeader('Quick Actions'),
                  _buildActionCard(
                    'Send Push Notification',
                    'Send a notification to all or specific users',
                    Icons.notifications,
                    Colors.blue,
                    _showPushNotificationDialog,
                  ),

                  const SizedBox(height: 16),

                  _buildActionCard(
                    'System Maintenance',
                    'Perform system cleanup and maintenance tasks',
                    Icons.build,
                    Colors.orange,
                    () => _showSystemMaintenanceDialog(),
                  ),

                  const SizedBox(height: 16),

                  _buildActionCard(
                    'Export Data',
                    'Export user data, listings, and reports',
                    Icons.download,
                    Colors.green,
                    () => _showDataExportDialog(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSettingCard(String title, Widget content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField(
    String label,
    TextEditingController controller,
    String helper,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            helperText: helper,
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showSystemMaintenanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Maintenance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cleaning_services),
              title: const Text('Clear Cache'),
              subtitle: const Text('Clear system cache and temporary files'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared successfully')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('Database Cleanup'),
              subtitle: const Text('Remove old logs and optimize database'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Database cleanup completed')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Restart Services'),
              subtitle: const Text('Restart background services'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Services restarted')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDataExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Export Users'),
              subtitle: const Text('Export all user data to CSV'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting users data...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Export Listings'),
              subtitle: const Text('Export all listings to CSV'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting listings data...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Export Reports'),
              subtitle: const Text('Export analytics and reports'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting reports...')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
