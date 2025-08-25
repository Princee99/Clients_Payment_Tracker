import 'package:cash_in_out/screens/add_payment.dart';
import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../models/client.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../services/base_service.dart';

class PaymentsListPage extends StatefulWidget {
  const PaymentsListPage({super.key});

  @override
  State<PaymentsListPage> createState() => _PaymentsListPageState();
}

class _PaymentsListPageState extends State<PaymentsListPage> {
  List<Map<String, dynamic>> payments = [];
  
  Future<void> fetchPayments() async {
    try {
      final response = await BaseService.authenticatedGet(
        'http://$ip/backend/payments.php',
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            payments = List<Map<String, dynamic>>.from(data['data']);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to fetch payments')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch payments')),
      );
    }
  }

  Future<List<Client>> fetchClients() async {
    try {
      final response = await BaseService.authenticatedGet(
        'http://$ip/backend/clients.php',
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return List<Client>.from(data['data'].map((c) => Client.fromJson(c)));
        }
      }
    } catch (_) {}
    return [];
  }

  void navigateToAddPayment() async {
    final clients = await fetchClients();

    if (clients.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No clients available')));
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddPaymentPage(clients: clients)),
    );

    if (result == true) {
      fetchPayments();
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPayments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payments List')),
      body: payments.isEmpty
          ? const Center(child: Text('No payments found'))
          : ListView.builder(
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                final amount = double.tryParse(payment['amount'].toString()) ?? 0.0;
                final status = payment['status'] ?? '';
                final timestamp = DateTime.tryParse(payment['timestamp'] ?? '') ?? DateTime.now();
                final clientName = payment['client_name'] ?? 'Unknown Client';
                final clientPhone = payment['client_phone'] ?? '';
                final tag = payment['tag'] ?? '';
                final note = payment['note'] ?? '';
                final installmentId = payment['installment_id'];
                
                return Card(
                  margin: const EdgeInsets.all(8),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Client Info Row
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Text(
                                clientName.isNotEmpty ? clientName[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    clientName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (clientPhone.isNotEmpty)
                                    Text(
                                      clientPhone,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Amount and Status
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${amount.abs().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: amount >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: status == 'sent' ? Colors.red[100] : Colors.green[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      color: status == 'sent' ? Colors.red[700] : Colors.green[700],
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Payment Details
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$tag - $note',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  if (installmentId != null)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Installment Payment',
                                        style: TextStyle(
                                          color: Colors.blue[700],
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              timestamp.toLocal().toString().split('.')[0],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: navigateToAddPayment,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
