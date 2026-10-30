import 'dart:async';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reality_shift/screens/level_2_screen.dart';
import 'package:flutter/material.dart';
import 'package:reality_shift/core/widget/campaign_monetization_controls.dart';
import 'package:reality_shift/screens/home/widgets/level_header.dart';

class Level1Screen extends StatefulWidget {
  const Level1Screen({super.key});

  @override
  State<Level1Screen> createState() => _Level1ScreenState();
}

class _Level1ScreenState extends State<Level1Screen>
    with TickerProviderStateMixin {
  Offset moonPosition = const Offset(120, 600);
  final Offset moonStartPosition = const Offset(140, 620);
  int attempts = 0;
  bool usedHint = false;
  int earnedCoins = 0;

  bool flash = false;
  Offset screenShake = Offset.zero;

  bool completed = false;
  bool dragging = false;
  int lives = 5;
  double portalScale = 1.0;
  double portalScaleAtGestureStart = 1.0;
  int coins = 0;
  int stars = 0;

  late AnimationController portalController;
  late AnimationController floatController;
  late AnimationController pulseController;

  final GlobalKey portalKey = GlobalKey();

  Offset? portalCenter;
  Future<void> shakeScreen() async {
    for (int i = 0; i < 8; i++) {
      if (!mounted) return;
      setState(() {
        screenShake = Offset(i.isEven ? 6 : -6, 0);
      });

      await Future.delayed(const Duration(milliseconds: 35));
    }

    if (!mounted) return;
    setState(() {
      screenShake = Offset.zero;
    });
  }

  @override
  void initState() {
    super.initState();
    loadProgress();

    portalController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderObject = portalKey.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return;
      final box = renderObject;

      portalCenter = box.localToGlobal(
        Offset(box.size.width / 2, box.size.height / 2),
      );
    });
  }

  @override
  void dispose() {
    portalController.dispose();
    pulseController.dispose();
    floatController.dispose();
    super.dispose();
  }

  void checkCompletion() {
    if (portalCenter == null || completed) return;

    final moonCenter = Offset(moonPosition.dx + 70, moonPosition.dy + 70);

    final distance = (moonCenter - portalCenter!).distance;

    if (distance < 90 && portalScale >= 1.7) {
      setState(() {
        completed = true;
        flash = true;

        // ⭐ Calculate Stars
        if (usedHint || attempts >= 4) {
          stars = 1;
        } else if (attempts >= 2) {
          stars = 2;
        } else {
          stars = 3;
        }

        // 🪙 Give Coins
        if (stars == 3) {
          earnedCoins = 50;
        } else if (stars == 2) {
          earnedCoins = 35;
        } else {
          earnedCoins = 20;
        }

        coins += earnedCoins;

        moonPosition = Offset(portalCenter!.dx - 70, portalCenter!.dy - 70);
      });

      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          setState(() {
            flash = false;
          });
        }
      });

      Future.delayed(const Duration(milliseconds: 600), () async {
        await saveProgress();

        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF182848), Color(0xFF0F2027)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border.all(color: Colors.cyanAccent, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: .45),
                      blurRadius: 35,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 70,
                      color: Colors.amber,
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      "MISSION COMPLETE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        stars,
                        (index) => const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 36,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      "Reality Restored!",
                      style: TextStyle(color: Colors.white70, fontSize: 20),
                    ),

                    const SizedBox(height: 30),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: Colors.orange,
                          ),

                          const SizedBox(width: 10),

                          Text(
                            "+$earnedCoins Coins",
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "$stars Stars Earned",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 28),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.cyanAccent),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "LEVELS",
                              style: TextStyle(color: Colors.cyanAccent),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const Level2Screen(),
                                ),
                              );
                            },
                            child: const Text(
                              "NEXT",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      });
    } else if (distance < 180 && portalScale < 1.7 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Too small! Pinch the portal wider.")),
      );
    }
  }

  void _revealHint() {
    usedHint = true;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hint'),
        content: const Text(
          'Use two fingers to spread the portal until it is large enough. Then drag the moon into the center of the portal.',
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

  Future<void> saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("coins", coins);

    // Save stars of Level 1
    await prefs.setInt("level1Stars", stars);

    // Unlock Level 2
    if ((prefs.getInt("unlockedLevel") ?? 1) < 2) {
      await prefs.setInt("unlockedLevel", 2);
    }
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      coins = prefs.getInt("coins") ?? 0;
      stars = prefs.getInt("level1Stars") ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
          child: CampaignMonetizationControls(
            level: 1,
            onHint: _revealHint,
            onSkipped: () => Navigator.maybePop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              "assets/images/splash_reality_hero.png",
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Lives
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.red),
                        const SizedBox(width: 6),
                        Text(
                          "$lives",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Stars
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text(
                          "$stars",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Coins
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text(
                          "$coins",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Pause
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.pause, color: Colors.white),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Level1Screen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Header
          const LevelHeader(
            mission: "MISSION 01",
            title: "THE BROKEN MOON",
            description:
                "The portal is tiny! Use two fingers to enlarge it, then drag the moon inside.",
          ),

          // Rotating Portal
          Align(
            alignment: const Alignment(0, -0.25),
            child: GestureDetector(
              onScaleStart: (_) => portalScaleAtGestureStart = portalScale,
              onScaleUpdate: (details) {
                if (details.pointerCount < 2) return;
                setState(() {
                  portalScale = (portalScaleAtGestureStart * details.scale)
                      .clamp(1.0, 2.0)
                      .toDouble();
                });
              },
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  portalController,
                  pulseController,
                ]),
                builder: (_, child) {
                  final pulse = 1 + (pulseController.value * 0.12);

                  return Transform.rotate(
                    angle: portalController.value * math.pi * 2,
                    child: Transform.scale(
                      scale: pulse * portalScale,
                      child: Container(
                        key: portalKey,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withValues(alpha: 0.7),
                              blurRadius: 35,
                              spreadRadius: 8,
                            ),
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.35),
                              blurRadius: 70,
                              spreadRadius: 18,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    ),
                  );
                },
                child: Image.asset("assets/images/energy_ring.png", width: 300),
              ),
            ),
          ),

          // Draggable Moon
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            left: moonPosition.dx,
            top: moonPosition.dy,
            child: GestureDetector(
              onPanStart: (_) {
                dragging = true;
                setState(() {});
              },
              onPanUpdate: (details) {
                if (completed) return;

                setState(() {
                  moonPosition += details.delta;
                });
              },
              onPanEnd: (_) {
                dragging = false;

                checkCompletion();

                if (!completed) {
                  setState(() {
                    attempts++; // Count a failed attempt
                    moonPosition = moonStartPosition;
                  });
                }

                setState(() {});
              },
              child: AnimatedBuilder(
                animation: floatController,
                builder: (_, child) {
                  final floatY = dragging
                      ? 0.0
                      : math.sin(floatController.value * math.pi) * 12;

                  return Transform.translate(
                    offset: Offset(0, floatY),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 150),
                      scale: dragging
                          ? 1.15
                          : completed
                          ? 0.15
                          : 1,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.yellow.withValues(alpha: .7),
                              blurRadius: 35,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    ),
                  );
                },
                child: Image.asset(
                  "assets/images/full_moon_icon.png",
                  width: 100,
                ),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: flash ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            child: IgnorePointer(child: Container(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
