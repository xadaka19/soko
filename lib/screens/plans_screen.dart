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

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  late Future<List<Plan>> _plansFuture;

  @override
  void initState() {
    super.initState();
    _plansFuture = fetchPlans();
  }

  Future<List<Plan>> fetchPlans() async {
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
        title: const Text('Choose Your Plan'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: FutureBuilder<List<Plan>>(
        future: _plansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _plansFuture = fetchPlans();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No plans available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final plans = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select a plan that works for you',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upgrade anytime. Cancel anytime.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ...plans.map((plan) => _buildPlanCard(plan)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlanCard(Plan plan) {
    final isFeatured = plan.type.contains('feat');
    final isFree =
        plan.price.toLowerCase().contains('free') ||
        plan.price.contains('0') && !plan.price.contains('10');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFeatured ? Colors.deepPurple : Colors.grey[300]!,
          width: isFeatured ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => _selectPlan(plan),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isFeatured
                                      ? Colors.deepPurple
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    plan.price,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isFree
                                          ? Colors.green
                                          : Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    plan.period,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isFeatured
                                ? Colors.deepPurple.withValues(alpha: 0.1)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isFree
                                ? Icons.star_outline
                                : Icons.diamond_outlined,
                            color: isFeatured
                                ? Colors.deepPurple
                                : Colors.grey[600],
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...plan.features
                        .take(4)
                        .map(
                          (feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: isFeatured
                                      ? Colors.deepPurple
                                      : Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    if (plan.features.length > 4)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+${plan.features.length - 4} more features',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _selectPlan(plan),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFeatured
                              ? Colors.deepPurple
                              : isFree
                              ? Colors.green
                              : Colors.grey[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isFree ? 'Start Free' : 'Choose Plan',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isFeatured)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 12,
                ),
                child: const Text(
                  'POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
