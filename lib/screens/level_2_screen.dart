import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:reality_shift/core/widget/campaign_monetization_controls.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'level_3_screen.dart';

class Level2Screen extends StatefulWidget {
  const Level2Screen({super.key});

  @override
  State<Level2Screen> createState() => _Level2ScreenState();
}

class _Level2ScreenState extends State<Level2Screen>
    with TickerProviderStateMixin {
  late final AnimationController _orbit;
  late final AnimationController _reveal;
  late final AnimationController _celebrate;
  bool _revealing = false;
  bool _complete = false;
  bool _draggingSun = false;
  bool _showNudge = true;
  Offset? _sunPosition;
  Size _sceneSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _celebrate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void dispose() {
    _orbit.dispose();
    _reveal.dispose();
    _celebrate.dispose();
    super.dispose();
  }

  void _onSceneSize(Size size) {
    if (size == _sceneSize) return;
    _sceneSize = size;
    if (!_draggingSun && !_revealing && !_complete) {
      _sunPosition = Offset(size.width * .76, size.height * .47);
    }
  }

  void _dragStart(DragStartDetails details) {
    if (_revealing || _complete) return;
    setState(() {
      _draggingSun = true;
      _showNudge = false;
    });
  }

  void _dragUpdate(DragUpdateDetails details) {
    if (!_draggingSun || _revealing || _complete) return;
    final next =
        (_sunPosition ??
            Offset(_sceneSize.width * .76, _sceneSize.height * .47)) +
        details.delta;
    final radius = math.min(_sceneSize.shortestSide * .095, 43.0);
    // Trigger as soon as the Sun starts crossing the edge. Requiring the
    // whole disc to leave the viewport made an ordinary swipe feel unresponsive.
    if (next.dx < radius ||
        next.dx > _sceneSize.width - radius ||
        next.dy < radius ||
        next.dy > _sceneSize.height - radius) {
      _startReveal();
      return;
    }
    setState(() => _sunPosition = next);
  }

  void _dragEnd(DragEndDetails details) {
    if (!_draggingSun || _revealing || _complete) return;
    final size = _sceneSize;
    final start = Offset(size.width * .76, size.height * .47);
    // If the player releases before reaching an edge, spring back and restore
    // the swipe cue so they can retry immediately.
    setState(() {
      _draggingSun = false;
      _sunPosition = start;
      _showNudge = true;
    });
  }

  Future<void> _startReveal() async {
    if (_revealing || _complete) return;
    setState(() {
      _draggingSun = false;
      _revealing = true;
      _showNudge = false;
    });
    await _reveal.forward(from: 0);
    if (!mounted) return;
    setState(() => _complete = true);
    _celebrate.repeat();
    final prefs = await SharedPreferences.getInstance();
    final previousStars = prefs.getInt('level2Stars') ?? 0;
    if (previousStars < 3) await prefs.setInt('level2Stars', 3);
    if ((prefs.getInt('unlockedLevel') ?? 1) < 3) {
      await prefs.setInt('unlockedLevel', 3);
    }
  }

  void _continue() {
    if (!_complete) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const Level3Screen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
          child: CampaignMonetizationControls(
            level: 2,
            onHint: _revealHint,
            onSkipped: () => Navigator.maybePop(context),
          ),
        ),
      ),
      backgroundColor: const Color(0xFF030713),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final sceneSize = Size(constraints.maxWidth, constraints.maxHeight);
          _onSceneSize(sceneSize);
          final compact = constraints.maxHeight < 700;
          final marsSize = math.min(
            sceneSize.shortestSide * .52,
            compact ? 220.0 : 270.0,
          );
          final sunSize = math.min(sceneSize.shortestSide * .19, 90.0);
          return Stack(
            fit: StackFit.expand,
            children: [
              const Positioned.fill(child: _SpaceBackdrop()),
              AnimatedBuilder(
                animation: Listenable.merge([_orbit, _reveal, _celebrate]),
                builder: (context, _) {
                  final center = Offset(
                    sceneSize.width * .48,
                    sceneSize.height * .53,
                  );
                  final phase = _orbit.value * math.pi * 2;
                  final orbitRadiusX = marsSize * .92;
                  final orbitRadiusY = marsSize * .69;
                  final first =
                      center +
                      Offset(
                        math.cos(phase) * orbitRadiusX,
                        math.sin(phase) * orbitRadiusY,
                      );
                  final revealT = Curves.easeInOutCubic.transform(
                    _reveal.value,
                  );
                  final secondAngle = phase + math.pi + .32;
                  final targetSecond =
                      center +
                      Offset(
                        math.cos(secondAngle) * orbitRadiusX * 1.18,
                        math.sin(secondAngle) * orbitRadiusY * 1.18,
                      );
                  final second = center + (targetSecond - center) * revealT;
                  final sun =
                      _sunPosition ??
                      Offset(sceneSize.width * .76, sceneSize.height * .47);
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _OrbitPainter(
                            center: center,
                            radiusX: orbitRadiusX,
                            radiusY: orbitRadiusY,
                            visible: _revealing,
                          ),
                        ),
                      ),
                      if (_revealing && _reveal.value < .58)
                        Positioned(
                          left: second.dx - 16 * revealT,
                          top: second.dy - 16 * revealT,
                          child: Opacity(
                            opacity: revealT,
                            child: _RealisticMoon(
                              imagePath: 'assets/images/deimos_realistic.png',
                              size: 32 * revealT,
                              glowColor: const Color(0xFFC4BDB0),
                            ),
                          ),
                        ),
                      Positioned(
                        left: center.dx - marsSize / 2,
                        top: center.dy - marsSize / 2,
                        width: marsSize,
                        height: marsSize,
                        child: _Mars(size: marsSize),
                      ),
                      Positioned(
                        left: first.dx - 21,
                        top: first.dy - 21,
                        child: const _RealisticMoon(
                          imagePath: 'assets/images/phobos_realistic.png',
                          size: 42,
                          glowColor: Color(0xFFB8C3D9),
                        ),
                      ),
                      if (_revealing && _reveal.value >= .58)
                        Positioned(
                          left: second.dx - 16 * revealT,
                          top: second.dy - 16 * revealT,
                          child: Opacity(
                            opacity: revealT,
                            child: _RealisticMoon(
                              imagePath: 'assets/images/deimos_realistic.png',
                              size: 32 * revealT,
                              glowColor: const Color(0xFFC4BDB0),
                            ),
                          ),
                        ),
                      if (!_revealing && !_complete)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          left: sun.dx - sunSize / 2,
                          top: sun.dy - sunSize / 2,
                          width: sunSize,
                          height: sunSize,
                          child: GestureDetector(
                            key: const ValueKey('level2-sun'),
                            onPanStart: _dragStart,
                            onPanUpdate: _dragUpdate,
                            onPanEnd: _dragEnd,
                            child: _Sun(size: sunSize, dragging: _draggingSun),
                          ),
                        ),
                      if (_revealing)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Opacity(
                              opacity: revealT * .62,
                              child: const ColoredBox(color: Color(0xFF02040D)),
                            ),
                          ),
                        ),
                      if (_revealing)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _CosmicBurstPainter(progress: revealT),
                            ),
                          ),
                        ),
                      if (_complete)
                        Positioned(
                          left: 16,
                          right: 16,
                          top: sceneSize.height * .25,
                          child: _CompleteBanner(controller: _celebrate),
                        ),
                    ],
                  );
                },
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                      child: Row(
                        children: [
                          IconButton.filledTonal(
                            tooltip: 'Back to levels',
                            onPressed: () => Navigator.maybePop(context),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'REALITY SHIFT  /  02',
                            style: TextStyle(
                              color: Color(0xFF8AA9C8),
                              fontSize: 11,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'THE HIDDEN MOON',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 21 : 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        shadows: const [
                          Shadow(color: Color(0xFF66D9FF), blurRadius: 18),
                        ],
                      ),
                    ),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 550),
                      switchInCurve: Curves.easeOutCubic,
                      child: _complete
                          ? _FactCard(onContinue: _continue, compact: compact)
                          : Padding(
                              key: const ValueKey('level2-instruction'),
                              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                              child: Column(
                                children: [
                                  Text(
                                    _revealing
                                        ? 'A SECOND ORBIT AWAKENS…'
                                        : 'Something is hidden in the darkness. Swipe the Sun away to reveal it.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: .92,
                                      ),
                                      fontSize: compact ? 14 : 16,
                                      height: 1.5,
                                      fontWeight: FontWeight.w600,
                                      shadows: const [
                                        Shadow(
                                          color: Color(0xFF041024),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (_showNudge)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          Icons.swipe_rounded,
                                          color: Color(0xFF72E6FF),
                                          size: 18,
                                        ),
                                        SizedBox(width: 7),
                                        Text(
                                          'DRAG THE SUN OFF SCREEN',
                                          style: TextStyle(
                                            color: Color(0xFF72E6FF),
                                            fontSize: 10,
                                            letterSpacing: 1.8,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (_revealing)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 18),
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF79E6FF),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _revealHint() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hint'),
        content: const Text(
          'Drag the Sun completely off the screen. Keep moving it until the hidden moon appears.',
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
}

class _SpaceBackdrop extends StatelessWidget {
  const _SpaceBackdrop();
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _StarfieldPainter(),
    child: const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-.25, -.1),
          radius: 1.15,
          colors: [Color(0xFF15223F), Color(0xFF080E20), Color(0xFF02050D)],
        ),
      ),
    ),
  );
}

