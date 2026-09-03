# Fix Excel Parsing on Web (TypeError: null is not a subtype of JSObject)

The error `TypeError: null: type 'Null' is not a subtype of type 'JSObject'` occurs in `cashew_import_web_helper.dart` when a JavaScript interop call returns `null` or `undefined` and is explicitly cast to a non-nullable `JSObject` or its subtypes.

## Proposed Changes

### [Cashew Component]

#### [MODIFY] [cashew_import_web_helper.dart](file:///Users/kalyanthammineni/Downloads/ktdata405/ktapps-flutter-new/lib/cashew/cashew_import_web_helper.dart)
- Update `_xlsxGlobal` to be nullable (`JSAny?`).
- Use nullable return types in extensions for SheetJS interop.
- Replace explicit `as JSObject` or `as JSArray` casts with safe property access and null checks.
- Use extensions more effectively to avoid `getProperty` and `callMethod` where possible.
- Add error logging if the XLSX library is not found.

## Verification Plan

### Manual Verification
- Run the Flutter app on Web.
- Navigate to the Import Excel screen.
- Upload an Excel file.
- Verify that the file is parsed correctly without the `JSObject` error.
