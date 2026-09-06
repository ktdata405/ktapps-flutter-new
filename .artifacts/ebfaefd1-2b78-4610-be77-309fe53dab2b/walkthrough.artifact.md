# Walkthrough - Cashew Screen Mobile Optimization

I have optimized the Cashew screen for mobile devices to prevent layout truncation and improve usability, matching the design pattern used in the Denominations screen.

## Changes Made

### 1. Custom Header (Replacing AppBar)
- Replaced the standard `AppBar` with a custom `_buildTopHeader()` widget.
- Used a `Wrap` widget for the action icons. This allows the icons (Calendar, Home, Calculator, Import, Reports) to automatically flow into a **second row** on narrow mobile screens, preventing them from being cut off.
- Styled the header to match the modern, card-based aesthetic of the `DenominationsScreen`.

### 2. Optimized Bottom Bar
- Updated `_buildBottomBar()` to detect mobile screen widths.
- On mobile, the action buttons (Add, Clear All, Draft, Save) now display in **two rows** instead of one.
    - **Row 1**: Add and Delete (Clear All) buttons.
    - **Row 2**: Draft and Save buttons.
- This ensures all button labels are fully visible and provide a larger touch target for mobile users.

### 3. Layout and Padding
- Wrapped the entire screen content in a `SafeArea` to handle device notches and system bars correctly.
- Adjusted main padding and spacing to ensure a comfortable fit on all screen sizes.
- Re-aligned the calendar accordion to appear correctly below the new custom header.

## Verification Results

### Manual Verification
- **Header**: Confirmed that icons wrap into multiple rows on narrow widths. All features remain accessible.
- **Bottom Bar**: Verified the two-row button layout on mobile view. Labels are no longer truncated.
- **Interactions**: All navigation and save actions work as expected with the new UI components.
