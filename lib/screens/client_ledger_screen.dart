import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/client.dart';
import '../models/ledger_entry.dart';
import '../services/ledger_service.dart';
import '../services/export_service.dart';
import 'dart:io';

class ClientLedgerScreen extends StatefulWidget {
  final Client client;

  const ClientLedgerScreen({Key? key, required this.client}) : super(key: key);

  @override
  _ClientLedgerScreenState createState() => _ClientLedgerScreenState();
}

class _ClientLedgerScreenState extends State<ClientLedgerScreen> {
  List<LedgerEntry> ledgerEntries = [];
  Map<String, dynamic> summary = {};
  bool isLoading = true;
  DateTime? startDate;
  DateTime? endDate;
  bool showDateFilter = false;

  @override
  void initState() {
    super.initState();
    _loadLedgerData();
  }

  Future<void> _loadLedgerData() async {
    setState(() {
      isLoading = true;
    });

    try {
      print('Loading ledger data for client: ${widget.client.id}');
      final entries = await LedgerService.getClientLedger(
        widget.client.id!,
        startDate: startDate,
        endDate: endDate,
      );
      print('Loaded ${entries.length} ledger entries');
      
      final clientSummary = await LedgerService.getClientSummary(widget.client.id!);
      print('Loaded client summary: $clientSummary');

      setState(() {
        ledgerEntries = entries;
        summary = clientSummary;
        isLoading = false;
      });
    } catch (e) {
      print('Error in _loadLedgerData: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading ledger data: $e')),
      );
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      _loadLedgerData();
    }
  }

  void _clearDateFilter() {
    setState(() {
      startDate = null;
      endDate = null;
    });
    _loadLedgerData();
  }

  Future<void> _exportToPDF() async {
    try {
      // Convert summary values to proper types for export
      final exportSummary = {
        'total_debit': double.tryParse(summary['total_debit']?.toString() ?? '0') ?? 0.0,
        'total_credit': double.tryParse(summary['total_credit']?.toString() ?? '0') ?? 0.0,
        'outstanding_balance': double.tryParse(summary['outstanding_balance']?.toString() ?? '0') ?? 0.0,
        'last_transaction_date': summary['last_transaction_date'],
      };
      
      final file = await ExportService.exportToPDF(
        entries: ledgerEntries,
        client: widget.client,
        summary: exportSummary,
        startDate: startDate,
        endDate: endDate,
      );
      await ExportService.shareFile(file);
    } catch (e) {
      print('Error in _exportToPDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting PDF: $e')),
      );
    }
  }

  // Excel export removed

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Export Ledger',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _exportToPDF();
                    },
                    icon: Icon(Icons.picture_as_pdf),
                    label: Text('PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                // Excel option removed
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.client.name}\'s Ledger'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                showDateFilter = !showDateFilter;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: _showExportOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Client Info Card
          Container(
            margin: EdgeInsets.all(16),
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
                Text(
                  widget.client.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Phone: ${widget.client.phone}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  'Address: ${widget.client.address}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Summary Cards
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Debit',
                    '₹${(double.tryParse(summary['total_debit']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}',
                    Colors.red[600]!,
                    Icons.remove_circle,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Total Credit',
                    '₹${(double.tryParse(summary['total_credit']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}',
                    Colors.green[600]!,
                    Icons.add_circle,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Balance',
                    '₹${(double.tryParse(summary['outstanding_balance']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}',
                    (double.tryParse(summary['outstanding_balance']?.toString() ?? '0') ?? 0.0) >= 0 
                        ? Colors.orange[600]! 
                        : Colors.red[600]!,
                    Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
          ),

          // Date Filter
          if (showDateFilter)
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date Range Filter',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectDateRange,
                          icon: Icon(Icons.date_range),
                          label: Text(
                            startDate != null && endDate != null
                                ? '${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}'
                                : 'Select Date Range',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal[600],
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        onPressed: _clearDateFilter,
                        icon: Icon(Icons.clear),
                        tooltip: 'Clear Filter',
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Ledger Entries
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ledgerEntries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No ledger entries found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: ledgerEntries.length,
                        itemBuilder: (context, index) {
                          final entry = ledgerEntries[index];
                          return _buildLedgerEntryCard(entry);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color color, IconData icon) {
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
            amount,
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

  Widget _buildLedgerEntryCard(LedgerEntry entry) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMM yyyy').format(entry.date),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: entry.debit > 0 ? Colors.red[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: entry.debit > 0 ? Colors.red[200]! : Colors.green[200]!,
                    ),
                  ),
                  child: Text(
                    entry.debit > 0 ? 'DEBIT' : 'CREDIT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: entry.debit > 0 ? Colors.red[600] : Colors.green[600],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              entry.description,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (entry.debit > 0)
                  Text(
                    'Debit: ₹${entry.debit.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[600],
                    ),
                  ),
                if (entry.credit > 0)
                  Text(
                    'Credit: ₹${entry.credit.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[600],
                    ),
                  ),
                Text(
                  'Balance: ₹${entry.runningBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                ),
              ],
            ),
            if (entry.notes != null && entry.notes!.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                'Notes: ${entry.notes}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 