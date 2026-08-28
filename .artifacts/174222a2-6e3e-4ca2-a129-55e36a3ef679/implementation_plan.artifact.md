# Refactor and Optimize Cashew Screens

The Cashew screen and its report page are currently slow to load due to redundant network calls, large monolithic files, and duplicated code/constants. This plan aims to improve performance and maintainability.

## User Review Required

> [!IMPORTANT]
> This refactor involves moving a lot of code into separate files. While functionality will remain identical, the file structure will change significantly.

## Proposed Changes

### [Cashew Module Cleanup]

I will extract shared logic, constants, and models into a common package to remove redundancy and improve clarity.

#### [NEW] [cashew_constants.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/cashew/cashew_constants.dart)
* Define shared colors (e.g., `_bgDark`, `_primary`, etc.).
* Define the Google Apps Script URL (`_cashewSheetUrl`).
* Define common category lists.

#### [NEW] [cashew_models.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/cashew/cashew_models.dart)
* Define `CashewRecord`, `ExpenseRow`, `ScheduledRecord`, and `ImportEntry` models.
* Add `fromJson` and `toJson` methods for cleaner data handling.

#### [NEW] [cashew_service.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/cashew/cashew_service.dart)
* Create a `CashewService` class to handle all HTTP requests.
* Implement basic in-memory caching to prevent redundant loads when switching between screens.
* Use `Future.wait` to parallelize independent requests (e.g., fetching data and calendar dates).

#### [MODIFY] [cashew_screen.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/cashew/cashew_screen.dart)
* Import shared constants and service.
* Replace local API logic with `CashewService` calls.
* Break down the 2700-line file by extracting large UI components (like the Calculator, Calendar, and Expense List) into private sub-widgets or separate files if necessary.

#### [MODIFY] [cashew_report_screen.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/cashew/cashew_report_screen.dart)
* Import shared constants and service.
* Replace local API logic with `CashewService` calls.
* Extract complex UI components (Insights, Scheduled list, Export dialogs) to improve readability and build performance.

---

## Verification Plan

### Automated Tests
* I will verify that the project still builds successfully.
* Since this is a UI-heavy refactor, manual verification of data loading is crucial.

### Manual Verification
* Verify that the Cashew screen loads data correctly for a selected date.
* Verify that the Report screen displays transactions, insights, and scheduled items.
* Check that the loading indicator appears and disappears as expected.
* Ensure the calculator and export features still work.
