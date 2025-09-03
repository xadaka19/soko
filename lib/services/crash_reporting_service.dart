import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'firebase_service.dart';

/// Comprehensive crash reporting and analytics service
class CrashReportingService {
  static bool _isInitialized = false;
  static final List<String> _breadcrumbs = [];
  static const int _maxBreadcrumbs = 50;

  /// Initialize crash reporting
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set up global error handlers
      _setupErrorHandlers();

      // Set up isolate error handler
      _setupIsolateErrorHandler();

      // Set up platform error handler
      _setupPlatformErrorHandler();

      _isInitialized = true;
      debugPrint('Crash reporting service initialized');

      // Log initialization
      await logMessage('CrashReportingService initialized');
    } catch (e, stackTrace) {
      debugPrint('Failed to initialize crash reporting: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't rethrow to avoid breaking app initialization
    }
  }

  /// Set up Flutter error handlers
  static void _setupErrorHandlers() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log to console in debug mode
      if (kDebugMode) {
        FlutterError.presentError(details);
      }

      // Report to Firebase Crashlytics
      FirebaseService.logError(
        details.exception,
        details.stack,
        reason: 'Flutter Error: ${details.context?.toString() ?? 'Unknown'}',
        customKeys: {
          'error_type': 'flutter_error',
          'library': details.library ?? 'unknown',
          'context': details.context?.toString() ?? 'unknown',
        },
      );

      // Add breadcrumb
      addBreadcrumb('Flutter Error: ${details.exception}');
    };

    // Handle async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      // Log to console in debug mode
      if (kDebugMode) {
        debugPrint('Async Error: $error\n$stack');
      }

      // Report to Firebase Crashlytics
      FirebaseService.logError(
        error,
        stack,
        reason: 'Async Error',
        customKeys: {'error_type': 'async_error'},
      );

      // Add breadcrumb
      addBreadcrumb('Async Error: $error');

      return true; // Handled
    };
  }

  /// Set up isolate error handler
  static void _setupIsolateErrorHandler() {
    Isolate.current.addErrorListener(
      RawReceivePort((pair) async {
        final List<dynamic> errorAndStacktrace = pair;
        final error = errorAndStacktrace.first;
        final stackTrace = errorAndStacktrace.last;

        // Log to console in debug mode
        if (kDebugMode) {
          debugPrint('Isolate Error: $error\n$stackTrace');
        }

        // Report to Firebase Crashlytics
        await FirebaseService.logError(
          error,
          StackTrace.fromString(stackTrace.toString()),
          reason: 'Isolate Error',
          customKeys: {'error_type': 'isolate_error'},
        );

        // Add breadcrumb
        addBreadcrumb('Isolate Error: $error');
      }).sendPort,
    );
  }

  /// Set up platform-specific error handler
  static void _setupPlatformErrorHandler() {
    // Handle platform channel errors
    PlatformDispatcher.instance.onError = (error, stack) {
      if (error is PlatformException) {
        FirebaseService.logError(
          error,
          stack,
          reason: 'Platform Error: ${error.code}',
          customKeys: {
            'error_type': 'platform_error',
            'platform_code': error.code,
            'platform_message': error.message ?? 'unknown',
            'platform_details': error.details?.toString() ?? 'none',
          },
        );

        addBreadcrumb('Platform Error: ${error.code} - ${error.message}');
      }

      return true;
    };
  }

  /// Log a custom error
  static Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? customData,
    bool fatal = false,
  }) async {
    try {
      // Add breadcrumb
      addBreadcrumb('Custom Error: ${error.toString()}');

      // Prepare custom keys
      final customKeys = <String, dynamic>{
        'error_type': 'custom_error',
        'fatal': fatal,
        'timestamp': DateTime.now().toIso8601String(),
        'breadcrumbs': _breadcrumbs.join(' -> '),
        ...?customData,
      };

      // Log to Firebase Crashlytics
      await FirebaseService.logError(
        error,
        stackTrace,
        reason: reason,
        customKeys: customKeys,
      );

      // Log to console in debug mode
      if (kDebugMode) {
        debugPrint('Custom Error: $error');
        if (stackTrace != null) {
          debugPrint('Stack Trace: $stackTrace');
        }
      }
    } catch (e) {
      debugPrint('Failed to log custom error: $e');
    }
  }

  /// Log a message for debugging
  static Future<void> logMessage(String message) async {
    try {
      addBreadcrumb(message);
      await FirebaseService.logMessage(message);

      if (kDebugMode) {
        debugPrint('Crash Log: $message');
      }
    } catch (e) {
      debugPrint('Failed to log message: $e');
    }
  }

  /// Add breadcrumb for tracking user actions
  static void addBreadcrumb(String breadcrumb) {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final formattedBreadcrumb = '[$timestamp] $breadcrumb';

      _breadcrumbs.add(formattedBreadcrumb);

      // Keep only the last N breadcrumbs
      if (_breadcrumbs.length > _maxBreadcrumbs) {
        _breadcrumbs.removeAt(0);
      }

      if (kDebugMode) {
        debugPrint('Breadcrumb: $formattedBreadcrumb');
      }
    } catch (e) {
      debugPrint('Failed to add breadcrumb: $e');
    }
  }

  /// Set user information for crash reports
  static Future<void> setUserInfo({
    required String userId,
    String? email,
    String? name,
    Map<String, dynamic>? customAttributes,
  }) async {
    try {
      final userInfo = <String, dynamic>{
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
        ...?customAttributes,
      };

      await FirebaseService.setCrashUserInfo(
        userId: userId,
        email: email,
        name: name,
        customKeys: userInfo,
      );

      addBreadcrumb('User info set: $userId');
    } catch (e) {
      debugPrint('Failed to set user info: $e');
    }
  }

  /// Record a handled exception
  static Future<void> recordHandledException(
    dynamic exception,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await logError(
        exception,
        stackTrace,
        reason: 'Handled Exception${context != null ? ': $context' : ''}',
        customData: {
          'handled': true,
          'context': context ?? 'unknown',
          ...?additionalData,
        },
        fatal: false,
      );
    } catch (e) {
      debugPrint('Failed to record handled exception: $e');
    }
  }

  /// Record app performance issue
  static Future<void> recordPerformanceIssue({
    required String issueType,
    required String description,
    Map<String, dynamic>? metrics,
  }) async {
    try {
      await logError(
        'Performance Issue: $issueType',
        StackTrace.current,
        reason: description,
        customData: {
          'error_type': 'performance_issue',
          'issue_type': issueType,
          'metrics': metrics ?? {},
        },
        fatal: false,
      );

      addBreadcrumb('Performance Issue: $issueType - $description');
    } catch (e) {
      debugPrint('Failed to record performance issue: $e');
    }
  }

  /// Record network error
  static Future<void> recordNetworkError({
    required String url,
    required String method,
    int? statusCode,
    String? errorMessage,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await logError(
        'Network Error: $method $url',
        StackTrace.current,
        reason: errorMessage ?? 'Network request failed',
        customData: {
          'error_type': 'network_error',
          'url': url,
          'method': method,
          'status_code': statusCode,
          'error_message': errorMessage,
          ...?additionalData,
        },
        fatal: false,
      );

      addBreadcrumb('Network Error: $method $url (${statusCode ?? 'unknown'})');
    } catch (e) {
      debugPrint('Failed to record network error: $e');
    }
  }

  /// Get current breadcrumbs
  static List<String> getBreadcrumbs() {
    return List.from(_breadcrumbs);
  }

  /// Clear breadcrumbs
  static void clearBreadcrumbs() {
    _breadcrumbs.clear();
    addBreadcrumb('Breadcrumbs cleared');
  }

  /// Force a crash for testing (DEBUG ONLY)
  static void testCrash() {
    if (kDebugMode) {
      addBreadcrumb('Test crash initiated');
      FirebaseService.testCrash();
    }
  }

  /// Check if crash reporting is initialized
  static bool get isInitialized => _isInitialized;
}
