import 'dart:typed_data';

import 'package:excel/excel.dart' as xl;
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';

// Conditional import: dart:io on native, stub on web
import 'cashew_file_helper_web.dart'
    if (dart.library.io) 'cashew_file_helper_native.dart';

import '../models/cashew_record.dart';
import '../services/api_service.dart';

// ─── Constants ────────────────────────────────────────────────────────────────

const _kCategories = <String>[
  'Home', 'My Personal', 'My Family', 'For Latha',
  'Baby', 'Credit Card', 'Mutual Funds/Investments', 'Lap EMI',
];

const _kIncomingTokens = ['received', 'credit', 'cr', 'incoming', 'refund', 'reversal', 'deposit'];

// ─── Screen ──────────────────────────────────────────────────────────────────

class CashewImportScreen extends StatefulWidget {
  const CashewImportScreen({super.key});

  @override
  State<CashewImportScreen> createState() => _CashewImportScreenState();
}

class _CashewImportScreenState extends State<CashewImportScreen> {
  Map<String, List<_ImportEntry>>? _entriesByDate;
  String _selectedDate = '';
  String _fileName = '';
  final _savedDates = <String>{};
  final _failedDates = <String>{};
  final _checkedDates = <String>{};
  bool _loading = false;
  String _loadingText = '';

  // ── Colors ──────────────────────────────────────────────────────────────────
  static const _bg        = Color(0xFF0B0F19);
  static const _headerBg  = Color(0xFF141A2B);
  static const _cardBg    = Color(0xFF141A2B);
  static const _surfaceBg = Color(0xFF1E2535);
  static const _border    = Color(0xFF2B3347);
  static const _indigo    = Color(0xFF6366F1);
  static const _emerald   = Color(0xFF10B981);

