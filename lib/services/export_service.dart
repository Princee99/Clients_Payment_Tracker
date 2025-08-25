import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/ledger_entry.dart';
import '../models/client.dart';
import 'package:flutter/services.dart' show rootBundle;

class ExportService {
  // Helper method to safely format amounts from various types
  static String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';

    if (amount is num) {
      return amount.toStringAsFixed(2);
    }

    if (amount is String) {
      final parsed = double.tryParse(amount);
      return parsed?.toStringAsFixed(2) ?? '0.00';
    }

    return '0.00';
  }

  // (Excel helpers removed because we no longer export Excel)

  // UI helpers for PDF
  static pw.Widget _summaryChip(
    String title,
    String value,
    PdfColor bg,
    PdfColor fg,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '₹$value',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _th(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Align(
        alignment:
            alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  static pw.Widget _td(
    String text, {
    bool alignRight = false,
    PdfColor? color,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Align(
        alignment:
            alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            color: color,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  static Future<File> exportToPDF({
    required List<LedgerEntry> entries,
    required Client client,
    required Map<String, dynamic> summary,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();

    // Load custom fonts to support currency symbols (₹) and better typography
    final baseFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto/static/Roboto-Regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto/static/Roboto-Bold.ttf'),
    );

    // Page theme and header/footer for better layout
    final pageTheme = pw.PageTheme(
      margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header:
            (ctx) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'CashInOut',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Client Ledger Report',
                          style: const pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      DateFormat('dd MMM yyyy').format(DateTime.now()),
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Container(height: 1, color: PdfColors.grey300),
              ],
            ),
        footer:
            (ctx) => pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Page ${ctx.pageNumber} / ${ctx.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ),
        build:
            (context) => [
              // Client Information
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Client Information',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: [
                        pw.Expanded(child: pw.Text('Name: ${client.name}')),
                        pw.Expanded(child: pw.Text('Phone: ${client.phone}')),
                      ],
                    ),
                    pw.Text('Address: ${client.address}'),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // Summary chips
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _summaryChip(
                    'Total Debit',
                    _formatAmount(summary['total_debit']),
                    PdfColors.red50,
                    PdfColors.red800,
                  ),
                  _summaryChip(
                    'Total Credit',
                    _formatAmount(summary['total_credit']),
                    PdfColors.green50,
                    PdfColors.green800,
                  ),
                  _summaryChip(
                    'Outstanding',
                    _formatAmount(summary['outstanding_balance']),
                    PdfColors.orange50,
                    PdfColors.orange800,
                  ),
                ],
              ),

              if (startDate != null || endDate != null) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  'Period: ${startDate != null ? DateFormat('dd/MM/yyyy').format(startDate) : 'All'} - ${endDate != null ? DateFormat('dd/MM/yyyy').format(endDate) : 'All'}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],

              pw.SizedBox(height: 12),

              // Ledger Table with zebra rows and right-aligned amounts
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.2),
                  1: const pw.FlexColumnWidth(2.6),
                  2: const pw.FlexColumnWidth(1.1),
                  3: const pw.FlexColumnWidth(1.1),
                  4: const pw.FlexColumnWidth(1.2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      _th('Date'),
                      _th('Description'),
                      _th('Debit', alignRight: true),
                      _th('Credit', alignRight: true),
                      _th('Balance', alignRight: true),
                    ],
                  ),
                  ...entries.asMap().entries.map((e) {
                    final i = e.key;
                    final entry = e.value;
                    final bg = i.isEven ? PdfColors.white : PdfColors.grey100;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: bg),
                      children: [
                        _td(DateFormat('dd/MM/yyyy').format(entry.date)),
                        _td(entry.description),
                        _td(
                          entry.debit > 0
                              ? '₹${entry.debit.toStringAsFixed(2)}'
                              : '',
                          alignRight: true,
                          color: PdfColors.red800,
                        ),
                        _td(
                          entry.credit > 0
                              ? '₹${entry.credit.toStringAsFixed(2)}'
                              : '',
                          alignRight: true,
                          color: PdfColors.green800,
                        ),
                        _td(
                          '₹${entry.runningBalance.toStringAsFixed(2)}',
                          alignRight: true,
                          isBold: true,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/ledger_${client.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<void> shareFile(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: 'Ledger Report');
  }
}
