import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ledger_entry.dart';
import '../models/client.dart';
import '../config.dart';
import 'base_service.dart';

class LedgerService {
  static Future<List<LedgerEntry>> getClientLedger(int clientId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String url = 'http://$ip/backend/ledger.php?client_id=$clientId';
      
      if (startDate != null) {
        url += '&start_date=${startDate.toIso8601String().split('T')[0]}';
      }
      if (endDate != null) {
        url += '&end_date=${endDate.toIso8601String().split('T')[0]}';
      }

      final response = await BaseService.authenticatedGet(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return List<LedgerEntry>.from(
            data['data'].map((entry) => LedgerEntry.fromJson(entry)),
          );
        }
      }
      return [];
    } catch (e) {
      print('Error fetching ledger: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getClientSummary(int clientId) async {
    try {
      final response = await BaseService.authenticatedGet(
        'http://$ip/backend/ledger_summary.php?client_id=$clientId',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['data'];
        }
      }
      return {
        'total_debit': 0.0,
        'total_credit': 0.0,
        'outstanding_balance': 0.0,
        'last_transaction_date': null,
      };
    } catch (e) {
      print('Error fetching client summary: $e');
      return {
        'total_debit': 0.0,
        'total_credit': 0.0,
        'outstanding_balance': 0.0,
        'last_transaction_date': null,
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getAllClientsSummary() async {
    try {
      final response = await BaseService.authenticatedGet(
        'http://$ip/backend/all_clients_summary.php',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching all clients summary: $e');
      return [];
    }
  }

  static Future<List<LedgerEntry>> getAllLedgerEntries({
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) async {
    try {
      String url = 'http://$ip/backend/all_ledger.php';
      List<String> params = [];
      
      if (startDate != null) {
        params.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        params.add('end_date=${endDate.toIso8601String()}');
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        params.add('search=$searchQuery');
      }
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await BaseService.authenticatedGet(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return List<LedgerEntry>.from(
            data['data'].map((entry) => LedgerEntry.fromJson(entry)),
          );
        }
      }
      return [];
    } catch (e) {
      print('Error fetching all ledger entries: $e');
      return [];
    }
  }
} 