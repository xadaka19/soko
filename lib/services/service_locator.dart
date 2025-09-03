import 'package:flutter/foundation.dart';

import 'firebase_service.dart';
import 'crash_reporting_service.dart';
import 'google_auth_service.dart';
import 'notification_service.dart';

/// Simple service locator for dependency injection
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};

  /// Register a service as singleton
  void registerSingleton<T>(T Function() factory) {
    _services[T] = factory();
  }

  /// Get a service instance
  T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service of type $T is not registered');
    }
    return service as T;
  }

  /// Check if service is registered
  bool isRegistered<T>() => _services.containsKey(T);

  /// Clear all services
  void clear() => _services.clear();
}

final locator = ServiceLocator();

/// Setup all services for the application
Future<void> setupServices() async {
  try {
    debugPrint('Setting up services...');

    // Register services as singletons
    // Note: These services use static methods, so we don't need actual instances
    // This is more for demonstration of the pattern
    
    // Initialize all services sequentially for safety
    if (!kIsWeb) {
      await CrashReportingService.initialize();
      debugPrint('CrashReportingService initialized');
    }
    
    await FirebaseService.initialize();
    debugPrint('FirebaseService initialized');
    
    await GoogleAuthService.initialize();
    debugPrint('GoogleAuthService initialized');
    
    await NotificationService.initialize();
    debugPrint('NotificationService initialized');

    debugPrint('All services setup completed successfully');
  } catch (e) {
    debugPrint('Error during service setup: $e');
    // Don't throw to avoid breaking app initialization
  }
}
