# Implementation Plan - Cashew Screen Enhancements

This plan outlines the changes to be made to the `CashewScreen` in the `ktapps-flutter-new` project.

## User Review Required

> [!IMPORTANT]
> - The existing wallet icon in the AppBar's leading position will be replaced by a standard back button for better navigation.
> - The Home icon will be added to the AppBar actions.
> - The Month/Year selector will be moved from the AppBar to the body of the screen, placed directly below the date navigator.

## Proposed Changes

### Cashew Feature

#### [MODIFY] [cashew_screen.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/cashew/cashew_screen.dart)

- **AppBar Updates**:
    - Replace the `leading` widget with a `BackButton`.
    - Add a Home icon button to the `actions`.
    - Remove the `_calendarTitleBarBtn` from the `actions`.
- **Body Updates**:
    - Add a new widget (moved from AppBar) to display the Month/Year below the date navigator block.
    - Adjust the layout to accommodate the new Month/Year selector.
    - Ensure the calendar accordion correctly displays when the Month/Year selector is tapped.

## Verification Plan

### Manual Verification
- **Navigation**:
    - Tap the back button: Screen should pop.
    - Tap the home icon: Screen should pop until root (main dashboard).
- **Date Management**:
    - Verify the Month/Year selector is now below the "Date" block.
    - Tap the Month/Year selector: Calendar accordion should toggle visibility.
    - Select a date from the calendar: Date should update and accordion should behave as expected.
