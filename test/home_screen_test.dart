import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_shift/screens/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home menu keeps discovery, settings, and play without a shop', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'coins': 90,
      'hapticsEnabled': false,
    });

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('90'), findsOneWidget);
    expect(find.text('REALITY SHIFT'), findsOneWidget);
    expect(find.text('YOUR JOURNEY'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-play')), findsOneWidget);
    expect(find.text('SHOP'), findsNothing);
    expect(find.text('STORY'), findsOneWidget);
    expect(find.text('ACHIEVEMENTS'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);

    await tester.tap(find.text('STORY'));
    await tester.pumpAndSettle();
    expect(find.text('A WORLD OUT OF PLACE'), findsOneWidget);
    await tester.tap(find.text('CLOSE'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('coins'), 90);
    expect(tester.takeException(), isNull);
  });
}
