import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import '../config/api.dart';
import '../utils/session_manager.dart';
import '../utils/image_utils.dart';
import '../services/subscription_service.dart';
import '../services/listing_service.dart';
import '../services/whatsapp_service.dart';
import '../services/firebase_service.dart';
import '../services/recommendation_service.dart';
import '../widgets/plan_badge.dart';
import '../widgets/seller_reviews_widget.dart';
import '../widgets/ellipsis_loader.dart';
import 'login_screen.dart';
import 'seller_listings_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> listing;

  const ListingDetailScreen({super.key, required this.listing});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  Map<String, dynamic>? _detailedListing;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFavorite = false;
  Map<String, dynamic>? _currentUser;

  // Credit and subscription info
  int _creditsRemaining = 0;

  // Similar listings
  List<Map<String, dynamic>> _similarListings = [];
  bool _isLoadingSimilar = false;

  @override
  void initState() {
    super.initState();
    _loadDataConcurrently();

    // Track screen view
    FirebaseService.trackScreenView('listing_detail_screen');

    // Track listing view for recommendations
    _trackListingView();
  }

  Future<void> _trackListingView() async {
    try {
      await RecommendationService.trackListingView(
        listingId: widget.listing['id']?.toString() ?? '',
        categoryId: widget.listing['category_id']?.toString() ?? '',
        subcategoryId: widget.listing['subcategory_id']?.toString(),
        location: widget.listing['location']?.toString(),
        priceRange: _getPriceRange(widget.listing['price']),
      );
    } catch (e) {
      // Silently handle tracking errors
      debugPrint('Error tracking listing view: $e');
    }
  }

  String _getPriceRange(dynamic price) {
    final priceInt = int.tryParse(price.toString()) ?? 0;

    if (priceInt < 1000) return 'under_1k';
    if (priceInt < 5000) return '1k_5k';
    if (priceInt < 10000) return '5k_10k';
    if (priceInt < 50000) return '10k_50k';
    if (priceInt < 100000) return '50k_100k';
    return 'over_100k';
  }

  Future<void> _loadDataConcurrently() async {
    // Load user and listing details concurrently
    await Future.wait([_loadCurrentUser(), _loadListingDetails()]);

    // Load similar listings after main data is loaded
    if (_detailedListing != null) {
      _loadSimilarListings();
    }
  }

  Future<void> _loadSimilarListings() async {
    try {
      setState(() {
        _isLoadingSimilar = true;
      });

      final categoryId = _detailedListing?['category_id'];
      if (categoryId != null) {
        final similarListings = await ListingService.getListings(
          category: categoryId.toString(),
          limit: 5,
        );

        // Remove current listing from similar listings
        final filtered = similarListings
            .where((listing) => listing['id'] != widget.listing['id'])
            .take(4)
            .toList()
            .cast<Map<String, dynamic>>();

        if (mounted) {
          setState(() {
            _similarListings = filtered;
            _isLoadingSimilar = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSimilar = false;
        });
      }
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      _currentUser = await SessionManager.getUser();

      if (_currentUser != null) {
        // Load user's subscription info
        final credits = await SubscriptionService.getLocalCredits();

        if (mounted) {
          setState(() {
            _creditsRemaining = credits;
          });
        }
      }
    } catch (e) {
      // Handle error silently for user loading
    }
  }

  Future<void> _loadListingDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final listingId = widget.listing['id'].toString();
      debugPrint('Loading listing details for ID: $listingId');

      final response = await http
          .get(
            Uri.parse(
              '${Api.baseUrl}${Api.getListingEndpoint}',
            ).replace(queryParameters: {'listing_id': listingId}),
            headers: Api.headers,
          )
          .timeout(Api.timeout);

      debugPrint('Listing detail response status: ${response.statusCode}');
      debugPrint('Listing detail response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Handle different response formats
          if (data.containsKey('listing') && data['listing'] != null) {
            // Single listing format
            setState(() {
              _detailedListing = data['listing'];
              _isFavorite = data['is_favorite'] ?? false;
              _isLoading = false;
            });
          } else if (data.containsKey('listings') && data['listings'] is List) {
            // Listings array format
            final listings = data['listings'] as List;
            if (listings.isNotEmpty) {
              setState(() {
                _detailedListing = listings.first;
                _isFavorite = data['is_favorite'] ?? false;
                _isLoading = false;
              });
            } else {
              throw Exception('No listing found');
            }
          } else {
            // Fallback: use the original listing data
            debugPrint('Using fallback listing data');
            setState(() {
              _detailedListing = widget.listing;
              _isFavorite = false;
              _isLoading = false;
            });
          }
        } else {
          throw Exception(
            data['error'] ??
                data['message'] ??
                'Failed to load listing details',
          );
        }
      } else if (response.statusCode == 404) {
        // Listing not found, use original data
        debugPrint('Listing not found on server, using original data');
        setState(() {
          _detailedListing = widget.listing;
          _isFavorite = false;
          _isLoading = false;
        });
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading listing details: $e');
      // Fallback to using the original listing data
      setState(() {
        _detailedListing = widget.listing;
        _isFavorite = false;
        _isLoading = false;
        _errorMessage = null; // Don't show error, just use fallback
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please login to add favorites'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Login',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          ),
        );
      }
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}/api/toggle-favorite.php'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': _currentUser!['id'],
              'listing_id': widget.listing['id'],
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _isFavorite = data['is_favorite'];
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isFavorite ? 'Added to favorites' : 'Removed from favorites',
                ),
                backgroundColor: const Color(0xFF5BE206),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _contactSeller() async {
    final listing = _detailedListing ?? widget.listing;

    // Track contact seller analytics
    FirebaseService.logEvent('contact_seller_initiated', {
      'listing_id': listing['id'].toString(),
      'listing_title': listing['title'] ?? '',
      'seller_id': listing['seller_id']?.toString() ?? '',
      'plan_type': listing['plan_type'] ?? 'free',
    });

    // Show contact options dialog
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => _buildContactSellerSheet(listing),
      );
    }
  }

  Widget _buildContactSellerSheet(Map<String, dynamic> listing) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF5BE206),
                  child: Text(
                    _getSellerInitial(listing['seller_name']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact ${listing['seller_name'] ?? 'Seller'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'About: ${listing['title'] ?? 'Item'}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Contact options - ONLY for logged-in users
            if (_currentUser != null) ...[
              // Chat with Seller Section Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: const Color(0xFF5BE206),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Quick Chat Options',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5BE206),
                      ),
                    ),
                  ],
                ),
              ),

              // Make an Offer
              _buildContactOption(
                icon: Icons.local_offer,
                title: 'Make an Offer',
                subtitle: 'Negotiate the price',
                onTap: () => _showMakeOfferDialog(listing),
                color: const Color(0xFF5BE206),
              ),

              const SizedBox(height: 8),

              // Is this available?
              _buildContactOption(
                icon: Icons.help_outline,
                title: 'Is this available?',
                subtitle: 'Ask about availability',
                onTap: () => _sendAvailabilityMessage(listing),
                color: Colors.blue,
              ),

              const SizedBox(height: 8),

              // Last Price
              _buildContactOption(
                icon: Icons.price_check,
                title: 'Last Price',
                subtitle: 'Ask for best price',
                onTap: () => _sendLastPriceMessage(listing),
                color: Colors.orange,
              ),

              const SizedBox(height: 16),

              // Direct Contact Section Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.contact_phone,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Direct Contact',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Phone number (if available)
              if (listing['seller_phone'] != null)
                _buildContactOption(
                  icon: Icons.phone,
                  title: 'Call Seller',
                  subtitle: listing['seller_phone'],
                  onTap: () => _makePhoneCall(listing['seller_phone']),
                ),

              const SizedBox(height: 8),

              // SMS option
              if (listing['seller_phone'] != null)
                _buildContactOption(
                  icon: Icons.message,
                  title: 'Send SMS',
                  subtitle: 'Send a text message',
                  onTap: () => _sendSMS(listing),
                ),

              const SizedBox(height: 8),

              // WhatsApp option
              if (listing['seller_whatsapp'] != null ||
                  listing['seller_phone'] != null)
                _buildContactOption(
                  icon: Icons.chat,
                  title: 'WhatsApp',
                  subtitle: 'Chat on WhatsApp',
                  onTap: () => _openWhatsApp(listing),
                  color: Colors.green,
                ),

              const SizedBox(height: 8),

              // Copy phone number
              if (listing['seller_phone'] != null)
                _buildContactOption(
                  icon: Icons.copy,
                  title: 'Copy Phone Number',
                  subtitle: 'Copy to clipboard',
                  onTap: () => _copyPhoneNumber(listing['seller_phone']),
                ),

              const SizedBox(height: 8),

              // Request callback option
              _buildContactOption(
                icon: Icons.phone_callback,
                title: 'Request Callback',
                subtitle: 'Ask seller to call you back',
                onTap: () => _requestCallback(listing),
                color: Colors.blue,
              ),
            ] else ...[
              // For visitors - show login requirement
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[600],
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Login Required',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Please login to view seller contact information and send messages.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LoginScreen(redirectToListing: widget.listing),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5BE206),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ),
            ],

            // No phone available message
            if (_currentUser != null &&
                (listing['seller_phone'] == null ||
                    listing['seller_phone'].toString().isEmpty)) ...[
              // No contact info available
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.phone_disabled,
                      color: Colors.grey[400],
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Contact Info Not Available',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'The seller hasn\'t provided contact information for this listing.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Close button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? const Color(0xFF5BE206)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  void _makePhoneCall(String phoneNumber) {
    Navigator.pop(context);
    // In a real app, you would use url_launcher to make the call
    // For now, just copy the number and show a message
    Clipboard.setData(ClipboardData(text: phoneNumber));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number $phoneNumber copied to clipboard'),
          backgroundColor: const Color(0xFF5BE206),
        ),
      );
    }
  }

  void _sendSMS(Map<String, dynamic> listing) {
    Navigator.pop(context);
    final message = 'Hi! I\'m interested in your listing: ${listing['title']}';
    Clipboard.setData(ClipboardData(text: message));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message template copied to clipboard'),
          backgroundColor: Color(0xFF5BE206),
        ),
      );
    }
  }

  void _copyPhoneNumber(String phoneNumber) {
    Navigator.pop(context);
    Clipboard.setData(ClipboardData(text: phoneNumber));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number $phoneNumber copied'),
          backgroundColor: const Color(0xFF5BE206),
        ),
      );
    }
  }

  void _requestCallback(Map<String, dynamic> listing) {
    Navigator.pop(context);

    // Show callback request dialog
    _showCallbackRequestDialog(listing);
  }

  void _showCallbackRequestDialog(Map<String, dynamic> listing) {
    final phoneController = TextEditingController();
    final messageController = TextEditingController();
    final timeController = TextEditingController();
    bool isLoading = false;

    // Pre-fill user's phone if available
    if (_currentUser?['phone'] != null) {
      phoneController.text = _currentUser!['phone'];
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.phone_callback, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Request Callback'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request a callback from ${listing['seller_name'] ?? 'the seller'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),

                    // Phone number field
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Your Phone Number *',
                        hintText: 'Enter your phone number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Preferred time field
                    Builder(
                      builder: (builderContext) => GestureDetector(
                        onTap: () async {
                          final currentContext = builderContext;
                          final messenger = ScaffoldMessenger.of(
                            builderContext,
                          );

                          final time = await showTimePicker(
                            context: currentContext,
                            initialTime: const TimeOfDay(hour: 9, minute: 0),
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(
                                  context,
                                ).copyWith(alwaysUse24HourFormat: false),
                                child: child!,
                              );
                            },
                          );

                          if (time != null && mounted) {
                            // Check if time is within 8:00 AM - 6:00 PM range
                            if (time.hour >= 8 && time.hour < 18) {
                              // Format time manually to avoid context issues
                              final hour = time.hourOfPeriod == 0
                                  ? 12
                                  : time.hourOfPeriod;
                              final period = time.period == DayPeriod.am
                                  ? 'AM'
                                  : 'PM';
                              final minute = time.minute.toString().padLeft(
                                2,
                                '0',
                              );
                              final formattedTime = '$hour:$minute $period';
                              timeController.text = formattedTime;
                            } else {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select a time between 8:00 AM and 6:00 PM',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            controller: timeController,
                            decoration: const InputDecoration(
                              labelText: 'Preferred Time (8:00 AM - 6:00 PM)',
                              hintText: 'Tap to select time',
                              prefixIcon: Icon(Icons.access_time),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Message field
                    TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        labelText: 'Message (Optional)',
                        hintText: 'Any specific questions or details...',
                        prefixIcon: Icon(Icons.message),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Info text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'The seller will receive your callback request and contact you at the provided number.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (phoneController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter your phone number'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          // Capture context before async operation
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);

                          setState(() => isLoading = true);

                          try {
                            await _sendCallbackRequest(
                              listing,
                              phoneController.text.trim(),
                              timeController.text.trim(),
                              messageController.text.trim(),
                            );

                            if (mounted) {
                              navigator.pop();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Callback request sent successfully!',
                                  ),
                                  backgroundColor: Color(0xFF5BE206),
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => isLoading = false);
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Failed to send request: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send Request'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _sendCallbackRequest(
    Map<String, dynamic> listing,
    String phoneNumber,
    String preferredTime,
    String message,
  ) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}${Api.callbackRequestEndpoint}'),
            headers: Api.headers,
            body: jsonEncode({
              'listing_id': listing['id'],
              'seller_id': listing['seller_id'],
              'buyer_id': user['id'],
              'buyer_name': user['name'] ?? 'Anonymous',
              'buyer_phone': phoneNumber,
              'preferred_time': preferredTime,
              'message': message,
              'listing_title': listing['title'],
              'token': user['token'],
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to send callback request');
        }

        // Track callback request analytics
        FirebaseService.logEvent('callback_request_sent', {
          'listing_id': listing['id'].toString(),
          'listing_title': listing['title'] ?? '',
          'seller_id': listing['seller_id']?.toString() ?? '',
          'buyer_id': user['id'].toString(),
          'has_preferred_time': preferredTime.isNotEmpty,
          'has_message': message.isNotEmpty,
        });
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      // Track failed callback request
      FirebaseService.logEvent('callback_request_failed', {
        'listing_id': listing['id'].toString(),
        'error': e.toString(),
      });

      rethrow;
    }
  }

  void _openWhatsApp(Map<String, dynamic> listing) {
    Navigator.pop(context);

    // Track WhatsApp contact analytics
    FirebaseService.logEvent('whatsapp_contact', {
      'listing_id': listing['id'].toString(),
      'listing_title': listing['title'] ?? '',
      'seller_id': listing['seller_id']?.toString() ?? '',
      'contact_method': 'whatsapp',
    });

    final whatsappNumber =
        listing['seller_whatsapp'] ?? listing['seller_phone'];
    if (whatsappNumber != null) {
      WhatsAppService.showWhatsAppDialog(
        context: context,
        phoneNumber: whatsappNumber,
        listingTitle: listing['title'] ?? 'Listing',
        sellerName:
            '${listing['seller_first_name'] ?? ''} ${listing['seller_last_name'] ?? ''}'
                .trim(),
      );
    }
  }

  void _markUnavailable(Map<String, dynamic> listing) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.visibility_off, color: Colors.orange),
              SizedBox(width: 8),
              Text('Mark as Unavailable'),
            ],
          ),
          content: const Text(
            'Are you sure you want to mark this listing as unavailable? This action will hide the listing from search results.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _submitMarkUnavailable(listing['id']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Mark Unavailable'),
            ),
          ],
        );
      },
    );
  }

  void _reportAbuse(Map<String, dynamic> listing) {
    final reasons = [
      'This is illegal/fraudulent',
      'This ad is spam',
      'The price is wrong',
      'Seller asked for prepayment',
      'It is sold',
      'User is unreachable',
      'Other',
    ];

    String? selectedReason;
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.report, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Report Abuse'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Why are you reporting this listing?'),
                    const SizedBox(height: 16),
                    ...reasons.map(
                      (reason) => RadioListTile<String>(
                        title: Text(reason),
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value;
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Additional details (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
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
                  onPressed: selectedReason != null
                      ? () async {
                          Navigator.of(context).pop();
                          await _submitAbuseReport(
                            listing['id'],
                            selectedReason!,
                            descriptionController.text,
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Submit Report'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitMarkUnavailable(int listingId) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}${Api.markUnavailableEndpoint}'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': _currentUser!['id'],
              'listing_id': listingId,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Listing marked as unavailable'),
              backgroundColor: data['success']
                  ? const Color(0xFF5BE206)
                  : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark listing as unavailable'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitAbuseReport(
    int listingId,
    String reason,
    String description,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}${Api.reportAbuseEndpoint}'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': _currentUser!['id'],
              'listing_id': listingId,
              'reason': reason,
              'description': description,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Report submitted successfully'),
              backgroundColor: data['success']
                  ? const Color(0xFF5BE206)
                  : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit report'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareListing() async {
    final listing = _detailedListing ?? widget.listing;
    final title = listing['title'] ?? 'Check out this item';
    final price = listing['price'] ?? '0';
    final location = listing['city_name'] ?? 'Kenya';
    final listingId = listing['id'] ?? '';

    final shareText =
        '''$title

Price: KES $price
Location: $location

Check out this item on SokoFiti!
https://sokofiti.ke/listing/$listingId''';

    try {
      // Track share analytics
      FirebaseService.logEvent('listing_shared', {
        'listing_id': listingId.toString(),
        'listing_title': title,
        'share_method': 'native_share',
      });

      await Share.share(
        shareText,
        subject: 'Check out this item on SokoFiti - $title',
      );
    } catch (e) {
      // Fallback: copy to clipboard if share fails
      Clipboard.setData(ClipboardData(text: shareText));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing details copied to clipboard'),
            backgroundColor: Color(0xFF5BE206),
          ),
        );
      }
    }
  }

  Widget _buildImageGallery() {
    final listing = _detailedListing ?? widget.listing;
    return ImageUtils.buildListingImageGallery(
      listing: listing,
      height: 300,
      borderRadius: BorderRadius.circular(8),
      context: context,
    );
  }

  Widget _buildListingInfo() {
    final listing = _detailedListing ?? widget.listing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and Price
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing['title'] ?? 'No title',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (listing['plan_type'] != null) ...[
                    const SizedBox(height: 8),
                    PlanBadge(
                      planType: listing['plan_type'],
                      size: 20,
                      showLabel: true,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: _toggleFavorite,
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.grey,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Text(
          'KES ${_formatPrice(int.tryParse(listing['price']?.toString() ?? '0') ?? 0)}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5BE206),
          ),
        ),

        const SizedBox(height: 12),

        // Price History - Clickable text
        GestureDetector(
          onTap: () => _showPriceHistoryDialog(listing),
          child: Row(
            children: [
              Icon(Icons.trending_up, color: const Color(0xFF5BE206), size: 16),
              const SizedBox(width: 4),
              Text(
                'Price History',
                style: TextStyle(
                  color: const Color(0xFF5BE206),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Location and Date
        Row(
          children: [
            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '${listing['city'] ?? 'Unknown'}, ${listing['county'] ?? 'Kenya'}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const Spacer(),
            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              _formatDate(listing['created_at']),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Description
        const Text(
          'Description',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          listing['description'] ?? 'No description available',
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),

        const SizedBox(height: 24),

        // Seller Info
        Row(
          children: [
            const Text(
              'Seller Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SellerListingsScreen(
                      sellerId: listing['seller_id']?.toString() ?? '',
                      sellerName: listing['seller_name'] ?? 'Unknown Seller',
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF5BE206).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF5BE206)),
                ),
                child: const Text(
                  'View All Ads',
                  style: TextStyle(
                    color: Color(0xFF5BE206),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF5BE206),
                child: Text(
                  _getSellerInitial(listing['seller_name']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing['seller_name'] ?? 'Unknown Seller',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Member since ${_formatDate(listing['seller_joined'])}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getResponseTimeText(listing['seller_response_time']),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _isSellerOnline(listing['seller_last_seen'])
                              ? Icons.circle
                              : Icons.access_time,
                          size: 12,
                          color: _isSellerOnline(listing['seller_last_seen'])
                              ? Colors.green
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getOnlineStatusText(listing['seller_last_seen']),
                          style: TextStyle(
                            color: _isSellerOnline(listing['seller_last_seen'])
                                ? Colors.green
                                : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Seller Reviews Section
        SellerReviewsWidget(
          sellerId: listing['seller_id']?.toString() ?? '',
          sellerName: listing['seller_name'] ?? 'Unknown Seller',
        ),

        const SizedBox(height: 16),

        // Mark Unavailable and Report Abuse - ONLY for logged-in users
        if (_currentUser != null) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _markUnavailable(listing),
                  icon: const Icon(Icons.visibility_off, size: 18),
                  label: const Text('Mark Unavailable'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _reportAbuse(listing),
                  icon: const Icon(Icons.report, size: 18),
                  label: const Text('Report Abuse'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} months ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hours ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  String _getResponseTimeText(dynamic responseTime) {
    if (responseTime == null) {
      return 'Response time unknown';
    }

    // Convert to int if it's a string
    int? timeInMinutes;
    if (responseTime is String) {
      timeInMinutes = int.tryParse(responseTime);
    } else if (responseTime is int) {
      timeInMinutes = responseTime;
    }

    if (timeInMinutes == null || timeInMinutes <= 0) {
      return 'Response time varies';
    }

    if (timeInMinutes < 60) {
      return 'Typically replies within an hour';
    } else if (timeInMinutes < 360) {
      // 6 hours
      return 'Typically replies within a few hours';
    } else if (timeInMinutes < 1440) {
      // 24 hours
      return 'Typically replies within a day';
    } else if (timeInMinutes < 4320) {
      // 3 days
      return 'Typically replies within a few days';
    } else {
      return 'May take longer to reply';
    }
  }

  bool _isSellerOnline(String? lastSeen) {
    if (lastSeen == null) return false;

    try {
      final lastSeenDate = DateTime.parse(lastSeen);
      final now = DateTime.now();
      final difference = now.difference(lastSeenDate);

      // Consider online if last seen within 5 minutes
      return difference.inMinutes <= 5;
    } catch (e) {
      return false;
    }
  }

  String _getOnlineStatusText(String? lastSeen) {
    if (lastSeen == null) return 'Last seen unknown';

    if (_isSellerOnline(lastSeen)) {
      return 'Online now';
    }

    try {
      final lastSeenDate = DateTime.parse(lastSeen);
      final now = DateTime.now();
      final difference = now.difference(lastSeenDate);

      if (difference.inMinutes < 60) {
        return 'Last seen ${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return 'Last seen ${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return 'Last seen ${difference.inDays}d ago';
      } else {
        return 'Last seen ${_formatDate(lastSeen)}';
      }
    } catch (e) {
      return 'Last seen unknown';
    }
  }

  Widget _buildSimilarListings() {
    if (_similarListings.isEmpty && !_isLoadingSimilar) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Similar Items',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        if (_isLoadingSimilar)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: BouncingEllipsisLoader()),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _similarListings.length,
              itemBuilder: (context, index) {
                final listing = _similarListings[index];
                return _buildSimilarListingCard(listing);
              },
            ),
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSimilarListingCard(Map<String, dynamic> listing) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListingDetailScreen(listing: listing),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: SizedBox(
                width: double.infinity,
                child: ImageUtils.buildListingImage(
                  listing: listing,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing['title'] ?? 'No title',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'KSh ${listing['price'] ?? '0'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5BE206),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (listing['location'] != null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 10,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              listing['location'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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

  void _showMakeOfferDialog(Map<String, dynamic> listing) {
    Navigator.pop(context); // Close the contact sheet first

    final currentPrice =
        double.tryParse(listing['price']?.toString() ?? '0') ?? 0;

    // Calculate offers with 5% reduction pattern: 200 → 190, 180.5, 171, 162
    final offerPrices = <double>[];
    double price = currentPrice;
    for (int i = 0; i < 4; i++) {
      price = price * 0.95; // Reduce by 5% each time
      offerPrices.add(price);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make an Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Original Price: KES ${currentPrice.toStringAsFixed(0)}'),
            const SizedBox(height: 16),
            const Text('Select your offer:'),
            const SizedBox(height: 12),
            ...offerPrices.map((price) {
              final discountAmount = currentPrice - price;
              final discountPercent = ((discountAmount / currentPrice) * 100)
                  .round();
              return ListTile(
                title: Text('KES ${price.toStringAsFixed(1)}'),
                subtitle: Text(
                  'KES ${discountAmount.toStringAsFixed(1)} off ($discountPercent% discount)',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCustomOfferDialog(listing, price);
                },
              );
            }),
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

  void _showCustomOfferDialog(
    Map<String, dynamic> listing,
    double suggestedPrice,
  ) {
    final TextEditingController offerController = TextEditingController(
      text: suggestedPrice.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Your Bid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: offerController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Your Offer (KES)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Text(
                '⚠️ Avoid paying in advance! Even for delivery',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendOfferMessage(listing, offerController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5BE206),
            ),
            child: const Text('Send Offer'),
          ),
        ],
      ),
    );
  }

  void _sendOfferMessage(Map<String, dynamic> listing, String offerAmount) {
    final message =
        '''Hi! I'm interested in your listing: ${listing['title']}

I would like to make an offer of KES $offerAmount.

⚠️ Avoid paying in advance! Even for delivery

Please let me know if this works for you.''';

    _sendWhatsAppMessage(listing, message);
  }

  void _sendAvailabilityMessage(Map<String, dynamic> listing) {
    Navigator.pop(context); // Close the contact sheet

    final message = '''Hi! I'm interested in your listing: ${listing['title']}

Is this item still available?

⚠️ Avoid paying in advance! Even for delivery''';

    _sendWhatsAppMessage(listing, message);
  }

  void _sendLastPriceMessage(Map<String, dynamic> listing) {
    Navigator.pop(context); // Close the contact sheet

    final message = '''Hi! I'm interested in your listing: ${listing['title']}

What's your last price for this item?

⚠️ Avoid paying in advance! Even for delivery''';

    _sendWhatsAppMessage(listing, message);
  }

  void _sendWhatsAppMessage(Map<String, dynamic> listing, String message) {
    final phoneNumber = listing['seller_whatsapp'] ?? listing['seller_phone'];
    if (phoneNumber != null) {
      WhatsAppService.openWhatsAppChat(
        phoneNumber: phoneNumber,
        message: message,
      );
    } else {
      // Fallback: copy message to clipboard
      Clipboard.setData(ClipboardData(text: message));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message copied to clipboard'),
          backgroundColor: Color(0xFF5BE206),
        ),
      );
    }
  }

  void _showPriceHistoryDialog(Map<String, dynamic> listing) {
    // Mock price history data - in real app, this would come from API
    final currentPrice =
        double.tryParse(listing['price']?.toString() ?? '0') ?? 0;
    final priceHistory = [
      {
        'date': '30 days ago',
        'price': currentPrice * 1.15,
        'change': 'increase',
      },
      {
        'date': '15 days ago',
        'price': currentPrice * 1.05,
        'change': 'increase',
      },
      {
        'date': '7 days ago',
        'price': currentPrice * 0.95,
        'change': 'decrease',
      },
      {'date': 'Today', 'price': currentPrice, 'change': 'current'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.trending_up, color: const Color(0xFF5BE206), size: 24),
            const SizedBox(width: 8),
            const Text('Price History'),
          ],
        ),
        content: SizedBox(
          width: 300,
          height: 200,
          child: Column(
            children: [
              // Bar chart
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: priceHistory.map((entry) {
                    final price = entry['price'] as double;
                    final maxPrice = priceHistory
                        .map((e) => e['price'] as double)
                        .reduce((a, b) => a > b ? a : b);
                    final height = (price / maxPrice) * 120;
                    final isIncrease = entry['change'] == 'increase';
                    final isDecrease = entry['change'] == 'decrease';
                    final isCurrent = entry['change'] == 'current';

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 30,
                          height: height,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? const Color(0xFF5BE206)
                                : isIncrease
                                ? Colors.red[400]
                                : isDecrease
                                ? Colors.orange[400]
                                : Colors.grey[400],
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'KES ${_formatPrice(price.toInt())}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry['date'] as String,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem(Colors.red[400]!, 'Increase'),
                  _buildLegendItem(Colors.orange[400]!, 'Decrease'),
                  _buildLegendItem(const Color(0xFF5BE206), 'Current'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listing['title'] ?? 'Listing Details'),
        backgroundColor: const Color(0xFF5BE206),
        foregroundColor: Colors.white,
        actions: [
          // Credits display for logged-in users
          if (_currentUser != null && _creditsRemaining > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5BE206),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '$_creditsRemaining',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          IconButton(onPressed: _shareListing, icon: const Icon(Icons.share)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load listing details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadListingDetails,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5BE206),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Gallery
                  _buildImageGallery(),

                  // Listing Information
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildListingInfo(),
                  ),

                  // Similar Listings
                  _buildSimilarListings(),
                ],
              ),
            ),
      bottomNavigationBar: _isLoading || _errorMessage != null
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _toggleFavorite,
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.grey,
                      ),
                      label: Text(
                        _isFavorite ? 'Favorited' : 'Add to Favorites',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _isFavorite ? Colors.red : Colors.grey,
                        side: BorderSide(
                          color: _isFavorite ? Colors.red : Colors.grey,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _contactSeller,
                      icon: const Icon(Icons.message),
                      label: const Text('Contact Seller'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5BE206),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Get seller initial safely, handling empty or null names
  String _getSellerInitial(dynamic sellerName) {
    final name = sellerName?.toString() ?? '';
    if (name.isEmpty) {
      return 'U'; // Default to 'U' for User
    }
    return name[0].toUpperCase();
  }
}
