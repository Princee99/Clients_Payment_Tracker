// 📁 lib/screens/monthly_installments.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../services/base_service.dart';

class MonthlyInstallmentsPage extends StatefulWidget {
  final int planId;
  final String? clientName;

  const MonthlyInstallmentsPage({super.key, required this.planId, this.clientName});

  @override
  State<MonthlyInstallmentsPage> createState() =>
      _MonthlyInstallmentsPageState();
}

class _MonthlyInstallmentsPageState extends State<MonthlyInstallmentsPage> {
  List installments = [];

  @override
  void initState() {
    super.initState();
    fetchMonthlyInstallments();
  }

  Future<void> fetchMonthlyInstallments() async {
    try {
      final response = await BaseService.authenticatedGet(
        'http://$ip/backend/installments.php?type=installments&plan_id=${widget.planId}',
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            installments = data['data'];
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    Color _statusColor(String status) {
      switch (status) {
        case 'paid':
          return Colors.green[600]!;
        case 'overdue':
          return Colors.red[600]!;
        case 'cancelled':
          return Colors.grey[600]!;
        default:
          return Colors.orange[700]!; // pending
      }
    }

    IconData _statusIcon(String status) {
      switch (status) {
        case 'paid':
          return Icons.check_circle;
        case 'overdue':
          return Icons.error_outline;
        case 'cancelled':
          return Icons.cancel_outlined;
        default:
          return Icons.schedule;
      }
    }

    Widget _statusChip(String status) {
      final color = _statusColor(status);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          status.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      );
    }

    int paidCount = installments.where((e) => e['status'] == 'paid').length;
    int totalCount = installments.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.clientName == null
              ? 'Monthly Installments'
              : 'Monthly: ${widget.clientName}',
        ),
      ),
      body: installments.isEmpty
          ? const Center(child: Text('No installments found'))
          : RefreshIndicator(
              onRefresh: fetchMonthlyInstallments,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: installments.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Progress: $paidCount / $totalCount paid',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final item = installments[index - 1];
                  final status = (item['status'] ?? '').toString();
                  final monthYear = (item['month_year'] ?? '').toString();
                  final amount = double.tryParse(item['amount'].toString()) ?? 0.0;
                  final dueDate = (item['due_date'] ?? '').toString();
                  final paidDate = (item['paid_date'] ?? '').toString();

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: _statusColor(status).withOpacity(0.15),
                            radius: 20,
                            child: Icon(
                              _statusIcon(status),
                              color: _statusColor(status),
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
                                        monthYear,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    _statusChip(status),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      'Amount: ',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text('₹${amount.toStringAsFixed(2)}'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (dueDate.isNotEmpty)
                                  Row(
                                    children: [
                                      Text(
                                        'Due: ',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(dueDate),
                                    ],
                                  ),
                                if (paidDate.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Paid: ',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(paidDate),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
