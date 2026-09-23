import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'essential_models.dart';

class EssentialService {
  static const String _prefKey = 'essential_cached_records';

  static const String defaultEndpoint =
      'https://script.google.com/macros/s/AKfycby5LUFWnkCFDIBHWDyXAejoynf7j0DY8VujegqWBJdaSqjALXyuRvvKin8_DowsSE6RYw/exec';

  Future<List<EssentialRecord>> fetchRecords() async {
    List<EssentialRecord> localRecords = await _loadFromLocal();

    try {
      final uri = Uri.parse(
          '$defaultEndpoint?sheetName=${Uri.encodeComponent("Essential Items for Delivery")}&action=list&t=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode < 400) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> list = data['data'];
          final fetched = list.map((item) => EssentialRecord.fromJson(item)).toList();

          if (fetched.isNotEmpty) {
            await _saveToLocal(fetched);
            return fetched;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching essential records from Apps Script: $e');
    }

    return localRecords;
  }

  Future<bool> addRecord(EssentialRecord record) async {
    final current = await _loadFromLocal();
    current.removeWhere((item) => item.sNo == record.sNo);
    current.insert(0, record);
    await _saveToLocal(current);

    try {
      final Map<String, String> params = {
        'sheetName': 'Essential Items for Delivery',
        'action': 'add',
        'sNo': record.sNo,
        'date': record.date,
        'fullName': record.fullName,
        'itemD': record.itemD.toString(),
        'itemE': record.itemE.toString(),
        'itemF': record.itemF.toString(),
        'itemG': record.itemG.toString(),
        'itemH': record.itemH.toString(),
        'totalAmount': record.totalAmount.toString(), // Column K
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final uri = Uri.parse(defaultEndpoint).replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode < 400) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('Error adding essential record: $e');
    }
    return true;
  }

  Future<bool> updateRecord(EssentialRecord record) async {
    final current = await _loadFromLocal();
    final index = current.indexWhere((item) => item.sNo == record.sNo);
    if (index != -1) {
      current[index] = record;
    } else {
      current.insert(0, record);
    }
    await _saveToLocal(current);

    try {
      final Map<String, String> params = {
        'sheetName': 'Essential Items for Delivery',
        'action': 'update',
        'sNo': record.sNo,
        'date': record.date,
        'fullName': record.fullName,
        'itemD': record.itemD.toString(),
        'itemE': record.itemE.toString(),
        'itemF': record.itemF.toString(),
        'itemG': record.itemG.toString(),
        'itemH': record.itemH.toString(),
        'totalAmount': record.totalAmount.toString(), // Column K
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final uri = Uri.parse(defaultEndpoint).replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode < 400) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('Error updating essential record: $e');
    }
    return true;
  }

  Future<bool> deleteRecord(String sNo) async {
    final current = await _loadFromLocal();
    current.removeWhere((item) => item.sNo == sNo);
    await _saveToLocal(current);

    try {
      final Map<String, String> params = {
        'sheetName': 'Essential Items for Delivery',
        'action': 'delete',
        'sNo': sNo,
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final uri = Uri.parse(defaultEndpoint).replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode < 400) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('Error deleting essential record: $e');
    }
    return true;
  }

  Future<List<EssentialRecord>> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> list = json.decode(jsonString);
        return list.map((item) => EssentialRecord.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error loading local essentials: $e');
    }
    return [];
  }

  Future<void> _saveToLocal(List<EssentialRecord> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(records.map((r) => r.toJson()).toList());
      await prefs.setString(_prefKey, jsonString);
    } catch (e) {
      debugPrint('Error saving local essentials: $e');
    }
  }
}
