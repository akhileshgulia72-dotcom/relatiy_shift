import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/menu_music_service.dart';

import '../../data/level_catalog.dart';
import '../level/level_screen.dart';
import 'worlds_screen.dart';
import 'rewards_screen.dart';

const _midnight = Color(0xFF070A18);
const _violet = Color(0xFFA779FF);
const _electric = Color(0xFF7B43FF);
const _cyan = Color(0xFF73E7FF);
const _gold = Color(0xFFFFC95F);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with MenuMusicRoute<HomeScreen> {
  int _coins = 0;
  int _stars = 0;
  int _completed = 0;
  int _unlockedLevel = 1;

  int get _currentLevel => _unlockedLevel.clamp(1, levelStories.length).toInt();
  LevelStory get _currentStory => storyForLevel(_currentLevel);

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  Future<void> _refreshStats() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    var stars = 0;
    var completed = 0;
    for (var level = 1; level <= levelStories.length; level++) {
      final earned = prefs.getInt('level${level}Stars') ?? 0;
      stars += earned;
      if (earned > 0) completed++;
    }
    setState(() {
      _coins = prefs.getInt('coins') ?? 0;
      _stars = stars;
      _completed = completed;
      _unlockedLevel = prefs.getInt('unlockedLevel') ?? 1;
    });
  }

  Future<void> _openArchive() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LevelScreen()),
    );
    _refreshStats();
  }

  Future<void> _continueJourney() async {
    final page = campaignPageForLevel(_currentLevel);
    if (page == null) {
      await _openArchive();
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _refreshStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _midnight,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/home_first_shift_hero.png',
            fit: BoxFit.cover,
            alignment: const Alignment(.12, -.12),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, .19, .34, .49, .68, 1],
                colors: [
                  Color(0x99030817),
                  Color(0x53030817),
                  Color(0x99030817),
                  Color(0xE9070918),
                  Color(0xF3070918),
                  Color(0xFF050713),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 116),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(constraints.maxWidth),
                      SizedBox(
                        height: (constraints.maxHeight * .085).clamp(48, 86),
                      ),
                      _hero(),
                      const SizedBox(height: 14),
                      _continueButton(),
                      const SizedBox(height: 23),
                      _quickActions(),
                      const SizedBox(height: 17),
                      _nextMissionCard(),
                      const SizedBox(height: 14),
                      _progressCard(),
                      const SizedBox(height: 14),
                      _archiveCard(),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'REALITY SHIFT  •  CHAPTER ${_currentStory.chapter.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .38),
                            fontSize: 9,
                            letterSpacing: 1.15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _bottomNavigation(),
        ],
      ),
    );
  }

  Widget _header(double availableWidth) {
    final compact = availableWidth < 370;
    return Row(
      children: [
        Expanded(child: _brandLockup(compact: compact)),
        const SizedBox(width: 5),
        _balancePill(
          icon: Icons.diamond_rounded,
          value: _coins,
          color: const Color(0xFF83C8FF),
          compact: compact,
          onTap: _showCurrencyInfo,
        ),
        const SizedBox(width: 5),
        _balancePill(
          icon: Icons.star_rounded,
          value: _stars,
          color: _gold,
          compact: compact,
          onTap: _showCurrencyInfo,
        ),
        const SizedBox(width: 5),
        _roundIconButton(
          Icons.settings_rounded,
          _showSettings,
          key: const ValueKey('home-settings'),
        ),
      ],
    );
  }

  Widget _brandLockup({required bool compact}) => Row(
    children: [
      Container(
        width: compact ? 32 : 39,
        height: compact ? 36 : 43,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF77E8FF), Color(0xFF9D59FF), Color(0xFF4D32CE)],
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x667B43FF), blurRadius: 17),
          ],
        ),
        child: Icon(
          Icons.change_history_rounded,
          color: Colors.white,
          size: compact ? 25 : 31,
        ),
      ),
      SizedBox(width: compact ? 6 : 9),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'REALITY\nSHIFT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 10 : 15,
                  height: .91,
                  fontWeight: FontWeight.w900,
                  letterSpacing: compact ? 1.25 : 2,
                ),
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 5),
              const Text(
                'EXPLORE  •  SOLVE  •  TRANSCEND',
                maxLines: 1,
                style: TextStyle(
                  color: Color(0xFFBDB9E8),
                  fontSize: 7,
                  letterSpacing: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );

  Widget _balancePill({
    required IconData icon,
    required int value,
    required Color color,
    required bool compact,
    required VoidCallback onTap,
  }) => Material(
    color: const Color(0xB90A1024),
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minWidth: compact ? 43 : 62),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: .28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: compact ? 16 : 18),
            const SizedBox(width: 4),
            Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.add_rounded,
                color: Colors.white.withValues(alpha: .78),
                size: 15,
              ),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _hero() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'CHAPTER ${_currentStory.chapter}',
        style: const TextStyle(
          color: _violet,
          fontSize: 11,
          letterSpacing: 3,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 11),
      const Text(
        'THE FIRST\nSHIFT',
        style: TextStyle(
          color: Colors.white,
          fontSize: 39,
          height: .99,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.3,
          shadows: [Shadow(color: Color(0xBB050713), blurRadius: 22)],
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Step into a new reality.\nSolve puzzles, unlock worlds\nand discover what’s beyond.',
        style: TextStyle(
          color: Color(0xFFE1E3F3),
          fontSize: 14,
          height: 1.45,
          letterSpacing: .15,
          shadows: [Shadow(color: Color(0xE6050713), blurRadius: 12)],
        ),
      ),
    ],
  );

  Widget _continueButton() => Material(
    color: Colors.transparent,
    child: InkWell(
      key: const ValueKey('home-play'),
      borderRadius: BorderRadius.circular(19),
      onTap: _continueJourney,
      child: Ink(
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFAC55FF), Color(0xFF712AFF), Color(0xFF35149D)],
          ),
          border: Border.all(color: const Color(0xFFDCB4FF), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x886D27FF),
              blurRadius: 25,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 30,
              ),
              const SizedBox(width: 7),
              const Text(
                'CONTINUE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 37, color: Colors.white24),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LEVEL $_currentLevel',
                      style: const TextStyle(
                        color: Color(0xFFDCCBFF),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .7,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _currentStory.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFD7B7FF),
                size: 26,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _quickActions() => Row(
    children: [
      Expanded(
        child: _quickCard(
          'LEVELS',
          '20 realities',
          Icons.view_in_ar_rounded,
          const Color(0xFF8AAEFF),
          _openArchive,
        ),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: _quickCard(
          'WORLDS',
          '1 universe',
          Icons.public_rounded,
          const Color(0xFFB18CFF),
          _openWorlds,
        ),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: _quickCard(
          'ACHIEVEMENTS',
          'Your wins',
          Icons.adjust_rounded,
          const Color(0xFFC65FFF),
          _showAchievements,
        ),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: _quickCard(
          'SETTINGS',
          'Preferences',
          Icons.gamepad_rounded,
          const Color(0xFF8AAEFF),
          _showSettings,
        ),
      ),
    ],
  );

  Widget _quickCard(
    String title,
    String subtitle,
    IconData icon,
    Color accent,
    VoidCallback onTap,
  ) => Material(
    color: const Color(0xE90A1022),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 104,
        padding: const EdgeInsets.fromLTRB(4, 11, 4, 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: .34)),
          boxShadow: const [
            BoxShadow(color: Color(0x22030816), blurRadius: 12),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 27),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .35,
                ),
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                subtitle,
                style: const TextStyle(color: Color(0xFFB5BED5), fontSize: 7.5),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _nextMissionCard() => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xED0B1021),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0x553F5E9B)),
      boxShadow: const [BoxShadow(color: Color(0x3D000000), blurRadius: 18)],
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Icon(Icons.bolt_rounded, color: _gold, size: 19),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'NEXT REALITY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .9,
                ),
              ),
            ),
            Text(
              'LEVEL ${_currentLevel.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Color(0xFFB8C6E5),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.asset(
                'assets/images/home_quantum_cube.png',
                width: 94,
                height: 88,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentStory.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentStory.teaser,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFBEC8DD),
                      fontSize: 10,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _continueJourney,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'PLAY NOW',
                          style: TextStyle(
                            color: _violet,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .7,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: _violet,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _progressCard() {
    final progress = _completed / levelStories.length;
    final percent = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xEB0A1021),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x443E5B9F)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _ProgressRingPainter(progress),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'COMPLETE',
                    style: TextStyle(
                      color: Color(0xFFB8C1D7),
                      fontSize: 7,
                      letterSpacing: .45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'YOUR JOURNEY',
                        style: TextStyle(
                          color: Color(0xFFB9B9FF),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .7,
                        ),
                      ),
                    ),
                    Text(
                      '$_completed / ${levelStories.length}',
                      style: const TextStyle(
                        color: Color(0xFFE0E5F5),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '$_completed / ${levelStories.length} levels restored',
                  style: const TextStyle(
                    color: Color(0xFFB9C3D8),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 11),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: const Color(0xFF141B31),
                    valueColor: const AlwaysStoppedAnimation(_electric),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _openArchive,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'VIEW ARCHIVE',
                        style: TextStyle(
                          color: _violet,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .6,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: _violet,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _archiveCard() => Container(
    height: 192,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFFFC44F), width: 1.4),
      boxShadow: const [BoxShadow(color: Color(0x44FFBB46), blurRadius: 17)],
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/home_observatory.png', fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xF2070B17), Color(0xD9070B17), Color(0x53070B17)],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 13, 15, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: _gold, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'THE REALITY ARCHIVE',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Twenty worlds. One story waiting to unfold.',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
              const Spacer(),
              _archiveBenefit(
                Icons.all_inclusive_rounded,
                '4 chapters to explore',
              ),
              const SizedBox(height: 5),
              _archiveBenefit(
                Icons.stars_rounded,
                'Earn stars and crystals as you play',
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: _goldButton('EXPLORE ARCHIVE', _showStory),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _archiveBenefit(IconData icon, String label) => Row(
    children: [
      Icon(icon, size: 15, color: _gold),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  Widget _goldButton(String label, VoidCallback onTap) => Material(
    color: const Color(0xD91A160B),
    borderRadius: BorderRadius.circular(99),
    child: InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: _gold, width: 1.2),
          boxShadow: const [
            BoxShadow(color: Color(0x55FFC95F), blurRadius: 14),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.explore_rounded, color: _gold, size: 15),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: .5,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right_rounded, color: _gold, size: 16),
          ],
        ),
      ),
    ),
  );

  Widget _bottomNavigation() => Positioned(
    left: 12,
    right: 12,
    bottom: 5,
    child: SafeArea(
      top: false,
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xF00B1023),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: const Color(0x664F50A0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0xCC030613),
              blurRadius: 22,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            _navItem(Icons.home_rounded, 'Home', selected: true, onTap: () {}),
            _navItem(Icons.view_in_ar_rounded, 'Levels', onTap: _openArchive),
            _navItem(Icons.public_rounded, 'Worlds', onTap: _openWorlds),
            _navItem(
              Icons.card_giftcard_rounded,
              'Rewards',
              onTap: _openRewards,
            ),
            _navItem(
              Icons.workspace_premium_outlined,
              'Badges',
              onTap: _openRewards,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _navItem(
    IconData icon,
    String label, {
    bool selected = false,
    required VoidCallback onTap,
  }) => Expanded(
    child: Material(
      color: selected ? const Color(0x332E1B74) : Colors.transparent,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: SizedBox(
          height: 59,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? _violet : const Color(0xFFB8BDE0),
                size: 21,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFFC2C8E0),
                  fontSize: 9,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _roundIconButton(IconData icon, VoidCallback onTap, {Key? key}) =>
      Material(
        color: const Color(0xC50A1024),
        shape: const CircleBorder(),
        child: InkWell(
          key: key,
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      );

  void _showCurrencyInfo() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF10172B),
        title: const Text(
          'MISSION REWARDS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Complete realities to earn crystals and stars. Your current balance is $_coins crystals and $_stars stars.',
          style: const TextStyle(color: Color(0xFFD0D7E9), height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('GOT IT'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _openArchive();
            },
            child: const Text('VIEW LEVELS'),
          ),
        ],
      ),
    );
  }

  void _showStory() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF11182D),
        title: const Text(
          'A WORLD OUT OF PLACE',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reality has fractured into twenty memories. Solve the strange rules hidden in each one, recover the fragments, and discover what broke the first world.',
                style: TextStyle(color: Colors.white70, height: 1.45),
              ),
              const SizedBox(height: 15),
              for (var chapter = 1; chapter <= 4; chapter++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 15,
                        color: storyForLevel((chapter - 1) * 5 + 1).accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          storyForLevel((chapter - 1) * 5 + 1).chapterTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            letterSpacing: .6,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '0$chapter',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CLOSE'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _openArchive();
            },
            child: const Text('OPEN STORY MAP'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    var hapticsEnabled = prefs.getBool('hapticsEnabled') ?? true;
    var musicEnabled = MenuMusicService.instance.enabled;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF11182D),
          title: const Text(
            'GAME SETTINGS',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Menu haptics',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'A light tap when using the home controls.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                value: hapticsEnabled,
                activeThumbColor: _cyan,
                onChanged: (value) async {
                  setDialogState(() => hapticsEnabled = value);
                  await prefs.setBool('hapticsEnabled', value);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Background music',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Play on opening and level selection screens.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                value: musicEnabled,
                activeThumbColor: _cyan,
                onChanged: (value) async {
                  setDialogState(() => musicEnabled = value);
                  await MenuMusicService.instance.setEnabled(value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('DONE'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAchievements() {
    _openRewards();
  }

  void _openWorlds() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const WorldsScreen()),
  );

  void _openRewards() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const RewardsScreen()),
  );
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.shortestSide / 2 - 5;
    final track = Paint()
      ..color = const Color(0xFF293252)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    if (progress <= 0) return;
    final progressPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [Color(0xFF7A35FF), Color(0xFFD04BFF)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0).toDouble(),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
