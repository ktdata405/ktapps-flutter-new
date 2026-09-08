import 'package:flutter/material.dart';
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
