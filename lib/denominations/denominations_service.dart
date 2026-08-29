import 'dart:convert';
import 'package:http/http.dart' as http;

class DenominationsService {
  static const String denomEndpoint =
      'https://script.google.com/macros/s/AKfycbyPA-Tg-g8MhrdMZPNIKFfNvU691amfVEd751V-PwVh7FmZm_HmPBiVhLSr8d25R1qUlg/exec';

  Future<Map<String, dynamic>> fetchReport() async {
    final response = await http.get(Uri.parse(
        '$denomEndpoint?action=getReport&t=${DateTime.now().millisecondsSinceEpoch}'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch denominations report');
  }

  Future<Map<String, dynamic>> fetchSheetData(String sheetName) async {
    final response = await http.get(Uri.parse(
        '$denomEndpoint?sheetName=${Uri.encodeComponent(sheetName)}&t=${DateTime.now().millisecondsSinceEpoch}'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch sheet data');
  }

  Future<double> fetchPreviousBalance(String date) async {
    final response = await http.get(Uri.parse(
        '$denomEndpoint?action=getPrevBalance&date=$date&t=${DateTime.now().millisecondsSinceEpoch}'));
    if (response.statusCode == 200) {
      final res = jsonDecode(response.body);
      return double.tryParse('${res['balance'] ?? 0}') ?? 0;
    }
    return 0;
  }

  Future<void> saveData(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse(denomEndpoint),
      headers: {'Content-Type': 'text/plain;charset=utf-8'},
      body: jsonEncode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to save denominations data');
    }
  }
}
