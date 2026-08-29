import 'dart:convert';
import 'package:http/http.dart' as http;

class MsiService {
  static const String msiEndpoint =
      'https://script.google.com/macros/s/AKfycbymQCgffCJ_XCrKk1RjgZlVTfquqzHW_n3pPYNNrINeDsTjJy0Yx18ZfgOmr6qSsCcb/exec';

  Future<Map<String, dynamic>> fetchReport() async {
    final response = await http.get(Uri.parse('$msiEndpoint?action=getReport&t=${DateTime.now().millisecondsSinceEpoch}'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch MSI report');
  }

  Future<Map<String, dynamic>> fetchData(String month, String year, String user) async {
    final url = '$msiEndpoint?action=getData&month=$month&year=$year&user=$user&t=${DateTime.now().millisecondsSinceEpoch}';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch MSI data');
  }

  Future<void> saveData(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse(msiEndpoint),
      headers: {'Content-Type': 'text/plain;charset=utf-8'},
      body: jsonEncode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to save MSI data');
    }
  }
}
