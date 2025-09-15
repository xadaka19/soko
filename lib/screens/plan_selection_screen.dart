import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import 'payment_screen.dart';

class Plan {
  final dynamic id;
  final String name;
  final String price;
  final String period;
  final List<String> features;
  final String type;

  Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.period,
    required this.features,
    required this.type,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'],
      name: json['name'] ?? '',
      price: json['price'] ?? '',
      period: json['period'] ?? '',
      features: List<String>.from(json['features'] ?? []),
      type: json['type'] ?? json['name']?.toString().toLowerCase() ?? '',
    );
  }
}

class PlanSelectionScreen extends StatefulWidget {
  const PlanSelectionScreen({super.key});

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  late Future<List<Plan>> _plansFuture;

  @override
  void initState() {
    super.initState();
    _plansFuture = _fetchPlans();
  }

  Future<List<Plan>> _fetchPlans() async {
    try {
      final response = await http
          .get(
            Uri.parse('${Api.baseUrl}${Api.getPlansEndpoint}'),
            headers: Api.headers,
          )
          .timeout(Api.timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List plansJson = data['plans'];
          return plansJson.map((plan) => Plan.fromJson(plan)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load plans');
        }
      } else {
        throw Exception('Failed to fetch plans: ${response.statusCode}');
      }
    } catch (e) {
      // Return default plans if API fails
      return _getDefaultPlans();
    }
  }

  List<Plan> _getDefaultPlans() {
    return [
      Plan(
        id: 'free',
        name: 'FREE PLAN',
        price: 'KES 0',
        period: '',
        features: ['Ads auto-renew Every 48 hours', '7 free credits(ads)'],
        type: 'free',
      ),
      Plan(
        id: 'top',
        name: 'TOP',
        price: 'KES 250',
        period: '',
        features: [
          '7 days listing',
          '1 credit (ad)',
          'Ads auto-renew Every 24 hours',
        ],
        type: 'top',
      ),
      Plan(
        id: 'top_featured',
        name: 'TOP FEATURED',
        price: 'KES 400',
        period: '/ month',
        features: ['1 credit (ad)', 'Ads auto-renew Every 16 hours'],
        type: 'featured',
      ),
      Plan(
        id: 'starter',
        name: 'STARTER',
        price: 'KES 3,000',
        period: '/ month',
        features: ['10 credits (ads)', 'Ads auto-renew Every 12 hours'],
        type: 'starter',
      ),
      Plan(
        id: 'basic',
        name: 'BASIC',
        price: 'KES 5,000',
        period: '/ month',
        features: ['27 credits (ads)', 'Ads auto-renew Every 10 hours'],
        type: 'basic',
      ),
      Plan(
        id: 'premium',
        name: 'PREMIUM',
        price: 'KES 7,000',
        period: '/ month',
        features: ['45 credits (ads)', 'Ads auto-renew Every 8 hours'],
        type: 'premium',
      ),
      Plan(
        id: 'business',
        name: 'BUSINESS',
        price: 'KES 10,000',
        period: '/ month',
        features: ['74 credits (ads)', 'Ads auto-renew Every 6 hours'],
        type: 'business',
      ),
    ];
  }

  void _selectPlan(Plan plan) {
    // Convert Plan to Map for PaymentScreen compatibility
    final planMap = {
      'id': plan.id,
      'name': plan.name,
      'price': plan.price,
      'period': plan.period,
      'features': plan.features,
      'type': plan.type,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(selectedPlan: planMap),
      ),
    );
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
      body: FutureBuilder<List<Plan>>(
        future: _plansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load plans',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Using default plans',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _plansFuture = _fetchPlans();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No plans available'));
          }

          final plans = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Refresh button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _plansFuture = _fetchPlans();
                        });
                      },
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
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      final plan = plans[index];
                      return _buildPlanCard(plan);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlanCard(Plan plan) {
    // Highlight featured plans
    final isFeatured = plan.type.contains('feat');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: isFeatured
              ? Border.all(color: Colors.deepPurple, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isFeatured ? Colors.deepPurple : Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                plan.name,
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
                  plan.price,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (plan.period.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    plan.period,
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
                children: plan.features.map<Widget>((feature) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: isFeatured
                              ? Colors.deepPurple
                              : Colors.green[600],
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
                onPressed: () => _selectPlan(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFeatured
                      ? Colors.deepPurple
                      : Colors.green,
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
