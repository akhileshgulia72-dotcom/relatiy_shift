import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_shift/screens/advanced_puzzle_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> mount(WidgetTester tester, int level) async {
    SharedPreferences.setMockInitialValues({
      'coins': 0,
      'unlockedLevel': level,
    });
    await tester.pumpWidget(
      MaterialApp(home: AdvancedPuzzleScreen(level: level)),
    );
    await tester.pump();
  }

  testWidgets('missions 7–10 render their own campaign screens', (
    tester,
  ) async {
    const titles = [
      'THE SHADOW THIEF',
      'THE GRAVITY THIEF',
      'THE DISAPPEARING BRIDGE',
      'THE BROKEN MOON FINALE',
    ];
    for (var i = 0; i < titles.length; i++) {
      await mount(tester, i + 7);
      expect(find.text(titles[i]), findsOneWidget);
      expect(find.byKey(const ValueKey('puzzle-board')), findsOneWidget);
    }
  });

  testWidgets('level 7 shadow sequence grants the reward and unlocks 8', (
    tester,
  ) async {
    await mount(tester, 7);
    final boardWidth = tester
        .getSize(find.byKey(const ValueKey('puzzle-board')))
        .width;

    await tester.drag(
      find.byKey(const ValueKey('shadow-light')),
      Offset(-boardWidth * .58, 0),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('CAGE OPEN'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('shadow-cage')));
    await tester.pump();

    await tester.drag(
      find.byKey(const ValueKey('shadow-light')),
      Offset(boardWidth * .535, 0),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('shadow-exit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('THE SHADOW THIEF'), findsOneWidget);
    expect(find.text('NEXT MISSION'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('level7Stars'), 3);
    expect(prefs.getInt('unlockedLevel'), 8);
  });

  testWidgets('level 9 bridge route reaches the exit and unlocks 10', (
    tester,
  ) async {
    await mount(tester, 9);
    const steps = [
      'bridge-right',
      'bridge-up',
      'bridge-right',
      'bridge-right',
      'bridge-up',
      'bridge-right',
      'bridge-up',
      'bridge-right',
      'bridge-up',
    ];
    for (final step in steps) {
      await tester.tap(find.byKey(ValueKey(step)));
      await tester.pump(const Duration(milliseconds: 240));
    }
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('NEXT MISSION'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('level9Stars'), 3);
    expect(prefs.getInt('unlockedLevel'), 10);
  });

  testWidgets('level 8 gravity route reaches the landing and unlocks 9', (
    tester,
  ) async {
    await mount(tester, 8);
    Future<void> advancePhysics() async {
      for (var i = 0; i < 180; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    await advancePhysics();
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(const ValueKey('gravity-shift')));
      await tester.pump();
      await advancePhysics();
    }

    expect(find.text('NEXT MISSION'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('level8Stars'), 3);
    expect(prefs.getInt('unlockedLevel'), 9);
  });

  testWidgets('level 10 pinch-compatible portal slider and route complete', (
    tester,
  ) async {
    await mount(tester, 10);
    final portalCenter = tester.getCenter(
      find.byKey(const ValueKey('moon-portal')),
    );
    final firstFinger = await tester.startGesture(
      portalCenter.translate(-20, 0),
      pointer: 1,
    );
    final secondFinger = await tester.startGesture(
      portalCenter.translate(20, 0),
      pointer: 2,
    );
    await firstFinger.moveBy(const Offset(-25, 0));
    await secondFinger.moveBy(const Offset(25, 0));
    await tester.pump();
    await firstFinger.up();
    await secondFinger.up();
    await tester.pump();
    expect(find.text('MOON FITS'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('portal-slider')));
    await tester.drag(
      find.byKey(const ValueKey('portal-slider')),
      const Offset(250, 0),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('moon-rotate')));
    await tester.pump(const Duration(milliseconds: 350));
    final boardWidth = tester
        .getSize(find.byKey(const ValueKey('puzzle-board')))
        .width;
    await tester.drag(
      find.byKey(const ValueKey('moon')),
      Offset(boardWidth * .14, 0),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await tester.tap(find.byKey(const ValueKey('moon-send')));
    await tester.pump(const Duration(milliseconds: 950));
    await tester.pump();

    expect(find.text('REALITY REWRITTEN'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('level10Stars'), 3);
    expect(prefs.getInt('unlockedLevel'), 11);
  });
}
