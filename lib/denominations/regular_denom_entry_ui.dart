import 'package:flutter/material.dart';
import '../core_constants.dart';

class RegularDenomEntryUI extends StatelessWidget {
  final List<int> notes;
  final List<int> coins;
  final Map<int, TextEditingController> qtyCtrls;
  final int? focusedIndex;
  final Function(int) onRowTap;
  final double grandTotal;
  final String amountInWords;

  const RegularDenomEntryUI({
    super.key,
    required this.notes,
    required this.coins,
    required this.qtyCtrls,
    required this.focusedIndex,
    required this.onRowTap,
    required this.grandTotal,
    required this.amountInWords,
  });

  String _fmt(double val) {
    return val.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  int _toInt(String s) => int.tryParse(s.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allDenoms = [...notes, ...coins];

    Widget buildRow(int value, int idx) {
      final ctrl = qtyCtrls[value]!;
      final qty = _toInt(ctrl.text);
      final rowTotal = qty * value;
      final isCoin = idx >= notes.length;
      final isFocused = focusedIndex == idx;
      final active = qty > 0;

      return GestureDetector(
        onTap: () => onRowTap(idx),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isFocused
                ? ktPrimary.withValues(alpha: 0.15)
                : (isDark ? const Color(0xFF0E1627) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFocused
                  ? ktPrimary
                  : (active
                      ? ktPrimary.withValues(alpha: 0.5)
                      : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.25))),
              width: isFocused ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 36,
                decoration: BoxDecoration(
                  color: isCoin ? const Color(0xFFD97706) : const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              const Text(
                '  ×',
                style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              Container(
                width: 76,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFocused
                        ? ktPrimary
                        : (isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.4)),
                    width: isFocused ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$qty',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '=',
                style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                'Rs. ${_fmt(rowTotal.toDouble())}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF065F46),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...allDenoms.asMap().entries.map((e) => buildRow(e.value, e.key)),
        const SizedBox(height: 16),
      ],
    );
  }
}
