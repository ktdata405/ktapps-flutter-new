import 'dart:convert';
import 'package:http/http.dart' as http;

class DenominationsService {
  static const String denomEndpoint =
      'https://script.google.com/macros/s/AKfycbyPA-Tg-g8MhrdMZPNIKFfNvU691amfVEd751V-PwVh7FmZm_HmPBiVhLSr8d25R1qUlg/exec';

  Future<Map<String, dynamic>> fetchReport() async {
    try {
      final response = await http.get(Uri.parse(
          '$denomEndpoint?action=getReport&t=${DateTime.now().millisecondsSinceEpoch}'));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && !decoded.containsKey('error')) {
          return Map<String, dynamic>.from(decoded);
        } else if (decoded is List) {
          return {'reports': decoded};
        }
      }
    } catch (_) {}

    // Fallback to sheetName=Reports if action=getReport fails or isn't supported
    final response = await http.get(Uri.parse(
        '$denomEndpoint?sheetName=Reports&t=${DateTime.now().millisecondsSinceEpoch}'));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      } else if (decoded is List) {
        return {'reports': decoded};
      }
    }
    throw Exception('Failed to fetch denominations report');
  }

  Future<Map<String, dynamic>> fetchSheetData(String sheetName) async {
    final response = await http.get(Uri.parse(
        '$denomEndpoint?sheetName=${Uri.encodeComponent(sheetName)}&t=${DateTime.now().millisecondsSinceEpoch}'));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      } else if (decoded is List) {
        return {'data': decoded};
      }
      return {};
    }
    throw Exception('Failed to fetch sheet data');
  }

  Future<double> fetchPreviousBalance(String date) async {
    final response = await http.get(Uri.parse(
        '$denomEndpoint?action=getPrevBalance&date=$date&t=${DateTime.now().millisecondsSinceEpoch}'));
    if (response.statusCode == 200) {
      final res = jsonDecode(response.body);
      if (res is Map) {
        return double.tryParse('${res['balance'] ?? 0}') ?? 0;
      } else if (res is List && res.isNotEmpty) {
        // If it returns a list, maybe the first item has the balance? 
        // Or if it's just a number in a list?
        return double.tryParse('${res[0]}') ?? 0;
      } else if (res is num) {
        return res.toDouble();
      }
    }
    return 0;
  }

  Future<void> saveData(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse(denomEndpoint),
      headers: {'Content-Type': 'text/plain;charset=utf-8'},
      body: jsonEncode(payload),
    );
    // Google Apps Script often returns 302 Found or 200 OK.
    // If status is 4xx or 5xx, then it's a real error.
    if (response.statusCode >= 400) {
      throw Exception('Failed to save denominations data (Status: ${response.statusCode})');
    }
  }
}
