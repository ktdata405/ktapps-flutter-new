import 'package:flutter/material.dart';

class RegularDenomEntryUI extends StatelessWidget {
  final List<int> notes;
  final List<int> coins;
  final Map<int, TextEditingController> qtyCtrls;
  final Function(int) onRowTap;
  final VoidCallback onAddManual;
  final VoidCallback onSubtractManual;
  final double notesTotal;
  final double coinsTotal;
  final double grandTotal;
  final int totalNotesCount;
  final int totalCoinsCount;
  final String amountInWords;

  const RegularDenomEntryUI({
    super.key,
    required this.notes,
    required this.coins,
    required this.qtyCtrls,
    required this.onRowTap,
    required this.onAddManual,
    required this.onSubtractManual,
    required this.notesTotal,
    required this.coinsTotal,
    required this.grandTotal,
    required this.totalNotesCount,
    required this.totalCoinsCount,
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

    Widget buildRow(int value, bool isCoin) {
      final ctrl = qtyCtrls[value]!;
      final qty = _toInt(ctrl.text);
      final rowTotal = qty * value;

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0E1627) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.25),
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
            SizedBox(
              width: 76,
              height: 42,
              child: TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.4),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
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
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...notes.map((v) => buildRow(v, false)),
        const SizedBox(height: 6),
        ...coins.map((v) => buildRow(v, true)),
        const SizedBox(height: 16),
        Row(
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF93C5FD)),
                ),
                child: Column(
                  children: [
                    const Text('Total Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF))),
                    const SizedBox(height: 4),
                    Text('Rs. ${_fmt(grandTotal)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0E1627) : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  amountInWords,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
