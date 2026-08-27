import 'dart:convert';
import 'package:http/http.dart' as http;
import 'wallet_models.dart';

class WalletService {
  static const String _endpoint =
      'https://script.google.com/macros/s/AKfycbzucE4LXHR8Jg6JNHnk2HsT01Ph7-9DfarVCceqZyPrKKElNS0tc1c5b76vIDy8XJbE/exec';

  Future<List<WalletRecord>> fetchEntries() async {
    try {
      final response = await http.get(Uri.parse('$_endpoint?action=listWalletEntries&t=${DateTime.now().millisecondsSinceEpoch}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> list = data['data'];
          return list.map((item) => WalletRecord.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching wallet entries: $e');
      return [];
    }
  }

  Future<bool> addEntry(Map<String, dynamic> payload) async {
    try {
      final Map<String, String> params = {
        'action': 'addWalletEntry',
        'savedAt': DateTime.now().toIso8601String(),
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      
      payload.forEach((key, value) {
        if (value != null) {
          params[key] = value.toString();
        }
      });
      
      final uri = Uri.parse(_endpoint).replace(queryParameters: params);
      final response = await http.get(uri); // Apps Script doGet handles it
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error adding wallet entry: $e');
      return false;
    }
  }

  Future<bool> deleteEntry(String id) async {
    try {
      final Map<String, String> params = {
        'action': 'deleteWalletEntry',
        'id': id,
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      
      final uri = Uri.parse(_endpoint).replace(queryParameters: params);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error deleting wallet entry: $e');
      return false;
    }
  }
}
