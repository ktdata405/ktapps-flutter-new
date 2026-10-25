import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'core_constants.dart';

/// Shows a premium, branded custom toast notification.
/// Compatible with both Light and Dark themes.
void ktShowCustomToast(BuildContext context, String message) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  // Clear any existing snackbars before showing new one
  ScaffoldMessenger.of(context).clearSnackBars();
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      content: Container(
        height: 64,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF030303) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? ktBorderWhite10 : Colors.black.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.6 : 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            // Branded Logo Container (Always white for contrast, like Woolworths style)
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  topRight: Radius.circular(48),
                  bottomRight: Radius.circular(48),
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/app_logo.jpeg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.apps, 
                    color: ktPrimary, 
                    size: 30
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    ),
  );
}

/// A premium, modern Edit button style used across the app.
Widget ktEditButton({required VoidCallback onPressed, String label = 'Edit'}) {
  return Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF6366F1).withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.edit_note_rounded, size: 20, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

/// A premium, modern Delete button style.
Widget ktDeleteButton({required VoidCallback onPressed, String label = 'Delete'}) {
  return TextButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.delete_outline_rounded, color: ktRose, size: 20),
    label: Text(
      label,
      style: const TextStyle(
        color: ktRose,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    ),
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: ktRose, width: 1),
      ),
    ),
  );
}

/// Shows a premium, branded bottom sheet with details.
/// Inspired by the Cashew Report Insights style.
void ktShowDetailsSheet({
  required BuildContext context,
  required String title,
  required IconData icon,
  required Color themeColor,
  required List<Map<String, dynamic>> details, // Each map: {'label': String, 'value': String, 'color': Color?, 'isHighlight': bool?}
  String? subtitle,
  Widget? bodyHeader,
  String? footerNote,
  List<Widget>? actions,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  // Extract highlighted item if any
  Map<String, dynamic>? highlightItem;
  final otherDetails = details.where((item) {
    if (item['isHighlight'] == true) {
      highlightItem = item;
      return false;
    }
    return true;
  }).toList();

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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle/Indicator
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: themeColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.black45),
                ),
              ],
            ),
          ),
          
          const Divider(height: 0.5),
          
          // Highlight Section (Centered)
          if (highlightItem != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: (highlightItem!['color'] as Color? ?? themeColor).withOpacity(0.05),
              ),
              child: Column(
                children: [
                  Text(
                    highlightItem!['label'].toUpperCase(),
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    highlightItem!['value'],
                    style: TextStyle(
                      color: highlightItem!['color'] ?? (isDark ? Colors.white : Colors.black87),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            
          const Divider(height: 1),
          
          // Content
          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(16),
              shrinkWrap: true,
              children: [
                if (bodyHeader != null) ...[
                  bodyHeader,
                  const SizedBox(height: 16),
                ],
                for (var i = 0; i < otherDetails.length; i += 2)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: (i ~/ 2) % 2 == 0
                              ? (isDark
                                  ? Colors.white.withOpacity(0.03)
                                  : Colors.black.withOpacity(0.02))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // Left Item
                            Expanded(child: _buildDetailItem(otherDetails[i], isDark)),
                            
                            // Spacer & Divider if there's a second item
                            if (i + 1 < otherDetails.length) ...[
                              Container(
                                width: 1,
                                height: 24,
                                margin: const EdgeInsets.symmetric(horizontal: 12),
                                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                              ),
                              // Right Item
                              Expanded(child: _buildDetailItem(otherDetails[i + 1], isDark)),
                            ] else
                              const Expanded(child: SizedBox.shrink()),
                          ],
                        ),
                      ),
                      if (i + 2 < otherDetails.length)
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                          indent: 8,
                          endIndent: 8,
                        ),
                    ],
                  ),
                
                if (footerNote != null && footerNote.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      footerNote,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Actions
          if (actions != null && actions.isNotEmpty)
            Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: isDark ? Colors.black12 : const Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: isDark ? ktBorderWhite10 : Colors.black.withOpacity(0.05))),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: actions,
              ),
            ),
        ],
      ),
    ),
  );
}

