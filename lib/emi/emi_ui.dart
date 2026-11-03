import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core_constants.dart';

String formatIndianAmount(num value) =>
    NumberFormat('#,##,##0', 'en_IN').format(value);

class IndianAmountInputFormatter extends TextInputFormatter {
  const IndianAmountInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final beforeCursor =
        newValue.text
            .substring(
              0,
              newValue.selection.extentOffset.clamp(0, newValue.text.length),
            )
            .replaceAll(RegExp(r'[^0-9]'), '')
            .length;
    final grouped =
        digits.length <= 3
            ? digits
            : '${digits.substring(0, digits.length - 3).replaceAllMapped(RegExp(r'\B(?=(\d{2})+(?!\d))'), (_) => ',')},${digits.substring(digits.length - 3)}';
    var cursor = 0;
    var passed = 0;
    while (cursor < grouped.length && passed < beforeCursor) {
      if (grouped.codeUnitAt(cursor) != 44) passed++;
      cursor++;
    }
    return TextEditingValue(
      text: grouped,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}

InputDecoration emiInputDecoration({
  required bool isDark,
  required IconData icon,
  String? label,
  String? hint,
}) => InputDecoration(
  labelText: label,
  labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
  hintText: hint,
  hintStyle: TextStyle(
    color: isDark ? Colors.white38 : Colors.black38,
    fontSize: 13,
  ),
  prefixIcon: Icon(icon, color: ktCcEmiPrimary, size: 20),
  filled: true,
  fillColor: isDark ? ktCardBg : Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: isDark ? ktBorderWhite10 : Colors.black12),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: isDark ? ktBorderWhite10 : Colors.black12),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: ktCcEmiPrimary, width: 2),
  ),
);

LinearGradient emiCalculationGradient(bool isDark) => LinearGradient(
  colors:
      isDark
          ? [const Color(0xFF1E1B4B), const Color(0xFF311B92)]
          : [const Color(0xFF6366F1), ktCcEmiPrimary],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

Widget emiReportKpiCard({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
  required bool isDark,
}) => Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: isDark ? ktCardBg : Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: color.withValues(alpha: 0.3)),
    boxShadow: [
      BoxShadow(
        color: color.withValues(alpha: 0.08),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: Row(
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ],
  ),
);
