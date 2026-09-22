import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core_colors.dart';

class CalcBaseLayout extends StatelessWidget {
  final String title;
  final List<Widget> inputs;
  final Widget? results;
  final List<Widget>? actions;
  final List<Widget>? history;
  final VoidCallback? onBack;

  const CalcBaseLayout({
    super.key,
    required this.title,
    required this.inputs,
    this.results,
    this.actions,
    this.history,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: ktBgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ktTextWhite, size: 20),
          onPressed: onBack ?? () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(color: ktTextWhite, fontWeight: FontWeight.bold, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: isWide ? _buildWideLayout() : _buildMobileLayout(),
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputSection(),
              if (actions != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: actions!.map((a) => Expanded(
                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: a),
                  )).toList(),
                ),
              ],
              if (history != null) ...[
                const SizedBox(height: 20),
                ...history!,
              ],
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 4,
          child: results ?? const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputSection(),
        if (actions != null) ...[
          const SizedBox(height: 16),
          Column(
            children: actions!.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(width: double.infinity, child: a),
            )).toList(),
          ),
        ],
        if (results != null) ...[
          const SizedBox(height: 12),
          results!,
        ],
        if (history != null) ...[
          const SizedBox(height: 20),
          ...history!,
        ],
      ],
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ktCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ktBorderWhite5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: inputs,
      ),
    );
  }
}

class IndianCurrencyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    
    String cleanedText = newValue.text.replaceAll(',', '');
    List<String> parts = cleanedText.split('.');
    String integerPart = parts[0];
    String? decimalPart = parts.length > 1 ? parts[1] : null;

    if (integerPart.isEmpty && decimalPart == null) return newValue;
    if (integerPart.isEmpty && decimalPart != null) return newValue;

    String formatted = _formatIndian(integerPart);
    if (decimalPart != null) {
      formatted = '$formatted.${decimalPart.substring(0, decimalPart.length > 2 ? 2 : decimalPart.length)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatIndian(String n) {
    if (n.length <= 3) return n;
    String lastThree = n.substring(n.length - 3);
    String otherNumbers = n.substring(0, n.length - 3);
    String formattedOther = "";
    for (int i = 0; i < otherNumbers.length; i++) {
      if ((otherNumbers.length - i) % 2 == 0 && i != 0) {
        formattedOther += ",";
      }
      formattedOther += otherNumbers[i];
    }
    return "$formattedOther,$lastThree";
  }
}

class CalcInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final Widget? prefix;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final bool isCurrency;

  const CalcInput({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.prefix,
    this.suffix,
    this.onChanged,
    this.isCurrency = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(color: ktTextGray400, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: isCurrency ? [IndianCurrencyFormatter()] : null,
            style: const TextStyle(color: ktTextWhite, fontSize: 13, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              prefixIcon: prefix,
              suffixIcon: suffix,
              isDense: true,
              filled: true,
              fillColor: ktBorderWhite5,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ktPrimary, width: 1)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class CalcResultCard extends StatelessWidget {
  final List<Widget> children;
  final String? title;

  const CalcResultCard({super.key, required this.children, this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ktPrimary.withValues(alpha: 0.15), ktSecondary.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ktPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!.toUpperCase(),
              style: const TextStyle(color: ktTextWhite, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }
}

class CalcResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const CalcResultRow({super.key, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label, 
              style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.2),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value, 
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class CalcButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final IconData? icon;

  const CalcButton({super.key, required this.label, required this.onPressed, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final isPrimary = color == null || color == ktPrimary || color == ktSecondary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isPrimary ? LinearGradient(
          colors: [
            (color ?? ktPrimary),
            (color ?? ktPrimary).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ) : null,
        boxShadow: isPrimary ? [
          BoxShadow(
            color: (color ?? ktPrimary).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.transparent : color,
          foregroundColor: ktTextWhite,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
            Flexible(
              child: Text(
                label.toUpperCase(), 
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the calculation result in a global bottom sheet
void showCalcResultBottomSheet({
  required BuildContext context,
  required String title,
  required Widget resultWidget,
  IconData icon = Icons.calculate_rounded,
  Color themeColor = ktPrimary,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: themeColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: isDark ? ktTextWhite : Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Calculation Summary & Result',
                          style: TextStyle(
                            color: ktTextGray400,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white54 : Colors.black45,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: ktBorderWhite10),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: resultWidget,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
