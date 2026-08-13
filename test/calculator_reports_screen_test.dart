import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ktppsflutter/reports/calculator_reports_screen.dart';

void main() {
  testWidgets('calculator report renders header', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CalculatorReportsScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Calculator Reports'), findsOneWidget);
  });
}

