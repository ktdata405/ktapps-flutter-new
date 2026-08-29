import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'debts_models.dart';

class DebtsService {
  static const String _endpoint =
      'https://script.google.com/macros/s/AKfycbzXF14LayWcUqHi8IHAaPby3klVgLwg1joi18lX6RybVIFLEYFlqkT7HZwKofecLrUxEQ/exec';

  Future<List<DebtRecord>> fetchRecords() async {
    try {
      final response = await http.get(Uri.parse('$_endpoint?action=list&t=${DateTime.now().millisecondsSinceEpoch}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> list = data['data'];
          return list.map((item) => DebtRecord.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching debt records: $e');
      return [];
    }
  }

  Future<bool> addRecord(DebtRecord record) async {
    try {
      final Map<String, String> params = {
        'action': 'addDebt',
        'date': record.date,
        'type': record.type,
        'person': record.person,
        'amount': record.amount.toString(),
        'remarks': record.remarks,
        'status': record.status,
        'settleRemarks': record.settleRemarks,
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      
      final uri = Uri.parse(_endpoint).replace(queryParameters: params);
      final response = await http.get(uri); // Apps Script doGet handles it
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding debt record: $e');
      return false;
    }
  }

  Future<bool> updateRecord(DebtRecord record) async {
    try {
      final Map<String, String> params = {
        'action': 'updateDebt',
        'id': record.id.toString(),
        'date': record.date,
        'type': record.type,
        'person': record.person,
        'amount': record.amount.toString(),
        'remarks': record.remarks,
        'status': record.status,
        'settleRemarks': record.settleRemarks,
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      
      final uri = Uri.parse(_endpoint).replace(queryParameters: params);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating debt record: $e');
      return false;
    }
  }

  Future<bool> updateStatus(int id, String status, String remarks) async {
    try {
      final Map<String, String> params = {
        'action': 'updateStatus',
        'id': id.toString(),
        'status': status,
        'remarks': remarks,
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      
      final uri = Uri.parse(_endpoint).replace(queryParameters: params);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating status: $e');
      return false;
    }
  }

  Future<bool> deleteRecord(int id) async {
    try {
      final Map<String, String> params = {
        'action': 'deleteDebt',
        'id': id.toString(),
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      
      final uri = Uri.parse(_endpoint).replace(queryParameters: params);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting debt record: $e');
      return false;
    }
  }
}
