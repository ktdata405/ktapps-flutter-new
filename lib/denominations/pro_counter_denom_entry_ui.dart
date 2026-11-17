import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core_constants.dart';

class ProCounterDenomEntryUI extends StatelessWidget {
  final List<int> notes;
  final List<int> coins;
  final Map<int, TextEditingController> qtyCtrls;
  final int? focusedIndex;
  final Function(int) onRowTap;
  final double grandTotal;
  final String amountInWords;

  const ProCounterDenomEntryUI({
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allDenoms = [...notes, ...coins];

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 124,
          ),
          itemCount: allDenoms.length,
          itemBuilder: (ctx, idx) {
            final v = allDenoms[idx];
            final c = qtyCtrls[v]!;
            final qty = _toInt(c.text);
            final isFocused = focusedIndex == idx;
            final active = qty > 0;

            return GestureDetector(
              onTap: () => onRowTap(idx),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? ktCardBg : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isFocused
                        ? ktPrimary
                        : (active ? ktPrimary.withValues(alpha: 0.5) : ktBorderWhite10),
                    width: isFocused ? 2 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          '$v',
                          style: const TextStyle(
                            color: ktTextWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('×', style: TextStyle(color: ktTextGray500, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: ktBorderWhite10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$qty',
                              style: const TextStyle(
                                color: ktTextWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: ktBorderWhite10),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(color: ktTextGray500, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text(
                          _fmtCurrency((qty * v).toDouble(), decimal: true),
                          style: TextStyle(
                            color: active ? ktEmerald : ktTextGray400,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
