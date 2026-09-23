import 'package:intl/intl.dart';

/// Returns the current time in India Standard Time (UTC+5:30)
DateTime getIndiaTime() {
  return DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
}

/// Formats a [DateTime] to "dd/MMM/yyyy (E)" format, e.g. "22/Sep/2026 (Mon)"
String ktFormatDate(DateTime date) {
  return DateFormat('dd/MMM/yyyy (E)').format(date);
}

/// Formats a [DateTime] to "dd/MMM/yyyy" format for sheet saving if needed
String ktFormatDateForSheet(DateTime date) {
  return DateFormat('dd/MMM/yyyy').format(date);
}

/// A flexible parser that handles various date formats used in the project,
/// including ISO strings, JS Date strings (e.g. "Thu Apr 02 2020 12:30:00 GMT+0530..."), and custom formatted dates.
DateTime? ktParseDate(Object? v) {
  if (v == null) return null;
  var raw = v.toString().trim();
  if (raw.isEmpty) return null;

  // Try direct parse (ISO)
  final direct = DateTime.tryParse(raw);
  if (direct != null) {
    final dt = direct.toLocal();
    return DateTime(dt.year, dt.month, dt.day);
  }

  // Handle JS Date string e.g. "Thu Apr 02 2020 12:30:00 GMT+0530 (India Standard Time)"
  if (raw.contains('GMT') || raw.contains('Standard Time') || raw.contains('UTC')) {
    final parts = raw.split(' ');
    if (parts.length >= 4) {
      final dateSub = '${parts[0]} ${parts[1]} ${parts[2]} ${parts[3]}';
      try {
        final d = DateFormat('EEE MMM dd yyyy').parse(dateSub);
        return DateTime(d.year, d.month, d.day);
      } catch (_) {}

      final dateSub2 = '${parts[1]} ${parts[2]} ${parts[3]}';
      try {
        final d = DateFormat('MMM dd yyyy').parse(dateSub2);
        return DateTime(d.year, d.month, d.day);
      } catch (_) {}
    }
  }

  // RegEx fallback for Month Day Year anywhere in string (e.g. "Apr 02 2020" or "Apr 2 2020")
  final match = RegExp(
    r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{1,2})\s+(\d{4})',
    caseSensitive: false,
  ).firstMatch(raw);
  if (match != null) {
    try {
      final str = '${match.group(1)} ${match.group(2)} ${match.group(3)}';
      final d = DateFormat('MMM dd yyyy').parse(str);
      return DateTime(d.year, d.month, d.day);
    } catch (_) {}
  }

  // Try common formats
  final formats = [
    'EEE MMM dd yyyy HH:mm:ss',
    'EEE MMM dd yyyy',
    'MMM dd yyyy',
    'dd MMM yyyy',
    'dd/MMM/yyyy (E)',
    'dd/MM/yyyy (E)',
    'dd/MM/yyyy',
    'dd/MMM/yyyy',
    'dd-MMM-yyyy',
    'dd-MM-yyyy',
    'yyyy-MM-dd',
  ];

  for (final p in formats) {
    try {
      final d = DateFormat(p).parse(raw);
      return DateTime(d.year, d.month, d.day);
    } catch (_) {}
  }

  return null;
}