/// A premium, standardized header icon button for project title bars.
Widget ktHeaderIcon(IconData icon, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: ktWhite.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ktPanelBorder),
      ),
      child: Icon(icon, size: 16, color: ktWhite70),
    ),
  );
}

/// Internal helper for Details Sheet items
Widget _buildDetailItem(Map<String, dynamic> item, bool isDark) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        item['label'],
        style: TextStyle(
          color: isDark ? Colors.white60 : Colors.black54,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 2),
      Text(
        item['value'],
        style: TextStyle(
          color: item['color'] ?? (isDark ? Colors.white : Colors.black87),
          fontSize: 13,
          fontWeight: FontWeight.w800,
          fontFamily: 'monospace',
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

/// A globally reusable structured report card with date header, line separators,
/// and two-column section metrics (Milk Report List View style / Future Reference).
class KtMilkReportCard extends StatelessWidget {
  final String dateTitle;
  final String leftTitle;
  final Color leftTitleColor;
  final String leftQtyLabel;
  final String leftQtyValue;
  final String leftRateLabel;
  final String leftRateValue;
  final String leftAmtLabel;
  final String leftAmtValue;

  final String? rightTitle;
  final Color? rightTitleColor;
  final String? rightQtyLabel;
  final String? rightQtyValue;
  final String? rightRateLabel;
  final String? rightRateValue;
  final String? rightAmtLabel;
  final String? rightAmtValue;
  final VoidCallback? onTap;

  const KtMilkReportCard({
    super.key,
    required this.dateTitle,
    required this.leftTitle,
    required this.leftTitleColor,
    required this.leftQtyLabel,
    required this.leftQtyValue,
    required this.leftRateLabel,
    required this.leftRateValue,
    required this.leftAmtLabel,
    required this.leftAmtValue,
    this.rightTitle,
    this.rightTitleColor,
    this.rightQtyLabel,
    this.rightQtyValue,
    this.rightRateLabel,
    this.rightRateValue,
    this.rightAmtLabel,
    this.rightAmtValue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFBAC7FF).withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Date Header Block
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: ktStone200,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFCBD5E1),
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Date: $dateTitle',
                style: const TextStyle(
                  color: ktSlate600,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // Sections Row with line separators
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Section
                  Expanded(
                    child: _buildSectionColumn(
                      title: leftTitle,
                      titleColor: leftTitleColor,
                      qtyLabel: leftQtyLabel,
                      qtyValue: leftQtyValue,
                      rateLabel: leftRateLabel,
                      rateValue: leftRateValue,
                      amtLabel: leftAmtLabel,
                      amtValue: leftAmtValue,
                    ),
                  ),
                  // Vertical line separator
                  Container(
                    width: 1,
                    color: const Color(0xFFCBD5E1).withOpacity(0.5),
                  ),
                  // Right Section
                  Expanded(
                    child: rightTitle != null
                        ? _buildSectionColumn(
                            title: rightTitle!,
                            titleColor: rightTitleColor ?? ktCyan400,
                            qtyLabel: rightQtyLabel ?? '',
                            qtyValue: rightQtyValue ?? '',
                            rateLabel: rightRateLabel ?? '',
                            rateValue: rightRateValue ?? '',
                            amtLabel: rightAmtLabel ?? '',
                            amtValue: rightAmtValue ?? '',
                          )
                        : Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(12),
                            child: const Text(
                              '—',
                              style: TextStyle(
                                color: ktTextGray500,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionColumn({
    required String title,
    required Color titleColor,
    required String qtyLabel,
    required String qtyValue,
    required String rateLabel,
    required String rateValue,
    required String amtLabel,
    required String amtValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: const Color(0xFFCBD5E1).withOpacity(0.3)),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          alignment: Alignment.centerLeft,
          child: Text(
            '$qtyLabel : $qtyValue',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: const Color(0xFFCBD5E1).withOpacity(0.3)),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  alignment: Alignment.center,
                  child: Text(
                    '$rateLabel : $rateValue',
                    style: const TextStyle(
                      color: ktPink700,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Container(
                width: 1,
                color: const Color(0xFFCBD5E1).withOpacity(0.3),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  alignment: Alignment.center,
                  child: Text(
                    '$amtLabel : $amtValue',
                    style: const TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

