import 'package:flutter/material.dart';
import '../core_constants.dart';

class DenomsKeyboard extends StatelessWidget {
  final String currentDenom;
  final String currentCount;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final ValueChanged<String> onKeyPress;
  final VoidCallback onClear;
  final VoidCallback onBackspace;
  final ValueChanged<int> onIncrement;
  final VoidCallback onDone;

  const DenomsKeyboard({
    super.key,
    required this.currentDenom,
    required this.currentCount,
    required this.onUp,
    required this.onDown,
    required this.onKeyPress,
    required this.onClear,
    required this.onBackspace,
    required this.onIncrement,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ktCardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
        border: const Border(top: BorderSide(color: ktBorderWhite10)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            children: [
              IconButton(
                  onPressed: onUp,
                  icon: const Icon(Icons.arrow_upward,
                      color: ktTextWhite, size: 20)),
              IconButton(
                  onPressed: onDown,
                  icon: const Icon(Icons.arrow_downward,
                      color: ktTextWhite, size: 20)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ktPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '₹$currentDenom',
                  style: const TextStyle(
                      color: ktPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
              const Spacer(),
              Text(
                'Count: $currentCount',
                style: const TextStyle(
                    color: ktTextGray400,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
              const SizedBox(width: 12),
              IconButton(
                  onPressed: onDone,
                  icon: const Icon(Icons.keyboard_hide, color: ktTextGray400)),
            ],
          ),
          const SizedBox(height: 12),
          // Number Pad
          _buildRow(['1', '2', '3']),
          const SizedBox(height: 10),
          _buildRow(['4', '5', '6']),
          const SizedBox(height: 10),
          _buildRow(['7', '8', '9']),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildKey('C',
                  color: ktRose.withValues(alpha: 0.15),
                  textColor: ktRose,
                  flex: 1,
                  onTap: onClear),
              const SizedBox(width: 10),
              _buildKey('0', flex: 1, onTap: () => onKeyPress('0')),
              const SizedBox(width: 10),
              _buildKey('backspace',
                  icon: Icons.backspace_outlined,
                  color: Colors.white.withValues(alpha: 0.05),
                  flex: 1,
                  onTap: onBackspace),
            ],
          ),
          const SizedBox(height: 16),
          // Quick Increments
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildIncrementKey('+1', 1),
                _buildIncrementKey('+5', 5),
                _buildIncrementKey('+10', 10),
                _buildIncrementKey('+50', 50),
                _buildIncrementKey('+100', 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      children: keys
          .expand((k) => [
                _buildKey(k, flex: 1, onTap: () => onKeyPress(k)),
                if (k != keys.last) const SizedBox(width: 10),
              ])
          .toList(),
    );
  }

  Widget _buildKey(String label,
      {IconData? icon,
      Color? color,
      Color? textColor,
      int flex = 1,
      required VoidCallback onTap}) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: color ?? Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ktBorderWhite10),
          ),
          child: Center(
            child: icon != null
                ? const Icon(Icons.backspace_outlined, color: ktTextWhite)
                : Text(
                    label,
                    style: TextStyle(
                      color: textColor ?? ktTextWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncrementKey(String label, int val) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => onIncrement(val),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: ktEmerald.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ktEmerald.withValues(alpha: 0.3)),
          ),
          child: Text(
            label,
            style: const TextStyle(
                color: ktEmerald, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
