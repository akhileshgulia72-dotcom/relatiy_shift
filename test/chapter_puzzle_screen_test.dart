import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_shift/data/level_catalog.dart';
import 'package:reality_shift/screens/chapter_puzzle_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('each late-story level opens with its own mission title', (
    tester,
  ) async {
    for (var level = 9; level <= 20; level++) {
      await tester.pumpWidget(
        MaterialApp(home: ChapterPuzzleScreen(level: level)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      expect(
        find.text(storyForLevel(level).title.toUpperCase()),
        findsNWidgets(level == 12 ? 2 : 1),
        reason: 'Level $level should show its catalog title.',
      );
      final background = tester.widget<Image>(find.byType(Image).first);
      expect(
        (background.image as AssetImage).assetName,
        'assets/images/level${level.toString().padLeft(2, '0')}_'
        '${switch (level) {
          9 => 'echo',
          10 => 'mirror',
          11 => 'parallel_worlds',
          12 => 'time_freeze',
          13 => 'shattered_mirror',
          14 => 'signal',
          15 => 'liars',
          16 => 'dust',
          17 => 'reverse_time',
          18 => 'anchors',
          19 => 'quiet',
          _ => 'first_reality',
        }}_bg.png',
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('level 11 switches only on anchors and completes the route', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'unlockedLevel': 11, 'coins': 0});
    await tester.pumpWidget(
      const MaterialApp(home: ChapterPuzzleScreen(level: 11)),
    );
    await tester.pump(const Duration(milliseconds: 120));

    await tester.tap(find.byKey(const ValueKey('parallel-switch')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('0 / 8'), findsOneWidget);
    expect(
      find.text('You need a shared anchor platform to change dimensions.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('parallel-right')));
    await tester.pump(const Duration(milliseconds: 280));
    await tester.tap(find.byKey(const ValueKey('parallel-right')));
    await tester.pump(const Duration(milliseconds: 280));
    expect(find.text('2 / 8'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('parallel-up')));
    await tester.pump(const Duration(milliseconds: 280));
    expect(
      find.text('That platform is only solid in Purple World.'),
      findsOneWidget,
    );
    expect(find.text('2 / 8'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('parallel-switch')));
    await tester.pump(const Duration(milliseconds: 280));
    expect(find.text('2 / 8'), findsOneWidget);
    expect(find.text('PURPLE WORLD'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.refresh_rounded).last);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('0 / 8'), findsOneWidget);
    expect(find.text('BLUE WORLD'), findsOneWidget);

    const route = [
      'parallel-right',
      'parallel-right',
      'parallel-switch',
      'parallel-up',
      'parallel-right',
      'parallel-switch',
      'parallel-up',
      'parallel-right',
      'parallel-switch',
      'parallel-up',
      'parallel-right',
    ];
    for (final action in route) {
      await tester.tap(find.byKey(ValueKey(action)));
      await tester.pump(const Duration(milliseconds: 280));
    }
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('REALITY REPAIRED'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('level11Stars'), 3);
    expect(prefs.getInt('unlockedLevel'), 12);
  });

  testWidgets('level 12 freezes hazards, recharges, restarts and completes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'unlockedLevel': 12, 'coins': 0});
    await tester.pumpWidget(
      const MaterialApp(home: ChapterPuzzleScreen(level: 12)),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('TIME FREEZE'), findsNWidgets(2));
    expect(find.text('COOLDOWN'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('time-right')));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.byKey(const ValueKey('time-right')));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('0 / 9'), findsOneWidget);
    expect(
      find.text('Laser contact. Reset to the starting platform.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('time-freeze')));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('OBSTACLES SUSPENDED'), findsOneWidget);
    expect(find.textContaining('FROZEN'), findsNWidgets(3));

    // Player input remains live while the laser animation is stopped.
    await tester.tap(find.byKey(const ValueKey('time-right')));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('1 / 9'), findsOneWidget);
    final freezeButton = tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('time-freeze')),
    );
    expect(freezeButton.onPressed, isNull);

    await tester.pump(const Duration(milliseconds: 3000));
    expect(find.text('HAZARDS ACTIVE'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(const ValueKey('time-freeze')))
          .onPressed,
      isNull,
      reason: 'The ability remains on cooldown after the freeze expires.',
    );

    await tester.tap(find.byIcon(Icons.refresh_rounded).last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('0 / 9'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(const ValueKey('time-freeze')))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const ValueKey('time-freeze')));
    await tester.pump(const Duration(milliseconds: 50));
    const route = [
      'time-right',
      'time-right',
      'time-up',
      'time-right',
      'time-up',
      'time-right',
      'time-up',
      'time-right',
      'time-up',
    ];
    for (final action in route) {
      await tester.tap(find.byKey(ValueKey(action)));
      await tester.pump(const Duration(milliseconds: 45));
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('REALITY REPAIRED'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('level12Stars'), 3);
    expect(prefs.getInt('unlockedLevel'), 13);
  });

  testWidgets('level 13 reflects the beam, opens the bridge and completes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'unlockedLevel': 13, 'coins': 0});
    await tester.pumpWidget(
      const MaterialApp(home: ChapterPuzzleScreen(level: 13)),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('THE SHATTERED MIRROR'), findsOneWidget);
    expect(find.byKey(const ValueKey('mirror-emitter')), findsOneWidget);
    expect(find.byKey(const ValueKey('mirror-portal')), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      expect(find.byKey(ValueKey('mirror-$i')), findsOneWidget);
    }

    await tester.tap(find.byKey(const ValueKey('mirror-0')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('RECEIVERS 1 / 3'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.refresh_rounded).last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('RECEIVERS 0 / 3'), findsOneWidget);

    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byKey(ValueKey('mirror-$i')));
      await tester.pump(const Duration(milliseconds: 280));
    }
    expect(find.text('RECEIVERS 3 / 3'), findsOneWidget);
    expect(find.text('BRIDGE OPEN'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mirror-portal')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('REALITY REPAIRED'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('level13Stars'), 3);
    expect(prefs.getInt('unlockedLevel'), 14);
  });
}
