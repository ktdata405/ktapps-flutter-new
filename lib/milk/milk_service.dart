import 'dart:convert';
import 'package:http/http.dart' as http;
import 'milk_models.dart';

class MilkService {
  static const String milkSheetUrl =
      'https://script.google.com/macros/s/AKfycbw9HPgLQojIqypEKeaCpwdZtdXmM7gqANY8LFWLWUAe5CNexRLTyrrX6JLFmiZC03B4CQ/exec';

  Future<Map<String, dynamic>> fetchDataForDate(String formattedDate, String sheetName) async {
    final url = '$milkSheetUrl?sheetName=${Uri.encodeComponent(sheetName)}&t=${DateTime.now().millisecondsSinceEpoch}';
    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final allRows = (data['data'] as List? ?? []);
    final forDate = allRows.where((e) => (e['date'] ?? '') == formattedDate).toList();
    
    return {
      'rows': forDate,
    };
  }

  Future<List<String>> fetchDatesForCalendar(String sheetName) async {
    final url = '$milkSheetUrl?sheetName=${Uri.encodeComponent(sheetName)}&datesOnly=true';
    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['dates'] as List? ?? []).cast<String>();
  }

  Future<void> saveData(Map<String, dynamic> payload) async {
    await http.post(
      Uri.parse(milkSheetUrl),
      body: jsonEncode(payload),
    );
  }

  Future<Map<String, dynamic>> fetchReport({String? month, int? year, bool fetchAll = false}) async {
    String url;
    if (fetchAll) {
      url = '$milkSheetUrl?fetchAll=true&t=${DateTime.now().millisecondsSinceEpoch}';
    } else {
      url = '$milkSheetUrl?sheetName=${Uri.encodeComponent('$month $year')}&t=${DateTime.now().millisecondsSinceEpoch}';
    }

    final response = await http.get(Uri.parse(url));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> markMonthPaid(String sheetName) async {
    final payload = {
      'type': 'milk',
      'action': 'markMonthPaid',
      'sheetName': sheetName,
      'status': 'Paid',
    };
    await http.post(
      Uri.parse(milkSheetUrl),
      body: jsonEncode(payload),
    );
  }
}
