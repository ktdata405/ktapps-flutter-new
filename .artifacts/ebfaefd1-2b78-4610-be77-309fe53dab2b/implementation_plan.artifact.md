# Implementation Plan - Cashew Screen Mobile UI Optimization

The user reported that the Cashew screen is truncated on mobile and requested a layout similar to the Denominations screen, specifically using two rows for icons on mobile.

## Proposed Changes

### Cashew Feature

#### [MODIFY] [cashew_screen.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/cashew/cashew_screen.dart)

- **Header Update**:
    - Remove the standard `AppBar`.
    - Implement a custom `_buildTopHeader()` method similar to `DenominationsScreen`.
    - Use a `Wrap` for action icons to allow them to flow into two rows on narrow screens.
    - Style the icons and header to match the `DenominationsScreen` aesthetic.
- **Bottom Bar Update**:
    - Refactor `_buildBottomBar()` to use a two-row layout for action buttons on mobile.
    - This will prevent truncation of button labels (Add, Draft, Save) and provide a more touch-friendly interface.
    - Row 1: Add, Clear All.
    - Row 2: Draft, Save.
- **Layout Adjustments**:
    - Wrap the body content in a `SafeArea` and ensure consistent padding.
    - Adjust `isCompact` threshold or layout to be more resilient to narrow widths.

## Verification Plan

### Manual Verification
- **Header**:
    - Open Cashew screen on a mobile-sized window/device.
    - Verify that the header icons wrap into two rows instead of being truncated.
    - Verify that the "Month Year" selector and other icons are fully visible and functional.
- **Bottom Bar**:
    - Verify that the action buttons (Add, Draft, Save, Clear) are arranged in two rows on mobile.
    - Verify that all buttons are clickable and perform their respective actions.
- **General**:
    - Ensure no horizontal overflow occurs in the expense list or date navigator.
