import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';

class BiometricLoginWidget extends StatefulWidget {
  final VoidCallback? onSuccess;
  final Function(String)? onError;
  final bool showTitle;

  const BiometricLoginWidget({
    super.key,
    this.onSuccess,
    this.onError,
    this.showTitle = true,
  });

  @override
  State<BiometricLoginWidget> createState() => _BiometricLoginWidgetState();
}

class _BiometricLoginWidgetState extends State<BiometricLoginWidget>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _canUseBiometric = false;
  String _biometricType = 'Biometric';
  IconData _biometricIcon = Icons.fingerprint;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final bool canUse = await AuthService.canUseBiometricLogin();
      final String type = await BiometricService.getPrimaryBiometricType();
      final IconData icon = await BiometricService.getBiometricIcon();

      if (mounted) {
        setState(() {
          _canUseBiometric = canUse;
          _biometricType = type;
          _biometricIcon = icon;
        });
      }
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
    }
  }

  Future<void> _authenticateWithBiometric() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    _animationController.forward();

    try {
      final bool success = await AuthService.loginWithBiometric(context);

      if (mounted) {
        if (success) {
          widget.onSuccess?.call();
        } else {
          widget.onError?.call('Biometric authentication failed');
        }
      }
    } catch (e) {
      if (mounted) {
        widget.onError?.call('Biometric authentication error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canUseBiometric) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (widget.showTitle) ...[
          Text(
            'Quick Login',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
        ],

        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(40),
                    onTap: _isLoading ? null : _authenticateWithBiometric,
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Icon(_biometricIcon, size: 32, color: Colors.white),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        Text(
          _isLoading ? 'Authenticating...' : 'Use $_biometricType',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),

        if (!_isLoading) ...[
          const SizedBox(height: 4),
          Text(
            'Tap to authenticate',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ],
    );
  }
}

class BiometricSetupPrompt extends StatelessWidget {
  final VoidCallback? onSetup;
  final VoidCallback? onSkip;

  const BiometricSetupPrompt({super.key, this.onSetup, this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.security, size: 48, color: Colors.green.shade600),
          const SizedBox(height: 16),
          Text(
            'Secure Your Account',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enable biometric authentication for quick and secure access to your Sokofiti account.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onSkip,
                  child: Text(
                    'Skip',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Enable'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BiometricStatusIndicator extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback? onTap;

  const BiometricStatusIndicator({
    super.key,
    required this.isEnabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isEnabled
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isEnabled ? Icons.security : Icons.security_outlined,
              size: 16,
              color: isEnabled ? Colors.green.shade600 : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              isEnabled ? 'Biometric Enabled' : 'Biometric Disabled',
              style: TextStyle(
                fontSize: 12,
                color: isEnabled ? Colors.green.shade700 : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
