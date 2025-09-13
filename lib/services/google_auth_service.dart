import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/environment.dart';
import '../config/api.dart';
import '../utils/session_manager.dart';
import '../firebase_options.dart';
import 'firebase_service.dart';
import 'crash_reporting_service.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? Environment.googleSignInClientId : null,
    scopes: ['email', 'profile'],
  );

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> initialize() async {
    try {
      if (!kIsWeb) {
        await FirebaseService.initialize();
      } else {
        // For web, ensure Firebase is initialized
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          debugPrint('Firebase initialized for web');
        } catch (e) {
          debugPrint('Firebase already initialized or error: $e');
        }
      }

      // Try silent sign-in
      try {
        await _googleSignIn.signInSilently();
      } catch (e) {
        debugPrint('Silent sign-in failed: $e');
      }

      if (!kIsWeb) {
        CrashReportingService.addBreadcrumb('Google Auth Service initialized');
      }
      debugPrint('Google Auth Service initialized');
    } catch (e) {
      debugPrint('Google Auth Service initialization error: $e');
    }
  }

  static Future<bool> isSignedIn() async =>
      kIsWeb ? _auth.currentUser != null : _googleSignIn.isSignedIn();

  /// Check if user is properly authenticated with valid token
  static Future<bool> isProperlyAuthenticated() async {
    try {
      if (kIsWeb) {
        final user = _auth.currentUser;
        if (user == null) return false;

        // Try to get a fresh token
        final token = await user.getIdToken(true);
        return token != null && token.isNotEmpty;
      } else {
        final isSignedIn = await _googleSignIn.isSignedIn();
        if (!isSignedIn) return false;

        final googleUser = _googleSignIn.currentUser;
        if (googleUser == null) return false;

        final auth = await googleUser.authentication;
        return auth.idToken != null && auth.idToken!.isNotEmpty;
      }
    } catch (e) {
      debugPrint('Error checking authentication: $e');
      return false;
    }
  }

  static GoogleSignInAccount? getCurrentUser() =>
      kIsWeb ? null : _googleSignIn.currentUser;

  /// Sign in with Google (Web + Mobile)
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      debugPrint('Starting Google Sign-In process...');

      if (kIsWeb) {
        // Web: FirebaseAuth popup
        debugPrint('Using web Firebase Auth popup');
        final provider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(provider);
        final user = userCredential.user;
        if (user == null) {
          return {
            'success': false,
            'message': 'Sign-in failed - no user data',
            'user': null,
          };
        }

        debugPrint('Web sign-in successful: ${user.email}');

        final userData = {
          'id': user.uid,
          'email': user.email ?? '',
          'first_name': user.displayName?.split(' ').first ?? '',
          'last_name': user.displayName?.split(' ').skip(1).join(' ') ?? '',
          'photo_url': user.photoURL ?? '',
          'google_id': user.uid,
        };

        // Check if user exists in backend and authenticate
        String? idToken;
        try {
          // Force refresh to get a fresh token
          idToken = await user.getIdToken(true);
        } catch (e) {
          debugPrint('Error getting ID token: $e');
        }

        if (idToken == null || idToken.isEmpty) {
          return {
            'success': false,
            'message':
                'Firebase ID token missing. Please try signing in again.',
            'user': null,
          };
        }
        final backendResult = await _authenticateWithBackend(idToken, userData);

        if (backendResult['success']) {
          // Save session locally with backend user data
          await SessionManager.saveUser(backendResult['user']);
          if (backendResult['token'] != null) {
            await SessionManager.saveToken(backendResult['token']);
          }
          return {
            'success': true,
            'message': backendResult['message'] ?? 'Sign-in successful',
            'user': backendResult['user'],
            'is_new_user': backendResult['is_new_user'] ?? false,
          };
        } else {
          return {
            'success': false,
            'message': backendResult['message'] ?? 'Authentication failed',
            'user': null,
            'requires_registration':
                backendResult['requires_registration'] ?? false,
            'google_data': userData,
          };
        }
      } else {
        // Mobile: standard GoogleSignIn
        debugPrint('Using mobile Google Sign-In');
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          return {
            'success': false,
            'message': 'Sign-in cancelled',
            'user': null,
          };
        }
        final auth = await googleUser.authentication;
        if (auth.idToken == null) {
          return {
            'success': false,
            'message': 'Failed to get auth token',
            'user': null,
          };
        }

        debugPrint('Mobile sign-in successful: ${googleUser.email}');

        final userData = {
          'id': googleUser.id,
          'email': googleUser.email,
          'first_name': googleUser.displayName?.split(' ').first ?? '',
          'last_name':
              googleUser.displayName?.split(' ').skip(1).join(' ') ?? '',
          'photo_url': googleUser.photoUrl ?? '',
          'google_id': googleUser.id,
        };

        // For mobile, we'll use the auth token to authenticate with backend
        final backendResult = await _authenticateWithBackend(
          auth.idToken!,
          userData,
        );

        if (backendResult['success']) {
          // Save session locally with backend user data
          await SessionManager.saveUser(backendResult['user']);
          if (backendResult['token'] != null) {
            await SessionManager.saveToken(backendResult['token']);
          }
          return {
            'success': true,
            'message': backendResult['message'] ?? 'Sign-in successful',
            'user': backendResult['user'],
            'is_new_user': backendResult['is_new_user'] ?? false,
          };
        } else {
          return {
            'success': false,
            'message': backendResult['message'] ?? 'Authentication failed',
            'user': null,
            'requires_registration':
                backendResult['requires_registration'] ?? false,
            'google_data': userData,
          };
        }
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      String errorMessage = 'Sign-in failed';
      if (e.toString().contains('network')) {
        errorMessage = 'Network error. Check your connection.';
      } else if (e.toString().contains('popup')) {
        errorMessage = 'Sign-in popup blocked. Allow popups.';
      } else if (e.toString().contains('cancelled')) {
        errorMessage = 'Sign-in was cancelled.';
      }
      return {'success': false, 'message': errorMessage, 'user': null};
    }
  }

  /// Authenticate with backend using Google ID token
  static Future<Map<String, dynamic>> _authenticateWithBackend(
    String idToken,
    Map<String, dynamic> googleUserData,
  ) async {
    try {
      final url = '${Api.baseUrl}${Api.googleAuthEndpoint}';
      debugPrint('Authenticating with backend: $url');
      debugPrint('User data: ${googleUserData['email']}');

      final response = await http
          .post(
            Uri.parse(url),
            headers: Api.headers,
            body: jsonEncode({
              'id_token': idToken,
              'google_id': googleUserData['google_id'],
              'email': googleUserData['email'],
              'first_name': googleUserData['first_name'],
              'last_name': googleUserData['last_name'],
              'photo_url': googleUserData['photo_url'],
            }),
          )
          .timeout(Api.timeout);

      debugPrint('Backend response status: ${response.statusCode}');
      debugPrint('Backend response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        debugPrint('Backend error: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Backend authentication error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Sign-Out (Web + Mobile)
  static Future<void> signOut() async {
    if (kIsWeb) {
      await _auth.signOut();
    } else {
      await _googleSignIn.signOut();
    }
    await SessionManager.logout();
    debugPrint('User signed out');
  }
}
