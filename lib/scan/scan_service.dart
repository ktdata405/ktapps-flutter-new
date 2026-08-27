import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'scan_models.dart';

class ScanService {
  static const String _endpoint =
      'https://script.google.com/macros/s/AKfycbx1omrMP9s6nzIkaUXj2XtKZL8G3bmCuq_Kmbhca0B808X__k7ZjQzZNNoLUJqKS3V5/exec';

  Future<List<ScanRecord>> fetchScans() async {
    try {
      final response = await http.get(Uri.parse('$_endpoint?t=${DateTime.now().millisecondsSinceEpoch}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final List<dynamic> list = data['data'];
          return list.map((item) => ScanRecord.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching scans: $e');
      return [];
    }
  }

  Future<bool> uploadFiles(List<File> files, String? folderName) async {
    try {
      final List<Map<String, String>> processedFiles = [];
      for (var file in files) {
        final bytes = await file.readAsBytes();
        final base64Data = base64Encode(bytes);
        processedFiles.add({
          'name': file.path.split('/').last,
          'type': _getMimeType(file.path),
          'data': base64Data,
        });
      }

      final payload = {
        'files': processedFiles,
        if (folderName != null && folderName.isNotEmpty) 'folderName': folderName,
      };

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('Error uploading files: $e');
      return false;
    }
  }

  String _getMimeType(String path) {
    if (path.endsWith('.pdf')) return 'application/pdf';
    if (path.endsWith('.png')) return 'image/png';
    return 'image/jpeg';
  }

  Future<bool> performAction(String action, Map<String, dynamic> payload) async {
    try {
      final body = {'action': action, ...payload};
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('Error performing action $action: $e');
      return false;
    }
  }
}
