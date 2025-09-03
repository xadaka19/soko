import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/session_manager.dart';

/// Biometric authentication service with web compatibility
class BiometricService {
  // For web compatibility, we'll simulate biometric functionality
  static final bool _isWebPlatform = kIsWeb;

  /// Check if biometric authentication is available on the device
  static Future<bool> isBiometricAvailable() async {
    try {
      if (_isWebPlatform) {
        // Web doesn't support biometrics, but we'll return false gracefully
        return false;
      }

      // For mobile platforms, this would check actual biometric availability
      // Since we're focusing on web compatibility, return false
      return false;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types
  static Future<List<String>> getAvailableBiometrics() async {
    try {
      if (_isWebPlatform) {
        return []; // Web doesn't support biometrics
      }

      // For mobile platforms, this would return actual biometric types
      return [];
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate with biometrics
  static Future<bool> authenticate({
    required String localizedReason,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      if (_isWebPlatform) {
        debugPrint(
          'Biometric authentication not available on web: $localizedReason',
        );
        return false;
      }

      // For mobile platforms, this would perform actual biometric authentication
      debugPrint('Biometric authentication requested: $localizedReason');
      return false;
    } catch (e) {
      debugPrint('Error during biometric authentication: $e');
      return false;
    }
  }

  /// Check if device supports biometrics
  static Future<bool> canCheckBiometrics() async {
    try {
      if (_isWebPlatform) {
        return false;
      }

      // For mobile platforms, this would check device capabilities
      return false;
    } catch (e) {
      debugPrint('Error checking biometric capabilities: $e');
      return false;
    }
  }

  /// Get biometric type name
  static String getBiometricTypeName(String type) {
    switch (type) {
      case 'face':
        return 'Face ID';
      case 'fingerprint':
        return 'Fingerprint';
      case 'iris':
        return 'Iris';
      case 'strong':
        return 'Strong Biometric';
      case 'weak':
        return 'Weak Biometric';
      default:
        return 'Unknown';
    }
  }

  /// Get primary biometric type available on device
  static Future<String> getPrimaryBiometricType() async {
    try {
      final availableTypes = await getAvailableBiometrics();
      if (availableTypes.isEmpty) return 'none';

      // Prioritize face recognition, then fingerprint
      if (availableTypes.contains('face')) {
        return 'face';
      } else if (availableTypes.contains('fingerprint')) {
        return 'fingerprint';
      } else {
        return availableTypes.first;
      }
    } catch (e) {
      debugPrint('Error getting primary biometric type: $e');
      return 'none';
    }
  }

  /// Get appropriate icon for biometric type
  static Future<IconData> getBiometricIcon() async {
    try {
      final primaryType = await getPrimaryBiometricType();
      switch (primaryType) {
        case 'face':
          return Icons.face;
        case 'fingerprint':
          return Icons.fingerprint;
        case 'iris':
          return Icons.visibility;
        default:
          return Icons.security;
      }
    } catch (e) {
      debugPrint('Error getting biometric icon: $e');
      return Icons.security;
    }
  }

  /// Get comprehensive biometric status
  static Future<Map<String, dynamic>> getBiometricStatus() async {
    try {
      final isAvailable = await isBiometricAvailable();
      final canCheck = await canCheckBiometrics();
      final availableTypes = await getAvailableBiometrics();
      final primaryType = await getPrimaryBiometricType();

      return {
        'isAvailable': isAvailable,
        'isEnrolled': isAvailable, // Simplified for web compatibility
        'availableTypes': availableTypes,
        'primaryType': primaryType,
        'canCheckBiometrics': canCheck,
        'platform': _isWebPlatform ? 'web' : 'mobile',
      };
    } catch (e) {
      debugPrint('Error getting biometric status: $e');
      return {
        'isAvailable': false,
        'isEnrolled': false,
        'availableTypes': <String>[],
        'primaryType': 'none',
        'canCheckBiometrics': false,
        'platform': _isWebPlatform ? 'web' : 'mobile',
      };
    }
  }

  /// Enable biometric authentication for the app
  static Future<bool> enableBiometricAuth() async {
    try {
      if (_isWebPlatform) {
        debugPrint('Biometric authentication not available on web platform');
        return false;
      }

      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        debugPrint('Biometric authentication not available on this device');
        return false;
      }

      // Store preference
      await SessionManager.setBiometricEnabled(true);
      debugPrint('Biometric authentication enabled');
      return true;
    } catch (e) {
      debugPrint('Error enabling biometric authentication: $e');
      return false;
    }
  }

  /// Disable biometric authentication for the app
  static Future<bool> disableBiometricAuth() async {
    try {
      await SessionManager.setBiometricEnabled(false);
      debugPrint('Biometric authentication disabled');
      return true;
    } catch (e) {
      debugPrint('Error disabling biometric authentication: $e');
      return false;
    }
  }

  /// Check if biometric authentication is enabled in app settings
  static Future<bool> isBiometricAuthEnabled() async {
    try {
      return await SessionManager.isBiometricEnabled();
    } catch (e) {
      debugPrint('Error checking biometric auth status: $e');
      return false;
    }
  }

  /// Set biometric authentication preference
  static Future<void> setBiometricAuthEnabled(bool enabled) async {
    try {
      await SessionManager.setBiometricEnabled(enabled);
      debugPrint('Biometric auth preference set to: $enabled');
    } catch (e) {
      debugPrint('Error setting biometric auth preference: $e');
    }
  }

  /// Get biometric authentication preference
  static Future<bool> getBiometricAuthEnabled() async {
    try {
      return await SessionManager.isBiometricEnabled();
    } catch (e) {
      debugPrint('Error getting biometric auth preference: $e');
      return false;
    }
  }

  /// Authenticate user with biometrics (main authentication method)
  static Future<bool> authenticateUser(String reason) async {
    try {
      final isEnabled = await isBiometricAuthEnabled();
      if (!isEnabled) {
        debugPrint('Biometric authentication is disabled');
        return false;
      }

      return await authenticate(
        localizedReason: reason,
        useErrorDialogs: true,
        stickyAuth: true,
      );
    } catch (e) {
      debugPrint('Error during user authentication: $e');
      return false;
    }
  }

  /// Check if user has enrolled biometrics on their device
  static Future<bool> hasEnrolledBiometrics() async {
    try {
      if (_isWebPlatform) {
        return false;
      }

      final availableTypes = await getAvailableBiometrics();
      return availableTypes.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking enrolled biometrics: $e');
      return false;
    }
  }

  /// Quick biometric login (compatible with existing code)
  static Future<bool> quickBiometricLogin(String reason) async {
    try {
      if (_isWebPlatform) {
        debugPrint('Quick biometric login not available on web: $reason');
        return false;
      }

      final isEnabled = await isBiometricAuthEnabled();
      if (!isEnabled) {
        return false;
      }

      return await authenticateUser(reason);
    } catch (e) {
      debugPrint('Error during quick biometric login: $e');
      return false;
    }
  }

  /// Show biometric setup dialog (compatible with existing code)
  static Future<bool> showBiometricSetupDialog(BuildContext context) async {
    try {
      if (_isWebPlatform) {
        // Show web-compatible dialog
        return await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Biometric Authentication'),
                  content: const Text(
                    'Biometric authentication is not available on web browsers. '
                    'This feature is available on mobile devices with fingerprint or face recognition.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            ) ??
            false;
      }

      // For mobile platforms, show actual biometric setup dialog
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return false;
      }

      if (!context.mounted) return false;

      return await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('Enable Biometric Authentication'),
                content: const Text(
                  'Would you like to enable biometric authentication for faster login?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Skip'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final success = await enableBiometricAuth();
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop(success);
                      }
                    },
                    child: const Text('Enable'),
                  ),
                ],
              );
            },
          ) ??
          false;
    } catch (e) {
      debugPrint('Error showing biometric setup dialog: $e');
      return false;
    }
  }

  /// Get device capabilities (compatible with existing code)
  static Future<Map<String, dynamic>> getDeviceCapabilities() async {
    try {
      final status = await getBiometricStatus();
      return {
        'biometricAvailable': status['isAvailable'],
        'biometricEnrolled': status['isEnrolled'],
        'availableTypes': status['availableTypes'],
        'primaryType': status['primaryType'],
        'canCheckBiometrics': status['canCheckBiometrics'],
        'platform': status['platform'],
      };
    } catch (e) {
      debugPrint('Error getting device capabilities: $e');
      return {
        'biometricAvailable': false,
        'biometricEnrolled': false,
        'availableTypes': <String>[],
        'primaryType': 'none',
        'canCheckBiometrics': false,
        'platform': _isWebPlatform ? 'web' : 'mobile',
      };
    }
  }

  /// Authenticate with biometric (compatible with existing code)
  static Future<bool> authenticateWithBiometric({
    required String reason,
  }) async {
    return await authenticateUser(reason);
  }

  /// Enable biometric (compatible with existing code)
  static Future<bool> enableBiometric() async {
    return await enableBiometricAuth();
  }

  /// Disable biometric (compatible with existing code)
  static Future<bool> disableBiometric() async {
    return await disableBiometricAuth();
  }
}
