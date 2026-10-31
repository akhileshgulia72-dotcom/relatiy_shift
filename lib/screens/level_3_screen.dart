import 'dart:async';
import 'dart:math' as math;
import 'package:reality_shift/screens/home/widgets/constellation_painter.dart';

import 'package:flutter/material.dart';
import 'package:reality_shift/core/widget/campaign_monetization_controls.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home/widgets/level_header.dart';
import 'level_4_screen.dart';

class Level3Screen extends StatefulWidget {
  const Level3Screen({super.key});

  @override
  State<Level3Screen> createState() => _Level3ScreenState();
}

class StarData {
  Offset position;
  bool selected;
  bool isReal;
  bool removed;

  StarData({
    required this.position,
    required this.isReal,
    this.selected = false,
    this.removed = false,
  });
}

class _Level3ScreenState extends State<Level3Screen>
    with TickerProviderStateMixin {
  List<StarData> stars = [];

  bool showConstellation = true;
  bool completed = false;
  bool usedHint = false;
  int attempts = 0;

  int lives = 5;
  int coins = 0;

  late AnimationController floatController;
  late AnimationController portalController;

  final GlobalKey portalKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    loadProgress();

    generateStars();

    floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    portalController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    startPreview();
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      coins = prefs.getInt("coins") ?? 0;
    });
  }

  void generateStars() {
    stars = [
      StarData(position: const Offset(55, 260), isReal: false),
      StarData(position: const Offset(170, 250), isReal: false),
      StarData(position: const Offset(285, 270), isReal: false),
      StarData(position: const Offset(95, 390), isReal: false),
      StarData(position: const Offset(230, 400), isReal: false),
      StarData(position: const Offset(55, 530), isReal: false),
      StarData(position: const Offset(170, 545), isReal: false),
      StarData(position: const Offset(285, 525), isReal: false),
      StarData(position: const Offset(170, 655), isReal: false),
    ];

    final random = math.Random();
    final realIndexes = <int>{};

    while (realIndexes.length < 4) {
      realIndexes.add(random.nextInt(stars.length));
    }

    for (final index in realIndexes) {
      stars[index].isReal = true;
    }
  }

  Future<void> startPreview() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    setState(() {
      showConstellation = false;
    });
  }

  @override
  void dispose() {
    floatController.dispose();
    portalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
          child: CampaignMonetizationControls(
            level: 3,
            onHint: _revealHint,
            onSkipped: () => Navigator.maybePop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/level1_bg.png",
              fit: BoxFit.cover,
            ),
          ),

          Positioned(
            top: 8,
            left: 12,
            child: SafeArea(
              child: IconButton.filledTonal(
                tooltip: 'Back to levels',
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
          ),
          const LevelHeader(
            mission: "MISSION 03",
            title: "SHADOW CONSTELLATION",
            description: "Memorize the constellation before it disappears.",
          ),
          if (showConstellation)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: ConstellationPainter(
                    stars
                        .where((star) => star.isReal)
                        .map(
                          (star) => Offset(
                            star.position.dx + 35,
                            star.position.dy + 35,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ...stars.asMap().entries.map((entry) {
            final star = entry.value;

            return Positioned(
              left: star.position.dx,
              top: star.position.dy,
              child: GestureDetector(
                onTap: () {
                  if (showConstellation || completed) return;

                  setState(() {
                    star.selected = !star.selected;
                  });
                  final selected = stars
                      .where((item) => item.selected)
                      .toList();
                  if (selected.length == 4) {
                    if (selected.every((item) => item.isReal)) {
                      completeLevel();
                    } else {
                      attempts++;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'That pattern does not match. Try another constellation.',
                          ),
                        ),
                      );
                      setState(() => star.selected = false);
                    }
                  }
                },
                child: AnimatedBuilder(
                  animation: floatController,
                  builder: (_, child) {
                    final floatY =
                        math.sin(
                          (floatController.value * math.pi * 2) + entry.key,
                        ) *
                        8;

                    return Transform.translate(
                      offset: Offset(0, floatY),
                      child: child,
                    );
                  },
                  child: Transform.scale(
                    scale: showConstellation && star.isReal
                        ? 1.15 +
                              math.sin(floatController.value * math.pi * 2) *
                                  0.08
                        : 1,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        boxShadow: [
                          if (showConstellation && star.isReal)
                            BoxShadow(
                              color: Colors.cyanAccent,
                              blurRadius: 35,
                              spreadRadius: 10,
                            ),

                          if (star.selected)
                            BoxShadow(
                              color: Colors.orange,
                              blurRadius: 25,
                              spreadRadius: 8,
                            ),
                        ],
                      ),
                      child: Image.asset("assets/images/star.png", width: 70),
                    ),
                  ),
                ),
              ),
            );
          }),
          if (completed)
            Positioned.fill(
              child: Container(
                color: const Color(0xCC050816),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(28),
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: const Color(0xFF172447),
                      border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: .75),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.amber,
                          size: 54,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'CONSTELLATION RESTORED',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Level4Screen(),
                            ),
                          ),
                          child: const Text('NEXT MISSION'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _revealHint() {
    usedHint = true;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hint'),
        content: const Text(
          'During the 3-second preview, memorize the four glowing stars and their exact positions. When they disappear, tap those same four stars—no others.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }

  Future<void> completeLevel() async {
    setState(() => completed = true);
    final prefs = await SharedPreferences.getInstance();
    final previousStars = prefs.getInt('level3Stars') ?? 0;
    final earned = attempts == 0
        ? 3
        : attempts < 3
        ? 2
        : 1;
    await prefs.setInt('level3Stars', math.max(previousStars, earned));
    if (previousStars == 0) {
      await prefs.setInt('coins', (prefs.getInt('coins') ?? 0) + earned * 15);
    }
    if ((prefs.getInt('unlockedLevel') ?? 1) < 4) {
      await prefs.setInt('unlockedLevel', 4);
    }
  }
}