class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(41);
    for (var i = 0; i < 105; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.45 + .25;
      final alpha = .2 + random.nextDouble() * .65;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Mars extends StatelessWidget {
  const _Mars({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        // Deep atmospheric red heat bloom
        BoxShadow(
          color: const Color(0x99EE4824).withValues(alpha: 0.55),
          blurRadius: 42,
          spreadRadius: 3,
        ),
        // Outer atmospheric limb (Martian blue-white haze seen from orbit)
        BoxShadow(
          color: const Color(0x3379DFFF).withValues(alpha: 0.35),
          blurRadius: 22,
          spreadRadius: 1,
        ),
        // Deep space shadow cast
        const BoxShadow(
          color: Color(0xD5000000),
          blurRadius: 40,
          offset: Offset(22, 28),
        ),
      ],
    ),
    child: ClipOval(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/mars_realistic.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
          // Directional space shadow & spherical terminator shading
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.35, -0.42),
                radius: 0.96,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Color(0x331C0804),
                  Color(0xDD090204),
                ],
                stops: [0.0, 0.58, 0.82, 1.0],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _RealisticMoon extends StatelessWidget {
  const _RealisticMoon({
    required this.imagePath,
    required this.size,
    required this.glowColor,
  });

  final String imagePath;
  final double size;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    if (size <= 0) return const SizedBox.shrink();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.35),
            blurRadius: size * 0.45,
            spreadRadius: 1,
          ),
          const BoxShadow(
            color: Color(0x99000000),
            blurRadius: 8,
            offset: Offset(4, 5),
          ),
        ],
      ),
      child: Image.asset(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _MarsSurfacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(12);
    for (var i = 0; i < 34; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = random.nextDouble() * size.width * .035 + 2;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = (i.isEven
              ? const Color(0x44FFD19A)
              : const Color(0x33611722)),
      );
    }
    final shade = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.transparent, Color(0xAA160F22)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, shade);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Moon extends StatelessWidget {
  const _Moon({required this.size, required this.color, required this.crater});
  final double size;
  final Color color;
  final Color crater;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        center: const Alignment(-.4, -.45),
        colors: [
          Color.lerp(color, Colors.white, .32)!,
          color,
          Color.lerp(color, Colors.black, .48)!,
        ],
        stops: const [0, .48, 1],
      ),
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: .38), blurRadius: 12),
      ],
    ),
    child: CustomPaint(painter: _CraterPainter(color: crater)),
  );
}

