import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ktppsflutter/reports/debts_reports_screen.dart';

void main() {
  testWidgets('debts report screen renders header', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DebtsReportsScreen()),
    );

    await tester.pumpAndSettle();

    expect(find.text('Debts Intelligence'), findsOneWidget);
  });
}

