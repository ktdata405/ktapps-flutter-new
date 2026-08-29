# All Modules Cleanup Implementation Plan

This plan outlines the steps to clean up all modules in the KT Apps project by removing redundant code, centralizing constants/models, and optimizing network logic.

## Proposed Changes

### [Core/Shared Cleanup]
*   **[NEW] [core_constants.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/core_constants.dart)**: Extract app-wide constants (standard months list, common colors like `primary`, `emerald`, `rose`, etc.).

### [Milk Module]
*   **[NEW] [milk_models.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/milk/milk_models.dart)**: Define `MilkRecord`.
*   **[NEW] [milk_service.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/milk/milk_service.dart)**: Centralize API calls for milk entries.
*   **[MODIFY] [milk_screen.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/milk/milk_screen.dart)** & **[milk_report_screen.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/milk/milk_report_screen.dart)**: Use shared models, service, and core constants.

### [MSI Module]
*   **[NEW] [msi_models.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/msi/msi_models.dart)**: Define investment models.
*   **[NEW] [msi_service.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/msi/msi_service.dart)**: Centralize API calls for MSI.
*   **[MODIFY] [msi_screen.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/msi/msi_screen.dart)** & **[msi_report_screen.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/msi/msi_report_screen.dart)**: Use shared models and service.

### [Loan/Rent/Debts/Wallet/Scan Cleanup]
*   **[MODIFY]** Update these modules to use `core_constants.dart` for colors and months.
*   **[OPTIMIZE]** Parallelize network calls in `initState` or data fetching methods where multiple requests are made sequentially.

---

## Verification Plan

### Automated Tests
*   Run `flutter build apk` (or similar) to ensure no syntax errors.

### Manual Verification
*   Verify each module loads data correctly.
*   Check that the UI remains consistent (colors, layouts).
*   Verify that saving/updating data still works across all modules.
