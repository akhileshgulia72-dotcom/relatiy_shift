import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_shift/core/widget/campaign_monetization_controls.dart';
import 'package:reality_shift/screens/level/level_screen.dart';
import 'package:reality_shift/screens/chapter_puzzle_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reality_shift/screens/level_15_screen.dart';
import 'package:reality_shift/screens/level_16_screen.dart';
import 'package:reality_shift/screens/privacy_policy_screen.dart';

void main() {
  test('campaign routes select the current levels after level 14', () {
    expect(campaignPageForLevel(15), isA<Level15Screen>());
    expect(campaignPageForLevel(16), isA<Level16Screen>());
  });

  testWidgets(
    'level 14 shows completion and continues to the current level 15',
    (tester) async {
      SharedPreferences.setMockInitialValues({'unlockedLevel': 14});
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: ChapterPuzzleScreen(level: 14)),
      );
      Future<void> tapKey(String key) async {
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 200));
      }

      await tapKey('anchor-0');
      await tapKey('switch-1');
      await tester.tap(find.text('MAGENTA').last);
      await tester.pump();
      await tapKey('anchor-4');
      await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
      await tester.pump(const Duration(milliseconds: 200));
      await tapKey('anchor-1');
      await tapKey('switch-2');
      await tester.tap(find.text('CYAN').last);
      await tester.pump();
      await tapKey('anchor-5');
      await tester.tap(find.byIcon(Icons.arrow_downward_rounded).last);
      await tester.pump(const Duration(milliseconds: 200));
      await tapKey('anchor-4');
      await tapKey('switch-3');
      await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
      await tester.pump(const Duration(milliseconds: 300));
      await tapKey('exit-gateway');
      expect(find.text('CONGRATULATIONS!'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('unlockedLevel'), 15);
      await tester.runAsync(() async {
        await tester.tap(find.text('NEXT REALITY'));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Level15Screen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('skip remains hidden when a hint ad is unavailable', (
    tester,
  ) async {
    var hints = 0;
    var skips = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CampaignMonetizationControls(
            level: 14,
            onHint: () => hints++,
            onSkipped: () => skips++,
          ),
        ),
      ),
    );
    expect(find.text('SKIP'), findsNothing);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(find.text('SKIP'), findsNothing);
    expect(hints, 0);
    expect(skips, 0);
    expect(find.text('Reward ad unavailable. Keep playing!'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('privacy details are readable in the app with an online link', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));
    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('Information handled by the Game'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Open online policy'), 400);
    expect(find.text(privacyPolicyUrl), findsOneWidget);
    expect(find.text('Open online policy'), findsOneWidget);
  });
}