  // ── Life-cycle ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _disposeEntries();
    super.dispose();
  }

  void _disposeEntries() {
    _entriesByDate?.values.forEach((list) {
      for (final e in list) e.dispose();
    });
  }

  // ── File picking ─────────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    try {
      // Uses dart:html on web, file_picker on native — no LateInitializationError
      final picked = await pickFileBytes();
      if (picked == null) return;

      final (bytes, name) = picked;

      // Validate extension
      final lower = name.toLowerCase();
      if (!lower.endsWith('.xlsx') && !lower.endsWith('.xls') && !lower.endsWith('.csv')) {
        _showErrorDialog('Unsupported file', 'Please select a .xlsx, .xls or .csv file.\n\nSelected: $name');
        return;
      }

      await _processFile(bytes, name);
    } catch (e, st) {
      _showErrorDialog('File picker error', '$e\n\n$st');
    }
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF141A2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Text(message, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF6366F1))),
          ),
        ],
      ),
    );
  }

  Future<void> _processFile(Uint8List bytes, String filename) async {
    setState(() { _loading = true; _loadingText = 'Reading file…'; });

    // Yield two frames so the loading indicator actually renders before we block
    await Future.delayed(const Duration(milliseconds: 80));

    try {
      // Parse on a microtask so the loader is visible first.
      // compute() is used on native for true parallelism; on web it falls back
      // to a Future so the event loop can at least paint one frame.
      late List<_EntryData> dataList;
      try {
        dataList = await compute(
          _parseFileBackground,
          _ParseInput(bytes: bytes, filename: filename),
        );
      } catch (_) {
        // compute() not supported on web — run synchronously after a frame delay
        dataList = await Future(
          () => _parseFileBackground(_ParseInput(bytes: bytes, filename: filename)),
        );
      }

      if (dataList.isEmpty) {
        setState(() => _loading = false);
        _showAlert('No valid rows found. Check column headers: Date, Amount/Debit, Remarks/Tags.');
        return;
      }

      // Convert plain _EntryData → _ImportEntry (with controllers) on main thread
      final entries = dataList.map((d) => _ImportEntry(
        entryId:    d.entryId,
        date:       d.date,
        tag:        d.tag,
        category:   d.category,
        amount:     d.amount,
        isIncoming: d.isIncoming,
        txDetails:  d.txDetails,
        remarks:    d.remarks,
      )).toList();

      final grouped = _groupByDate(entries);
      _disposeEntries();

      setState(() {
        _entriesByDate = grouped;
        _fileName      = filename;
        _savedDates.clear();
        _failedDates.clear();
        _checkedDates.clear();
        _loading = false;
        final dates = _sortedDates;
        _selectedDate = dates.isNotEmpty ? dates.first : '';
      });
    } catch (e, st) {
      setState(() => _loading = false);
      _showErrorDialog('Error reading file', '$e\n\n$st');
    }
  }

  // ── Excel parsing ─────────────────────────────────────────────────────────────

  List<_ImportEntry> _parseExcel(Uint8List bytes, String filename) {
    final excel = xl.Excel.decodeBytes(bytes);
    final all = <_ImportEntry>[];
    int counter = 0;

    for (final sheetName in excel.tables.keys) {
      final sheet = excel.tables[sheetName];
      if (sheet == null || sheet.rows.isEmpty) continue;

      // Build headers from first row
      final headerRow = sheet.rows.first;
      final headers = headerRow.map((cell) => _cellStr(cell?.value)).toList();
      if (headers.every((h) => h.isEmpty)) continue;

      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final rowMap = <String, dynamic>{};
        for (var j = 0; j < headers.length && j < row.length; j++) {
          if (headers[j].isNotEmpty) rowMap[headers[j]] = row[j]?.value;
        }

        final tag = _getColValue(rowMap, ['Tags', 'Tag', 'Category Label']);
        if (tag.toLowerCase().trim() == 'self') continue;

        final dateObj = _parseDate(_getColValue(rowMap, ['Date', 'Transaction Date', 'Txn Date', 'Entry Date']));
        if (dateObj == null) continue;

        final amtDetails = _resolveAmount(rowMap);
        if (amtDetails == null || amtDetails.$1 <= 0) continue;

        final txDetails = _getColValue(rowMap, ['Transaction Details', 'Transaction Description', 'Narration', 'Description', 'Details', 'Txn Details']);
        final remarks   = _getColValue(rowMap, ['Remarks', 'Remark']);
        final description = txDetails.isNotEmpty ? txDetails : (remarks.isNotEmpty ? remarks : tag.isNotEmpty ? tag : 'Imported');
        final remarkText  = remarks.isNotEmpty ? remarks : (txDetails.isNotEmpty ? txDetails : tag.isNotEmpty ? tag : 'Imported');

        all.add(_ImportEntry(
          entryId: '${sheetName}_${counter++}',
          date: _formatDate(dateObj),
          tag: tag,
          category: '',
          amount: amtDetails.$1,
          isIncoming: amtDetails.$2,
          txDetails: description,
          remarks: '${remarkText.isNotEmpty ? remarkText : "Imported"}-${_fmtAmt(amtDetails.$1)}',
        ));
      }
    }
    return all;
  }

  // ── CSV parsing ───────────────────────────────────────────────────────────────

  List<_ImportEntry> _parseCsv(Uint8List bytes, String filename) {
    final content = String.fromCharCodes(bytes);
    final lines = content.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.length < 2) return [];

    final headers = _splitCsvLine(lines[0]);
    final all = <_ImportEntry>[];
    int counter = 0;

    for (var i = 1; i < lines.length; i++) {
      final cols = _splitCsvLine(lines[i]);
      final rowMap = <String, String>{};
      for (var j = 0; j < headers.length && j < cols.length; j++) {
        if (headers[j].isNotEmpty) rowMap[headers[j]] = cols[j];
      }

      final tag = _getColValue(rowMap, ['Tags', 'Tag', 'Category Label']);
      if (tag.toLowerCase().trim() == 'self') continue;

      final dateObj = _parseDate(_getColValue(rowMap, ['Date', 'Transaction Date', 'Txn Date', 'Entry Date']));
      if (dateObj == null) continue;

      final amtDetails = _resolveAmount(rowMap);
      if (amtDetails == null || amtDetails.$1 <= 0) continue;

      final txDetails = _getColValue(rowMap, ['Transaction Details', 'Transaction Description', 'Narration', 'Description', 'Details']);
      final remarks   = _getColValue(rowMap, ['Remarks', 'Remark']);
      final description = txDetails.isNotEmpty ? txDetails : (remarks.isNotEmpty ? remarks : tag.isNotEmpty ? tag : 'Imported');
      final remarkText  = remarks.isNotEmpty ? remarks : (txDetails.isNotEmpty ? txDetails : tag.isNotEmpty ? tag : 'Imported');

      all.add(_ImportEntry(
        entryId: 'csv_${counter++}',
        date: _formatDate(dateObj),
        tag: tag,
        category: '',
        amount: amtDetails.$1,
        isIncoming: amtDetails.$2,
        txDetails: description,
        remarks: '${remarkText.isNotEmpty ? remarkText : "Imported"}-${_fmtAmt(amtDetails.$1)}',
      ));
    }
    return all;
  }

  List<String> _splitCsvLine(String line) {
    final result = <String>[];
    var inQuotes = false;
    var current = StringBuffer();
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        result.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(ch);
      }
    }
    result.add(current.toString().trim());
    return result;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _cellStr(dynamic value) {
    if (value == null) return '';
    // Handle excel package CellValue types
    final typeName = value.runtimeType.toString();
    if (typeName.contains('Date')) {
      try {
        // Try to extract year/month/day via reflection-like toString
        final str = value.toString();
        // DateCellValue toString might be "DateCellValue(year: 2026, month: 8, day: 13)"
        // or might just be the date string
        return str;
      } catch (_) {
        return value.toString();
      }
    }
    return value.toString();
  }

  String _getColValue(Map<String, dynamic> row, List<String> aliases) {
    final norm = aliases.map((a) => a.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')).toList();
    for (final key in row.keys) {
      final normKey = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (norm.contains(normKey)) {
        final v = row[key];
        return v?.toString().trim() ?? '';
      }
    }
    // partial match
    for (final key in row.keys) {
      final normKey = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      for (final alias in norm) {
        if (normKey.contains(alias) || alias.contains(normKey)) {
          final v = row[key];
          final s = v?.toString().trim() ?? '';
          if (s.isNotEmpty) return s;
        }
      }
    }
    return '';
  }

  /// Returns (amount, isIncoming) or null if no amount found.
  (double, bool)? _resolveAmount(Map<String, dynamic> row) {
    final debitAliases  = ['Debit', 'Debit Amount', 'Withdrawal', 'Dr', 'Paid Out'];
    final creditAliases = ['Credit', 'Credit Amount', 'Deposit', 'Cr', 'Paid In', 'Received', 'Incoming'];
    final genericAliases = ['Amount', 'Txn Amount', 'Transaction Amount', 'Amt', 'Value'];

    final debit = _parseAmt(_getColValue(row, debitAliases));
    if (debit != null && debit > 0) return (debit, false);

    final generic = _parseAmt(_getColValue(row, genericAliases));
    if (generic != null && generic != 0) return (generic.abs(), generic < 0);

    final credit = _parseAmt(_getColValue(row, creditAliases));
    if (credit != null && credit > 0) return (credit, true);

    return null;
  }

  double? _parseAmt(String s) {
    if (s.isEmpty) return null;
    final cleaned = s.replaceAll(',', '').replaceAll(RegExp(r'[^\d.\-]'), '');
    return double.tryParse(cleaned);
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    final typeName = raw.runtimeType.toString();

    // Handle excel DateCellValue / DateTimeCellValue
    if (typeName.contains('DateTime') || typeName.contains('DateCell') || typeName.contains('DateTimeCell')) {
      try {
        // Try to parse from toString like "2026-08-13 00:00:00.000"
        final str = raw.toString();
        final cleaned = str.replaceAll(RegExp(r'[A-Za-z(){}]'), '').trim();
        final parts = cleaned.split(RegExp(r'[-/\s:]'));
        if (parts.length >= 3) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final d = int.tryParse(parts[2]);
          if (y != null && m != null && d != null && y > 1900) {
            return DateTime(y, m, d);
          }
        }
      } catch (_) {}
    }

    // Handle numeric (Excel serial date)
    if (raw is num && raw > 1000 && raw < 100000) {
      // Excel serial date: days since Dec 30, 1899
      return DateTime(1899, 12, 30).add(Duration(days: raw.round()));
    }

    final str = raw.toString().trim();
    if (str.isEmpty) return null;

    // Try DD/MM/YYYY or DD-MM-YYYY
    var m = RegExp(r'^(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})$').firstMatch(str);
    if (m != null) {
      return DateTime(int.parse(m.group(3)!), int.parse(m.group(2)!), int.parse(m.group(1)!));
    }
    // Try YYYY-MM-DD
    m = RegExp(r'^(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})').firstMatch(str);
    if (m != null) {
      return DateTime(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
    }
    // Try DD/MMM/YYYY (already in app format)
    m = RegExp(r'^(\d{2})/([A-Za-z]{3})/(\d{4})$').firstMatch(str);
    if (m != null) {
      const mo = {'Jan':1,'Feb':2,'Mar':3,'Apr':4,'May':5,'Jun':6,'Jul':7,'Aug':8,'Sep':9,'Oct':10,'Nov':11,'Dec':12};
      final month = mo[m.group(2)] ?? 0;
      if (month > 0) return DateTime(int.parse(m.group(3)!), month, int.parse(m.group(1)!));
    }

    return null;
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day.toString().padLeft(2,'0')}/${months[d.month-1]}/${d.year}';
  }

  String _fmtAmt(double n) {
    return n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '');
  }

  Map<String, List<_ImportEntry>> _groupByDate(List<_ImportEntry> entries) {
    final map = <String, List<_ImportEntry>>{};
    for (final e in entries) {
      map.putIfAbsent(e.date, () => []).add(e);
    }
    return map;
  }

  List<String> get _sortedDates {
    final dates = (_entriesByDate?.keys ?? []).toList();
    dates.sort((a, b) => _parseAppDate(a).compareTo(_parseAppDate(b)));
    return dates;
  }

  DateTime _parseAppDate(String label) {
    const mo = {'Jan':1,'Feb':2,'Mar':3,'Apr':4,'May':5,'Jun':6,'Jul':7,'Aug':8,'Sep':9,'Oct':10,'Nov':11,'Dec':12};
    final m = RegExp(r'^(\d{2})/([A-Za-z]{3})/(\d{4})$').firstMatch(label);
    if (m == null) return DateTime(1970);
    return DateTime(int.parse(m.group(3)!), mo[m.group(2)] ?? 1, int.parse(m.group(1)!));
  }

  String _dayName(String dateLabel) {
    const days = ['SUN','MON','TUE','WED','THU','FRI','SAT'];
    final d = _parseAppDate(dateLabel);
    return days[d.weekday % 7];
  }

  bool _isSunday(String dateLabel) => _parseAppDate(dateLabel).weekday % 7 == 0;

  double _dateTotal(String dateLabel) {
    return (_entriesByDate?[dateLabel] ?? []).fold(0, (s, e) => s + e.amount);
  }

  double get _grandTotal {
    return (_entriesByDate?.values ?? []).fold(0, (s, list) => s + list.fold(0, (ls, e) => ls + e.amount));
  }

  bool _isIncoming(_ImportEntry e) {
    if (e.isIncoming) return true;
    final text = '${e.tag} ${e.remarksCtrl.text}'.toLowerCase();
    return _kIncomingTokens.any((t) => text.contains(t));
  }

  bool _isCtt(_ImportEntry e) => RegExp(r'\bctt\b', caseSensitive: false).hasMatch('${e.tag} ${e.remarksCtrl.text}');

  // ── Data mutations ────────────────────────────────────────────────────────────

  void _resetImport() {
    _disposeEntries();
    setState(() {
      _entriesByDate = null;
      _selectedDate = '';
      _fileName = '';
      _savedDates.clear();
      _failedDates.clear();
      _checkedDates.clear();
    });
  }

  void _removeIncoming() {
    if (_entriesByDate == null) return;
    int removed = 0;
    final toDelete = <String>[];

    _entriesByDate!.forEach((date, list) {
      final kept = list.where((e) => !_isIncoming(e) && !_isCtt(e)).toList();
      removed += list.length - kept.length;
      // dispose removed entries
      for (final e in list) {
        if (!kept.contains(e)) e.dispose();
      }
      if (kept.isEmpty) {
        toDelete.add(date);
      } else {
        _entriesByDate![date] = kept;
      }
    });

    for (final d in toDelete) _entriesByDate!.remove(d);

    setState(() {
      if (_selectedDate.isNotEmpty && !(_entriesByDate?.containsKey(_selectedDate) ?? false)) {
        _selectedDate = _sortedDates.isNotEmpty ? _sortedDates.first : '';
      }
    });
    _showAlert('Removed $removed incoming/CTT transaction(s).');
  }

  void _clubSameCategoryForDate(String dateLabel) {
    final rows = _entriesByDate?[dateLabel];
    if (rows == null) return;

    final grouped = <String, List<_ImportEntry>>{};
    for (final row in rows) {
      final cat = row.category.trim().toLowerCase();
      if (cat.isEmpty || cat == 'select') continue;
      grouped.putIfAbsent(cat, () => []).add(row);
    }

    final merged = <_ImportEntry>[];
    final seenCats = <String>{};
    int removedCount = 0;

    for (final row in rows) {
      final cat = row.category.trim().toLowerCase();
      if (cat.isEmpty || cat == 'select') {
        merged.add(row);
        continue;
      }
      if (seenCats.contains(cat)) continue;
      seenCats.add(cat);
      final members = grouped[cat]!;
      if (members.length == 1) {
        merged.add(members.first);
        continue;
      }
      removedCount += members.length - 1;
      final total = members.fold<double>(0, (s, e) => s + e.amount);
      final base = members.first;
      final txParts = members.map((e) => e.txDetailsCtrl.text.trim()).where((s) => s.isNotEmpty).toSet().join(', ');
      final remarkParts = members.map((e) => e.remarksCtrl.text.trim()).where((s) => s.isNotEmpty).toSet().join(', ');

      base.amount = double.parse(total.toStringAsFixed(2));
      base.amountCtrl.text = base.amount.toStringAsFixed(2);
      base.txDetailsCtrl.text = txParts;
      base.remarksCtrl.text = remarkParts;

      for (final m in members.skip(1)) m.dispose();
      merged.add(base);
    }

    _entriesByDate![dateLabel] = merged;
    setState(() {});
    if (removedCount > 0) _showAlert('Merged $removedCount duplicate(s) under same category.');
  }

  void _addManualRow() {
    if (_selectedDate.isEmpty) {
      _showAlert('Select a date first.');
      return;
    }
    _entriesByDate ??= {};
    _entriesByDate![_selectedDate] ??= [];
    _entriesByDate![_selectedDate]!.add(_ImportEntry(
      entryId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      date: _selectedDate,
      tag: 'Manual',
      category: '',
      amount: 0,
      isIncoming: false,
      txDetails: '',
      remarks: '',
    ));
    setState(() {});
  }

  void _deleteEntry(String dateLabel, _ImportEntry entry) {
    final list = _entriesByDate?[dateLabel];
    if (list == null) return;
    list.remove(entry);
    entry.dispose();
    if (list.isEmpty) {
      _entriesByDate!.remove(dateLabel);
      _checkedDates.remove(dateLabel);
    }
    setState(() {
      if (_selectedDate == dateLabel && !(_entriesByDate?.containsKey(dateLabel) ?? false)) {
        _selectedDate = _sortedDates.isNotEmpty ? _sortedDates.first : '';
      }
    });
  }

  void _splitEntry(String dateLabel, _ImportEntry entry) {
    if (entry.amount <= 0) {
      _showAlert('Amount must be > 0 to split.');
      return;
    }
    final list = _entriesByDate?[dateLabel];
    if (list == null) return;
    final idx = list.indexOf(entry);
    final half1 = double.parse((entry.amount / 2).toStringAsFixed(2));
    final half2 = double.parse((entry.amount - half1).toStringAsFixed(2));
    entry.amount = half1;
    entry.amountCtrl.text = half1.toStringAsFixed(2);
    final clone = _ImportEntry(
      entryId: 'split_${DateTime.now().millisecondsSinceEpoch}',
      date: entry.date,
      tag: entry.tag,
      category: entry.category,
      amount: half2,
      isIncoming: entry.isIncoming,
      txDetails: entry.txDetailsCtrl.text,
      remarks: entry.remarksCtrl.text,
    );
    list.insert(idx + 1, clone);
    setState(() {});
  }

  void _duplicateEntry(String dateLabel, _ImportEntry entry) {
    final list = _entriesByDate?[dateLabel];
    if (list == null) return;
    final idx = list.indexOf(entry);
    final clone = _ImportEntry(
      entryId: 'dup_${DateTime.now().millisecondsSinceEpoch}',
      date: entry.date,
      tag: entry.tag,
      category: entry.category,
      amount: entry.amount,
      isIncoming: entry.isIncoming,
      txDetails: entry.txDetailsCtrl.text,
      remarks: entry.remarksCtrl.text,
    );
    list.insert(idx + 1, clone);
    setState(() {});
  }

  void _applyDateCategory(String dateLabel, String category) {
    final list = _entriesByDate?[dateLabel];
    if (list == null || category.isEmpty) return;
    for (final e in list) e.category = category;
    _clubSameCategoryForDate(dateLabel);
  }

  // ── Save ─────────────────────────────────────────────────────────────────────

  bool _validateDate(String dateLabel) {
    final list = _entriesByDate?[dateLabel] ?? [];
    for (final e in list) {
      if (e.category.trim().isEmpty) return false;
      if (e.amount <= 0) return false;
    }
    return list.isNotEmpty;
  }

  List<CashewRecord> _buildPayload(String dateLabel) {
    final list = _entriesByDate?[dateLabel] ?? [];
    final catMap = <String, _Bucket>{};
    for (final e in list) {
      final cat = e.category.trim();
      if (cat.isEmpty || e.amount <= 0) continue;
      catMap.putIfAbsent(cat, () => _Bucket(date: dateLabel, category: cat));
      catMap[cat]!.amount += e.amount;
      final desc = e.remarksCtrl.text.trim();
      if (desc.isNotEmpty) catMap[cat]!.descs.add(desc);
    }
    return catMap.values.map((b) => CashewRecord(
      date: dateLabel,
      category: b.category,
      description: b.descs.toSet().join(', '),
      amount: double.parse(b.amount.toStringAsFixed(2)),
      status: 'completed',
    )).toList();
  }

  Future<void> _saveDate(String dateLabel) async {
    if (!_validateDate(dateLabel)) {
      _showAlert('Set a valid category and amount for all rows in $dateLabel');
      return;
    }
    final records = _buildPayload(dateLabel);
    if (records.isEmpty) return;

    setState(() { _loading = true; _loadingText = 'Saving $dateLabel…'; });
    try {
      await ApiService.saveCashewRecordsForDate(date: dateLabel, records: records, status: 'completed');
      _savedDates.add(dateLabel);
      _failedDates.remove(dateLabel);
      setState(() => _loading = false);
      _showAlert('Saved ${records.length} record(s) for $dateLabel ✓');
    } catch (e) {
      _failedDates.add(dateLabel);
      setState(() => _loading = false);
      _showAlert('Error saving $dateLabel: $e');
    }
  }

  Future<void> _saveCheckedDates() async {
    final dates = _sortedDates.where((d) => _checkedDates.contains(d)).toList();
    if (dates.isEmpty) { _showAlert('Check at least one date to save.'); return; }
    for (final d in dates) {
      if (!_validateDate(d)) { _showAlert('Fix all rows for $d before saving.'); return; }
    }

    setState(() { _loading = true; _loadingText = 'Saving checked dates…'; });
    int saved = 0;
    for (final d in dates) {
      setState(() => _loadingText = 'Saving $d… ($saved/${dates.length})');
      try {
        final records = _buildPayload(d);
        if (records.isEmpty) continue;
        await ApiService.saveCashewRecordsForDate(date: d, records: records, status: 'completed');
        _savedDates.add(d);
        _failedDates.remove(d);
        saved++;
      } catch (e) {
        _failedDates.add(d);
      }
    }
    setState(() => _loading = false);
    _showAlert('Saved $saved/${dates.length} checked date(s) ✓');
  }

  Future<void> _saveAllDates() async {
    final dates = _sortedDates;
    if (dates.isEmpty) { _showAlert('No data to save.'); return; }
    for (final d in dates) {
      if (!_validateDate(d)) { _showAlert('Fix all rows for $d before saving all.'); return; }
    }

    setState(() { _loading = true; _loadingText = 'Saving all dates…'; });
    int saved = 0;
    for (final d in dates) {
      setState(() => _loadingText = 'Saving $d… ($saved/${dates.length})');
      try {
        final records = _buildPayload(d);
        if (records.isEmpty) continue;
        await ApiService.saveCashewRecordsForDate(date: d, records: records, status: 'completed');
        _savedDates.add(d);
        _failedDates.remove(d);
        saved++;
      } catch (e) {
        _failedDates.add(d);
      }
    }
    setState(() => _loading = false);
    _showAlert('Saved $saved/${dates.length} date(s) ✓');
  }

  void _showAlert(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFF1E2535),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _entriesByDate == null ? _buildUploadSection() : _buildPreviewSection(),
              ),
            ],
          ),
          if (_loading) _buildLoader(),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: _headerBg,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.upload_file_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cashew Import',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
              Text('Import Excel / CSV',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ],
          ),
          const Spacer(),
          _navBtn(Icons.home_rounded,
              () => Navigator.popUntil(context, ModalRoute.withName('/'))),
          const SizedBox(width: 6),
          _navBtn(Icons.arrow_back_rounded, () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 34, height: 34,
      child: IconButton(
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: _surfaceBg,
          foregroundColor: const Color(0xFF9CA3AF),
          side: const BorderSide(color: _border),
          shape: const CircleBorder(),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 16),
      ),
    );
  }

  // ── Upload Section ────────────────────────────────────────────────────────────

  Widget _buildUploadSection() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF121635), Color(0xFF10182D), Color(0xFF26142D)],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                // Hero
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 16),
                const Text('Import Transactions',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 26)),
                const SizedBox(height: 8),
                const Text(
                  'Upload your bank statement or expense file.\nWe\'ll parse and group it by date for easy editing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 28),
                // Drop zone / pick button
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0x4D6366F1), width: 2),
                      color: const Color(0x086366F1),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0x336366F1),
                            border: Border.all(color: const Color(0x406366F1)),
                          ),
                          child: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF818CF8), size: 30),
                        ),
                        const SizedBox(height: 16),
                        const Text('Click to pick your file',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 4),
                        const Text('Bank statements and expense spreadsheets',
                            style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _fmtBadge('.xlsx', const Color(0xFF818CF8), const Color(0x1F6366F1)),
                            const SizedBox(width: 8),
                            _fmtBadge('.xls',  const Color(0xFFC084FC), const Color(0x1F8B5CF6)),
                            const SizedBox(width: 8),
                            _fmtBadge('.csv',  const Color(0xFF5EEAD4), const Color(0x1F14B8A6)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Expected columns card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0x99141A2B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x14FFFFFF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.table_chart_outlined, color: Color(0xFFFBBF24), size: 16),
                          SizedBox(width: 8),
                          Text('EXPECTED COLUMNS',
                              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _colHint(Icons.calendar_today_outlined, const Color(0xFF818CF8), 'Date', 'Transaction date'),
                      const SizedBox(height: 8),
                      _colHint(Icons.currency_rupee_rounded, const Color(0xFF34D399), 'Amount / Debit', 'Debit amount'),
                      const SizedBox(height: 8),
                      _colHint(Icons.notes_rounded, const Color(0xFFF472B6), 'Remarks', 'Description / Narration'),
                      const SizedBox(height: 8),
                      _colHint(Icons.label_outline_rounded, const Color(0xFFFBBF24), 'Tags', 'Self / Self Transfer skipped'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fmtBadge(String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withAlpha(80)),
      ),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _colHint(IconData icon, Color color, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        const SizedBox(width: 6),
        Text('— $subtitle', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
      ],
    );
  }

  // ── Preview Section ───────────────────────────────────────────────────────────

  Widget _buildPreviewSection() {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: LayoutBuilder(builder: (ctx, c) {
            if (c.maxWidth < 700) return _buildMobilePreview();
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateSidebar(),
                const SizedBox(width: 12),
                Expanded(child: _buildTransactionArea()),
              ],
            );
          }),
        ),
      ],
    );
  }

  // ── Toolbar ───────────────────────────────────────────────────────────────────

  Widget _buildToolbar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // File icon + name
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: const Color(0x1A6366F1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x336366F1)),
              ),
              child: const Icon(Icons.file_present_rounded, color: Color(0xFF818CF8), size: 16),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(_fileName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            _toolBtn('New File', Icons.refresh_rounded, const Color(0xFF9CA3AF), onTap: _resetImport),
            _vDivider(),
            _toolBtn('Club', Icons.layers_rounded, const Color(0xFFFDE68A),
                onTap: () => _clubSameCategoryForDate(_selectedDate)),
            _toolBtn('Filter', Icons.filter_alt_outlined, const Color(0xFFFCA5A5),
                onTap: _removeIncoming),
            _toolBtn('Add Row', Icons.add_rounded, const Color(0xFF7DD3FC),
                onTap: _addManualRow),
            _vDivider(),
            _toolBtn('Save Date', Icons.event_available_outlined, const Color(0xFFC4B5FD),
                onTap: () => _saveDate(_selectedDate)),
            _toolBtn('Save Checked', Icons.check_box_outlined, const Color(0xFFC4B5FD),
                onTap: _saveCheckedDates,
                badge: _checkedDates.isEmpty ? null : '${_checkedDates.length}'),
            _toolBtn('Save All', Icons.save_rounded, const Color(0xFF6EE7B7),
                onTap: _saveAllDates),
          ],
        ),
      ),
    );
  }

  Widget _toolBtn(String label, IconData icon, Color color, {VoidCallback? onTap, String? badge}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
              if (badge != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0x406366F1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0x606366F1)),
                  ),
                  child: Text(badge, style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 1, height: 20, margin: const EdgeInsets.symmetric(horizontal: 6),
    color: const Color(0x33FFFFFF),
  );

  // ── Date Sidebar ──────────────────────────────────────────────────────────────

  Widget _buildDateSidebar() {
    final dates = _sortedDates;
    return Container(
      width: 220,
      margin: const EdgeInsets.fromLTRB(12, 12, 0, 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0x0F6366F1),
              border: Border(bottom: BorderSide(color: _border)),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Text('DATES',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const Spacer(),
                Text('${dates.length} dates',
                    style: const TextStyle(color: Color(0xFF818CF8), fontSize: 10, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          // Date list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: dates.length,
              itemBuilder: (_, i) => _buildDateItem(dates[i]),
            ),
          ),
          // Grand total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0x33000000),
              border: Border(top: BorderSide(color: _border)),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Text('TOTAL',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const Spacer(),
                Text('₹${_grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(color: Color(0xFF34D399), fontSize: 14, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateItem(String dateLabel) {
    final isSelected = _selectedDate == dateLabel;
    final isSaved   = _savedDates.contains(dateLabel);
    final isFailed  = _failedDates.contains(dateLabel);
    final isSunday  = _isSunday(dateLabel);
    final isChecked = _checkedDates.contains(dateLabel);
    final total     = _dateTotal(dateLabel);
    final count     = _entriesByDate?[dateLabel]?.length ?? 0;
    final day       = _dayName(dateLabel);

    Color itemBg = Colors.transparent;
    Color borderC = Colors.transparent;
    Color dateColor = const Color(0xFFE2E8F0);
    Color amtColor = const Color(0xFF34D399);

    if (isSelected) { itemBg = const Color(0x1A6366F1); borderC = const Color(0x806366F1); dateColor = const Color(0xFFC7D2FE); }
    else if (isFailed) { itemBg = const Color(0x14F87171); borderC = const Color(0x66F87171); dateColor = const Color(0xFFFCA5A5); amtColor = const Color(0xFFFCA5A5); }
    else if (isSaved)  { itemBg = const Color(0x1410B981); borderC = const Color(0x6610B981); dateColor = const Color(0xFF6EE7B7); amtColor = const Color(0xFF6EE7B7); }
    else if (isSunday) { itemBg = const Color(0x14EF4444); borderC = const Color(0x66EF4444); dateColor = const Color(0xFFFCA5A5); amtColor = const Color(0xFFFCA5A5); }

    return GestureDetector(
      onTap: () => setState(() => _selectedDate = dateLabel),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: itemBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderC),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: isChecked,
              onChanged: (v) => setState(() {
                if (v == true) _checkedDates.add(dateLabel);
                else _checkedDates.remove(dateLabel);
              }),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              activeColor: _indigo,
              side: const BorderSide(color: Color(0xFF4B5563)),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isFailed) const Icon(Icons.error_outline_rounded, color: Color(0xFFFCA5A5), size: 10)
                      else if (isSaved) const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF34D399), size: 10)
                      else if (isSunday) const Icon(Icons.circle, color: Color(0xFFF87171), size: 8),
                      if (isFailed || isSaved || isSunday) const SizedBox(width: 4),
                      Flexible(
                        child: Text(dateLabel,
                            style: TextStyle(color: dateColor, fontSize: 10, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(day, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 9, fontWeight: FontWeight.w700)),
                      const Text(' · ', style: TextStyle(color: Color(0xFF4B5563), fontSize: 9)),
                      Text('$count rows', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
            Text('₹${total.toStringAsFixed(0)}',
                style: TextStyle(color: amtColor, fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }

  // ── Transaction Area ──────────────────────────────────────────────────────────

  Widget _buildTransactionArea() {
    final entries = _entriesByDate?[_selectedDate] ?? [];
    final total = entries.fold<double>(0, (s, e) => s + e.amount);

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // Date bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0x146366F1), Color(0x0A8B5CF6)]),
              border: Border(bottom: BorderSide(color: _border)),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, color: Color(0xFF818CF8), size: 14),
                const SizedBox(width: 8),
                Text(_selectedDate.isNotEmpty ? '$_selectedDate ${_dayName(_selectedDate)}' : '—',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                if (_savedDates.contains(_selectedDate)) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0x1A10B981),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0x5910B981)),
                    ),
                    child: const Text('✓ Saved', style: TextStyle(color: Color(0xFF34D399), fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                ],
                if (_isSunday(_selectedDate) && _selectedDate.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0x14EF4444),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0x59EF4444)),
                    ),
                    child: const Text('Sunday', style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                ],
                const Spacer(),
                // Apply category dropdown
                _buildApplyCategoryDropdown(),
                const SizedBox(width: 12),
                Text('${entries.length} rows',
                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                const SizedBox(width: 10),
                Text('₹${total.toStringAsFixed(2)}',
                    style: const TextStyle(color: Color(0xFF34D399), fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
              ],
            ),
          ),
          // Entries
          Expanded(
            child: entries.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined, color: Color(0xFF374151), size: 40),
                        SizedBox(height: 8),
                        Text('No data for this date', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: entries.length,
                    itemBuilder: (_, i) => _buildEntryRow(entries[i], i),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyCategoryDropdown() {
    return DropdownButton<String>(
      hint: const Text('Apply Cat.', style: TextStyle(color: Color(0xFF6B7280), fontSize: 10)),
      value: null,
      dropdownColor: const Color(0xFF1E2535),
      style: const TextStyle(color: Colors.white, fontSize: 11),
      underline: const SizedBox(),
      items: _kCategories.map((c) => DropdownMenuItem(
        value: c,
        child: Text(c, style: const TextStyle(fontSize: 11)),
      )).toList(),
      onChanged: (v) { if (v != null) _applyDateCategory(_selectedDate, v); },
    );
  }

  Widget _buildEntryRow(_ImportEntry entry, int idx) {
    final rowColors = [
      const Color(0xFF7DD3FC),
      const Color(0xFFC4B5FD),
      const Color(0xFFF9A8D4),
      const Color(0xFF5EEAD4),
      const Color(0xFFFED7AA),
      const Color(0xFFBEF264),
      const Color(0xFFFCA5A5),
      const Color(0xFFFDE68A),
    ];
    final txColor = rowColors[idx % rowColors.length];
    final rowBg = idx % 2 == 0 ? const Color(0x0F6366F1) : const Color(0x0A0F172A);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Category
              Expanded(
                flex: 3,
                child: _fieldCol(
                  label: 'CATEGORY',
                  child: DropdownButtonFormField<String>(
                    value: _kCategories.contains(entry.category) ? entry.category : null,
                    decoration: _dropDecoration(),
                    dropdownColor: const Color(0xFF1E2535),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    hint: const Text('Select', style: TextStyle(color: Color(0xFF4B5563), fontSize: 12)),
                    iconEnabledColor: const Color(0xFF6B7280),
                    isExpanded: true,
                    items: _kCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => entry.category = v ?? ''),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Transaction Details
              Expanded(
                flex: 4,
                child: _fieldCol(
                  label: 'TRANSACTION DETAILS',
                  child: TextField(
                    controller: entry.txDetailsCtrl,
                    style: TextStyle(color: txColor, fontSize: 12, fontWeight: FontWeight.w600),
                    decoration: _inputDecoration(
                      hint: 'Details…',
                      fillColor: txColor.withAlpha(28),
                      borderColor: txColor.withAlpha(100),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Amount
              Expanded(
                flex: 2,
                child: _fieldCol(
                  label: 'AMOUNT (₹)',
                  child: TextField(
                    controller: entry.amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 12, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
                    decoration: _inputDecoration(
                      hint: '0.00',
                      fillColor: const Color(0x1F064E3B),
                      borderColor: const Color(0x8010B981),
                    ),
                    onChanged: (v) => entry.amount = double.tryParse(v) ?? entry.amount,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Action buttons
              Column(
                children: [
                  _rowActionBtn(Icons.copy_rounded, const Color(0xFFFDE68A), const Color(0x33F59E0B),
                      () => _duplicateEntry(_selectedDate, entry)),
                  const SizedBox(height: 4),
                  _rowActionBtn(Icons.call_split_rounded, const Color(0xFF7DD3FC), const Color(0x330EA5E9),
                      () => _splitEntry(_selectedDate, entry)),
                  const SizedBox(height: 4),
                  _rowActionBtn(Icons.delete_outline_rounded, const Color(0xFFF87171), const Color(0x33EF4444),
                      () => _deleteEntry(_selectedDate, entry)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Remarks
          _fieldCol(
            label: 'REMARK — AMOUNT',
            child: TextField(
              controller: entry.remarksCtrl,
              style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 12, fontWeight: FontWeight.w700),
              decoration: _inputDecoration(
                hint: 'e.g. Groceries-850',
                fillColor: const Color(0x1F78350F),
                borderColor: const Color(0x80FACC15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldCol({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  InputDecoration _dropDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      filled: true, fillColor: const Color(0x40000000),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0x33FFFFFF))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0x33FFFFFF))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _indigo)),
    );
  }

  InputDecoration _inputDecoration({String? hint, required Color fillColor, required Color borderColor}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: borderColor.withAlpha(120), fontSize: 11),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      filled: true, fillColor: fillColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor, width: 1.5)),
    );
  }

  Widget _rowActionBtn(IconData icon, Color fg, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: fg.withAlpha(80))),
        child: Icon(icon, color: fg, size: 14),
      ),
    );
  }

  // ── Mobile Preview ────────────────────────────────────────────────────────────

  Widget _buildMobilePreview() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: const [Tab(text: 'Dates'), Tab(text: 'Transactions')],
            labelColor: const Color(0xFF818CF8),
            unselectedLabelColor: const Color(0xFF6B7280),
            indicatorColor: _indigo,
          ),
          Expanded(
            child: TabBarView(children: [
              _buildDateSidebar(),
              _buildTransactionArea(),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Loader ────────────────────────────────────────────────────────────────────

  Widget _buildLoader() {
    return Container(
      color: const Color(0xBF030305),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: _emerald, strokeWidth: 3),
              const SizedBox(height: 16),
              Text(_loadingText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Import Entry ─────────────────────────────────────────────────────────────

class _ImportEntry {
  final String entryId;
  String date;
  String tag;
  String category;
  double amount;
  bool isIncoming;
  final TextEditingController txDetailsCtrl;
  final TextEditingController amountCtrl;
  final TextEditingController remarksCtrl;

  _ImportEntry({
    required this.entryId,
    required this.date,
    required this.tag,
    required this.category,
    required this.amount,
    required this.isIncoming,
    String txDetails = '',
    String remarks = '',
  })  : txDetailsCtrl = TextEditingController(text: txDetails),
        amountCtrl = TextEditingController(text: amount > 0 ? amount.toStringAsFixed(2) : ''),
        remarksCtrl = TextEditingController(text: remarks);

  void dispose() {
    txDetailsCtrl.dispose();
    amountCtrl.dispose();
    remarksCtrl.dispose();
  }
}

// ─── Save Bucket ─────────────────────────────────────────────────────────────

class _Bucket {
  final String date;
  final String category;
  double amount = 0;
  final List<String> descs = [];
  _Bucket({required this.date, required this.category});
}

// ─── Background parse helpers ─────────────────────────────────────────────────

class _ParseInput {
  final Uint8List bytes;
  final String filename;
  const _ParseInput({required this.bytes, required this.filename});
}

/// Plain data class — safe to pass through isolates (no Flutter objects).
class _EntryData {
  final String entryId, date, tag, category, txDetails, remarks;
  final double amount;
  final bool isIncoming;
  const _EntryData({
    required this.entryId, required this.date, required this.tag,
    required this.category, required this.txDetails, required this.remarks,
    required this.amount, required this.isIncoming,
  });
}

/// Top-level function — runs in a background isolate via compute().
List<_EntryData> _parseFileBackground(_ParseInput input) {
  final bytes    = input.bytes;
  final filename = input.filename;
  return filename.toLowerCase().endsWith('.csv')
      ? _bgParseCsv(bytes)
      : _bgParseExcel(bytes);
}

List<_EntryData> _bgParseExcel(Uint8List bytes) {
  final excel = xl.Excel.decodeBytes(bytes);
  final all   = <_EntryData>[];
  int counter = 0;

  for (final sheetName in excel.tables.keys) {
    final sheet = excel.tables[sheetName];
    if (sheet == null || sheet.rows.isEmpty) continue;

    final headerRow = sheet.rows.first;
    final headers   = headerRow.map((c) => _bgCellStr(c?.value)).toList();
    if (headers.every((h) => h.isEmpty)) continue;

    for (var i = 1; i < sheet.rows.length; i++) {
      final row    = sheet.rows[i];
      final rowMap = <String, dynamic>{};
      for (var j = 0; j < headers.length && j < row.length; j++) {
        if (headers[j].isNotEmpty) rowMap[headers[j]] = row[j]?.value;
      }

      final tag = _bgCol(rowMap, ['Tags', 'Tag', 'Category Label']);
      if (tag.toLowerCase().trim() == 'self') continue;

      final dateObj = _bgParseDate(_bgCol(rowMap, ['Date', 'Transaction Date', 'Txn Date', 'Entry Date']));
      if (dateObj == null) continue;

      final amt = _bgResolveAmount(rowMap);
      if (amt == null || amt.$1 <= 0) continue;

      final tx      = _bgCol(rowMap, ['Transaction Details', 'Transaction Description', 'Narration', 'Description', 'Details', 'Txn Details']);
      final rem     = _bgCol(rowMap, ['Remarks', 'Remark']);
      final desc    = tx.isNotEmpty  ? tx  : (rem.isNotEmpty ? rem  : (tag.isNotEmpty ? tag  : 'Imported'));
      final remBase = rem.isNotEmpty ? rem : (tx.isNotEmpty  ? tx   : (tag.isNotEmpty ? tag  : 'Imported'));

      all.add(_EntryData(
        entryId:    '${sheetName}_${counter++}',
        date:       _bgFmtDate(dateObj),
        tag:        tag,
        category:   '',
        amount:     amt.$1,
        isIncoming: amt.$2,
        txDetails:  desc,
        remarks:    '$remBase-${_bgFmtAmt(amt.$1)}',
      ));
    }
  }
  return all;
}

List<_EntryData> _bgParseCsv(Uint8List bytes) {
  final src   = String.fromCharCodes(bytes);
  final lines = src.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
  if (lines.length < 2) return [];

  final headers = _bgSplitCsv(lines[0]);
  final all     = <_EntryData>[];
  int counter   = 0;

  for (var i = 1; i < lines.length; i++) {
    final cols   = _bgSplitCsv(lines[i]);
    final rowMap = <String, String>{};
    for (var j = 0; j < headers.length && j < cols.length; j++) {
      if (headers[j].isNotEmpty) rowMap[headers[j]] = cols[j];
    }

    final tag = _bgCol(rowMap, ['Tags', 'Tag', 'Category Label']);
    if (tag.toLowerCase().trim() == 'self') continue;

    final dateObj = _bgParseDate(_bgCol(rowMap, ['Date', 'Transaction Date', 'Txn Date', 'Entry Date']));
    if (dateObj == null) continue;

    final amt = _bgResolveAmount(rowMap);
    if (amt == null || amt.$1 <= 0) continue;

    final tx      = _bgCol(rowMap, ['Transaction Details', 'Transaction Description', 'Narration', 'Description', 'Details']);
    final rem     = _bgCol(rowMap, ['Remarks', 'Remark']);
    final desc    = tx.isNotEmpty  ? tx  : (rem.isNotEmpty ? rem  : (tag.isNotEmpty ? tag  : 'Imported'));
    final remBase = rem.isNotEmpty ? rem : (tx.isNotEmpty  ? tx   : (tag.isNotEmpty ? tag  : 'Imported'));

    all.add(_EntryData(
      entryId:    'csv_${counter++}',
      date:       _bgFmtDate(dateObj),
      tag:        tag,
      category:   '',
      amount:     amt.$1,
      isIncoming: amt.$2,
      txDetails:  desc,
      remarks:    '$remBase-${_bgFmtAmt(amt.$1)}',
    ));
  }
  return all;
}

// ── Parsing utilities (top-level, isolate-safe) ───────────────────────────────

String _bgCellStr(dynamic v) {
  if (v == null) return '';
  return v.toString();
}

String _bgCol(Map<String, dynamic> row, List<String> aliases) {
  final norm = aliases.map((a) => a.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')).toList();
  for (final k in row.keys) {
    final nk = k.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (norm.contains(nk)) return row[k]?.toString().trim() ?? '';
  }
  for (final k in row.keys) {
    final nk = k.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    for (final a in norm) {
      if (nk.contains(a) || a.contains(nk)) {
        final s = row[k]?.toString().trim() ?? '';
        if (s.isNotEmpty) return s;
      }
    }
  }
  return '';
}

(double, bool)? _bgResolveAmount(Map<String, dynamic> row) {
  final debit   = _bgAmt(_bgCol(row, ['Debit', 'Debit Amount', 'Withdrawal', 'Dr', 'Paid Out']));
  if (debit != null && debit > 0) return (debit, false);

  final generic = _bgAmt(_bgCol(row, ['Amount', 'Txn Amount', 'Transaction Amount', 'Amt', 'Value']));
  if (generic != null && generic != 0) return (generic.abs(), generic < 0);

  final credit  = _bgAmt(_bgCol(row, ['Credit', 'Credit Amount', 'Deposit', 'Cr', 'Paid In', 'Received', 'Incoming']));
  if (credit != null && credit > 0) return (credit, true);

  return null;
}

double? _bgAmt(String s) {
  if (s.isEmpty) return null;
  return double.tryParse(s.replaceAll(',', '').replaceAll(RegExp(r'[^\d.\-]'), ''));
}

DateTime? _bgParseDate(dynamic raw) {
  if (raw == null) return null;

  // Excel package date types
  final typeName = raw.runtimeType.toString();
  if (typeName.contains('Date')) {
    try {
      final str     = raw.toString();
      final cleaned = str.replaceAll(RegExp(r'[A-Za-z(){}]'), '').trim();
      final parts   = cleaned.split(RegExp(r'[-/\s:]'));
      if (parts.length >= 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null && y > 1900) return DateTime(y, m, d);
      }
    } catch (_) {}
  }

  // Excel serial number
  if (raw is num && raw > 1000 && raw < 100000) {
    return DateTime(1899, 12, 30).add(Duration(days: raw.round()));
  }

  final str = raw.toString().trim();
  if (str.isEmpty) return null;

  var m = RegExp(r'^(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})$').firstMatch(str);
  if (m != null) return DateTime(int.parse(m.group(3)!), int.parse(m.group(2)!), int.parse(m.group(1)!));

  m = RegExp(r'^(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})').firstMatch(str);
  if (m != null) return DateTime(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));

  m = RegExp(r'^(\d{2})/([A-Za-z]{3})/(\d{4})$').firstMatch(str);
  if (m != null) {
    const mo = {'Jan':1,'Feb':2,'Mar':3,'Apr':4,'May':5,'Jun':6,'Jul':7,'Aug':8,'Sep':9,'Oct':10,'Nov':11,'Dec':12};
    final month = mo[m.group(2)] ?? 0;
    if (month > 0) return DateTime(int.parse(m.group(3)!), month, int.parse(m.group(1)!));
  }
  return null;
}

String _bgFmtDate(DateTime d) {
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  final dd = d.day.toString().padLeft(2, '0');
  return '$dd/${months[d.month - 1]}/${d.year}';
}

String _bgFmtAmt(double n) {
  return n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '');
}

List<String> _bgSplitCsv(String line) {
  final result   = <String>[];
  var inQuotes   = false;
  var current    = StringBuffer();
  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (ch == '"') {
      inQuotes = !inQuotes;
    } else if (ch == ',' && !inQuotes) {
      result.add(current.toString().trim());
      current = StringBuffer();
    } else {
      current.write(ch);
    }
  }
  result.add(current.toString().trim());
  return result;
}
