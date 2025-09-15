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
      appBar: AppBar(title: const Text('Subscription Plans')),
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
                  Text('Error: ${snapshot.error}'),
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
            return const Center(child: Text('No plans available'));
          }

          final plans = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];

              // Highlight featured plans
              final isFeatured = plan.type.contains('feat');

              return Stack(
                children: [
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () => _selectPlan(plan),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isFeatured
                                    ? Colors.deepPurple
                                    : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${plan.price} ${plan.period}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isFeatured
                                    ? Colors.deepPurple
                                    : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: plan.features
                                  .map(
                                    (feature) => Row(
                                      children: [
                                        Icon(
                                          Icons.check,
                                          size: 16,
                                          color: isFeatured
                                              ? Colors.deepPurple
                                              : Colors.green,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(child: Text(feature)),
                                      ],
                                    ),
                                  )
                                  .toList(),
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
                            topRight: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 10,
                        ),
                        child: const Text(
                          'FEATURED',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
