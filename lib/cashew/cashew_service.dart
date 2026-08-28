import 'dart:convert';
import 'package:http/http.dart' as http;
import 'cashew_constants.dart';
import 'cashew_models.dart';

class CashewService {
  static final CashewService _instance = CashewService._internal();
  factory CashewService() => _instance;
  CashewService._internal();

  // Simple in-memory cache
  final Map<String, dynamic> _cache = {};

  Future<Map<String, dynamic>> fetchDataForDate(DateTime date, String formattedDate, String sheetName) async {
    final url = '$cashewSheetUrl?sheetName=${Uri.encodeComponent(sheetName)}&t=${DateTime.now().millisecondsSinceEpoch}';
    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final allRows = (data['data'] as List? ?? []);
    final forDate = allRows.where((e) => (e['date'] ?? '') == formattedDate).toList();
    
    return {
      'rows': forDate,
      'availableBalance': data['availableBalance'] ?? 0,
    };
  }

  Future<List<String>> fetchDatesForCalendar(String sheetName) async {
    final url = '$cashewSheetUrl?sheetName=${Uri.encodeComponent(sheetName)}&datesOnly=true';
    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['dates'] as List? ?? []).cast<String>();
  }

  Future<void> saveData(Map<String, dynamic> payload) async {
    await http.post(
      Uri.parse(cashewSheetUrl),
      body: jsonEncode(payload),
    );
  }

  Future<Map<String, dynamic>> fetchReport({String? month, int? year, bool fetchAll = false}) async {
    String url;
    if (fetchAll) {
      url = '$cashewSheetUrl?fetchAll=true&t=${DateTime.now().millisecondsSinceEpoch}';
    } else {
      url = '$cashewSheetUrl?sheetName=${Uri.encodeComponent('$month $year')}&t=${DateTime.now().millisecondsSinceEpoch}';
    }

    final cacheKey = 'report_$month\_$year\_$fetchAll';
    if (_cache.containsKey(cacheKey)) {
      // Background update could be implemented here
    }

    final response = await http.get(Uri.parse(url));
    final res = jsonDecode(response.body) as Map<String, dynamic>;
    
    _cache[cacheKey] = res;
    return res;
  }

  Future<List<Map<String, dynamic>>> fetchScheduled() async {
    final url = '$cashewSheetUrl?sheetName=Scheduled&t=${DateTime.now().millisecondsSinceEpoch}';
    final response = await http.get(Uri.parse(url));
    final res = jsonDecode(response.body) as Map<String, dynamic>;
    return (res['data'] as List? ?? []).cast<Map<String, dynamic>>();
  }
}
