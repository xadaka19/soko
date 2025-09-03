import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/listing_service.dart';
import '../services/image_service.dart';
import '../services/location_service.dart';
import '../services/subscription_service.dart';
import '../services/validation_service.dart';
import '../services/photo_detection_service.dart';
import '../services/phone_verification_service.dart';
import '../services/recommendation_service.dart';
import '../utils/session_manager.dart';
import '../widgets/phone_verification_dialog.dart';
import 'plan_selection_screen.dart';

class CreateListingScreen extends StatefulWidget {
  final String? selectedPlan;

  const CreateListingScreen({super.key, this.selectedPlan});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _locationController = TextEditingController();

  // Additional state variables
  String? _selectedMainCategory;
  String? _selectedSubCategory;
  String? _selectedCounty;
  String? _selectedSubcity;
  String _selectedCondition = 'used'; // Default to 'used'
  List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _isProcessingImages = false;
  // final ImagePicker _imagePicker = ImagePicker(); // Removed for web compatibility

  // Credit management
  bool _isCheckingEligibility = true;
  bool _canCreateListing = false;
  int _creditsRemaining = 0;
  String _eligibilityMessage = '';
  bool _requiresPlan = false;

  // Phone verification
  bool _isPhoneVerified = false;
  final TextEditingController _locationSearchController =
      TextEditingController();
  List<Map<String, dynamic>> _locationSearchResults = [];
  bool _showLocationSearch = false;

  // Category structure with main categories and subcategories
  final Map<String, Map<String, dynamic>> _categories = {
    'electronics': {
      'name': 'Electronics',
      'icon': Icons.devices,
      'id': 1,
      'subcategories': {
        'phones': {'name': 'Mobile Phones', 'id': 11},
        'computers': {'name': 'Computers & Laptops', 'id': 12},
        'audio': {'name': 'Audio & Headphones', 'id': 13},
        'cameras': {'name': 'Cameras & Photography', 'id': 14},
        'gaming': {'name': 'Gaming', 'id': 15},
        'accessories': {'name': 'Electronics Accessories', 'id': 16},
      },
    },
    'fashion': {
      'name': 'Fashion & Beauty',
      'icon': Icons.checkroom,
      'id': 2,
      'subcategories': {
        'mens_clothing': {'name': 'Men\'s Clothing', 'id': 21},
        'womens_clothing': {'name': 'Women\'s Clothing', 'id': 22},
        'shoes': {'name': 'Shoes', 'id': 23},
        'bags': {'name': 'Bags & Accessories', 'id': 24},
        'beauty': {'name': 'Beauty & Personal Care', 'id': 25},
        'jewelry': {'name': 'Jewelry & Watches', 'id': 26},
      },
    },
    'home': {
      'name': 'Home & Garden',
      'icon': Icons.home,
      'id': 3,
      'subcategories': {
        'furniture': {'name': 'Furniture', 'id': 31},
        'appliances': {'name': 'Home Appliances', 'id': 32},
        'decor': {'name': 'Home Decor', 'id': 33},
        'kitchen': {'name': 'Kitchen & Dining', 'id': 34},
        'garden': {'name': 'Garden & Outdoor', 'id': 35},
        'tools': {'name': 'Tools & Hardware', 'id': 36},
      },
    },
    'vehicles': {
      'name': 'Vehicles',
      'icon': Icons.directions_car,
      'id': 4,
      'subcategories': {
        'cars': {'name': 'Cars', 'id': 41},
        'motorcycles': {'name': 'Motorcycles', 'id': 42},
        'trucks': {'name': 'Trucks & Commercial', 'id': 43},
        'parts': {'name': 'Auto Parts & Accessories', 'id': 44},
        'bicycles': {'name': 'Bicycles', 'id': 45},
      },
    },
    'services': {
      'name': 'Services',
      'icon': Icons.build,
      'id': 5,
      'subcategories': {
        'professional': {'name': 'Professional Services', 'id': 51},
        'home_services': {'name': 'Home Services', 'id': 52},
        'education': {'name': 'Education & Training', 'id': 53},
        'health': {'name': 'Health & Wellness', 'id': 54},
        'events': {'name': 'Events & Entertainment', 'id': 55},
      },
    },
    'other': {
      'name': 'Other',
      'icon': Icons.more_horiz,
      'id': 6,
      'subcategories': {
        'books': {'name': 'Books & Media', 'id': 61},
        'sports': {'name': 'Sports & Recreation', 'id': 62},
        'pets': {'name': 'Pets & Animals', 'id': 63},
        'baby': {'name': 'Baby & Kids', 'id': 64},
        'miscellaneous': {'name': 'Miscellaneous', 'id': 65},
      },
    },
  };

