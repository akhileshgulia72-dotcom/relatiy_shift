import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:reality_shift/core/widget/campaign_monetization_controls.dart';
import '../services/level_progress_service.dart';
import '../services/ads_service.dart';

import 'level_5_screen.dart';

class Level4Screen extends StatefulWidget {
  const Level4Screen({super.key});

  @override
  State<Level4Screen> createState() => _Level4ScreenState();
}

class _Level4ScreenState extends State<Level4Screen>
    with SingleTickerProviderStateMixin {
  bool chartMoved = false;
  bool completed = false;
  bool savingCompletion = false;
  bool leaving = false;
  double chartShift = 0;
  final double shardScale = .78;
  Offset shardPosition = const Offset(.43, .68);
  int mistakes = 0;
  final List<int> lensTurns = [0, 0, 0];
  static const lensTargets = [2, 1, 3];
  int shardTurns = 0;
  bool get lensesAligned => List.generate(
    3,
    (i) => lensTurns[i] == lensTargets[i],
  ).every((aligned) => aligned);

  late final AnimationController glowController;

  @override
  void initState() {
    super.initState();
    glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    glowController.dispose();
    super.dispose();
  }

  String get instruction {
    if (!chartMoved) {
      return 'The old star chart is hiding something. Shift it aside.';
    }
    if (!lensesAligned) {
      return 'Align the three lenses with the marked directions to reveal the moon’s true notch.';
    }
    if (shardTurns != 2) {
      return 'Tap the fragment until its bright edge faces the moon.';
    }
    return 'Drag the aligned fragment into the glowing notch on the moon’s right edge.';
  }

  void registerMistake(String message) {
    mistakes++;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF202B47),
          duration: const Duration(milliseconds: 1800),
        ),
      );
  }

  Future<void> finishPuzzle() async {
    if (completed || savingCompletion) return;
    setState(() => savingCompletion = true);
    final earnedStars = mistakes == 0
        ? 3
        : mistakes < 3
        ? 2
        : 1;
    try {
      await LevelProgressService.complete(level: 4, stars: earnedStars);
      if (mounted) setState(() => completed = true);
    } catch (_) {
      if (mounted) registerMistake('Progress could not be saved. Try placing the fragment again.');
    } finally {
      if (mounted) setState(() => savingCompletion = false);
    }
  }

  void checkDrop(double width, double height, double moonSize) {
    if (!lensesAligned) {
      registerMistake('The observatory lenses are not aligned yet.');
      return;
    }
    if (shardTurns != 2) {
      registerMistake(
        'Rotate the fragment until its bright edge faces the moon.',
      );
      return;
    }
    final pieceSize = width * .31 * shardScale;
    final pieceCenter = Offset(
      shardPosition.dx * width + pieceSize / 2,
      shardPosition.dy * height + pieceSize / 2,
    );
    final moonLeft = (width - moonSize) / 2;
    final moonTop = height * .09;
    // The opening is the triangular notch on the right edge of the moon.
    final notchCenter = Offset(
      moonLeft + moonSize * .76,
      moonTop + moonSize * .50,
    );
    final distanceToNotch = (pieceCenter - notchCenter).distance;
    if (distanceToNotch > moonSize * .22) {
      registerMistake('Aim for the bright notch on the moon’s right side.');
      return;
    }
    finishPuzzle();
  }

  Future<void> continueToNext() async {
    if (!completed || leaving) return;
    leaving = true;
    await AdsService.instance.showInterstitialAtTransition();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Level5Screen()),
    );
  }

  void restartPuzzle() {
    setState(() {
      chartMoved = false;
      completed = false;
      chartShift = 0;
      shardPosition = const Offset(.43, .68);
      shardTurns = 0;
      mistakes = 0;
      for (var i = 0; i < lensTurns.length; i++) {
        lensTurns[i] = 0;
      }
      leaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
          child: CampaignMonetizationControls(
            level: 4,
            onHint: _revealHint,
            onSkipped: () => Navigator.maybePop(context),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/level4_observatory_bg.png',
            fit: BoxFit.cover,
          ),
          Container(color: const Color(0x66101930)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      _roundButton(
                        Icons.arrow_back_rounded,
                        () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      _missionChip(),
                      const Spacer(),
                      _roundButton(Icons.restart_alt_rounded, restartPuzzle),
                      const SizedBox(width: 7),
                      _roundButton(Icons.pause_rounded, _showPause),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _titlePanel(),
                  const SizedBox(height: 10),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => _puzzleStage(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      ),
                    ),
                  ),
                  if (chartMoved) _lensPanel(),
                  _instructionPanel(),
                ],
              ),
            ),
          ),
          if (completed) _completionOverlay(),
        ],
      ),
    );
  }

  void _revealHint() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hint'),
        content: Text(
          !chartMoved
              ? 'Slide the old star chart to the right to uncover the fragment.'
              : !lensesAligned
              ? 'Tap the lenses until their pointers match the small target marks: down, right, left. Each tap turns one lens clockwise.'
              : 'Tap the fragment twice to orient it, then drag its center to the moon’s small glowing notch on the right.',
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

  Widget _puzzleStage(double width, double height) {
    final moonSize = math.min(width * .64, 224.0);
    final pieceSize = width * .31 * shardScale;
    final chartSize = math.min(width * .46, 164.0);

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          left: (width - moonSize) / 2,
          top: height * .08,
          child: AnimatedBuilder(
            animation: glowController,
            builder: (context, child) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(moonSize / 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withValues(
                      alpha: chartMoved
                          ? .22 + glowController.value * .23
                          : .10,
                    ),
                    blurRadius: 35,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: child,
            ),
            child: SizedBox(
              width: moonSize,
              height: moonSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _relic(1, 0, moonSize),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _LunarNotchPainter(aligned: chartMoved),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (chartMoved)
          Positioned(
            left: shardPosition.dx * width,
            top: shardPosition.dy * height,
            child: GestureDetector(
              onTap: () {
                if (!lensesAligned) {
                  registerMistake('Align the observatory lenses first.');
                  return;
                }
                setState(() => shardTurns = (shardTurns + 1) % 4);
              },
              onPanUpdate: (details) {
                if (!lensesAligned) return;
                setState(() {
                  shardPosition = Offset(
                    (shardPosition.dx + details.delta.dx / width)
                        .clamp(.02, .82)
                        .toDouble(),
                    (shardPosition.dy + details.delta.dy / height)
                        .clamp(.08, .82)
                        .toDouble(),
                  );
                });
              },
              onPanEnd: (_) {
                if (lensesAligned) checkDrop(width, height, moonSize);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: pieceSize,
                height: pieceSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(pieceSize / 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: .45),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Transform.rotate(
                  angle: shardTurns * math.pi / 2,
                  child: _relic(0, 1, pieceSize),
                ),
              ),
            ),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeInOutCubic,
          left: chartMoved
              ? width + chartSize
              : (width - chartSize) / 2 + chartShift,
          top: height * .58,
          child: IgnorePointer(
            ignoring: chartMoved,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  chartShift = (chartShift + details.delta.dx)
                      .clamp(-width * .12, width * .42)
                      .toDouble();
                  if (chartShift > width * .24) chartMoved = true;
                });
              },
              child: _relic(0, 0, chartSize),
            ),
          ),
        ),
      ],
    );
  }

  Widget _relic(int column, int row, double size) => ClipRect(
    child: SizedBox(
      width: size,
      height: size,
      child: Align(
        alignment: Alignment(column == 0 ? -1 : 1, row == 0 ? -1 : 1),
        child: Image.asset(
          'assets/images/level4_relic_atlas.png',
          width: size * 2,
          height: size * 2,
          fit: BoxFit.fill,
        ),
      ),
    ),
  );

  Widget _lensPanel() => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.fromLTRB(10, 9, 10, 11),
    decoration: BoxDecoration(
      color: const Color(0xE9111D36),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: lensesAligned ? Colors.cyanAccent : Colors.white24,
      ),
    ),
    child: Column(
      children: [
        Text(
          lensesAligned
              ? 'OBSERVATORY ALIGNED  •  TAP THE FRAGMENT TO ROTATE'
              : 'ALIGN THE OBSERVATORY LENSES',
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(3, (index) {
            final aligned = lensTurns[index] == lensTargets[index];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Material(
                  color: aligned
                      ? const Color(0x443ED7B5)
                      : const Color(0xFF202C48),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(
                      () => lensTurns[index] = (lensTurns[index] + 1) % 4,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.rotate(
                            angle: lensTurns[index] * math.pi / 2,
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              color: aligned
                                  ? Colors.cyanAccent
                                  : Colors.white70,
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '→ ${['↓', '→', '←'][index]}',
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    ),
  );

  Widget _titlePanel() => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      color: const Color(0xCC101A31),
      border: Border.all(color: const Color(0x886EDDF7)),
      boxShadow: [
        BoxShadow(
          color: Colors.cyanAccent.withValues(alpha: .12),
          blurRadius: 22,
        ),
      ],
    ),
    child: const Column(
      children: [
        Text(
          'THE MOON’S MISSING MEMORY',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'A lost fragment is hidden in the observatory. Restore the moon.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
        ),
      ],
    ),
  );

  Widget _instructionPanel() => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xE6111B33),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: chartMoved
            ? Colors.cyanAccent.withValues(alpha: .8)
            : Colors.white.withValues(alpha: .18),
      ),
    ),
    child: Row(
      children: [
        Icon(
          chartMoved ? Icons.auto_awesome : Icons.tips_and_updates_outlined,
          color: chartMoved ? Colors.cyanAccent : Colors.amberAccent,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            instruction,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _missionChip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      color: const Color(0xCC202944),
      border: Border.all(color: Colors.amberAccent.withValues(alpha: .45)),
    ),
    child: const Text(
      'MISSION 04',
      style: TextStyle(
        color: Colors.amberAccent,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    ),
  );

  Widget _roundButton(IconData icon, VoidCallback callback) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      color: Colors.white.withValues(alpha: .1),
      border: Border.all(color: Colors.white.withValues(alpha: .2)),
    ),
    child: IconButton(
      onPressed: callback,
      icon: Icon(icon, color: Colors.white),
    ),
  );

  void _showPause() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF151D39),
      title: const Text('PAUSED', style: TextStyle(color: Colors.white)),
      content: const Text(
        'The observatory will wait for you.',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('RESUME'),
        ),
      ],
    ),
  );

  Widget _completionOverlay() => Container(
    color: const Color(0xDD070B18),
    child: Center(
      child: Container(
        margin: const EdgeInsets.all(25),
        padding: const EdgeInsets.fromLTRB(27, 28, 27, 23),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFF202D4B), Color(0xFF10172C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.amberAccent.withValues(alpha: .7)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x777CEBFF),
              blurRadius: 34,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 112, height: 112, child: _relic(1, 0, 112)),
            const SizedBox(height: 12),
            const Text(
              'THE MOON REMEMBERS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'The observatory awakens around you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                mistakes == 0
                    ? 3
                    : mistakes < 3
                    ? 2
                    : 1,
                (_) => const Icon(
                  Icons.star_rounded,
                  color: Colors.amberAccent,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: continueToNext,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('ENTER THE NEXT REALITY'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8A947),
                  foregroundColor: const Color(0xFF171A26),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LunarNotchPainter extends CustomPainter {
  const _LunarNotchPainter({required this.aligned});

  final bool aligned;

  @override
  void paint(Canvas canvas, Size size) {
    final notch = Path()
      ..moveTo(size.width * .99, size.height * .34)
      ..lineTo(size.width * .73, size.height * .50)
      ..lineTo(size.width * .99, size.height * .66);
    canvas.drawPath(
      notch,
      Paint()
        ..color = Colors.cyanAccent.withValues(alpha: aligned ? .42 : .15)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      notch,
      Paint()
        ..color = Colors.cyanAccent.withValues(alpha: aligned ? .95 : .42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = aligned ? 3 : 1.5
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = aligned
            ? const MaskFilter.blur(BlurStyle.solid, 5)
            : null,
    );
  }

  @override
  bool shouldRepaint(covariant _LunarNotchPainter oldDelegate) =>
      oldDelegate.aligned != aligned;
}