class _CraterPainter extends CustomPainter {
  const _CraterPainter({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    for (final crater in [
      const Offset(.3, .34),
      const Offset(.68, .62),
      const Offset(.42, .78),
    ]) {
      canvas.drawCircle(
        Offset(size.width * crater.dx, size.height * crater.dy),
        size.width * .09,
        Paint()..color = color.withValues(alpha: .38),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CraterPainter oldDelegate) => false;
}

class _Sun extends StatelessWidget {
  const _Sun({required this.size, required this.dragging});
  final double size;
  final bool dragging;
  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: dragging ? 1.16 : 1,
    duration: const Duration(milliseconds: 160),
    child: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFFFF6C8), Color(0xFFFFCB59), Color(0xFFFF7C36)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFFFFAB3D,
            ).withValues(alpha: dragging ? .85 : .58),
            blurRadius: dragging ? 48 : 32,
            spreadRadius: dragging ? 13 : 7,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * .53,
          height: size * .53,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color(0xFFFFFCE8), Color(0xFFFFD16C)],
            ),
          ),
        ),
      ),
    ),
  );
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({
    required this.center,
    required this.radiusX,
    required this.radiusY,
    required this.visible,
  });
  final Offset center;
  final double radiusX;
  final double radiusY;
  final bool visible;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: center,
      width: radiusX * 2,
      height: radiusY * 2,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: visible ? .13 : .075),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.center != center || oldDelegate.visible != visible;
}