  // Helper methods
  int? get _selectedCategoryId {
    if (_selectedMainCategory != null && _selectedSubCategory != null) {
      return _categories[_selectedMainCategory]!['subcategories'][_selectedSubCategory]['id'];
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _checkListingEligibility();
    _checkPhoneVerification();
  }

  Future<void> _checkPhoneVerification() async {
    try {
      final isVerified = await PhoneVerificationService.isPhoneVerified();

      setState(() {
        _isPhoneVerified = isVerified;
      });
    } catch (e) {
      setState(() {
        _isPhoneVerified = false;
      });
    }
  }

  Future<bool> _showPhoneVerificationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PhoneVerificationDialog(
        initialPhoneNumber: _phoneController.text.isNotEmpty
            ? _phoneController.text
            : null,
        onVerificationSuccess: () {
          setState(() => _isPhoneVerified = true);
        },
      ),
    );

    if (result == true) {
      setState(() => _isPhoneVerified = true);
      return true;
    }

    return false;
  }

  Future<void> _checkListingEligibility() async {
    try {
      setState(() {
        _isCheckingEligibility = true;
      });

      final user = await SessionManager.getUser();
      if (user == null) {
        setState(() {
          _isCheckingEligibility = false;
          _canCreateListing = false;
          _requiresPlan = true;
          _eligibilityMessage = 'Please login to create listings';
        });
        return;
      }

      final eligibility = await SubscriptionService.checkListingEligibility(
        userId: int.parse(user['id'].toString()),
      );

      setState(() {
        _isCheckingEligibility = false;
        _canCreateListing = eligibility['can_create'] ?? false;
        _creditsRemaining = eligibility['credits_remaining'] ?? 0;
        _eligibilityMessage = eligibility['message'] ?? '';
        _requiresPlan = eligibility['requires_plan'] ?? false;
      });

      // If user needs a plan, show dialog
      if (_requiresPlan && mounted) {
        _showPlanRequiredDialog();
      }
    } catch (e) {
      setState(() {
        _isCheckingEligibility = false;
        _canCreateListing = false;
        _eligibilityMessage = 'Error checking eligibility: $e';
      });
    }
  }

  void _showPlanRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.info_outline, color: Colors.orange, size: 64),
        title: const Text('Plan Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_eligibilityMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            const Text(
              'Select a plan to start creating listings and reach more customers!',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlanSelectionScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5BE206),
              foregroundColor: Colors.white,
            ),
            child: const Text('Select Plan'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      setState(() => _isProcessingImages = true);

      final ImagePicker picker = ImagePicker();
      final List<XFile> pickedFiles = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFiles.isEmpty) {
        setState(() => _isProcessingImages = false);
        return;
      }

      // Convert XFile to File for processing
      final List<File> imageFiles = [];
      for (final pickedFile in pickedFiles) {
        if (kIsWeb) {
          // For web, create a temporary file representation
          imageFiles.add(File(pickedFile.path));
        } else {
          imageFiles.add(File(pickedFile.path));
        }
      }

      if (imageFiles.isNotEmpty) {
        // Check for duplicate/stolen photos first
        final user = await SessionManager.getUser();
        final userId = user != null ? int.parse(user['id'].toString()) : 0;

        for (final imageFile in imageFiles) {
          final duplicateCheck =
              await PhotoDetectionService.checkPhotoUniqueness(imageFile);

          if (duplicateCheck['is_duplicate'] == true) {
            setState(() => _isProcessingImages = false);

            // Show duplicate photo warning
            if (mounted) {
              PhotoDetectionService.showDuplicatePhotoDialog(
                context: context,
                existingSeller: duplicateCheck['existing_seller'] ?? 'Unknown',
                similarity: duplicateCheck['similarity'] ?? 0.0,
              );

              // Report the attempt
              await PhotoDetectionService.reportStolenPhotoAttempt(
                userId: userId,
                originalListingId: duplicateCheck['existing_listing_id'] ?? '',
                similarity: duplicateCheck['similarity'] ?? 0.0,
              );

              // Check if user should be auto-suspended
              final suspended = await PhotoDetectionService.checkAutoSuspension(
                userId,
              );
              if (suspended && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Account suspended for repeated photo violations',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.of(context).pop(); // Return to previous screen
                return;
              }
            }
            return; // Stop processing if duplicate found
          }
        }

        // Process images: resize and add watermark
        final processedImages = <File>[];
        for (final imageFile in imageFiles) {
          final processedImage = await ImageService.processImage(imageFile);
          processedImages.add(processedImage);
        }

        setState(() {
          _selectedImages = processedImages;
          _isProcessingImages = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${processedImages.length} photos processed with watermark',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() => _isProcessingImages = false);
      }
    } catch (e) {
      setState(() => _isProcessingImages = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking images: $e')));
      }
    }
  }

  Future<void> _createListing() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
      }
      return;
    }

    // Check phone verification first
    if (!_isPhoneVerified) {
      final verified = await _showPhoneVerificationDialog();
      if (!verified) {
        return; // User cancelled or failed verification
      }
    }

    // Check if user can create listing (has credits)
    if (!_canCreateListing) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_eligibilityMessage),
            backgroundColor: Colors.orange,
            action: _requiresPlan
                ? SnackBarAction(
                    label: 'Select Plan',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlanSelectionScreen(),
                        ),
                      );
                    },
                  )
                : null,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await SessionManager.getUser();
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to create a listing')),
          );
        }
        return;
      }

      final locationName =
          LocationService.getLocationName(_selectedCounty, _selectedSubcity) ??
          _locationSearchController.text.trim();

      final result = await ListingService.createListing(
        userId: int.parse(user['id'].toString()),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        categoryId: _selectedCategoryId!,
        cityName: locationName,
        photos: _selectedImages.isNotEmpty ? _selectedImages : null,
        condition: _selectedCondition,
      );

      if (mounted) {
        if (result['success']) {
          final listingId = result['listing_id'];

          // Process new listing for recommendations (send notifications to interested users)
          _processListingForRecommendations(result['listing']);

          // Consume credit after successful listing creation
          try {
            final userId = int.parse(user['id'].toString());
            final creditConsumed = await SubscriptionService.consumeCredit(
              userId: userId,
              listingId:
                  listingId ?? 0, // Use actual listing ID or fallback to 0
            );

            if (creditConsumed) {
              // Update local credit count
              setState(() {
                _creditsRemaining = _creditsRemaining - 1;
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Listing created successfully! $_creditsRemaining credits remaining.',
                    ),
                    backgroundColor: const Color(0xFF5BE206),
                  ),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Listing created but failed to update credits. Please contact support.',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Listing created but credit update failed: $e'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }

          if (mounted) {
            Navigator.pop(context, true); // Return true to indicate success
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create listing. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _processListingForRecommendations(
    Map<String, dynamic>? listing,
  ) async {
    if (listing == null) return;

    try {
      // Process the new listing for recommendations in the background
      await RecommendationService.processNewListingForRecommendations(
        listing: listing,
      );
    } catch (e) {
      // Silently handle recommendation processing errors
      debugPrint('Error processing listing for recommendations: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _locationController.dispose();
    _locationSearchController.dispose();
    super.dispose();
  }

  String _getPlanDisplayName(String? planId) {
    switch (planId) {
      case 'free':
        return 'FREE PLAN';
      case 'top':
        return 'TOP';
      case 'top_featured':
        return 'TOP FEATURED';
      case 'starter':
        return 'STARTER';
      case 'basic':
        return 'BASIC';
      case 'premium':
        return 'PREMIUM';
      case 'business':
        return 'BUSINESS';
      default:
        return 'No Plan Selected';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sell Item'),
        backgroundColor: const Color(0xFF5BE206),
        foregroundColor: Colors.white,
        actions: [
          // Credits display
          if (!_isCheckingEligibility && _creditsRemaining > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
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
          // Plan display
          if (widget.selectedPlan != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getPlanDisplayName(widget.selectedPlan),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Eligibility status
              if (_isCheckingEligibility)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Checking your plan and credits...'),
                    ],
                  ),
                )
              else if (!_canCreateListing)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange[600]),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Cannot Create Listing',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_eligibilityMessage),
                      if (_requiresPlan) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PlanSelectionScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.star, size: 18),
                          label: const Text('Select Plan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5BE206),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ready to create listing • $_creditsRemaining credits remaining',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              // Photo upload section
              Container(
                height: _selectedImages.isEmpty ? 200 : 300,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _isProcessingImages
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.green,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Processing images...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Adding watermarks and optimizing',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      )
                    : _selectedImages.isEmpty
                    ? InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _pickImages,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 50,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add Photos',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to add up to 15 photos',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Photos will be watermarked automatically',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                              itemCount: _selectedImages.length + 1,
                              itemBuilder: (context, index) {
                                if (index == _selectedImages.length) {
                                  return InkWell(
                                    onTap: _selectedImages.length < 15
                                        ? _pickImages
                                        : null,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _selectedImages.length < 15
                                            ? const Color(
                                                0xFF5BE206,
                                              ).withValues(alpha: 0.1)
                                            : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _selectedImages.length < 15
                                              ? const Color(
                                                  0xFF5BE206,
                                                ).withValues(alpha: 0.3)
                                              : Colors.grey[300]!,
                                          width: 2,
                                        ),
                                        boxShadow: _selectedImages.length < 15
                                            ? [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF5BE206,
                                                  ).withValues(alpha: 0.1),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _selectedImages.length < 15
                                                ? Icons.add_a_photo_outlined
                                                : Icons.block,
                                            color: _selectedImages.length < 15
                                                ? const Color(0xFF5BE206)
                                                : Colors.grey[400],
                                            size: 24,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _selectedImages.length < 15
                                                ? 'Add Photo'
                                                : 'Max reached',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: _selectedImages.length < 15
                                                  ? const Color(0xFF5BE206)
                                                  : Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                return Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.1,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: FileImage(
                                                _selectedImages[index],
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.transparent,
                                                  Colors.black.withValues(
                                                    alpha: 0.1,
                                                  ),
                                                ],
                                                stops: const [0.0, 0.7, 1.0],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Main photo indicator
                                    if (index == 0)
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF5BE206),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.2,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            'Main',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    // Remove button
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _selectedImages.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withValues(
                                              alpha: 0.9,
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.3,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '${_selectedImages.length}/15 photos selected (watermarked)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 24),

              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'What are you selling?',
                  prefixIcon: Icon(Icons.title_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your item in detail...',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Price field
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (KES)',
                  hintText: '0',
                  prefixIcon: Icon(Icons.attach_money_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Condition field
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 8),
                      child: Text(
                        'Condition',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                    Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Icon(Icons.info_outline, color: Colors.grey),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              RadioListTile<String>(
                                title: const Text('Brand New'),
                                subtitle: const Text(
                                  'Never used, in original packaging',
                                ),
                                value: 'brand new',
                                groupValue: _selectedCondition,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCondition = value!;
                                  });
                                },
                                activeColor: const Color(0xFF5BE206),
                              ),
                              RadioListTile<String>(
                                title: const Text('Used'),
                                subtitle: const Text(
                                  'Previously owned, good condition',
                                ),
                                value: 'used',
                                groupValue: _selectedCondition,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCondition = value!;
                                  });
                                },
                                activeColor: const Color(0xFF5BE206),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Phone Number field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '0712345678 or 254712345678',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (!ValidationService.isValidKenyanPhone(value)) {
                    return 'Please enter a valid Kenyan phone number';
                  }
                  return null;
                },
                onChanged: (value) async {
                  if (value.isNotEmpty &&
                      ValidationService.isValidKenyanPhone(value)) {
                    // Check phone uniqueness with debouncing
                    await Future.delayed(const Duration(milliseconds: 500));
                    if (_phoneController.text == value) {
                      final isUnique =
                          await ValidationService.isPhoneUniqueForListing(
                            value,
                          );
                      if (!isUnique && mounted && context.mounted) {
                        // Show warning if phone is already used
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'This phone number is already used in another listing',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  }
                },
              ),

              const SizedBox(height: 16),

              // WhatsApp Number field
              TextFormField(
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp Number (Optional)',
                  hintText: '0712345678 or 254712345678',
                  prefixIcon: Icon(Icons.chat_outlined),
                  helperText: 'Buyers can contact you directly via WhatsApp',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!ValidationService.isValidKenyanPhone(value)) {
                      return 'Please enter a valid Kenyan phone number';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Dynamic Location Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Location search field
                  TextFormField(
                    controller: _locationSearchController,
                    decoration: InputDecoration(
                      labelText: 'Search Location',
                      hintText: 'Type city or area name',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _locationSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _locationSearchController.clear();
                                  _locationSearchResults.clear();
                                  _showLocationSearch = false;
                                  _selectedCounty = null;
                                  _selectedSubcity = null;
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (value.isNotEmpty) {
                          _locationSearchResults =
                              LocationService.searchLocations(value);
                          _showLocationSearch = true;
                        } else {
                          _locationSearchResults.clear();
                          _showLocationSearch = false;
                        }
                      });
                    },
                    validator: (value) {
                      if (_selectedCounty == null || _selectedSubcity == null) {
                        return 'Please select a location from the suggestions';
                      }
                      return null;
                    },
                  ),

                  // Search results
                  if (_showLocationSearch &&
                      _locationSearchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _locationSearchResults.length,
                        itemBuilder: (context, index) {
                          final location = _locationSearchResults[index];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              location['type'] == 'county'
                                  ? Icons.location_city
                                  : Icons.location_on,
                              color: Colors.green,
                              size: 20,
                            ),
                            title: Text(
                              location['name'],
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: location['type'] == 'subcity'
                                ? Text(
                                    location['fullName'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                if (location['type'] == 'subcity') {
                                  _selectedCounty = location['countyKey'];
                                  _selectedSubcity = location['subcityKey'];
                                  _locationSearchController.text =
                                      location['fullName'];
                                } else {
                                  _selectedCounty = location['key'];
                                  _selectedSubcity = null;
                                  _locationSearchController.text =
                                      location['name'];
                                }
                                _showLocationSearch = false;
                                _locationSearchResults.clear();
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],

                  // Popular locations
                  if (!_showLocationSearch && _selectedCounty == null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Popular Locations',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: LocationService.getPopularLocations().map((
                        location,
                      ) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCounty = location['countyKey'];
                              _selectedSubcity = location['subcityKey'];
                              _locationSearchController.text =
                                  location['fullName'];
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              location['fullName'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // Selected location display
                  if (_selectedCounty != null && _selectedSubcity != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Selected: ${LocationService.getLocationName(_selectedCounty, _selectedSubcity)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // Category selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Main category selection
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: _categories.entries.map((entry) {
                        final categoryKey = entry.key;
                        final categoryData = entry.value;
                        final isSelected = _selectedMainCategory == categoryKey;

                        return Column(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (_selectedMainCategory == categoryKey) {
                                    _selectedMainCategory = null;
                                    _selectedSubCategory = null;
                                  } else {
                                    _selectedMainCategory = categoryKey;
                                    _selectedSubCategory = null;
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : null,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      categoryData['icon'],
                                      color: isSelected
                                          ? Colors.green
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        categoryData['name'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? Colors.green
                                              : Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      isSelected
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      color: isSelected
                                          ? Colors.green
                                          : Colors.grey[600],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Subcategory selection
                            if (isSelected) ...[
                              Container(
                                color: Colors.grey[50],
                                child: Column(
                                  children:
                                      (categoryData['subcategories']
                                              as Map<String, dynamic>)
                                          .entries
                                          .map((subEntry) {
                                            final subCategoryKey = subEntry.key;
                                            final subCategoryData =
                                                subEntry.value;
                                            final isSubSelected =
                                                _selectedSubCategory ==
                                                subCategoryKey;

                                            return InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _selectedSubCategory =
                                                      subCategoryKey;
                                                });
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 48,
                                                      vertical: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isSubSelected
                                                      ? Colors.green.withValues(
                                                          alpha: 0.2,
                                                        )
                                                      : null,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      isSubSelected
                                                          ? Icons
                                                                .radio_button_checked
                                                          : Icons
                                                                .radio_button_unchecked,
                                                      color: isSubSelected
                                                          ? Colors.green
                                                          : Colors.grey[600],
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        subCategoryData['name'],
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              isSubSelected
                                                              ? FontWeight.w500
                                                              : FontWeight
                                                                    .normal,
                                                          color: isSubSelected
                                                              ? Colors
                                                                    .green[700]
                                                              : Colors
                                                                    .grey[700],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          })
                                          .toList(),
                                ),
                              ),
                            ],

                            if (entry.key != _categories.keys.last)
                              Divider(height: 1, color: Colors.grey[300]),
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                  // Selected category display
                  if (_selectedMainCategory != null &&
                      _selectedSubCategory != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Selected: ${_categories[_selectedMainCategory]!['subcategories'][_selectedSubCategory]['name']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createListing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5BE206),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Post Listing',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
