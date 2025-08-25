import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/client.dart';
import '../models/ledger_entry.dart';
import '../services/ledger_service.dart';
import '../services/export_service.dart';
import 'dart:io';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>> clientsSummary = [];
  bool isLoading = true;
  double totalOutstanding = 0.0;
  double totalDebit = 0.0;
  double totalCredit = 0.0;
  int totalClients = 0;
  int clientsWithBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadReportsData();
  }

    Future<void> _loadReportsData() async {
    setState(() {
      isLoading = true;
    });

    try {
      print('Loading reports data...');
      final summary = await LedgerService.getAllClientsSummary();
      print('Received summary: $summary');

      double outstanding = 0.0;
      double debit = 0.0;
      double credit = 0.0;
      int withBalance = 0;

      for (var client in summary) {
        // Convert string values to double
        double outstandingBalance = double.tryParse(client['outstanding_balance']?.toString() ?? '0') ?? 0.0;
        double totalDebit = double.tryParse(client['total_debit']?.toString() ?? '0') ?? 0.0;
        double totalCredit = double.tryParse(client['total_credit']?.toString() ?? '0') ?? 0.0;
        
        outstanding += outstandingBalance;
        debit += totalDebit;
        credit += totalCredit;
        if (outstandingBalance != 0) {
          withBalance++;
        }
      }

      print('Calculated totals:');
      print('Total clients: ${summary.length}');
      print('With balance: $withBalance');
      print('Total debit: $debit');
      print('Total credit: $credit');
      print('Outstanding: $outstanding');

      setState(() {
        clientsSummary = summary;
        totalOutstanding = outstanding;
        totalDebit = debit;
        totalCredit = credit;
        totalClients = summary.length;
        clientsWithBalance = withBalance;
        isLoading = false;
      });
    } catch (e) {
      print('Error in _loadReportsData: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading reports: $e')),
      );
    }
  }

  Future<void> _exportSummaryReport() async {
    try {
      // Create a mock client for the summary report
      final summaryClient = Client(
        id: 0,
        name: 'All Clients Summary',
        phone: '',
        address: '',
      );

      // Create ledger entries for summary
      final summaryEntries = clientsSummary.map((client) {
        double balance = double.tryParse(client['outstanding_balance']?.toString() ?? '0') ?? 0.0;
        int clientId = int.tryParse(client['client_id']?.toString() ?? '0') ?? 0;
        final double debitAmount = balance > 0 ? balance : 0.0;
        final double creditAmount = balance < 0 ? -balance : 0.0;
        return LedgerEntry(
          clientId: clientId,
          date: DateTime.now(),
          description: '${client['client_name']} - Outstanding Balance',
          debit: debitAmount,
          credit: creditAmount,
          runningBalance: balance,
          notes: 'Phone: ${client['client_phone'] ?? ''}',
        );
      }).toList();

      final summary = {
        'total_debit': totalDebit,
        'total_credit': totalCredit,
        'outstanding_balance': totalOutstanding,
      };

      final file = await ExportService.exportToPDF(
        entries: summaryEntries,
        client: summaryClient,
        summary: summary,
      );
      await ExportService.shareFile(file);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports & Summary'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadReportsData,
          ),
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: _exportSummaryReport,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReportsData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    _buildSummaryCards(),
                    SizedBox(height: 24),
                    
                    // Outstanding Balances Section
                    _buildOutstandingBalancesSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overall Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.teal[700],
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Clients',
                totalClients.toString(),
                Colors.blue[600]!,
                Icons.people,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'With Balance',
                clientsWithBalance.toString(),
                Colors.orange[600]!,
                Icons.account_balance_wallet,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Debit',
                '₹${totalDebit.toStringAsFixed(2)}',
                Colors.red[600]!,
                Icons.remove_circle,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Total Credit',
                '₹${totalCredit.toStringAsFixed(2)}',
                Colors.green[600]!,
                Icons.add_circle,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        _buildSummaryCard(
          'Outstanding Balance',
          '₹${totalOutstanding.toStringAsFixed(2)}',
          totalOutstanding >= 0 ? Colors.orange[600]! : Colors.red[600]!,
          Icons.account_balance,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutstandingBalancesSection() {
    final clientsWithOutstanding = clientsSummary
        .where((client) {
          double balance = double.tryParse(client['outstanding_balance']?.toString() ?? '0') ?? 0.0;
          return balance != 0;
        })
        .toList()
      ..sort((a, b) {
          double balanceA = double.tryParse(a['outstanding_balance']?.toString() ?? '0') ?? 0.0;
          double balanceB = double.tryParse(b['outstanding_balance']?.toString() ?? '0') ?? 0.0;
          return balanceB.compareTo(balanceA);
        });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Outstanding Balances',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal[700],
              ),
            ),
            Text(
              '${clientsWithOutstanding.length} clients',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        if (clientsWithOutstanding.isEmpty)
          Container(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 64,
                    color: Colors.green[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No outstanding balances!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: clientsWithOutstanding.length,
            itemBuilder: (context, index) {
              final client = clientsWithOutstanding[index];
              final balance = double.tryParse(client['outstanding_balance']?.toString() ?? '0') ?? 0.0;
              
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: balance > 0 ? Colors.red[100] : Colors.green[100],
                    child: Icon(
                      balance > 0 ? Icons.remove : Icons.add,
                      color: balance > 0 ? Colors.red[600] : Colors.green[600],
                    ),
                  ),
                  title: Text(
                    client['client_name'] ?? 'Unknown Client',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(
                        'Phone: ${client['client_phone'] ?? 'N/A'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (client['last_transaction_date'] != null)
                        Text(
                          'Last Transaction: ${DateFormat('dd MMM yyyy').format(DateTime.parse(client['last_transaction_date']))}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: balance > 0 ? Colors.red[600] : Colors.green[600],
                        ),
                      ),
                      Text(
                        balance > 0 ? 'Owes' : 'Credit',
                        style: TextStyle(
                          fontSize: 10,
                          color: balance > 0 ? Colors.red[600] : Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
} 