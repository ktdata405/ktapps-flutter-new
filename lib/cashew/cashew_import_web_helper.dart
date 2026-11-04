import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

@JS('XLSX')
external JSObject? get _xlsxGlobal;

extension XLSXGlobalExtension on JSObject {
  external JSObject? read(JSUint8Array data, JSObject opts);
  external JSObject? get Sheets;
  external JSArray? get SheetNames;
  external JSObject? get utils;
}

extension XLSXUtilsExtension on JSObject {
  external JSArray? sheet_to_json(JSObject sheet, [JSObject? opts]);
}

Future<List<Map<String, dynamic>>> parseExcelWeb(Uint8List bytes) async {
  try {
    final xlsx = _xlsxGlobal;
    if (xlsx == null) {
      debugPrint('SheetJS (XLSX) library not found on window.');
      return [];
    }

    JSUint8Array jsArray = bytes.toJS;
    var opts = {'type': 'array', 'cellDates': true}.jsify() as JSObject;

    JSObject? workbook = xlsx.read(jsArray, opts);
    if (workbook == null) return [];

    JSArray? sheetNamesArr = workbook.getProperty('SheetNames'.toJS) as JSArray?;
    if (sheetNamesArr == null) return [];
    
    int sheetCount = (sheetNamesArr.getProperty('length'.toJS) as JSNumber).toDartInt;
    String targetSheetName = '';
    
    // 1. Try to find by name "Passbook Payment History"
    for (int i = 0; i < sheetCount; i++) {
      var nameObj = sheetNamesArr.getProperty(i.toJS);
      if (nameObj.isUndefinedOrNull) continue;
      String name = (nameObj as JSString).toDart;
      if (name == 'Passbook Payment History') {
        targetSheetName = name;
        break;
      }
    }
    
    // 2. Fallback to 2nd sheet (index 1) if not found by name
    if (targetSheetName.isEmpty && sheetCount > 1) {
      var nameObj = sheetNamesArr.getProperty(1.toJS);
      if (!nameObj.isUndefinedOrNull) {
        targetSheetName = (nameObj as JSString).toDart;
      }
    } 
    
    // 3. Fallback to 1st sheet if still empty
    if (targetSheetName.isEmpty && sheetCount > 0) {
      var nameObj = sheetNamesArr.getProperty(0.toJS);
      if (!nameObj.isUndefinedOrNull) {
        targetSheetName = (nameObj as JSString).toDart;
      }
    }

    if (targetSheetName.isEmpty) return [];

    JSObject? sheetsObj = workbook.getProperty('Sheets'.toJS) as JSObject?;
    if (sheetsObj == null) return [];

    JSObject? targetSheet = sheetsObj.getProperty(targetSheetName.toJS) as JSObject?;
    if (targetSheet == null) return [];

    JSObject? utilsObj = xlsx.getProperty('utils'.toJS) as JSObject?;
    if (utilsObj == null) return [];

    JSObject jsonOpts = {'header': 1}.jsify() as JSObject;
    
    var rawJsonArray = utilsObj.callMethod('sheet_to_json'.toJS, targetSheet, jsonOpts) as JSArray?;
    if (rawJsonArray == null) return [];

    var dartified = rawJsonArray.dartify();

    if (dartified is List && dartified.isNotEmpty) {
      // Columns: A (0), C (2), F (5), I (8)
      const int dateIdx = 0;
      const int detailsIdx = 2; 
      const int amountIdx = 5;  
      const int remarksIdx = 8; 
      final header = dartified.first;
      final timeIdx = header is List
          ? header.indexWhere((value) => _normalizeHeader(value?.toString() ?? '') == 'time')
          : -1;

      List<Map<String, dynamic>> allRows = [];
      int counter = 0;

      for (int i = 1; i < dartified.length; i++) {
        var rawRow = dartified[i];
        if (rawRow is! List) continue;
        List<dynamic> row = rawRow;
        if (row.isEmpty) continue;
        
        String details = detailsIdx < row.length ? row[detailsIdx]?.toString().trim() ?? '' : '';

        if (details.toLowerCase().contains('other transaction') || details.isEmpty) {
          continue;
        }

        dynamic dateVal = dateIdx < row.length ? row[dateIdx] : null;
        String dateStr = _formatExcelDate(dateVal);
        final timeVal = timeIdx >= 0 && timeIdx < row.length ? row[timeIdx] : null;
        final transactionDateTime = _combineExcelDateAndTime(dateVal, timeVal);
        
        String amountRaw = amountIdx < row.length ? row[amountIdx]?.toString().trim() ?? '0' : '0';
        String remarksRaw = remarksIdx < row.length ? row[remarksIdx]?.toString().trim() ?? '' : '';
        
        // If Column I (Remarks) is empty, use Column C (Details) as the remark base
        String remarkBase = remarksRaw.isNotEmpty ? remarksRaw : details;

        double amount = (double.tryParse(amountRaw.replaceAll(',', '')) ?? 0).abs();
        if (amount == 0) continue;

        String formattedAmount = amount.toStringAsFixed(2);
        if (formattedAmount.endsWith('.00')) {
          formattedAmount = formattedAmount.substring(0, formattedAmount.length - 3);
        }

        allRows.add({
          'entryId': 'web-${counter++}',
          'date': dateStr,
          if (transactionDateTime != null)
            'transactionDateTime': transactionDateTime.toIso8601String(),
          'tag': 'Imported',
          'remarks': '${remarkBase.trim()} - $formattedAmount',
          'manualEntry': details,
          'amount': amount,
          'isIncoming': false,
          'category': '',
        });
      }
      return allRows;
    }
  } catch (e) {
    debugPrint('Error parsing Excel on Web: $e');
  }
  return [];
}

