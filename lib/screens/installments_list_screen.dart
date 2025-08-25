import 'package:flutter/material.dart';
import '../models/client.dart';
import 'add_installment.dart';
import 'monthly_installments.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../services/base_service.dart';

class InstallmentsListScreen extends StatefulWidget {
  const InstallmentsListScreen({super.key});

  @override
  State<InstallmentsListScreen> createState() => _InstallmentsListScreenState();
}

class _InstallmentsListScreenState extends State<InstallmentsListScreen> {
  List installments = [];
  Map<int, String> clientNames = {};
  
  Future<void> _refreshAll() async {
    await Future.wait([
      fetchClients(),
      fetchInstallments(),
    ]);
  }

  @override
  void initState() {
    super.initState();
    fetchClients(); // First get client names
    fetchInstallments(); // Then get installment data
  }

  Future<void> fetchInstallments() async {
    try {
      final response = await BaseService.authenticatedGet(
        'http://$ip/backend/installments.php?type=plans',
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            installments = data['data'];
          });
        } else {
          showError(data['message'] ?? 'Failed to load installments');
        }
      } else {
        showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      showError('Failed to load installments');
    }
  }

  Future<void> fetchClients() async {
    try {
      final response = await BaseService.authenticatedGet(
        'http://$ip/backend/clients.php',
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final clients = List<Client>.from(
            data['data'].map((c) => Client.fromJson(c)),
          );
          setState(() {
            clientNames = {for (var client in clients) client.id!: client.name};
          });
        } else {
          showError(data['message'] ?? 'Failed to load clients');
        }
      } else {
        showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      showError('Failed to load clients');
    }
  }

  void _navigateToAddInstallment() async {
    try {
      final response = await BaseService.authenticatedGet(
        'http://$ip/backend/clients.php',
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final clients = List<Client>.from(
            data['data'].map((c) => Client.fromJson(c)),
          );
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddInstallmentPlanPage(clients: clients),
            ),
          );
          if (result == true) {
            fetchInstallments();
          }
        } else {
          showError(data['message'] ?? 'Failed to load clients');
        }
      } else {
        showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      showError('Failed to connect to server');
    }
  }

  void _openMonthlyInstallments(int planId, String clientName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MonthlyInstallmentsPage(
          planId: planId,
          clientName: clientName,
        ),
      ),
    );
  }

  void showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Installments')),
      body: installments.isEmpty
          ? const Center(child: Text('No Installment Plans Found'))
          : RefreshIndicator(
              onRefresh: _refreshAll,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: installments.length,
                itemBuilder: (context, index) {
                  final i = installments[index];
                  final rawClientId = i['client_id'];
                  final clientId = rawClientId is int
                      ? rawClientId
                      : int.tryParse(rawClientId.toString());
                  final clientName = clientId != null
                      ? (clientNames[clientId] ?? 'Client #$clientId')
                      : 'Unknown client';

                  final isCompleted = (i['is_completed'] == true) || (i['status'] == 'completed');
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _openMonthlyInstallments(i['id'], clientName),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.teal[50],
                              child: Text(
                                clientName.isNotEmpty ? clientName[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: Colors.teal[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          clientName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if (isCompleted)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green[100],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'COMPLETED',
                                            style: TextStyle(
                                              color: Colors.green[800],
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.payments_outlined, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 6),
                                      Text('Total: ₹${i['total_amount']}'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_month_outlined, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 6),
                                      Text('Months: ${i['months']}'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.event_outlined, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 6),
                                      Text('Start: ${i['start_date']}'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right, color: Colors.grey[500]),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddInstallment,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
