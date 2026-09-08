import 'package:intl/intl.dart';

/// Returns the current time in India Standard Time (UTC+5:30)
DateTime getIndiaTime() {
  return DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
}

/// Formats a [DateTime] to "dd/MM/yyyy (E)" format, e.g. "22/04/2026 (Mon)"
String ktFormatDate(DateTime date) {
  return DateFormat('dd/MMM/yyyy (E)').format(date);
}

/// Formats a [DateTime] to "dd/MMM/yyyy" format for sheet saving if needed
String ktFormatDateForSheet(DateTime date) {
  return DateFormat('dd/MMM/yyyy').format(date);
}

/// A flexible parser that handles various date formats used in the project
DateTime? ktParseDate(Object? v) {
  if (v == null) return null;
  final raw = v.toString().trim();
  if (raw.isEmpty) return null;
  
  // Try direct parse (ISO)
  final direct = DateTime.tryParse(raw);
  if (direct != null) {
    // Force to local midnight of that calendar day
    final dt = direct.toLocal();
    return DateTime(dt.year, dt.month, dt.day);
  }

  // Try common formats
  final formats = [
    'dd/MM/yyyy (E)',
    'dd/MM/yyyy',
    'dd/MMM/yyyy',
    'dd-MMM-yyyy',
    'dd-MM-yyyy',
    'yyyy-MM-dd',
  ];

  for (final p in formats) {
    try {
      final d = DateFormat(p).parseStrict(raw);
      return DateTime(d.year, d.month, d.day);
    } catch (_) {}
  }
  return null;
}
