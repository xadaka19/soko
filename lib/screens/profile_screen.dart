import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../utils/session_manager.dart';
import '../config/api.dart';
import '../widgets/seller_analytics_widget.dart';
import 'login_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/desktop_admin_dashboard.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  String? _errorMessage;
  final ImagePicker _imagePicker = ImagePicker();
  Timer? _refreshTimer;

  // Subscription info
  int _creditsRemaining = 0;
  String _planName = 'No Plan';
  String _planStatus = 'inactive';

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _mpesaPhoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _countyController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _mpesaPhoneController.dispose();
    _cityController.dispose();
    _countyController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh profile when app comes back to foreground
      _loadUserData();
    }
  }

  void _startAutoRefresh() {
    // Refresh profile data every 5 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted && !_isEditing) {
        _loadUserData();
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // First get local user data for immediate display
      final localUser = await SessionManager.getUser();
      if (localUser != null && mounted) {
        setState(() {
          _user = localUser;
          _isLoading = false;
        });
        _populateControllers(localUser);
      }

      // Then fetch fresh data from server
      if (localUser != null) {
        final response = await http
            .get(
              Uri.parse(
                '${Api.baseUrl}${Api.getProfileEndpoint}?user_id=${localUser['id']}',
              ),
              headers: Api.headers,
            )
            .timeout(Api.timeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] && data['user'] != null) {
            final freshUser = data['user'];

            // Update session with fresh data
            await SessionManager.saveUser(freshUser);

            if (mounted) {
              setState(() {
                _user = freshUser;
                _errorMessage = null;
              });
              _populateControllers(freshUser);
              _loadSubscriptionInfo();
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadSubscriptionInfo() async {
    try {
      final credits = await SubscriptionService.getLocalCredits();
      final planName = await SubscriptionService.getLocalPlanName();
      final hasActiveSubscription =
          await SubscriptionService.hasActiveSubscription();

      if (mounted) {
        setState(() {
          _creditsRemaining = credits;
          _planName = planName;
          _planStatus = hasActiveSubscription ? 'active' : 'inactive';
        });
      }
    } catch (e) {
      // Silently handle subscription info loading errors
    }
  }

  void _populateControllers(Map<String, dynamic> user) {
    _firstNameController.text = user['first_name'] ?? '';
    _lastNameController.text = user['last_name'] ?? '';
    _emailController.text = user['email'] ?? '';
    _phoneController.text = user['phone'] ?? '';
    _mpesaPhoneController.text = user['mpesa_phone'] ?? '';
    _cityController.text = user['city'] ?? '';
    _countyController.text = user['county'] ?? '';
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final response = await http
          .put(
            Uri.parse('${Api.baseUrl}${Api.updateProfileEndpoint}'),
            headers: Api.headers,
            body: jsonEncode({
              'user_id': _user!['id'],
              'first_name': _firstNameController.text.trim(),
              'last_name': _lastNameController.text.trim(),
              'email': _emailController.text.trim(),
              'phone': _phoneController.text.trim(),
              'mpesa_phone': _mpesaPhoneController.text.trim(),
              'city': _cityController.text.trim(),
              'county': _countyController.text.trim(),
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          // Update local user data
          final updatedUser = Map<String, dynamic>.from(_user!);
          updatedUser['first_name'] = _firstNameController.text.trim();
          updatedUser['last_name'] = _lastNameController.text.trim();
          updatedUser['email'] = _emailController.text.trim();
          updatedUser['phone'] = _phoneController.text.trim();
          updatedUser['mpesa_phone'] = _mpesaPhoneController.text.trim();
          updatedUser['city'] = _cityController.text.trim();
          updatedUser['county'] = _countyController.text.trim();

          await SessionManager.saveUser(updatedUser);

          setState(() {
            _user = updatedUser;
            _isEditing = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully'),
                backgroundColor: Color(0xFF5BE206),
              ),
            );
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to update profile');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _uploadProfilePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploadingImage = true);

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Api.baseUrl}${Api.uploadProfilePictureEndpoint}'),
      );

      // Add headers
      request.headers.addAll(Api.headers);

      // Add user ID
      request.fields['user_id'] = _user!['id'].toString();

      // Add image file
      if (kIsWeb) {
        // For web, read bytes
        final bytes = await image.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'profile_picture',
            bytes,
            filename: 'profile_picture.jpg',
          ),
        );
      } else {
        // For mobile, use file path
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_picture',
            image.path,
            filename: 'profile_picture.jpg',
          ),
        );
      }

      final response = await request.send().timeout(Api.timeout);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        if (data['success']) {
          // Update user data with new profile picture URL
          final updatedUser = Map<String, dynamic>.from(_user!);
          updatedUser['profile_picture'] = data['profile_picture_url'];

          await SessionManager.saveUser(updatedUser);

          setState(() {
            _user = updatedUser;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully'),
                backgroundColor: Color(0xFF5BE206),
              ),
            );
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to upload image');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _deleteProfilePicture() async {
    try {
      setState(() => _isUploadingImage = true);

      final response = await http
          .delete(
            Uri.parse('${Api.baseUrl}${Api.uploadProfilePictureEndpoint}'),
            headers: Api.headers,
            body: jsonEncode({'user_id': _user!['id']}),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          // Update user data to remove profile picture
          final updatedUser = Map<String, dynamic>.from(_user!);
          updatedUser['profile_picture'] = null;

          await SessionManager.saveUser(updatedUser);

          setState(() {
            _user = updatedUser;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture deleted successfully'),
                backgroundColor: Color(0xFF5BE206),
              ),
            );
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to delete image');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _showAdminOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Dashboard'),
        content: const Text('Choose admin dashboard type:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminDashboardScreen(),
                ),
              );
            },
            child: const Text('Mobile'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (kIsWeb ||
                  defaultTargetPlatform == TargetPlatform.linux ||
                  defaultTargetPlatform == TargetPlatform.macOS ||
                  defaultTargetPlatform == TargetPlatform.windows) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DesktopAdminDashboard(),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Desktop dashboard is only available on web/desktop platforms',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Desktop'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop(); // Close dialog first
              await AuthService.logout();
              if (mounted) {
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF5BE206),
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing) ...[
            // Refresh button
            IconButton(
              onPressed: _loadUserData,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Profile',
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Profile',
            ),
          ],
          // Admin dashboard access (only for admin users)
          if (_user?['role'] == 'admin')
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminDashboardScreen(),
                  ),
                );
              },
              onLongPress: () {
                // Long press for desktop admin dashboard
                _showAdminOptions();
              },
              child: IconButton(
                icon: const Icon(Icons.admin_panel_settings),
                onPressed: null, // Handled by GestureDetector
                tooltip: 'Admin Dashboard (Long press for desktop)',
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? _buildErrorState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile image placeholder
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child:
                                _user!['profile_picture'] != null &&
                                    _user!['profile_picture']
                                        .toString()
                                        .isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: Image.network(
                                      _user!['profile_picture'],
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.person,
                                                  size: 40,
                                                  color: Colors.grey[400],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'NO IMAGES\nAVAILABLE',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey[500],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'NO IMAGES\nAVAILABLE',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 16),
                          if (_isEditing) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton.icon(
                                  onPressed: _isUploadingImage
                                      ? null
                                      : _uploadProfilePicture,
                                  icon: _isUploadingImage
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.edit, size: 16),
                                  label: Text(
                                    _isUploadingImage
                                        ? 'Uploading...'
                                        : 'Change',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                TextButton.icon(
                                  onPressed: _isUploadingImage
                                      ? null
                                      : () {
                                          // Show confirmation dialog
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                'Delete Profile Picture',
                                              ),
                                              content: const Text(
                                                'Are you sure you want to delete your profile picture?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _deleteProfilePicture();
                                                  },
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                  icon: const Icon(Icons.delete, size: 16),
                                  label: const Text('Delete'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Subscription Information
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.card_membership,
                                color: Colors.green[600],
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Subscription Status',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Plan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    _planName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Credits Remaining',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.stars,
                                        size: 16,
                                        color: Colors.green[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$_creditsRemaining',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _planStatus == 'active'
                                  ? Colors.green[100]
                                  : Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _planStatus == 'active' ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _planStatus == 'active'
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Seller Analytics (only show if user has listings)
                    const SellerAnalyticsWidget(),

                    const SizedBox(height: 32),

                    // Form fields
                    _buildFormField(
                      label: 'First Name',
                      controller: _firstNameController,
                      enabled: _isEditing,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'First name is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildFormField(
                      label: 'Last Name',
                      controller: _lastNameController,
                      enabled: _isEditing,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Last name is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildFormField(
                      label: 'Email',
                      controller: _emailController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildFormField(
                      label: 'Phone',
                      controller: _phoneController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 16),

                    _buildFormField(
                      label: 'M-Pesa Phone Number',
                      controller: _mpesaPhoneController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (!RegExp(
                            r'^254[0-9]{9}$|^0[0-9]{9}$',
                          ).hasMatch(value)) {
                            return 'Please enter a valid Kenyan phone number';
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildFormField(
                      label: 'City',
                      controller: _cityController,
                      enabled: _isEditing,
                    ),

                    const SizedBox(height: 16),

                    _buildFormField(
                      label: 'County',
                      controller: _countyController,
                      enabled: _isEditing,
                    ),

                    const SizedBox(height: 32),

                    // Action buttons
                    if (_isEditing) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() => _isEditing = false);
                                // Reset form to original values
                                _loadUserData();
                              },
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5BE206),
                                foregroundColor: Colors.white,
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Download Data button (placeholder)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Download data coming soon!'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('Download Data'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.blue),
                            foregroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Failed to load profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _loadUserData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.green, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: TextStyle(color: enabled ? Colors.black87 : Colors.grey[600]),
        ),
      ],
    );
  }
}
