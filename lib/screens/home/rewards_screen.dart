import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/level_catalog.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  static const _badges = [
    ('First Spark', 'Complete 5 levels', Icons.bolt_rounded, Color(0xFF7DEBFF)),
    (
      'Star Voyager',
      'Complete 10 levels',
      Icons.stars_rounded,
      Color(0xFFFFD17A),
    ),
    (
      'Realm Keeper',
      'Complete 15 levels',
      Icons.shield_rounded,
      Color(0xFFC9A1FF),
    ),
    (
      'Reality Guardian',
      'Complete 20 levels',
      Icons.workspace_premium_rounded,
      Color(0xFFFF92CB),
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF070B1A),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0C1428),
      title: const Text(
        'REWARDS & BADGES',
        style: TextStyle(fontSize: 17, letterSpacing: 1.4),
      ),
    ),
    body: DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/starfield_purple_sky.png'),
          fit: BoxFit.cover,
          opacity: .35,
        ),
      ),
      child: SafeArea(
        child: FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, snapshot) {
            final prefs = snapshot.data;
            final completed = Iterable<int>.generate(levelStories.length)
                .where(
                  (index) => (prefs?.getInt('level${index + 1}Stars') ?? 0) > 0,
                )
                .length;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                const Text(
                  'YOUR ACHIEVEMENTS',
                  style: TextStyle(
                    color: Color(0xFF80E5FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$completed of ${levelStories.length} levels completed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: completed / levelStories.length,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF27334D),
                    color: const Color(0xFF75E5FF),
                  ),
                ),
                const SizedBox(height: 20),
                for (var index = 0; index < _badges.length; index++) ...[
                  _badge(index, completed),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF302254), Color(0xFF12233D)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: const Color(0x887DC8FF)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x443E89D9), blurRadius: 28),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.card_giftcard_rounded,
                        color: Color(0xFFFFD182),
                        size: 42,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'STAY TUNED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.6,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'More prizes and gifts are on their way. For now, every restored reality brings you closer to your next badge.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFD4D8F0), height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 27),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Your story is still unfolding. Keep exploring. ✨',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFBEB8DF), height: 1.4),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );

  Widget _badge(int index, int completed) {
    final badge = _badges[index];
    final target = (index + 1) * 5;
    final earned = completed >= target;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: earned ? const Color(0xE8212B47) : const Color(0xD910192C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: earned ? badge.$4.withValues(alpha: .65) : Colors.white12,
        ),
        boxShadow: earned
            ? [
                BoxShadow(
                  color: badge.$4.withValues(alpha: .16),
                  blurRadius: 20,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: earned ? badge.$4.withValues(alpha: .18) : Colors.white10,
              border: Border.all(
                color: earned ? badge.$4 : Colors.white24,
                width: 2,
              ),
            ),
            child: Icon(
              earned ? badge.$3 : Icons.lock_outline_rounded,
              color: earned ? badge.$4 : Colors.white38,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.$1,
                  style: TextStyle(
                    color: earned ? Colors.white : Colors.white54,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  badge.$2,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            earned ? 'EARNED' : '$completed/$target',
            style: TextStyle(
              color: earned ? badge.$4 : Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
