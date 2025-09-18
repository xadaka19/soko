import 'package:flutter/material.dart';
import 'dart:async';
import '../services/mpesa_service.dart';
import '../services/subscription_service.dart';
import '../utils/session_manager.dart';
import 'create_listing_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> selectedPlan;

  const PaymentScreen({super.key, required this.selectedPlan});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  bool _isProcessing = false;
  bool _isWaitingForPayment = false;
  String? _checkoutRequestId;
  String? _errorMessage;
  Timer? _statusCheckTimer;
  int _statusCheckAttempts = 0;
  static const int _maxStatusCheckAttempts = 30; // 30 attempts = 2.5 minutes
  bool _showRetryOption = false;

  @override
  void initState() {
    super.initState();
    _loadUserPhone();

    // Check if it's a free plan
    if (_planAmount == 0) {
      // For free plans, automatically "complete" the payment
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleFreeplan();
      });
    }
  }

  Future<void> _handleFreeplan() async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Activate free plan subscription
      final result = await SubscriptionService.activateFreePlan(
        userId: int.parse(user['id'].toString()),
      );

      if (result['success']) {
        final creditsAdded = result['credits_added'] ?? 0;

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              icon: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              title: const Text('Plan Activated!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Your ${widget.selectedPlan['name']} is now active!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (creditsAdded > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars, color: Colors.green[600], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '$creditsAdded credits added!',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'You can now start creating listings with your plan.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateListingScreen(
                          selectedPlan: widget.selectedPlan['id'],
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Continue to Create Listing'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to activate plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPhone() async {
    final user = await SessionManager.getUser();
    if (user != null && user['mpesa_phone'] != null) {
      _phoneController.text = user['mpesa_phone'];
    }
  }

  double get _planAmount {
    String priceStr = widget.selectedPlan['price'].toString();
    // Extract number from "KES 1,000" format
    String numStr = priceStr.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(numStr) ?? 0.0;
  }

  double get _totalAmount => _planAmount;

  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) return;

    final phoneNumber = MpesaService.formatPhoneNumber(
      _phoneController.text.trim(),
    );

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final user = await SessionManager.getUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      final result = await MpesaService.initiatePayment(
        phoneNumber: phoneNumber,
        amount: _totalAmount,
        planId: widget.selectedPlan['id'],
        userId: int.parse(user['id'].toString()),
        accountReference:
            'PLAN_${widget.selectedPlan['id'].toString().toUpperCase()}',
      );

      if (result['success']) {
        // Save phone number to session for future use
        await MpesaService.savePhoneNumberToSession(phoneNumber);

        setState(() {
          _isProcessing = false;
          _isWaitingForPayment = true;
          _checkoutRequestId = result['checkout_request_id'];
          _errorMessage = null;
          _showRetryOption = false;
        });

        _startStatusChecking();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment request sent! Please check your phone.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = MpesaService.getErrorMessage(null, e.toString());
        _showRetryOption = true;
      });
    }
  }

  void _startStatusChecking() {
    _statusCheckAttempts = 0;
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (_checkoutRequestId == null ||
        _statusCheckAttempts >= _maxStatusCheckAttempts) {
      _statusCheckTimer?.cancel();
      if (_statusCheckAttempts >= _maxStatusCheckAttempts) {
        setState(() {
          _isWaitingForPayment = false;
          _errorMessage =
              'Payment request timed out. Please try again or check your phone for any pending M-Pesa prompts.';
          _showRetryOption = true;
        });
      }
      return;
    }

    _statusCheckAttempts++;

    try {
      final result = await MpesaService.checkPaymentStatus(
        checkoutRequestId: _checkoutRequestId!,
      );

      if (result['success']) {
        String paymentStatus = result['payment_status'] ?? 'pending';

        if (paymentStatus == 'completed') {
          _statusCheckTimer?.cancel();
          _handlePaymentSuccess(result);
        } else if (paymentStatus == 'failed' || paymentStatus == 'cancelled') {
          _statusCheckTimer?.cancel();
          setState(() {
            _isWaitingForPayment = false;
            _errorMessage = MpesaService.getErrorMessage(
              result['result_code']?.toString(),
              result['result_desc'],
            );
            _showRetryOption = true;
          });
        }
        // If still pending, continue checking
      }
    } catch (e) {
      // Continue checking on error - silently handle status check errors
      // In production, this could be logged to a proper logging service
    }
  }

  void _retryPayment() {
    setState(() {
      _errorMessage = null;
      _showRetryOption = false;
      _statusCheckAttempts = 0;
    });

    // Retry the payment
    _initiatePayment();
  }

  void _cancelPayment() {
    setState(() {
      _isWaitingForPayment = false;
      _isProcessing = false;
      _errorMessage = null;
      _showRetryOption = false;
      _statusCheckAttempts = 0;
    });
    _statusCheckTimer?.cancel();
  }

  Future<void> _handlePaymentSuccess(Map<String, dynamic> result) async {
    setState(() {
      _isWaitingForPayment = false;
    });

    try {
      final user = await SessionManager.getUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Activate paid plan subscription
      final subscriptionResult = await SubscriptionService.activateSubscription(
        planId: widget.selectedPlan['id'],
        userId: int.parse(user['id'].toString()),
        transactionId: result['transaction_id']?.toString() ?? '',
        amount: double.tryParse(result['amount']?.toString() ?? '0') ?? 0.0,
      );

      if (subscriptionResult['success']) {
        final creditsAdded = subscriptionResult['credits_added'] ?? 0;

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              icon: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              title: const Text('Payment Successful!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Transaction ID: ${result['transaction_id']}'),
                  const SizedBox(height: 8),
                  Text('Amount: KES ${result['amount']}'),
                  const SizedBox(height: 16),
                  Text(
                    'Your ${widget.selectedPlan['name']} plan is now active!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (creditsAdded > 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars, color: Colors.green[600], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '$creditsAdded credits added to your account!',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateListingScreen(
                          selectedPlan: widget.selectedPlan['id'],
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Continue to Create Listing'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception(subscriptionResult['message']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful but failed to activate plan: $e'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Continue',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateListingScreen(
                      selectedPlan: widget.selectedPlan['id'],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan Summary Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              widget.selectedPlan['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.selectedPlan['price'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (widget.selectedPlan['period'].isNotEmpty)
                        Text(
                          widget.selectedPlan['period'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(height: 16),
                      ...widget.selectedPlan['features'].map<Widget>((feature) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Payment Details
              const Text(
                'Payment Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Amount Breakdown
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Amount:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'KES ${_totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Phone Number Input
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'M-Pesa Phone Number',
                  hintText: '0712345678 or 254712345678',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your M-Pesa phone number';
                  }
                  if (!MpesaService.isValidMpesaNumber(value)) {
                    return 'Please enter a valid Kenyan mobile number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Error Message with Retry Options
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_showRetryOption) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _retryPayment,
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Retry Payment'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green,
                                  side: const BorderSide(color: Colors.green),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextButton.icon(
                                onPressed: _cancelPayment,
                                icon: const Icon(Icons.close, size: 18),
                                label: const Text('Cancel'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

              if (_errorMessage != null) const SizedBox(height: 16),

              // Payment Status
              if (_isWaitingForPayment)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Waiting for payment confirmation...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please check your phone and enter your M-Pesa PIN',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.blue[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Attempt $_statusCheckAttempts/$_maxStatusCheckAttempts',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _cancelPayment,
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Cancel'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[600],
                                side: BorderSide(color: Colors.grey[400]!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _retryPayment,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              if (_isWaitingForPayment) const SizedBox(height: 16),

              // Pay Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (_isProcessing || _isWaitingForPayment)
                      ? null
                      : _initiatePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isProcessing
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
                      : Text(
                          _isWaitingForPayment
                              ? 'Processing Payment...'
                              : 'Pay with M-Pesa',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Info Text
              Text(
                'You will receive an M-Pesa prompt on your phone. Enter your PIN to complete the payment.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
