# UI and Experience Enhancements Plan

Update several entry screens (Milk, Cashew, Rent, MSI, Loan, Wallet) to improve consistency, UI/UX, and functionality across both Web and Mobile.

## User Review Required

> [!IMPORTANT]
> - **Report Icon:** Standardizing to `Icons.bar_chart_rounded` across all entry pages.
> - **Milk/Cashew Calendar:** Removing the month/year dropdown from the Title Bar as requested. The custom calendar accordion will no longer be accessible from the header; users can still change dates via the Date Navigator section.

## Proposed Changes

### Core UI Standardization

#### [MODIFY] [core_ui_utils.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/core_ui_utils.dart)
- Ensure consistent styling utilities if needed (already mostly consistent).

### Milk & Cashew Entry Pages

#### [MODIFY] [milk_screen.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/milk/milk_screen.dart)
- Remove `_calendarTitleBarBtn()` from `_buildAppBar()`.
- Standardize report icon to `Icons.bar_chart_rounded`.

#### [MODIFY] [cashew_screen.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/cashew/cashew_screen.dart)
- Remove `_calendarHeaderBtn()` from `_buildTopHeader()`.
- Standardize report icon to `Icons.bar_chart_rounded`.

### Rent Entry Page Redesign

#### [MODIFY] [rent_entry_screen.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/rent/rent_entry_screen.dart)
- Apply the UI style from `milk_screen.dart`:
    - Add background glows and grid painter.
    - Redesign Header to match Milk's gradient icon style.
    - Redesign Date Navigator with large navigation buttons.
    - Update input fields to match Milk's aesthetic (rounded containers, specific icon colors).
    - Update Bottom Bar to include "Draft" and "Save" with Milk-style gradients/styling.
    - Standardize report icon.

### MSI Entry Page Grouping

#### [MODIFY] [msi_screen.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/msi/msi_screen.dart)
- Group small input boxes more effectively using `GridView`.
- Add clearer separators and category labels (Govt Scheme, Coin, Groww, etc.).
- Standardize report icon.

### Loan & Wallet Entry Pages

#### [MODIFY] [loan_screen.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/loan/loan_screen.dart)
- Add a "Clear" button to the form actions.
- Standardize report icon.

#### [MODIFY] [wallet_screen.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/wallet/wallet_screen.dart)
- Redesign to match the dark theme and glow aesthetic of Milk/Cashew.
- Add a "Clear" button.
- Improve form layout and grouping.
- Standardize report icon.

## Verification Plan

### Manual Verification
- Verify each screen on both Web and App.
- Check that the report icon is consistent (`Icons.bar_chart_rounded`) everywhere.
- Confirm the month/year dropdown is gone from Milk and Cashew headers.
- Test the new Rent entry UI for functionality and responsiveness.
- Verify MSI grouping and categories.
- Test "Clear" button functionality in Loan and Wallet screens.
- Verify the redesigned Wallet screen looks professional and consistent.
