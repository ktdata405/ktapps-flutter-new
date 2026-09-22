import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'invites_models.dart';

class InvitesService {
  static const String _prefKey = 'invites_cached_records';
  
  // Apps Script Endpoint URL for sheet "invites"
  // Users can also customize this in settings if needed
  static const String defaultEndpoint =
      'https://script.google.com/macros/s/AKfycbxcMzaVARHPqapkplVgcl5R9P7JRSFvnfjWCs92q3RDHHENWGM86poQi6bCjnR7Gkvv/exec';

  Future<List<InvitesRecord>> fetchRecords() async {
    List<InvitesRecord> localRecords = await _loadFromLocal();
    
    try {
      final uri = Uri.parse('$defaultEndpoint?sheetName=invites&action=list&t=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode < 400) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> list = data['data'];
          final fetched = list.map((item) => InvitesRecord.fromJson(item)).toList();
          
          if (fetched.isNotEmpty) {
            await _saveToLocal(fetched);
            return fetched;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching invites records from Apps Script: $e');
    }
    
    return localRecords;
  }

  Future<bool> addRecord(InvitesRecord record) async {
    // 1. Save locally first for instant offline responsiveness
    final current = await _loadFromLocal();
    current.removeWhere((item) => item.sNo == record.sNo);
    current.insert(0, record);
    await _saveToLocal(current);

    // 2. Sync to Google Apps Script Sheet "invites"
    try {
      final Map<String, String> params = {
        'sheetName': 'invites',
        'action': 'addInvite',
        'sNo': record.sNo,
        'name': record.name,
        'phone': record.phone,
        'status': record.status,
        'place': record.place,
        'isActive': record.isActive.toString(),
        'remarks': record.remarks,
        'date': record.date,
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final uri = Uri.parse(defaultEndpoint).replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode < 400) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('Error adding invite record to sheet: $e');
    }
    return true;
  }

  Future<bool> updateRecord(InvitesRecord record) async {
    // 1. Update local storage
    final current = await _loadFromLocal();
    final index = current.indexWhere((item) => item.sNo == record.sNo);
    if (index != -1) {
      current[index] = record;
    } else {
      current.insert(0, record);
    }
    await _saveToLocal(current);

    // 2. Sync to Google Apps Script Sheet "invites"
    try {
      final Map<String, String> params = {
        'sheetName': 'invites',
        'action': 'updateInvite',
        'sNo': record.sNo,
        'name': record.name,
        'phone': record.phone,
        'status': record.status,
        'place': record.place,
        'isActive': record.isActive.toString(),
        'remarks': record.remarks,
        'date': record.date,
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final uri = Uri.parse(defaultEndpoint).replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode < 400) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint('Error updating invite record in sheet: $e');
    }
    return true;
  }

  Future<bool> deleteRecord(String sNo) async {
    // 1. Remove from local storage
    final current = await _loadFromLocal();
    current.removeWhere((item) => item.sNo == sNo);
    await _saveToLocal(current);

    // 2. Sync to Google Apps Script Sheet "invites"
    try {
      final Map<String, String> params = {
        'sheetName': 'invites',
        'action': 'deleteInvite',
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
      debugPrint('Error deleting invite record from sheet: $e');
    }
    return true;
  }

  Future<List<InvitesRecord>> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> list = json.decode(jsonString);
        return list.map((item) => InvitesRecord.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error loading local invites: $e');
    }
    return [];
  }

  Future<void> _saveToLocal(List<InvitesRecord> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(records.map((r) => r.toJson()).toList());
      await prefs.setString(_prefKey, jsonString);
    } catch (e) {
      debugPrint('Error saving local invites: $e');
    }
  }
}