String _normalizeHeader(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

DateTime? _combineExcelDateAndTime(dynamic dateValue, dynamic timeValue) {
  final date = _parseExcelDate(dateValue);
  if (date == null) return null;
  final time = _parseExcelTime(timeValue) ?? _parseExcelTime(dateValue);
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.$1, time.$2, time.$3);
}

DateTime? _parseExcelDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is num) {
    final days = value.floor();
    return DateTime(1899, 12, 30).add(Duration(days: days));
  }
  if (value == null) return null;
  final raw = value.toString().trim();
  final dmY = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})').firstMatch(raw);
  if (dmY != null) {
    final day = int.tryParse(dmY.group(1)!);
    final month = int.tryParse(dmY.group(2)!);
    var year = int.tryParse(dmY.group(3)!);
    if (day != null && month != null && year != null) {
      if (year < 100) year += 2000;
      return DateTime(year, month, day);
    }
  }
  return DateTime.tryParse(raw);
}

(int, int, int)? _parseExcelTime(dynamic value) {
  if (value is DateTime) return (value.hour, value.minute, value.second);
  if (value is num) {
    final fraction = value - value.floorToDouble();
    if (fraction <= 0 || fraction >= 1) return null;
    final seconds = (fraction * Duration.secondsPerDay).round() % Duration.secondsPerDay;
    return (seconds ~/ 3600, (seconds % 3600) ~/ 60, seconds % 60);
  }
  if (value == null) return null;
  final match = RegExp(r'^\s*(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([AaPp][Mm])?\s*$')
      .firstMatch(value.toString());
  if (match == null) return null;
  var hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  final second = int.tryParse(match.group(3) ?? '0') ?? 0;
  final meridiem = match.group(4)?.toLowerCase();
  if (meridiem == 'pm' && hour < 12) hour += 12;
  if (meridiem == 'am' && hour == 12) hour = 0;
  if (hour > 23 || minute > 59 || second > 59) return null;
  return (hour, minute, second);
}

String _formatExcelDate(dynamic v) {
  if (v == null) return '';
  DateTime? dt;
  if (v is DateTime) {
    dt = v;
  } else if (v is num) {
    dt = DateTime(1899, 12, 30).add(Duration(days: v.floor()));
  } else {
    final raw = v.toString().trim();
    // Prioritize DD/MM/YYYY format to avoid browser default MM/DD/YYYY parsing
    final dmY = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})$').firstMatch(raw);
    if (dmY != null) {
      final d = int.tryParse(dmY.group(1)!);
      final m = int.tryParse(dmY.group(2)!);
      var y = int.tryParse(dmY.group(3)!);
      if (d != null && m != null && y != null) {
        if (y < 100) y += 2000;
        try {
          dt = DateTime(y, m, d);
        } catch (_) {}
      }
    }
    dt ??= DateTime.tryParse(raw);
  }
  
  if (dt == null) return v.toString();
  
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${dt.day.toString().padLeft(2, '0')}/${m[dt.month - 1]}/${dt.year}';
}
