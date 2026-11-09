import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reality_shift/screens/level_1_screen.dart';
import 'package:reality_shift/screens/level_2_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Level1 screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Level1Screen(),
      ),
    );

    expect(find.byType(Level1Screen), findsOneWidget);
  });

  testWidgets('Level 1 Next keeps the level menu available on Back', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const Level1Screen()),
              ),
              child: const Text('Select level 1'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Select level 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Put the moon inside an enlarged portal to open the completion dialog.
    final dynamic level = tester.state(find.byType(Level1Screen));
    level.portalScale = 1.7;
    level.moonPosition = (level.portalCenter as Offset) - const Offset(70, 70);
    level.checkCompletion();
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(find.text('NEXT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(Level2Screen), findsOneWidget);

    await tester.tap(find.byTooltip('Back to levels'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Select level 1'), findsOneWidget);
  });
}
