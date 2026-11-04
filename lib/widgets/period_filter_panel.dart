import 'package:flutter/material.dart';

import '../core_constants.dart';
import '../core_utils.dart';

/// Reusable month/year filter with previous, refresh, and next actions.
///
/// Pages own the selected period and decide what each action does, allowing
/// the same filter UI to be shared without coupling it to a specific report.
class PeriodFilterPanel extends StatelessWidget {
  const PeriodFilterPanel({
    super.key,
    required this.month,
    required this.year,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.onPrevious,
    required this.onRefresh,
    required this.onNext,
    this.firstYear = 2020,
    this.title = 'FILTER PERIOD',
  });

  final String month;
  final int year;
  final ValueChanged<String> onMonthChanged;
  final ValueChanged<int> onYearChanged;
  final VoidCallback onPrevious;
  final VoidCallback onRefresh;
  final VoidCallback onNext;
  final int firstYear;
  final String title;

  @override
  Widget build(BuildContext context) {
    final currentYear = getIndiaTime().year;
    final years = List.generate(
      currentYear - firstYear + 1,
      (index) => currentYear - index,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x8B171E34),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBAC7FF).withValues(alpha: 0.2)),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 34)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.filter_alt,
                      color: ktPrimary.withValues(alpha: 0.7), size: 14),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFC7D2FE),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _actionButton(Icons.chevron_left, onPrevious),
                  const SizedBox(width: 6),
                  _actionButton(Icons.refresh_rounded, onRefresh),
                  const SizedBox(width: 6),
                  _actionButton(Icons.chevron_right, onNext),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _periodDropdown<String>(
                  context: context,
                  label: 'MONTH',
                  value: month,
                  items: ktMonths
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onMonthChanged(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _periodDropdown<int>(
                  context: context,
                  label: 'YEAR',
                  value: year,
                  items: years
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text('$value'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onYearChanged(value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      tooltip: switch (icon) {
        Icons.chevron_left => 'Previous period',
        Icons.chevron_right => 'Next period',
        _ => 'Refresh period',
      },
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      icon: Icon(icon, color: const Color(0xFFB8C4EA), size: 16),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFF9AA8FF).withValues(alpha: 0.08),
        side: BorderSide(color: const Color(0xFFBAC7FF).withValues(alpha: 0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _periodDropdown<T>({
    required BuildContext context,
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ktTextGray400,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF11182D).withValues(alpha: 0.7) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBAC7FF).withValues(alpha: 0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(
                color: ktTextWhite,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
