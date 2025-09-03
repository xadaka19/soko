import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/phone_verification_service.dart';
import '../services/validation_service.dart';

class PhoneVerificationDialog extends StatefulWidget {
  final String? initialPhoneNumber;
  final VoidCallback? onVerificationSuccess;

  const PhoneVerificationDialog({
    super.key,
    this.initialPhoneNumber,
    this.onVerificationSuccess,
  });

  @override
  State<PhoneVerificationDialog> createState() => _PhoneVerificationDialogState();
}

class _PhoneVerificationDialogState extends State<PhoneVerificationDialog> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _otpSent = false;
  String? _verificationId;
  String? _errorMessage;
  int _resendCountdown = 0;
  Timer? _countdownTimer;
  int _attemptsRemaining = 3;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhoneNumber != null) {
      _phoneController.text = widget.initialPhoneNumber!;
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendCountdown(int seconds) {
    setState(() => _resendCountdown = seconds);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phoneNumber = ValidationService.formatPhoneNumber(_phoneController.text.trim());
      final result = await PhoneVerificationService.sendOTP(phoneNumber);

      if (result['success'] == true) {
        setState(() {
          _otpSent = true;
          _verificationId = result['verification_id'];
        });
        _startResendCountdown(60); // 60 seconds before allowing resend
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('OTP sent to ${PhoneVerificationService.formatPhoneForDisplay(phoneNumber)}'),
              backgroundColor: const Color(0xFF5BE206),
            ),
          );
        }
      } else {
        setState(() => _errorMessage = result['message']);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to send OTP: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().length != 6) {
      setState(() => _errorMessage = 'Please enter a valid 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phoneNumber = ValidationService.formatPhoneNumber(_phoneController.text.trim());
      final result = await PhoneVerificationService.verifyOTP(
        phoneNumber: phoneNumber,
        otpCode: _otpController.text.trim(),
        verificationId: _verificationId!,
      );

      if (result['success'] == true && result['verified'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone number verified successfully!'),
              backgroundColor: Color(0xFF5BE206),
            ),
          );
          Navigator.of(context).pop(true); // Return success
          widget.onVerificationSuccess?.call();
        }
      } else {
        setState(() {
          _errorMessage = result['message'];
          _attemptsRemaining--;
        });
        
        if (_attemptsRemaining <= 0) {
          setState(() {
            _otpSent = false;
            _verificationId = null;
            _attemptsRemaining = 3;
          });
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to verify OTP: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOTP() async {
    if (_resendCountdown > 0 || _verificationId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phoneNumber = ValidationService.formatPhoneNumber(_phoneController.text.trim());
      final result = await PhoneVerificationService.resendOTP(
        phoneNumber: phoneNumber,
        verificationId: _verificationId!,
      );

      if (result['success'] == true) {
        _startResendCountdown(60);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP resent successfully'),
              backgroundColor: Color(0xFF5BE206),
            ),
          );
        }
      } else {
        setState(() => _errorMessage = result['message']);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to resend OTP: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.phone_android, color: Color(0xFF5BE206)),
          const SizedBox(width: 8),
          Text(_otpSent ? 'Verify Phone Number' : 'Phone Verification Required'),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_otpSent) ...[
                const Text(
                  'To post ads, you need to verify your phone number. This helps prevent spam and builds trust with buyers.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '0712345678 or 254712345678',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
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
                ),
              ] else ...[
                Text(
                  'Enter the 6-digit code sent to ${PhoneVerificationService.formatPhoneForDisplay(_phoneController.text)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Verification Code',
                    hintText: '123456',
                    prefixIcon: Icon(Icons.security),
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attempts remaining: $_attemptsRemaining',
                      style: TextStyle(
                        fontSize: 12,
                        color: _attemptsRemaining <= 1 ? Colors.red : Colors.grey,
                      ),
                    ),
                    TextButton(
                      onPressed: _resendCountdown > 0 ? null : _resendOTP,
                      child: Text(
                        _resendCountdown > 0 
                          ? 'Resend in ${_resendCountdown}s'
                          : 'Resend OTP',
                      ),
                    ),
                  ],
                ),
              ],
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade600, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : (_otpSent ? _verifyOTP : _sendOTP),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5BE206),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(_otpSent ? 'Verify' : 'Send OTP'),
        ),
      ],
    );
  }
}
