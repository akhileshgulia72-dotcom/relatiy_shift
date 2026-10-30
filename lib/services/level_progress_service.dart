import 'package:shared_preferences/shared_preferences.dart';

/// Owns persistent completion state for the story missions.
///
/// Completion is idempotent: replaying a cleared mission can improve its star
/// rating, but cannot award the first-clear currency a second time.
class LevelProgressService {
  const LevelProgressService._();

  static Future<void> complete({
    required int level,
    required int stars,
    int coinsPerStar = 15,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final starsKey = 'level${level}Stars';
    final previousStars = prefs.getInt(starsKey) ?? 0;
    final bestStars = stars > previousStars ? stars : previousStars;

    final firstClear = previousStars == 0;
    if (firstClear) {
      final coins = prefs.getInt('coins') ?? 0;
      await prefs.setInt('coins', coins + stars * coinsPerStar);
    }

    await prefs.setInt(starsKey, bestStars);
    final unlockedLevel = prefs.getInt('unlockedLevel') ?? 1;
    if (unlockedLevel < level + 1) {
      await prefs.setInt('unlockedLevel', level + 1);
    }
  }

  /// A rewarded skip unlocks the next coordinate without marking the current
  /// puzzle as a normal clear or awarding normal-clear currency/stars.
  static Future<void> skip({required int level}) async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedLevel = prefs.getInt('unlockedLevel') ?? 1;
    if (unlockedLevel <= level) {
      await prefs.setInt('unlockedLevel', level + 1);
    }
  }
}
