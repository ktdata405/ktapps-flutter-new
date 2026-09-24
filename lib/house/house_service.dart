import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'house_models.dart';

class HouseService {
  static const String _housePrefKey = 'house_bills_cached_records';
  static const String _hlPrefKey = 'hl_disbursement_cached_records';

  static const String defaultEndpoint =
      'https://script.google.com/macros/s/AKfycbywFVCu4CEiumfpkdbrb0Kyqau59MQiL0STPugrV5i775Y6drM3TLKSKl9cdcjPYCQh1Q/exec';

  // ── House Construction Bills (Splitwise Sheet) ───────────────────────────

  Future<List<HouseBillRecord>> fetchHouseBills() async {
    List<HouseBillRecord> localRecords = await _loadHouseBillsFromLocal();

    try {
      final uri = Uri.parse(
          '$defaultEndpoint?sheetName=${Uri.encodeComponent("Splitwise")}&action=list&t=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode < 400) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> list = data['data'];
          final fetched = list.map((item) => HouseBillRecord.fromJson(item)).toList();

          if (fetched.isNotEmpty) {
            await _saveHouseBillsToLocal(fetched);
            return fetched;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching House Construction Bills from Apps Script: $e');
    }

    return localRecords;
  }

  Future<bool> addHouseBill(HouseBillRecord record) async {
    final current = await _loadHouseBillsFromLocal();
    current.removeWhere((item) => item.sNo == record.sNo);
    current.insert(0, record);
    await _saveHouseBillsToLocal(current);

    try {
      final Map<String, String> params = {
        'sheetName': 'Splitwise',
        'action': 'add',
        'sNo': record.sNo,
        'date': record.date,
        'groupName': record.groupName,
        'amount': record.amount.toString(),
        'contractAmount': record.contractAmount.toString(),
        'balanceAmount': record.balanceAmount.toString(),
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final uri = Uri.parse(defaultEndpoint).replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode < 400) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('Error adding house bill: $e');
    }
    return true;
  }

  Future<bool> updateHouseBill(HouseBillRecord record) async {
    final current = await _loadHouseBillsFromLocal();
    final index = current.indexWhere((item) => item.sNo == record.sNo);
    if (index != -1) {
      current[index] = record;
    } else {
      current.insert(0, record);
    }
    await _saveHouseBillsToLocal(current);

    try {
      final Map<String, String> params = {
        'sheetName': 'Splitwise',
        'action': 'update',
        'sNo': record.sNo,
        'date': record.date,
        'groupName': record.groupName,
        'amount': record.amount.toString(),
        'contractAmount': record.contractAmount.toString(),
        'balanceAmount': record.balanceAmount.toString(),
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final uri = Uri.parse(defaultEndpoint).replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode < 400) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('Error updating house bill: $e');
    }
    return true;
  }

  Future<bool> deleteHouseBill(String sNo) async {
    final current = await _loadHouseBillsFromLocal();
    current.removeWhere((item) => item.sNo == sNo);
    await _saveHouseBillsToLocal(current);

    try {
      final Map<String, String> params = {
        'sheetName': 'Splitwise',
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
      debugPrint('Error deleting house bill: $e');
    }
    return true;
  }

  Future<List<HouseBillRecord>> _loadHouseBillsFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_housePrefKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> list = json.decode(jsonString);
        return list.map((item) => HouseBillRecord.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error loading local house bills: $e');
    }
    return [];
  }

  Future<void> _saveHouseBillsToLocal(List<HouseBillRecord> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(records.map((r) => r.toJson()).toList());
      await prefs.setString(_housePrefKey, jsonString);
    } catch (e) {
      debugPrint('Error saving local house bills: $e');
    }
  }

  // ── HL-disbursement (HL-disbursement Sheet) ──────────────────────────────

  Future<List<HlDisbursementRecord>> fetchHlDisbursements() async {
    List<HlDisbursementRecord> localRecords = await _loadHlFromLocal();

    try {
      final uri = Uri.parse(
          '$defaultEndpoint?sheetName=${Uri.encodeComponent("HL-disbursement")}&action=list&t=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode < 400) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> list = data['data'];
          final fetched = list.map((item) => HlDisbursementRecord.fromJson(item)).toList();

          if (fetched.isNotEmpty) {
            await _saveHlToLocal(fetched);
            return fetched;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching HL disbursements from Apps Script: $e');
    }

    return localRecords;
  }

  Future<bool> addHlDisbursement(HlDisbursementRecord record) async {
    final current = await _loadHlFromLocal();
    current.removeWhere((item) => item.sNo == record.sNo);
    current.insert(0, record);
    await _saveHlToLocal(current);

    try {
      final Map<String, String> params = {
        'sheetName': 'HL-disbursement',
        'action': 'add',
        'sNo': record.sNo,
        'date': record.date,
        'amount': record.amount.toString(),
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final uri = Uri.parse(defaultEndpoint).replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode < 400) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('Error adding HL disbursement: $e');
    }
    return true;
  }

  Future<bool> updateHlDisbursement(HlDisbursementRecord record) async {
    final current = await _loadHlFromLocal();
    final index = current.indexWhere((item) => item.sNo == record.sNo);
    if (index != -1) {
      current[index] = record;
    } else {
      current.insert(0, record);
    }
    await _saveHlToLocal(current);

    try {
      final Map<String, String> params = {
        'sheetName': 'HL-disbursement',
        'action': 'update',
        'sNo': record.sNo,
        'date': record.date,
        'amount': record.amount.toString(),
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final uri = Uri.parse(defaultEndpoint).replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode < 400) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('Error updating HL disbursement: $e');
    }
    return true;
  }

  Future<bool> deleteHlDisbursement(String sNo) async {
    final current = await _loadHlFromLocal();
    current.removeWhere((item) => item.sNo == sNo);
    await _saveHlToLocal(current);

    try {
      final Map<String, String> params = {
        'sheetName': 'HL-disbursement',
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
      debugPrint('Error deleting HL disbursement: $e');
    }
    return true;
  }

  Future<List<HlDisbursementRecord>> _loadHlFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_hlPrefKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> list = json.decode(jsonString);
        return list.map((item) => HlDisbursementRecord.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error loading local HL disbursements: $e');
    }
    return [];
  }

  Future<void> _saveHlToLocal(List<HlDisbursementRecord> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(records.map((r) => r.toJson()).toList());
      await prefs.setString(_hlPrefKey, jsonString);
    } catch (e) {
      debugPrint('Error saving local HL disbursements: $e');
    }
  }
}
