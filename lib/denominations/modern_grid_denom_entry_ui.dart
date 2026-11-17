import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core_constants.dart';

class ModernGridDenomEntryUI extends StatelessWidget {
  final List<int> notes;
  final List<int> coins;
  final Map<int, TextEditingController> qtyCtrls;
  final int? focusedIndex;
  final Function(int) onRowTap;
  final Function(int, int) onUpdateQty;
  final double grandTotal;
  final String amountInWords;
  final int crossAxisCount;
  final double childAspectRatio;

  const ModernGridDenomEntryUI({
    super.key,
    required this.notes,
    required this.coins,
    required this.qtyCtrls,
    required this.focusedIndex,
    required this.onRowTap,
    required this.onUpdateQty,
    required this.grandTotal,
    required this.amountInWords,
    required this.crossAxisCount,
    required this.childAspectRatio,
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

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: childAspectRatio,
      children: [
        for (int idx = 0; idx < allDenoms.length; idx++) ...[
          _buildDenomCard(context, allDenoms[idx], idx),
        ],
      ],
    );
  }

  Widget _buildDenomCard(BuildContext context, int value, int index) {
    final c = qtyCtrls[value]!;
    final qty = _toInt(c.text);
    final active = qty > 0;
    final isFocused = focusedIndex == index;

    return GestureDetector(
      onTap: () => onRowTap(index),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFocused
                ? ktPrimary
                : (active
                    ? ktPrimary.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.17)),
            width: isFocused ? 2 : 1,
          ),
          color: ktCardBg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: ktTextWhite,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  onPressed: () => onUpdateQty(value, qty - 1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 24, height: 24),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$qty',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ktTextWhite,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  onPressed: () => onUpdateQty(value, qty + 1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 24, height: 24),
                ),
              ],
            ),
            const Spacer(),
            Text(
              _fmtCurrency((qty * value).toDouble(), decimal: true),
              style: TextStyle(
                color: active ? ktEmerald : ktTextGray400,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
