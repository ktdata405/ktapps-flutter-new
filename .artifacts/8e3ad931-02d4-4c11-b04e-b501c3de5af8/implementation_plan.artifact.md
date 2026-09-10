# Implementation Plan - Optimize Cashew Entry Page Loading

The user reports that the loader on the Cashew Entry page takes a long time. Analysis shows that the app makes two separate network requests to a Google Apps Script backend every time a date is fetched (one for the day's data and one for the monthly calendar highlights). These requests are redundant because the data for a specific day is already part of the monthly data fetched by the other request.

## Proposed Changes

### Cashew Service Layer

#### [MODIFY] [cashew_service.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/cashew/cashew_service.dart)
- Implement an in-memory cache for monthly data (`_monthlyCache`).
- Refactor `fetchDataForDate` to fetch the entire month's data if not cached, then return both the specific date's rows and the list of all dates with data for the calendar.
- Update `saveData` to clear the relevant month's cache after a successful update.

### Cashew UI Layer

#### [MODIFY] [cashew_screen.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/cashew/cashew_screen.dart)
- Refactor `_fetchDataForDate` to make a single call to the updated service.
- Remove the redundant `Future.wait` and the separate call to `fetchDatesForCalendar`.
- Ensure the loader is only shown when a network request is actually needed.

## Verification Plan

### Automated Tests
- N/A (Project seems to rely on manual verification for UI/Service integration)

### Manual Verification
- Open Cashew screen: Observe the first load (should still take time but slightly less due to one less request).
- Change dates within the same month: Observe that the loader should NOT appear, and data should update instantly.
- Save a record: Verify that the calendar updates and the next day loads correctly (triggering a cache clear for the current month).
