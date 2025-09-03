import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api.dart';
import 'payment_screen.dart';

class PlanSelectionScreen extends StatefulWidget {
  const PlanSelectionScreen({super.key});

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await http
          .get(
            Uri.parse('${Api.baseUrl}${Api.getPlansEndpoint}'),
            headers: Api.headers,
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _plans = List<Map<String, dynamic>>.from(data['plans']);
            _isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load plans');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      // Fallback to default plans if API fails
      _loadDefaultPlans();
    }
  }

  void _loadDefaultPlans() {
    setState(() {
      _plans = [
        {
          'id': 'free',
          'name': 'FREE PLAN',
          'price': 'KES 0',
          'period': '',
          'color': Colors.blue,
          'features': ['Ads auto-renew Every 48 hours', '7 free credits(ads)'],
        },
        {
          'id': 'top',
          'name': 'TOP',
          'price': 'KES 250',
          'period': '',
          'color': Colors.blue,
          'features': [
            '7 days listing',
            '1 credit (ad)',
            'Ads auto-renew Every 24 hours',
          ],
        },
        {
          'id': 'top_featured',
          'name': 'TOP FEATURED',
          'price': 'KES 400',
          'period': '/ month',
          'color': Colors.blue,
          'features': ['1 credit (ad)', 'Ads auto-renew Every 16 hours'],
        },
        {
          'id': 'starter',
          'name': 'STARTER',
          'price': 'KES 3,000',
          'period': '/ month',
          'color': Colors.blue,
          'features': ['10 credits (ads)', 'Ads auto-renew Every 12 hours'],
        },
        {
          'id': 'basic',
          'name': 'BASIC',
          'price': 'KES 5,000',
          'period': '/ month',
          'color': Colors.blue,
          'features': ['27 credits (ads)', 'Ads auto-renew Every 10 hours'],
        },
        {
          'id': 'premium',
          'name': 'PREMIUM',
          'price': 'KES 7,000',
          'period': '/ month',
          'color': Colors.blue,
          'features': ['45 credits (ads)', 'Ads auto-renew Every 8 hours'],
        },
        {
          'id': 'business',
          'name': 'BUSINESS',
          'price': 'KES 10,000',
          'period': '/ month',
          'color': Colors.blue,
          'features': ['74 credits (ads)', 'Ads auto-renew Every 6 hours'],
        },
      ];
    });
  }

  void _selectPlan(String planId) {
    // Find the selected plan details
    final selectedPlan = _plans.firstWhere(
      (plan) => plan['id'] == planId,
      orElse: () => {},
    );

    if (selectedPlan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan not found. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if it's a free plan
    String priceStr = selectedPlan['price'].toString();
    String numStr = priceStr.replaceAll(RegExp(r'[^\d.]'), '');
    double amount = double.tryParse(numStr) ?? 0.0;

    if (amount == 0) {
      // Free plan - skip payment and go directly to create listing
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(selectedPlan: selectedPlan),
        ),
      );
    } else {
      // Paid plan - go to payment screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(selectedPlan: selectedPlan),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Plan'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load plans',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Using default plans',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadPlans,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Refresh button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: _loadPlans,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Refresh Plans'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Plans grid
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: _plans.length,
                      itemBuilder: (context, index) {
                        final plan = _plans[index];
                        return _buildPlanCard(plan);
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: plan['color'],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                plan['name'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  plan['price'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (plan['period'].isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    plan['period'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Features
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: plan['features'].map<Widget>((feature) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                              fontSize: 12,
                              color: Colors.grey[700],
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Select button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _selectPlan(plan['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Select',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
