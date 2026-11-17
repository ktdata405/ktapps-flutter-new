import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core_constants.dart';

class ClassicListDenomEntryUI extends StatelessWidget {
  final List<int> notes;
  final List<int> coins;
  final Map<int, TextEditingController> qtyCtrls;
  final int? focusedIndex;
  final Function(int) onRowTap;
  final double grandTotal;
  final String amountInWords;

  const ClassicListDenomEntryUI({
    super.key,
    required this.notes,
    required this.coins,
    required this.qtyCtrls,
    required this.focusedIndex,
    required this.onRowTap,
    required this.grandTotal,
    required this.amountInWords,
  });

  int _toInt(String s) => int.tryParse(s.trim()) ?? 0;

  String _fmtCurrency(num amount, {bool decimal = false}) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '\u20B9',
      decimalDigits: decimal ? 2 : 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final allDenoms = [...notes, ...coins];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: ktCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ktPanelBorder),
          ),
          child: Row(
            children: [
              const Text(
                'AMOUNT IN WORDS:',
                style: TextStyle(
                  color: ktTextGray500,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  amountInWords,
                  style: const TextStyle(
                    color: ktPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allDenoms.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, idx) {
            final v = allDenoms[idx];
            return _buildDenomRowSecondUI(ctx, v, idx);
          },
        ),
      ],
    );
  }

  Widget _buildDenomRowSecondUI(BuildContext context, int value, int index) {
    final c = qtyCtrls[value]!;
    final qty = _toInt(c.text);
    final isFocused = focusedIndex == index;

    return GestureDetector(
      onTap: () => onRowTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isFocused
              ? ktPrimary.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isFocused ? ktPrimary : ktBorderWhite10,
              width: isFocused ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5722),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                '$qty',
                style: const TextStyle(
                  color: ktTextWhite,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            Text(
              '= ${_fmtCurrency((qty * value).toDouble(), decimal: true)}',
              style: const TextStyle(
                color: ktTextWhite,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
