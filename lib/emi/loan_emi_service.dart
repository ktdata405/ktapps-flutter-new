import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../cc_emi/cc_emi_service.dart';
import 'loan_emi_models.dart';

class LoanEmiService {
  static String createRequestId() {
    final random = Random.secure();
    final suffix =
        List.generate(16, (_) => random.nextInt(16).toRadixString(16)).join();
    return '${DateTime.now().microsecondsSinceEpoch}-$suffix';
  }

  LoanEmiService({http.Client? client, this.endpoint = CcEmiService.endpoint})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String endpoint;

  // The existing web app uses GET mutations to avoid Apps Script's
  // cross-origin POST redirect restrictions in Flutter web.
  Future<Map<String, dynamic>> _request(
    String action, [
    Map<String, String> params = const {},
  ]) async {
    try {
      final uri = Uri.parse(endpoint).replace(
        queryParameters: {
          ...params,
          'action': action,
          't': DateTime.now().microsecondsSinceEpoch.toString(),
        },
      );
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw StateError('Loan EMI HTTP ${response.statusCode}');
      }
      final result = jsonDecode(response.body) as Map<String, dynamic>;
      if (result['module'] != 'loanEmi') {
        throw StateError('The Loan EMI Apps Script handlers are not deployed');
      }
      if (result['success'] != true) {
        throw StateError(
          result['error']?.toString() ?? 'Loan EMI request failed',
        );
      }
      return result;
    } catch (error) {
      debugPrint('Loan EMI $action failed: $error');
      rethrow;
    }
  }

  Future<List<LoanEmiRecord>> fetchRecords() async {
    final result = await _request('listLoanEmis');
    final records =
        (result['data'] as List<dynamic>)
            .map((row) => LoanEmiRecord.fromJson(row as Map<String, dynamic>))
            .toList();
    return records;
  }

  Future<void> saveRecord(
    LoanEmiRecord record, {
    required String requestId,
  }) async {
    await _request(record.id == null ? 'addLoanEmi' : 'updateLoanEmi', {
      ...record.toParams(),
      if (record.id == null) 'id': requestId,
    });
  }

  Future<void> deleteRecord(String id) async {
    await _request('deleteLoanEmi', {'id': id});
  }

  Future<void> recordPayment(LoanEmiPayment payment) async {
    await _request('recordLoanEmiPayment', payment.toParams());
  }

  Future<void> recordRateRevision(LoanRateRevision revision) async {
    await _request('recordLoanRateRevision', revision.toParams());
  }

  void dispose() => _client.close();
}
