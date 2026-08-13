import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ktppsflutter/main.dart';

void main() {
  testWidgets('app boots and renders primary shell', (tester) async {
    await tester.pumpWidget(const KTAppsApp());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
