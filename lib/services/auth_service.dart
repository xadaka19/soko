import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../utils/session_manager.dart';
import 'biometric_service.dart';
import 'notification_service.dart';

class AuthService {
  /// Login user with email and password
  static Future<bool> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}${Api.loginEndpoint}'),
            headers: Api.headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Login response: $data');

        if (data['success'] == true) {
          // Validate user data before saving
          if (data['user'] == null) {
            debugPrint('Login error: User data is null');
            return false;
          }

          // Save user data and token if available
          await SessionManager.saveUser(data['user']);
          if (data['token'] != null) {
            await SessionManager.saveToken(data['token']);
          }

          // Subscribe to notification topics
          await NotificationService.subscribeToUserTopics();

          return true;
        } else {
          debugPrint('Login failed: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        debugPrint(
          'Login HTTP error: ${response.statusCode} - ${response.body}',
        );
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  /// Register new user
  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}${Api.registerEndpoint}'),
            headers: Api.headers,
            body: jsonEncode({
              'first_name': firstName,
              'last_name': lastName,
              'email': email,
              'password': password,
              'phone': phone,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Registration response: $data');

        if (data['success'] == true) {
          // Validate user data before saving
          if (data['user'] == null) {
            debugPrint('Registration error: User data is null');
            return {'success': false, 'message': 'Invalid user data received'};
          }

          // Save user data and token if available
          await SessionManager.saveUser(data['user']);
          if (data['token'] != null) {
            await SessionManager.saveToken(data['token']);
          }
        }
        return data;
      } else {
        debugPrint(
          'Registration HTTP error: ${response.statusCode} - ${response.body}',
        );
      }
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      debugPrint('Registration error: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  /// Register user with Google data
  static Future<Map<String, dynamic>> registerWithGoogle({
    required Map<String, dynamic> googleData,
    required String phone,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${Api.baseUrl}${Api.registerWithGoogleEndpoint}'),
            headers: Api.headers,
            body: jsonEncode({
              'google_id': googleData['google_id'],
              'email': googleData['email'],
              'first_name': googleData['first_name'],
              'last_name': googleData['last_name'],
              'photo_url': googleData['photo_url'],
              'phone': phone,
            }),
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Save user data and token if available
          await SessionManager.saveUser(data['user']);
          if (data['token'] != null) {
            await SessionManager.saveToken(data['token']);
          }
        }
        return data;
      }
      return {'success': false, 'message': 'Server error'};
    } catch (e) {
      debugPrint('Google registration error: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  /// Test database connection
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse('${Api.baseUrl}/api/health-check.php'),
            headers: Api.headers,
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Database connection successful',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Connection test error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Logout user
  static Future<void> logout() async {
    // Unsubscribe from notification topics
    await NotificationService.unsubscribeFromUserTopics();

    await SessionManager.clearBiometricSettings();
    await SessionManager.logout();
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    return await SessionManager.isLoggedIn();
  }

  /// Get current user
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    return await SessionManager.getUser();
  }

  /// Login with biometric authentication
  static Future<bool> loginWithBiometric(BuildContext context) async {
    try {
      final bool userAuthenticated = await isAuthenticated();
      if (!userAuthenticated) {
        return false;
      }

      if (!context.mounted) return false;
      final bool biometricResult = await BiometricService.quickBiometricLogin(
        'Quick login authentication',
      );
      if (biometricResult) {
        await SessionManager.saveLastBiometricLogin();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Biometric login error: $e');
      return false;
    }
  }

  /// Check if biometric login is available for current user
  static Future<bool> canUseBiometricLogin() async {
    final bool userAuthenticated = await isAuthenticated();
    final bool isBiometricEnabled = await SessionManager.isBiometricEnabled();
    final bool isBiometricAvailable =
        await BiometricService.isBiometricAvailable();

    return userAuthenticated && isBiometricEnabled && isBiometricAvailable;
  }

  /// Setup biometric authentication after successful login
  static Future<bool> setupBiometricAfterLogin(BuildContext context) async {
    try {
      final bool isAvailable = await BiometricService.isBiometricAvailable();
      if (!isAvailable) {
        return false;
      }

      final bool isAlreadyEnabled = await SessionManager.isBiometricEnabled();
      if (isAlreadyEnabled) {
        return true;
      }

      // Show setup dialog and enable if user agrees
      if (!context.mounted) return false;
      return await BiometricService.showBiometricSetupDialog(context);
    } catch (e) {
      debugPrint('Setup biometric error: $e');
      return false;
    }
  }

  /// Enhanced login with biometric setup option
  static Future<Map<String, dynamic>> loginWithBiometricSetup(
    String email,
    String password,
    BuildContext context,
  ) async {
    try {
      // First, perform regular login
      final bool loginSuccess = await login(email, password);

      if (!loginSuccess) {
        return {
          'success': false,
          'message': 'Invalid email or password',
          'biometricSetup': false,
        };
      }

      // Check if biometric setup is available and not already enabled
      final bool canSetupBiometric =
          await BiometricService.isBiometricAvailable();
      final bool isAlreadyEnabled = await SessionManager.isBiometricEnabled();

      bool biometricSetup = false;
      if (canSetupBiometric && !isAlreadyEnabled && context.mounted) {
        // Offer biometric setup
        biometricSetup = await BiometricService.showBiometricSetupDialog(
          context,
        );
      }

      return {
        'success': true,
        'message': 'Login successful',
        'biometricSetup': biometricSetup,
      };
    } catch (e) {
      debugPrint('Enhanced login error: $e');
      return {
        'success': false,
        'message': 'Login failed',
        'biometricSetup': false,
      };
    }
  }
}
