import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_shift/screens/level_2_screen.dart';
import 'package:reality_shift/screens/level_3_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sun swipe reveals Deimos, completes, teaches, and continues', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'unlockedLevel': 2});
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: Level2Screen()));
    await tester.pump();
    expect(
      find.text(
        'Something is hidden in the darkness. Swipe the Sun away to reveal it.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('level2-sun')), findsOneWidget);
    expect(find.byKey(const ValueKey('level2-fact-card')), findsNothing);
    expect(find.text('Deimos'), findsNothing);

    await tester.timedDrag(
      find.byKey(const ValueKey('level2-sun')),
      const Offset(200, 0),
      const Duration(milliseconds: 600),
    );
    await tester.pump();
    expect(find.text('A SECOND ORBIT AWAKENS…'), findsOneWidget);
    expect(find.byKey(const ValueKey('level2-fact-card')), findsNothing);

    await tester.pump(const Duration(milliseconds: 2900));
    await tester.pump();
    expect(find.text('LEVEL COMPLETE!'), findsOneWidget);
    expect(find.byKey(const ValueKey('level2-fact-card')), findsOneWidget);
    expect(find.text('MARS HAS TWO MOONS! 🔴'), findsOneWidget);
    expect(find.textContaining('Phobos'), findsNWidgets(2));
    expect(find.textContaining('Deimos'), findsNWidgets(2));
    expect(find.textContaining('Earth has one natural moon'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('level2Stars'), 3);
    expect(prefs.getInt('unlockedLevel'), 3);

    final continueButton = find.byKey(const ValueKey('level2-continue'));
    await tester.ensureVisible(continueButton);
    tester.widget<FilledButton>(continueButton).onPressed!.call();
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(find.byType(Level3Screen, skipOffstage: false), findsOneWidget);
    expect(
      find.text('SHADOW CONSTELLATION', skipOffstage: false),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
