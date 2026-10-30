import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_shift/screens/level_5_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('gravity puzzle can be completed with the touch fallback', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'coins': 0, 'unlockedLevel': 5});
    await tester.pumpWidget(const MaterialApp(home: Level5Screen()));
    await tester.pump();

    expect(find.text('Bring the astronaut to the planet.'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.lightbulb_outline_rounded));
    await tester.pump();
    expect(
      find.textContaining('Maybe your phone knows which way is down.'),
      findsOneWidget,
    );

    await tester.tap(find.text('REVERSE GRAVITY'));
    await tester.pump();
    expect(find.text('GRAVITY REVERSED'), findsNothing);

    final boots = tester.getRect(find.byKey(const ValueKey('astronaut-boots')));
    await tester.tapAt(Offset(boots.center.dx, boots.top + boots.height * .86));
    await tester.pump();
    expect(
      find.text('Mag-lock released. Now reverse gravity.'),
      findsOneWidget,
    );

    await tester.tap(find.text('REVERSE GRAVITY'));
    await tester.pump();
    expect(find.text('GRAVITY REVERSED'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pump();
    expect(
      find.text('Bro discovered gravity before physics class 💀'),
      findsOneWidget,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('coins'), 45);
    expect(prefs.getInt('level5Stars'), 3);
    expect(prefs.getInt('unlockedLevel'), 6);
  });
}
