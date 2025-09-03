import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMoreData = true;
  String _searchQuery = '';
  String _selectedStatus = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreData = true;
        _users.clear();
      });
    }

    setState(() => _isLoading = true);

    try {
      final response = await AdminService.getUsers(
        page: _currentPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _selectedStatus != 'all' ? _selectedStatus : null,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _users = response['users'] ?? [];
          } else {
            _users.addAll(response['users'] ?? []);
          }
          _hasMoreData = (response['users'] ?? []).length >= 20;
          _currentPage++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateUserStatus(
    int userId,
    String status,
    String reason,
  ) async {
    try {
      final success = await AdminService.updateUserStatus(
        userId: userId,
        status: status,
        reason: reason,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User status updated to $status'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers(refresh: true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update user status'),
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

  void _showUserActionDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Manage ${user['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${user['email']}'),
              Text('Phone: ${user['phone'] ?? 'N/A'}'),
              Text('Status: ${user['status']}'),
              Text('Joined: ${_formatDate(user['created_at'])}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            if (user['status'] != 'banned')
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showReasonDialog('ban', user['id']);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Ban User'),
              ),
            if (user['status'] == 'banned')
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _updateUserStatus(user['id'], 'active', 'Unbanned by admin');
                },
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                child: const Text('Unban User'),
              ),
            if (user['status'] != 'suspended')
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showReasonDialog('suspended', user['id']);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                child: const Text('Suspend'),
              ),
          ],
        );
      },
    );
  }

  void _showReasonDialog(String action, int userId) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${action.toUpperCase()} User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please provide a reason for ${action}ing this user:'),
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
                _updateUserStatus(userId, action, reasonController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: action == 'ban' ? Colors.red : Colors.orange,
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
        title: const Text('Manage Users'),
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
                    hintText: 'Search users by name or email...',
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
                    _loadUsers(refresh: true);
                  },
                ),
                const SizedBox(height: 12),

                // Status filter
                Row(
                  children: [
                    const Text('Status: '),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Active'),
                          ),
                          DropdownMenuItem(
                            value: 'suspended',
                            child: Text('Suspended'),
                          ),
                          DropdownMenuItem(
                            value: 'banned',
                            child: Text('Banned'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedStatus = value!);
                          _loadUsers(refresh: true);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Users list
          Expanded(
            child: _isLoading && _users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                ? const Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadUsers(refresh: true),
                    child: ListView.builder(
                      itemCount: _users.length + (_hasMoreData ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _users.length) {
                          // Load more indicator
                          if (!_isLoading) {
                            _loadUsers();
                          }
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final user = _users[index];
                        return _buildUserCard(user);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(user['status']),
          child: Text(
            user['name']?.substring(0, 1).toUpperCase() ?? 'U',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user['name'] ?? 'Unknown User',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email'] ?? 'No email'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(user['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user['status']?.toUpperCase() ?? 'UNKNOWN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Joined: ${_formatDate(user['created_at'])}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: () => _showUserActionDialog(user),
          icon: const Icon(Icons.more_vert),
        ),
        onTap: () => _showUserActionDialog(user),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'suspended':
        return Colors.orange;
      case 'banned':
        return Colors.red;
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
