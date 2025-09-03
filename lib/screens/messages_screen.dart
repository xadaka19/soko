import 'package:flutter/material.dart';
import '../services/messaging_service.dart';
import '../widgets/ellipsis_loader.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  List<Map<String, dynamic>> _allMessages = [];
  List<Map<String, dynamic>> _filteredMessages = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Live messages will be loaded from API

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final result = await MessagingService.getConversations();

      setState(() {
        if (result['success'] == true) {
          _allMessages = List<Map<String, dynamic>>.from(
            result['conversations'] ?? [],
          );
          _filterMessages();
        } else {
          _allMessages = [];
          _filteredMessages = [];
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading messages: $e');
      setState(() {
        _allMessages = [];
        _filteredMessages = [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    _filterMessages();
  }

  void _filterMessages() {
    setState(() {
      List<Map<String, dynamic>> filtered = List.from(_allMessages);

      // Apply tab filter
      switch (_tabController.index) {
        case 0: // All
          // No additional filtering
          break;
        case 1: // Unread
          filtered = filtered.where((msg) => msg['unread'] == true).toList();
          break;
        case 2: // Spam
          filtered = filtered.where((msg) => msg['is_spam'] == true).toList();
          break;
      }

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        filtered = filtered.where((msg) {
          final senderName = msg['sender_name']?.toString().toLowerCase() ?? '';
          final lastMessage =
              msg['last_message']?.toString().toLowerCase() ?? '';
          final query = _searchQuery.toLowerCase();

          return senderName.contains(query) || lastMessage.contains(query);
        }).toList();
      }

      _filteredMessages = filtered;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterMessages();
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  int _getUnreadCount() {
    return _allMessages
        .where((msg) => msg['unread'] == true && msg['is_spam'] != true)
        .length;
  }

  int _getSpamCount() {
    return _allMessages.where((msg) => msg['is_spam'] == true).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: const Color(0xFF5BE206),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('All'),
                  if (_getUnreadCount() > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getUnreadCount().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Unread'),
                  if (_getUnreadCount() > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getUnreadCount().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Spam'),
                  if (_getSpamCount() > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getSpamCount().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search messages...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),

          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: BouncingEllipsisLoader())
                : _filteredMessages.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadMessages,
                    child: ListView.builder(
                      itemCount: _filteredMessages.length,
                      itemBuilder: (context, index) {
                        final message = _filteredMessages[index];
                        return _buildMessageTile(message);
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
          Icon(Icons.message_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation by contacting a seller',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTile(Map<String, dynamic> message) {
    final isSpam = message['is_spam'] == true;

    return Container(
      decoration: BoxDecoration(
        color: isSpam ? Colors.red.shade50 : null,
        border: isSpam
            ? Border.all(color: Colors.red.shade200, width: 1)
            : null,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSpam
              ? Colors.red[100]
              : const Color(0xFF5BE206).withValues(alpha: 0.1),
          child: isSpam
              ? const Icon(Icons.warning, color: Colors.red, size: 20)
              : Text(
                  message['sender_name'][0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF5BE206),
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                message['sender_name'],
                style: TextStyle(
                  fontWeight: message['unread']
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isSpam ? Colors.red.shade700 : null,
                ),
              ),
            ),
            if (isSpam)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'SPAM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          message['last_message'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSpam
                ? Colors.red.shade600
                : (message['unread'] ? Colors.black87 : Colors.grey[600]),
            fontWeight: message['unread'] ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message['timestamp'],
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            if (message['unread'] && !isSpam)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF5BE206),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        onTap: () {
          // Navigate to message thread
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatId: message['chat_id'] ?? '',
                recipientName: message['sender_name'] ?? 'Unknown',
                recipientId: message['sender_id'] ?? 0,
              ),
            ),
          );
        },
      ),
    );
  }
}
