import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reality_shift/screens/level_15_screen.dart';
import 'package:reality_shift/screens/level_16_screen.dart';
import 'package:reality_shift/screens/level_17_screen.dart';
import 'package:reality_shift/screens/level_18_screen.dart';
import 'package:reality_shift/screens/level_19_screen.dart';
import 'package:reality_shift/screens/level_20_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reality_shift/screens/level_1_screen.dart';
import 'package:reality_shift/screens/level_2_screen.dart';
import 'package:reality_shift/screens/level_3_screen.dart';
import 'package:reality_shift/screens/chapter_puzzle_screen.dart';
import 'package:reality_shift/screens/advanced_puzzle_screen.dart';
import 'package:reality_shift/screens/level_4_screen.dart';
import 'package:reality_shift/screens/level_5_screen.dart';
import 'package:reality_shift/screens/level_6_screen.dart';

import '../../data/level_catalog.dart';
import '../../data/levels.dart';
import 'level_title.dart';
import '../../services/menu_music_service.dart';

Widget? campaignPageForLevel(int levelId) => switch (levelId) {
  1 => const Level1Screen(),
  2 => const Level2Screen(),
  3 => const Level3Screen(),
  4 => const Level4Screen(),
  5 => const Level5Screen(),
  6 => const Level6Screen(),
  17 => const Level17Screen(),
  18 => const Level18Screen(),
  19 => const Level19Screen(),
  20 => const Level20Screen(),
  >= 7 && <= 10 => AdvancedPuzzleScreen(level: levelId),
  15 => const Level15Screen(),
  16 => const Level16Screen(),
  >= 11 && <= 20 => ChapterPuzzleScreen(level: levelId),
  _ => null,
};

