import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'rent_models.dart';

class RentService {
  static const String _endpoint =
      'https://script.google.com/macros/s/AKfycbxliXgeKL-Uz3fStf7TMSR4wuXgtHP6Aztf3fL0Oy26LvCHiHVmL0V-9z3pI1ehOZH9UQ/exec';

  Future<List<RentRecord>> fetchRecords() async {
    try {
      final response = await http.get(Uri.parse(_endpoint));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success' || data['data'] != null) {
          final List<dynamic> list = data['data'] ?? [];
          return list.map((item) => RentRecord.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching rent records: $e');
      return [];
    }
  }

  Future<bool> addRecord(RentRecord record) async {
    try {
      final payload = record.toJson();
      payload['action'] = 'add';
      final response = await http.post(
        Uri.parse(_endpoint),
        body: json.encode(payload),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint('Error adding rent record: $e');
      return false;
    }
  }

  Future<bool> updateRecord(RentRecord record, String originalDate, String originalSide) async {
    try {
      final payload = record.toJson();
      payload['action'] = 'update';
      payload['originalDate'] = originalDate;
      payload['originalSide'] = originalSide;
      final response = await http.post(
        Uri.parse(_endpoint),
        body: json.encode(payload),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint('Error updating rent record: $e');
      return false;
    }
  }

  Future<bool> deleteRecord(String date, String side) async {
    try {
      final payload = {
        'action': 'delete',
        'originalDate': date,
        'originalSide': side,
      };
      final response = await http.post(
        Uri.parse(_endpoint),
        body: json.encode(payload),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting rent record: $e');
      return false;
    }
  }
}
