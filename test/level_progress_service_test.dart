import 'package:flutter_test/flutter_test.dart';
import 'package:reality_shift/services/level_progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('first clear awards currency once and unlocks the next level', () async {
    await LevelProgressService.complete(level: 7, stars: 2);
    await LevelProgressService.complete(level: 7, stars: 3);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('coins'), 30);
    expect(prefs.getInt('level7Stars'), 3);
    expect(prefs.getInt('unlockedLevel'), 8);
  });

  test(
    'existing stars do not receive replay currency or lose progress',
    () async {
      SharedPreferences.setMockInitialValues({
        'coins': 90,
        'unlockedLevel': 12,
        'level6Stars': 2,
      });

      await LevelProgressService.complete(level: 6, stars: 1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('coins'), 90);
      expect(prefs.getInt('level6Stars'), 2);
      expect(prefs.getInt('unlockedLevel'), 12);
    },
  );
}
