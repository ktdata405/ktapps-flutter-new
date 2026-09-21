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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ktTextWhite),
          onPressed: onBack ?? () => Navigator.pop(context),
        ),
        title: Text(title, style: const TextStyle(color: ktTextWhite, fontWeight: FontWeight.bold, fontSize: 20), overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
                const SizedBox(height: 24),
                Row(
                  children: actions!.map((a) => Expanded(
                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: a),
                  )).toList(),
                ),
              ],
              if (history != null) ...[
                const SizedBox(height: 32),
                ...history!,
              ],
            ],
          ),
        ),
        const SizedBox(width: 32),
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
          const SizedBox(height: 24),
          Column(
            children: actions!.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(width: double.infinity, child: a),
            )).toList(),
          ),
        ],
        if (results != null) ...[
          const SizedBox(height: 12),
          results!,
        ],
        if (history != null) ...[
          const SizedBox(height: 32),
          ...history!,
        ],
      ],
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: ktCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ktBorderWhite5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: ktTextGray400, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 1.2), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: isCurrency ? [IndianCurrencyFormatter()] : null,
            style: const TextStyle(color: ktTextWhite, fontSize: 16, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white10),
              prefixIcon: prefix,
              suffixIcon: suffix,
              filled: true,
              fillColor: ktBorderWhite5,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: ktPrimary, width: 1)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ktPrimary.withValues(alpha: 0.15), ktSecondary.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ktPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!.toUpperCase(), style: const TextStyle(color: ktTextWhite, fontSize: 13.5, fontWeight: FontWeight.w900, letterSpacing: 1.5), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 20),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label, 
              style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value, 
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900),
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
        borderRadius: BorderRadius.circular(16),
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
            color: (color ?? ktPrimary).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ] : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.transparent : color,
          foregroundColor: ktTextWhite,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Flexible(
              child: Text(
                label.toUpperCase(), 
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
