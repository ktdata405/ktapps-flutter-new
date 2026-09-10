import 'dart:convert';
import 'package:http/http.dart' as http;
import 'cashew_constants.dart';

class CashewService {
  static final CashewService _instance = CashewService._internal();
  factory CashewService() => _instance;
  CashewService._internal();

  // Simple in-memory cache
  final Map<String, dynamic> _cache = {};
  
  // Cache for monthly data to avoid multiple hits for same month
  // Key: sheetName (e.g., "Jan 2024")
  final Map<String, Map<String, dynamic>> _monthlyCache = {};

  Future<Map<String, dynamic>> fetchDataForDate(DateTime date, String formattedDate, String sheetName) async {
    // If we have the month cached, use it
    if (_monthlyCache.containsKey(sheetName)) {
      final data = _monthlyCache[sheetName]!;
      final allRows = (data['data'] as List? ?? []);
      final forDate = allRows.where((e) => (e['date'] ?? '') == formattedDate).toList();
      final dates = allRows.map((e) => (e['date'] ?? '').toString()).toSet().toList();
      
      return {
        'rows': forDate,
        'dates': dates,
        'availableBalance': data['availableBalance'] ?? 0,
      };
    }

    final url = '$cashewSheetUrl?sheetName=${Uri.encodeComponent(sheetName)}&t=${DateTime.now().millisecondsSinceEpoch}';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch data: ${response.statusCode}');
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
      'availableBalance': data['availableBalance'] ?? 0,
    };
  }

  Future<List<String>> fetchDatesForCalendar(String sheetName) async {
    // If we have monthly cache, we don't need a separate network hit
    if (_monthlyCache.containsKey(sheetName)) {
      final allRows = (_monthlyCache[sheetName]!['data'] as List? ?? []);
      return allRows.map((e) => (e['date'] ?? '').toString()).toSet().toList();
    }

    final url = '$cashewSheetUrl?sheetName=${Uri.encodeComponent(sheetName)}&datesOnly=true';
    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['dates'] as List? ?? []).cast<String>();
  }

  Future<void> saveData(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse(cashewSheetUrl),
      body: jsonEncode(payload),
    );
    if (response.statusCode >= 400) {
      throw Exception('Failed to save data: ${response.statusCode}');
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
