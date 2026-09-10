import 'dart:convert';
import 'package:http/http.dart' as http;

class MilkService {
  static const String milkSheetUrl =
      'https://script.google.com/macros/s/AKfycbw9HPgLQojIqypEKeaCpwdZtdXmM7gqANY8LFWLWUAe5CNexRLTyrrX6JLFmiZC03B4CQ/exec';

  // Cache for monthly data to avoid multiple hits for same month
  // Key: sheetName (e.g., "Jan 2024")
  final Map<String, Map<String, dynamic>> _monthlyCache = {};

  Future<Map<String, dynamic>> fetchDataForDate(String formattedDate, String sheetName) async {
    // If we have the month cached, use it
    if (_monthlyCache.containsKey(sheetName)) {
      final data = _monthlyCache[sheetName]!;
      final allRows = (data['data'] as List? ?? []);
      final forDate = allRows.where((e) => (e['date'] ?? '') == formattedDate).toList();
      final dates = allRows.map((e) => (e['date'] ?? '').toString()).toSet().toList();
      
      return {
        'rows': forDate,
        'dates': dates,
      };
    }

    final url = '$milkSheetUrl?sheetName=${Uri.encodeComponent(sheetName)}&t=${DateTime.now().millisecondsSinceEpoch}';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch milk data: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    
    // Store in monthly cache
    _monthlyCache[sheetName] = data;

    final allRows = (data['data'] as List? ?? []);
    final forDate = allRows.where((e) => (e['date'] ?? '') == formattedDate).toList();
    final dates = allRows.map((e) => (e['date'] ?? '').toString()).toSet().toList();
    
    return {
      'rows': forDate,
      'dates': dates,
    };
  }

  Future<List<String>> fetchDatesForCalendar(String sheetName) async {
    // If we have monthly cache, we don't need a separate network hit
    if (_monthlyCache.containsKey(sheetName)) {
      final allRows = (_monthlyCache[sheetName]!['data'] as List? ?? []);
      return allRows.map((e) => (e['date'] ?? '').toString()).toSet().toList();
    }

    final url = '$milkSheetUrl?sheetName=${Uri.encodeComponent(sheetName)}&datesOnly=true';
    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['dates'] as List? ?? []).cast<String>();
  }

  Future<void> saveData(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse(milkSheetUrl),
      body: jsonEncode(payload),
    );
    if (response.statusCode >= 400) {
      throw Exception('Failed to save milk data: ${response.statusCode}');
    }

    // Clear cache for the month so it refreshes on next fetch
    final sheetName = payload['sheetName'] as String?;
    if (sheetName != null) {
      _monthlyCache.remove(sheetName);
    }
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
    final response = await http.post(
      Uri.parse(milkSheetUrl),
      body: jsonEncode(payload),
    );
    if (response.statusCode >= 400) {
      throw Exception('Failed to mark month paid: ${response.statusCode}');
    }

    // Clear cache for the month
    _monthlyCache.remove(sheetName);
  }
}
