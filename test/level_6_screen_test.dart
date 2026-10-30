import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_shift/screens/level_6_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Quantum Boxes HUD fits a compact phone screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: Level6Screen()));
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('move-left')), findsOneWidget);
    expect(find.byKey(const ValueKey('jump')), findsOneWidget);
    expect(find.byKey(const ValueKey('switch-reality')), findsOneWidget);
  });

  testWidgets('Quantum Boxes solves, saves progress, and opens level 7', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'coins': 0, 'unlockedLevel': 6});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: Level6Screen()));
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.takeException(), isNull, reason: 'initial level layout');

    expect(find.text('QUANTUM BOXES'), findsOneWidget);
    expect(find.text('REALITY A · BLUE'), findsOneWidget);
    expect(
      find.text('Two realities. Two quantum boxes. One way out.'),
      findsOneWidget,
    );

    // Reach the blue box, push it to the lower step, then change worlds.
    await tester.tap(find.byKey(const ValueKey('move-right')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('move-right')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('push-box')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('push-box')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('switch-reality')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull, reason: 'Reality B layout');
    expect(find.text('REALITY B · PURPLE'), findsOneWidget);

    // Hop over the purple box and push it onto the blue one.
    await tester.tap(find.byKey(const ValueKey('move-left')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('jump')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('move-right')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('push-box')));
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'staircase layout');
    await tester.tap(find.byKey(const ValueKey('push-box')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('switch-reality')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('jump')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('jump')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('jump')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull, reason: 'completion layout');

    expect(find.text('LEVEL COMPLETE'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('level6Stars'), 3);
    expect(prefs.getInt('unlockedLevel'), 7);
    expect(prefs.getInt('coins'), 45);

    await tester.tap(find.byKey(const ValueKey('next-mission')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull, reason: 'next mission transition');
    expect(find.text('THE SHADOW THIEF'), findsOneWidget);
  });
}