class _CosmicBurstPainter extends CustomPainter {
  const _CosmicBurstPainter({required this.progress});
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .48, size.height * .53);
    final random = math.Random(77);
    final radius = size.shortestSide * (.08 + progress * .56);
    for (var i = 0; i < 44; i++) {
      final a = i * math.pi * 2 / 44;
      final wobble = random.nextDouble() * 24;
      final p =
          center +
          Offset(
            math.cos(a) * (radius + wobble),
            math.sin(a) * (radius + wobble),
          );
      final alpha = (1 - progress).clamp(0.0, 1.0) * .85;
      canvas.drawCircle(
        p,
        (1.2 + random.nextDouble() * 2.1) * (1 - progress * .3),
        Paint()
          ..color =
              (i.isEven ? const Color(0xFF7DEBFF) : const Color(0xFFFFC978))
                  .withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _CompleteBanner extends StatelessWidget {
  const _CompleteBanner({required this.controller});
  final AnimationController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final glow = .35 + .35 * math.sin(controller.value * math.pi * 2).abs();
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xBB081322),
          border: Border.all(
            color: const Color(0xFF73E8FF).withValues(alpha: glow),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4ADFFF).withValues(alpha: glow * .42),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Column(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFFFDE8A),
              size: 30,
            ),
            SizedBox(height: 5),
            Text(
              'LEVEL COMPLETE!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                shadows: [Shadow(color: Color(0xFF57E4FF), blurRadius: 18)],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _FactCard extends StatelessWidget {
  const _FactCard({required this.onContinue, required this.compact});
  final VoidCallback onContinue;
  final bool compact;
  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('level2-fact-card'),
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    padding: EdgeInsets.fromLTRB(20, compact ? 15 : 20, 20, compact ? 14 : 18),
    decoration: BoxDecoration(
      color: const Color(0xED0B1427),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: const Color(0x5579E8FF)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x55000000),
          blurRadius: 28,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MARS HAS TWO MOONS! 🔴',
                    style: TextStyle(
                      color: Color(0xFFFFD28A),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Phobos  •  The larger of Mars’s two moons.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Deimos  •  The smaller and more distant moon.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const SizedBox(width: 100, height: 82, child: _MiniMarsSystem()),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color(0x223C9BB5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            'DID YOU KNOW?  Earth has one natural moon, while Mars has two: Phobos and Deimos.',
            style: TextStyle(
              color: Color(0xFFBDECF4),
              fontSize: 11,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 13),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton(
            key: const ValueKey('level2-continue'),
            onPressed: onContinue,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF31B8D1),
              foregroundColor: const Color(0xFF04101C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'CONTINUE TO LEVEL 3',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _MiniMarsSystem extends StatelessWidget {
  const _MiniMarsSystem();
  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      Container(
        width: 82,
        height: 52,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0x6673D9EB)),
          borderRadius: BorderRadius.circular(50),
        ),
      ),
      Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x99FF5A36),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/mars_realistic.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
      Positioned(
        left: 5,
        top: 20,
        child: Container(
          width: 15,
          height: 15,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0x66B8C3D9), blurRadius: 4)],
          ),
          child: Image.asset(
            'assets/images/phobos_realistic.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
      Positioned(
        right: 4,
        top: 34,
        child: Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0x66B8B4A8), blurRadius: 4)],
          ),
          child: Image.asset(
            'assets/images/deimos_realistic.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    ],
  );
}
