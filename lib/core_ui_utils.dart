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
            color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.12),
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

/// Shows a premium, branded bottom sheet with details.
/// Inspired by the Cashew Report Insights style.
void ktShowDetailsSheet({
  required BuildContext context,
  required String title,
  required IconData icon,
  required Color themeColor,
  required List<Map<String, dynamic>> details, // Each map: {'label': String, 'value': String, 'color': Color?, 'isHighlight': bool?}
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
        border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.05)),
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
                    color: themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: themeColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
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
                color: (highlightItem!['color'] as Color? ?? themeColor).withValues(alpha: 0.05),
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
                for (var i = 0; i < otherDetails.length; i += 2)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: (i ~/ 2) % 2 == 0
                              ? (isDark
                                  ? Colors.white.withValues(alpha: 0.03)
                                  : Colors.black.withValues(alpha: 0.02))
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
                                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
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
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
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
                border: Border(top: BorderSide(color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.05))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
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
        color: ktWhite.withValues(alpha: 0.04),
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

