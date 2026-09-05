# Responsive Improvements for MSI and MSI Report Screens

Improve the user experience on mobile devices by making the MSI and MSI Report screens responsive. Currently, these screens use fixed-column layouts and horizontal arrangements that become cramped or truncated on narrow displays.

## Proposed Changes

### [MSI Module]

#### [MODIFY] [msi_screen.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/msi/msi_screen.dart)
-   **Adaptive Header**: Change the header configuration card from a fixed `Row` to a responsive layout (stacking items on narrow screens).
-   **Dynamic Grid**: Adjust the `GridView` in `_buildSection` to use 1, 2, or 3 columns based on the available screen width.
-   **Padding Adjustments**: Use relative padding to ensure content doesn't feel too squeezed on small devices.
-   **Flexible Fund Cards**: Remove fixed `mainAxisExtent` or adjust it to accommodate content without truncation.

#### [MODIFY] [msi_report_screen.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/msi/msi_report_screen.dart)
-   **Stacked Hero/Control**: On mobile, stack the "Total Investment" card and "Controls" card vertically instead of side-by-side.
-   **Adaptive Platform Grid**: Change the horizontal-only scrolling platform cards to a responsive grid or list that fits the screen width.
-   **Compact Tab Switcher**: Ensure the tab switcher remains legible on small screens, potentially using smaller text or a scrollable container.
-   **Mobile-Friendly Transactions**: Transform the wide transaction table into a card-based list view for mobile users to avoid excessive horizontal scrolling.

## Verification Plan

### Manual Verification
-   **Screen Size Testing**: Open the app on a mobile emulator (or resize the window if running on web/desktop) to verify that:
    -   The MSI header items stack correctly.
    -   Fund cards adjust their column count.
    -   The Report dashboard stacks the hero and control cards.
    -   Platform cards are fully visible without horizontal scrolling (unless intended as a carousel).
    -   Transaction history is readable.
-   **Functionality Check**: Ensure Save/Update/Edit actions still work correctly after UI refactoring.