class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen>
    with MenuMusicRoute<LevelScreen> {
  int unlockedLevel = 1;
  int coins = 0;
  Map<int, int> starsByLevel = const {};
  int _selectedChapterFilter = 0; // 0 = All Chapters, 1..4 = Specific Chapter

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      coins = prefs.getInt('coins') ?? 0;
      unlockedLevel = prefs.getInt('unlockedLevel') ?? 1;
      starsByLevel = {
        for (final level in chapter1)
          level.id: prefs.getInt('level${level.id}Stars') ?? 0,
      };
    });
  }

  int get totalStars =>
      starsByLevel.values.fold<int>(0, (sum, stars) => sum + stars);

  int get completedRealities =>
      starsByLevel.values.where((stars) => stars > 0).length;

  int get currentTargetLevel =>
      unlockedLevel.clamp(1, levelStories.length).toInt();

  void openLevel(int levelId) {
    if (levelId > unlockedLevel) {
      _showLockedSheet(levelId);
      return;
    }

    _showMissionBriefingSheet(levelId);
  }

  void _launchLevelScreen(int levelId) {
    final page = campaignPageForLevel(levelId);
    if (page == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) => loadProgress());
  }

  void _showMissionBriefingSheet(int levelId) {
    final story = storyForLevel(levelId);
    final earnedStars = starsByLevel[levelId] ?? 0;
    final isCurrent = levelId == unlockedLevel;
    final isCompleted = earnedStars > 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 34),
          decoration: BoxDecoration(
            color: const Color(0xF4090F1C),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: story.accent.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: story.accent.withValues(alpha: 0.22),
                blurRadius: 36,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle Pill
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header: Chapter, Status Pill, Icon
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          story.accent.withValues(alpha: 0.35),
                          const Color(0xFF131D33),
                        ],
                      ),
                      border: Border.all(
                        color: story.accent.withValues(alpha: 0.7),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: story.accent.withValues(alpha: 0.3),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Icon(story.icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'REALITY #${levelId.toString().padLeft(2, '0')}',
                              style: GoogleFonts.orbitron(
                                color: story.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? const Color(0x224CD69B)
                                    : story.accent.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isCompleted
                                      ? const Color(0xFF4CD69B)
                                      : story.accent.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                isCompleted
                                    ? 'STABILIZED'
                                    : (isCurrent
                                          ? 'ACTIVE TARGET'
                                          : 'UNLOCKED'),
                                style: GoogleFonts.orbitron(
                                  color: isCompleted
                                      ? const Color(0xFF4CD69B)
                                      : story.accent,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          story.title,
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Lore Teaser Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0x66111A2D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: story.accent.withValues(alpha: 0.8),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        story.teaser,
                        style: GoogleFonts.rajdhani(
                          color: const Color(0xFFD4DCED),
                          fontSize: 14,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Directives & Stars
              Text(
                'QUANTUM DIRECTIVES',
                style: GoogleFonts.orbitron(
                  color: const Color(0xFF8BA5CE),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 10),

              _DirectiveRow(
                starNumber: 1,
                title: 'Stabilize Reality Anomaly',
                achieved: earnedStars >= 1,
                accent: story.accent,
              ),
              const SizedBox(height: 7),
              _DirectiveRow(
                starNumber: 2,
                title: 'Recover All Spatial Shards',
                achieved: earnedStars >= 2,
                accent: story.accent,
              ),
              const SizedBox(height: 7),
              _DirectiveRow(
                starNumber: 3,
                title: 'Flawless Dimensional Shift',
                achieved: earnedStars >= 3,
                accent: story.accent,
              ),

              const SizedBox(height: 20),

              // Rewards Strip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x3314223E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFFD15C).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.military_tech_rounded,
                      color: Color(0xFFFFD15C),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'COMPLETION BOUNTY',
                      style: GoogleFonts.rajdhani(
                        color: const Color(0xFFFFE082),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.diamond_rounded,
                      color: Color(0xFF73E5FF),
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+50',
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFD15C),
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+3 ★',
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Big Action CTA Button
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _launchLevelScreen(levelId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [story.accent, const Color(0xFF6C3DF8)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: story.accent.withValues(alpha: 0.45),
                        blurRadius: 22,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    height: 54,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isCompleted
                              ? 'RE-ENTER REALITY'
                              : 'COMMENCE REALITY SHIFT',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLockedSheet(int levelId) {
    final story = storyForLevel(levelId);
    final previousLevel = levelId - 1;
    final prevStory = previousLevel >= 1 ? storyForLevel(previousLevel) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 34),
          decoration: BoxDecoration(
            color: const Color(0xF4110A14),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: const Color(0xFFFF5277).withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5277).withValues(alpha: 0.22),
                blurRadius: 36,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x33FF5277),
                  border: Border.all(color: const Color(0xFFFF5277)),
                ),
                child: const Icon(
                  Icons.lock_clock_rounded,
                  color: Color(0xFFFF5277),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'SPATIAL SEAL ACTIVE',
                style: GoogleFonts.orbitron(
                  color: const Color(0xFFFF7A96),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                story.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                prevStory != null
                    ? 'This spacetime coordinate is locked. Stabilize Reality #${previousLevel.toString().padLeft(2, '0')} (${prevStory.title}) to breach the anomaly barrier.'
                    : 'This reality remains locked until previous anomalies are fully resolved.',
                textAlign: TextAlign.center,
                style: GoogleFonts.rajdhani(
                  color: const Color(0xFFC0CAD8),
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showMissionBriefingSheet(unlockedLevel);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF26122E),
                  side: const BorderSide(color: Color(0xFFFF5277)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.navigation_rounded,
                      color: Color(0xFFFF7A96),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'JUMP TO ACTIVE TARGET (#$unlockedLevel)',
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final completed = completedRealities;
    final totalRatio = (completed / 20).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF060914),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Cosmic Canvas
          Image.asset('assets/images/space_bg.png', fit: BoxFit.cover),

          // Twinkling Starfield Particle Overlay
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _CosmicStarfieldPainter()),
            ),
          ),

          // Deep Cinematic Vignette & Color Grading
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.25, 0.65, 1.0],
                colors: [
                  Color(0xC0060914),
                  Color(0xDD090F1E),
                  Color(0xF0060914),
                  Color(0xFD04060E),
                ],
              ),
            ),
          ),

          // Ambient Nebula Glow Orbs
          Positioned(
            top: 40,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF73E5FF).withValues(alpha: 0.08),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF73E5FF),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 360,
            left: -80,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFA779FF).withValues(alpha: 0.07),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFFA779FF),
                      blurRadius: 110,
                      spreadRadius: 25,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main View
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top Deluxe App Bar
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  sliver: SliverToBoxAdapter(
                    child: _topAppBar(totalRatio, completed)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: -0.15, end: 0),
                  ),
                ),

                // Hero Spotlight Card for Current Reality Target
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  sliver: SliverToBoxAdapter(
                    child: _heroAnomalySpotlight()
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 100.ms)
                        .scale(begin: const Offset(0.96, 0.96)),
                  ),
                ),

                // Chapter Selector Bar / Filter Tabs
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  sliver: SliverToBoxAdapter(
                    child: _chapterFilterBar().animate().fadeIn(
                      duration: 400.ms,
                      delay: 180.ms,
                    ),
                  ),
                ),

                // Chapter Grids
                if (_selectedChapterFilter == 0)
                  // Show all 4 chapters with distinct section headers
                  for (var chapter = 1; chapter <= 4; chapter++) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      sliver: SliverToBoxAdapter(
                        child: _chapterSectionHeader(
                          chapter,
                        ).animate().fadeIn(duration: 350.ms),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: _buildChapterGrid(chapter),
                    ),
                  ]
                else
                // Show single selected chapter
                ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    sliver: SliverToBoxAdapter(
                      child: _chapterSectionHeader(
                        _selectedChapterFilter,
                      ).animate().fadeIn(duration: 350.ms),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: _buildChapterGrid(_selectedChapterFilter),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topAppBar(double totalRatio, int completed) {
    return Row(
      children: [
        // Frosted Glass Back Button
        Material(
          color: const Color(0x66101B30),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x3373E5FF)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Title Lockup
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'REALITY ARCHIVE',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'COSMIC TIMELINE RESTORATION',
                style: GoogleFonts.rajdhani(
                  color: const Color(0xFF73E5FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),

        // HUD Stats: Coins & Stars
        _hudPill(
          icon: Icons.diamond_rounded,
          value: '$coins',
          color: const Color(0xFF73E5FF),
        ),
        const SizedBox(width: 6),
        _hudPill(
          icon: Icons.star_rounded,
          value: '$totalStars/60',
          color: const Color(0xFFFFD15C),
        ),
      ],
    );
  }

  Widget _hudPill({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x880C1426),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroAnomalySpotlight() {
    final targetId = currentTargetLevel;
    final story = storyForLevel(targetId);
    final earnedStars = starsByLevel[targetId] ?? 0;
    final isMastered = earnedStars >= 3;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(const Color(0xFF131D38), story.accent, 0.22)!,
            const Color(0xFF0D1426),
            const Color(0xFF080C18),
          ],
        ),
        border: Border.all(
          color: story.accent.withValues(alpha: 0.65),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: story.accent.withValues(alpha: 0.25),
            blurRadius: 28,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Beacon row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: story.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: story.accent.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: story.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: story.accent,
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CURRENT ANOMALY OBJECTIVE',
                      style: GoogleFonts.orbitron(
                        color: story.accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'REALITY #${targetId.toString().padLeft(2, '0')}',
                style: GoogleFonts.orbitron(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Title & Teaser
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.title,
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      story.teaser,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.rajdhani(
                        color: const Color(0xFFC1CCE0),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Big Emblem
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      story.accent.withValues(alpha: 0.4),
                      const Color(0xFF10192E),
                    ],
                  ),
                  border: Border.all(
                    color: story.accent.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: story.accent.withValues(alpha: 0.35),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Icon(story.icon, color: Colors.white, size: 28),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // CTA Launch Row
          Row(
            children: [
              // Stars progress
              Row(
                children: List.generate(3, (index) {
                  final active = index < earnedStars;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      active ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 16,
                      color: active
                          ? const Color(0xFFFFD15C)
                          : const Color(0x44FFFFFF),
                    ),
                  );
                }),
              ),
              const Spacer(),
              // Launch Button
              ElevatedButton(
                onPressed: () => openLevel(targetId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [story.accent, const Color(0xFF7543FA)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: story.accent.withValues(alpha: 0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isMastered ? 'REVISIT' : 'ENGAGE ANOMALY',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.3,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chapterFilterBar() {
    final filters = [
      {'label': 'ALL REALITIES', 'id': 0, 'color': const Color(0xFF73E5FF)},
      {'label': 'CH.01', 'id': 1, 'color': const Color(0xFF73E5FF)},
      {'label': 'CH.02', 'id': 2, 'color': const Color(0xFFD28CFF)},
      {'label': 'CH.03', 'id': 3, 'color': const Color(0xFF72DFFF)},
      {'label': 'CH.04', 'id': 4, 'color': const Color(0xFFFF8FCE)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final id = f['id'] as int;
          final isSelected = _selectedChapterFilter == id;
          final color = f['color'] as Color;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _selectedChapterFilter = id),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.22)
                        : const Color(0x6610192E),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? color
                          : Colors.white.withValues(alpha: 0.12),
                      width: isSelected ? 1.4 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.25),
                              blurRadius: 14,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        f['label'] as String,
                        style: GoogleFonts.orbitron(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _chapterSectionHeader(int chapter) {
    final story = storyForLevel((chapter - 1) * 5 + 1);
    final first = (chapter - 1) * 5 + 1;
    final last = first + 4;
    final chapterStars = Iterable<int>.generate(5)
        .map((index) => starsByLevel[first + index] ?? 0)
        .fold<int>(0, (sum, value) => sum + value);
    final chapterProgress = (chapterStars / 15).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x550C1426),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: story.accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 3.5,
                height: 38,
                decoration: BoxDecoration(
                  color: story.accent,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: story.accent.withValues(alpha: 0.8),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHAPTER ${chapter.toString().padLeft(2, '0')}  •  SECTOR $first–$last',
                      style: GoogleFonts.orbitron(
                        color: story.accent,
                        fontSize: 9.5,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      story.chapterTitle,
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x6614223A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFD15C).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFD15C),
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$chapterStars/15',
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: chapterProgress,
              minHeight: 4,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(story.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterGrid(int chapter) {
    return SliverGrid.builder(
      itemCount: 5,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 182,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final levelId = (chapter - 1) * 5 + index + 1;
        final story = storyForLevel(levelId);
        final isUnlocked = levelId <= unlockedLevel;
        final isCurrent = levelId == unlockedLevel;
        final stars = starsByLevel[levelId] ?? 0;

        return LevelTile(
              level: levelId,
              title: story.title,
              chapter: 'CHAPTER ${chapter.toString().padLeft(2, '0')}',
              accent: story.accent,
              icon: story.icon,
              unlocked: isUnlocked,
              isCurrent: isCurrent,
              stars: stars,
              teaser: story.teaser,
              onTap: () => openLevel(levelId),
            )
            .animate()
            .fadeIn(duration: 400.ms, delay: (index * 60).ms)
            .scale(begin: const Offset(0.94, 0.94));
      },
    );
  }
}

class _DirectiveRow extends StatelessWidget {
  const _DirectiveRow({
    required this.starNumber,
    required this.title,
    required this.achieved,
    required this.accent,
  });

  final int starNumber;
  final String title;
  final bool achieved;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: achieved ? const Color(0x33172E27) : const Color(0x4410182A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: achieved
              ? const Color(0xFF4CD69B).withValues(alpha: 0.5)
              : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Icon(
            achieved ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 16,
            color: achieved ? const Color(0xFFFFD15C) : const Color(0x55FFFFFF),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.rajdhani(
                color: achieved ? Colors.white : const Color(0x88FFFFFF),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (achieved)
            const Icon(Icons.check_rounded, size: 15, color: Color(0xFF4CD69B)),
        ],
      ),
    );
  }
}

class _CosmicStarfieldPainter extends CustomPainter {
  const _CosmicStarfieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 45; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5 + 0.4;
      final alpha = (random.nextDouble() * 0.45 + 0.15).clamp(0.0, 1.0);

      paint.color = (i % 3 == 0)
          ? const Color(0xFF73E5FF).withValues(alpha: alpha)
          : (i % 5 == 0)
          ? const Color(0xFFFFD15C).withValues(alpha: alpha)
          : Colors.white.withValues(alpha: alpha);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
