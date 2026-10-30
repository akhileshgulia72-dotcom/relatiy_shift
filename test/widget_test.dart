import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reality_shift/screens/level_1_screen.dart';

void main() {
  testWidgets('Level1 screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Level1Screen(),
      ),
    );

    expect(find.byType(Level1Screen), findsOneWidget);
  });
}