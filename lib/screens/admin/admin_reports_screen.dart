import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  List<dynamic> _reports = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMoreData = true;
  String _selectedStatus = 'all';
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreData = true;
        _reports.clear();
      });
    }

    setState(() => _isLoading = true);

    try {
      final response = await AdminService.getReports(
        page: _currentPage,
        status: _selectedStatus != 'all' ? _selectedStatus : null,
        type: _selectedType != 'all' ? _selectedType : null,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _reports = response['reports'] ?? [];
          } else {
            _reports.addAll(response['reports'] ?? []);
          }
          _hasMoreData = (response['reports'] ?? []).length >= 20;
          _currentPage++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load reports: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateReportStatus(int reportId, String status, String adminNotes) async {
    try {
      final success = await AdminService.updateReportStatus(
        reportId: reportId,
        status: status,
        adminNotes: adminNotes,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report status updated to $status'),
            backgroundColor: Colors.green,
          ),
        );
        _loadReports(refresh: true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update report status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReportDetailsDialog(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Report Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Type', report['type']),
                _buildDetailRow('Reporter', report['reporter_name']),
                _buildDetailRow('Reported Item', report['reported_item_title']),
                _buildDetailRow('Reason', report['reason']),
                _buildDetailRow('Description', report['description']),
                _buildDetailRow('Status', report['status']),
                _buildDetailRow('Submitted', _formatDate(report['created_at'])),
                if (report['admin_notes'] != null)
                  _buildDetailRow('Admin Notes', report['admin_notes']),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (report['status'] == 'pending') ...[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showActionDialog(report, 'resolved');
                },
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                child: const Text('Resolve'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showActionDialog(report, 'dismissed');
                },
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                child: const Text('Dismiss'),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  void _showActionDialog(Map<String, dynamic> report, String action) {
    final TextEditingController notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${action.toUpperCase()} Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please provide admin notes for ${action}ing this report:'),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Admin Notes',
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
                _updateReportStatus(report['id'], action, notesController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: action == 'resolved' ? Colors.green : Colors.orange,
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
        title: const Text('Reports & Analytics'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
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
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(value: 'pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                          DropdownMenuItem(value: 'dismissed', child: Text('Dismissed')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedStatus = value!);
                          _loadReports(refresh: true);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Type filter
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Type:', style: TextStyle(fontSize: 12)),
                      DropdownButton<String>(
                        value: _selectedType,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(value: 'spam', child: Text('Spam')),
                          DropdownMenuItem(value: 'inappropriate', child: Text('Inappropriate')),
                          DropdownMenuItem(value: 'fraud', child: Text('Fraud')),
                          DropdownMenuItem(value: 'duplicate', child: Text('Duplicate')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedType = value!);
                          _loadReports(refresh: true);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Reports list
          Expanded(
            child: _isLoading && _reports.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _reports.isEmpty
                    ? const Center(
                        child: Text(
                          'No reports found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadReports(refresh: true),
                        child: ListView.builder(
                          itemCount: _reports.length + (_hasMoreData ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _reports.length) {
                              // Load more indicator
                              if (!_isLoading) {
                                _loadReports();
                              }
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            
                            final report = _reports[index];
                            return _buildReportCard(report);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(report['type']),
          child: Icon(
            _getTypeIcon(report['type']),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          '${report['type']?.toUpperCase() ?? 'UNKNOWN'} Report',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item: ${report['reported_item_title'] ?? 'Unknown'}'),
            Text('Reporter: ${report['reporter_name'] ?? 'Anonymous'}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(report['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report['status']?.toUpperCase() ?? 'UNKNOWN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(report['created_at']),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: () => _showReportDetailsDialog(report),
          icon: const Icon(Icons.more_vert),
        ),
        onTap: () => _showReportDetailsDialog(report),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'spam':
        return Colors.red;
      case 'inappropriate':
        return Colors.purple;
      case 'fraud':
        return Colors.deepOrange;
      case 'duplicate':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'spam':
        return Icons.block;
      case 'inappropriate':
        return Icons.warning;
      case 'fraud':
        return Icons.security;
      case 'duplicate':
        return Icons.content_copy;
      default:
        return Icons.report;
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
