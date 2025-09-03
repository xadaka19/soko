import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'services/service_locator.dart';
import 'services/firebase_service.dart';
import 'config/web_config.dart';
import 'firebase_options.dart';
import 'widgets/error_boundary.dart';
import 'screens/splash_screen.dart';
import 'screens/admin/desktop_admin_dashboard.dart';

/// Background message handler for Firebase Messaging
/// This function must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  debugPrint('Message notification: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize web configuration
    if (kIsWeb) {
      await WebConfig.initialize();
      debugPrint('Web configuration initialized');
    }

    // Initialize Firebase with notifications
    await FirebaseService.initialize();
    debugPrint('Firebase with notifications initialized');

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize other services using service locator
    await setupServices();

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    debugPrint('All services initialized successfully');
  } catch (e) {
    debugPrint('Error during initialization: $e');
    // Continue with app startup even if some services fail
  }

  runApp(const SokofitiApp());
}

class SokofitiApp extends StatelessWidget {
  const SokofitiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppErrorBoundary(
      child: MaterialApp(
        title: 'SokoFiti - Buy, Sell, Connect',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: MaterialColor(0xFF5BE206, {
            50: Color(0xFFEBFCE0),
            100: Color(0xFFCDF7B3),
            200: Color(0xFFADF280),
            300: Color(0xFF8DED4D),
            400: Color(0xFF74E926),
            500: Color(0xFF5BE206),
            600: Color(0xFF53DF05),
            700: Color(0xFF49DB04),
            800: Color(0xFF3FD703),
            900: Color(0xFF2DCF01),
          }),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5BE206),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: Colors.grey[50],
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF5BE206),
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5BE206),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF5BE206), width: 2),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF5BE206),
            foregroundColor: Colors.white,
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        routes: {'/admin': (context) => const DesktopAdminDashboard()},
      ),
    );
  }
}
