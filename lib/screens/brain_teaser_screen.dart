import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'chapter_puzzle_screen.dart';
import '../data/level_catalog.dart';
import '../services/level_progress_service.dart';

/// Chapter puzzle screens for missions 4 through 8.
class BrainTeaserScreen extends StatefulWidget {
  const BrainTeaserScreen({super.key, required this.level});

  final int level;

  @override
  State<BrainTeaserScreen> createState() => _BrainTeaserScreenState();
}

class _BrainTeaserScreenState extends State<BrainTeaserScreen> {
  bool titleMoved = false;
  bool piecePlaced = false;
  bool cometHeld = false;
  bool moonMoved = false;
  double moonY = .62;
  bool sunCovered = false;
  bool gravityFlipped = false;
  bool shadowFound = false;
  bool completed = false;
  double arrowY = 0.68;
  double planetX = 0.18;
  int attempts = 0;

  static const _titles = {
    4: 'THE MISSING PIECE',
    5: 'QUIET THE COMET',
    6: 'ONLY ONE IS REAL',
    7: 'GRAVITY SWITCH',
    8: 'A STAR’S SHADOW',
  };

  static const _instructions = {
    4: 'Drag the star chart away from the moon to uncover the loose fragment. Drag the fragment into the bright notch on the moon.',
    5: 'Press and hold the comet until it stops moving. While holding it, drag the moon into the portal.',
    6: 'Drag the comet across the sun to cover it. Then tap the real portal revealed by the shadow.',
    7: 'Drag the gravity arrow upward until it flips. Then guide the object along the new route.',
    8: 'Drag the planet until its shadow falls over the hidden star, then tap the star.',
  };

  Color get _accent => storyForLevel(widget.level).accent;

  String get _backdrop => switch (widget.level) {
    6 => 'assets/images/nebula_1.png',
    7 => 'assets/images/nebula_2.png',
    _ => 'assets/images/starfield_purple_sky.png',
  };

  Future<void> finish() async {
    if (completed) return;
    setState(() => completed = true);
    final stars = attempts == 0
        ? 3
        : attempts < 3
        ? 2
        : 1;
    await LevelProgressService.complete(level: widget.level, stars: stars);
  }

  void miss(String message) {
    attempts++;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF26355F),
        ),
      );
  }

  Future<void> next() async {
    if (widget.level < 8) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BrainTeaserScreen(level: widget.level + 1),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChapterPuzzleScreen(level: 9)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level.clamp(4, 8).toInt();
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(_backdrop, fit: BoxFit.cover),
          Container(color: const Color(0x66071120)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      _glassButton(
                        Icons.arrow_back,
                        () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      _pill('MISSION ${level.toString().padLeft(2, '0')}'),
                      const Spacer(),
                      _glassButton(Icons.pause_rounded, _showPause),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _missionCard(level),
                  const SizedBox(height: 12),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, bounds) =>
                          _puzzle(level, bounds.maxWidth, bounds.maxHeight),
                    ),
                  ),
                  _pill('DRAG • TAP • THINK DIFFERENTLY'),
                ],
              ),
            ),
          ),
          if (completed) _completionOverlay(level),
        ],
      ),
    );
  }

  Widget _puzzle(int level, double width, double height) {
    switch (level) {
      case 4:
        return _missingPiece(width, height);
      case 5:
        return _quietComet(width, height);
      case 6:
        return _realPortal(width, height);
      case 7:
        return _gravity(width, height);
      default:
        return _starShadow(width, height);
    }
  }

  Widget _missionCard(int level) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        colors: [Color(0xDD172747), Color(0xCC10172D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: _accent.withValues(alpha: .55)),
      boxShadow: [
        BoxShadow(
          color: _accent.withValues(alpha: .14),
          blurRadius: 25,
          spreadRadius: 2,
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          _titles[level]!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 54,
          height: 2,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 9),
        Text(
          _instructions[level]!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          storyForLevel(level).teaser,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _accent.withValues(alpha: .78),
            fontSize: 11,
            height: 1.3,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ),
  );

  Widget _missingPiece(double w, double h) => Stack(
    children: [
      Positioned(
        left: w * .28,
        top: h * .19,
        child: _moonCore(size: w * .42),
      ),
      Positioned(
        left: w * .40,
        top: h * .28,
        child: Icon(
          Icons.dark_mode_rounded,
          size: w * .17,
          color: Colors.cyanAccent.withValues(alpha: piecePlaced ? .25 : .9),
        ),
      ),
      if (!titleMoved)
        Positioned(
          left: w * .12,
          top: h * .22,
          child: GestureDetector(
            onPanUpdate: (d) {
              if (d.delta.distance > 0) setState(() => titleMoved = true);
            },
            child: _sign('MOVE ME', w * .76),
          ),
        ),
      if (titleMoved && !piecePlaced)
        Positioned(
          left: w * .40,
          top: h * .28,
          child: GestureDetector(
            onTap: () => setState(() => piecePlaced = true),
            child: _moonCore(size: w * .18),
          ),
        ),
      Positioned(
        left: w * .18,
        top: h * .66,
        child: _caption(
          titleMoved
              ? (piecePlaced ? 'MOON RESTORED' : 'TAP THE HIDDEN FRAGMENT')
              : 'SOMETHING IS UNDER THE SIGN',
        ),
      ),
      if (piecePlaced)
        Positioned(left: w * .41, top: h * .48, child: _successMark()),
      if (piecePlaced) Positioned.fill(child: _autoFinish()),
    ],
  );

  Widget _quietComet(double w, double h) => Stack(
    children: [
      Positioned(
        left: w * .35,
        top: h * .15,
        child: _portal(size: w * .32),
      ),
      Positioned(
        left: w * .39,
        top: h * moonY,
        child: GestureDetector(
          onPanUpdate: (details) {
            if (!cometHeld) {
              miss('The comet is shaking everything. Hold it first!');
              return;
            }
            setState(() {
              moonY = (moonY + details.delta.dy / h).clamp(.15, .72).toDouble();
              moonMoved = moonY < .30;
            });
          },
          child: _moonCore(size: w * .22),
        ),
      ),
      Positioned(
        left: w * .68,
        top: h * .51,
        child: GestureDetector(
          onLongPressStart: (_) => setState(() => cometHeld = true),
          onLongPressEnd: (_) => setState(() => cometHeld = false),
          child: _comet(w * .21, held: cometHeld),
        ),
      ),
      Positioned(
        left: w * .19,
        top: h * .83,
        child: _caption(
          cometHeld ? 'NOW DRAG THE MOON UP' : 'PRESS AND HOLD THE COMET',
        ),
      ),
      if (moonMoved && cometHeld) Positioned.fill(child: _autoFinish()),
    ],
  );

  Widget _realPortal(double w, double h) => Stack(
    children: [
      Positioned(
        left: w * .37,
        top: h * .12,
        child: GestureDetector(
          onLongPressStart: (_) => setState(() => sunCovered = true),
          onLongPressEnd: (_) {},
          child: _sun(w * .25, covered: sunCovered),
        ),
      ),
      for (var i = 0; i < 3; i++)
        Positioned(
          left: w * (.10 + i * .30),
          top: h * .59,
          child: GestureDetector(
            onTap: () {
              if (!sunCovered) return miss('Cover the sun and look again.');
              if (i == 1) {
                finish();
              } else {
                miss('That portal is only a reflection.');
              }
            },
            child: _portal(size: w * .23, muted: !sunCovered),
          ),
        ),
      Positioned(
        left: w * .21,
        top: h * .84,
        child: _caption(
          sunCovered
              ? 'THE MIDDLE PORTAL IS REAL'
              : 'HOLD YOUR FINGER OVER THE SUN',
        ),
      ),
    ],
  );

  Widget _gravity(double w, double h) => Stack(
    children: [
      Positioned(
        left: w * .37,
        top: h * .68,
        child: _moonCore(size: w * .24),
      ),
      Positioned(
        left: w * .36,
        top: h * .16,
        child: _portal(size: w * .28),
      ),
      Positioned(
        left: w * .42,
        top: h * arrowY,
        child: GestureDetector(
          onPanUpdate: (d) => setState(
            () => arrowY = (arrowY + d.delta.dy / h).clamp(.12, .78).toDouble(),
          ),
          onPanEnd: (_) {
            if (arrowY < .34) {
              setState(() => gravityFlipped = true);
            } else {
              miss('Pull the arrow all the way toward the top!');
            }
          },
          child: _gravityArrow(w * .17, flipped: gravityFlipped),
        ),
      ),
      Positioned(
        left: w * .20,
        top: h * .86,
        child: _caption(
          gravityFlipped
              ? 'GRAVITY FLIPPED — TAP THE MOON'
              : 'DRAG THE ARROW UPWARD',
        ),
      ),
      if (gravityFlipped)
        Positioned(
          left: w * .39,
          top: h * .68,
          child: GestureDetector(
            onTap: finish,
            child: _moonCore(size: w * .24),
          ),
        ),
    ],
  );

  Widget _starShadow(double w, double h) => Stack(
    children: [
      Positioned(left: w * .42, top: h * .58, child: _hiddenStar(shadowFound)),
      Positioned(
        left: w * planetX,
        top: h * .23,
        child: GestureDetector(
          onPanUpdate: (d) {
            setState(
              () => planetX = (planetX + d.delta.dx / w)
                  .clamp(.04, .72)
                  .toDouble(),
            );
            if ((planetX - .42).abs() < .045) {
              setState(() => shadowFound = true);
            }
          },
          child: _planet(w * .25),
        ),
      ),
      Positioned(
        left: w * .15,
        top: h * .77,
        child: _caption(
          shadowFound
              ? 'STAR REVEALED — TAP IT'
              : 'MOVE THE PLANET TO LINE UP ITS SHADOW',
        ),
      ),
      if (shadowFound)
        Positioned(
          left: w * .41,
          top: h * .58,
          child: GestureDetector(onTap: finish, child: _hiddenStar(true)),
        ),
    ],
  );

  Widget _autoFinish() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !completed) finish();
    });
    return const SizedBox.expand();
  }

  Widget _completionOverlay(int level) => Container(
    color: const Color(0xCC050816),
    child: Center(
      child: Container(
        margin: const EdgeInsets.all(28),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFF16264A), Color(0xFF13162D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: _accent.withValues(alpha: .75)),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: .22),
              blurRadius: 36,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.amberAccent,
              size: 58,
            ),
            const SizedBox(height: 14),
            const Text(
              'REALITY SHIFTED!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You found the trick.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                attempts == 0
                    ? 3
                    : attempts < 3
                    ? 2
                    : 1,
                (_) => const Icon(
                  Icons.star_rounded,
                  color: Colors.amber,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: next,
                icon: Icon(
                  level < 20
                      ? Icons.arrow_forward_rounded
                      : Icons.grid_view_rounded,
                ),
                label: Text(level < 20 ? 'NEXT MISSION' : 'LEVEL MAP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA42B),
                  foregroundColor: const Color(0xFF161323),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _showPause() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF151D39),
      title: const Text('PAUSED', style: TextStyle(color: Colors.white)),
      content: const Text(
        'Take a breath, then keep solving.',
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

  Widget _glassButton(IconData icon, VoidCallback onTap) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.white.withValues(alpha: .18)),
    ),
    child: IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
    ),
  );

  Widget _pill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0x99202B4E),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _accent.withValues(alpha: .26)),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    ),
  );

  Widget _caption(String text) => Container(
    constraints: const BoxConstraints(maxWidth: 310),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xCC0B1428),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white12),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: .8,
      ),
    ),
  );

  Widget _sign(String label, double width) => Container(
    width: width,
    padding: const EdgeInsets.symmetric(vertical: 17),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: const LinearGradient(
        colors: [Color(0xFF445684), Color(0xFF1D2949)],
      ),
      border: Border.all(color: Colors.cyanAccent.withValues(alpha: .65)),
      boxShadow: const [BoxShadow(color: Color(0x553EEBFF), blurRadius: 22)],
    ),
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        letterSpacing: 3,
      ),
    ),
  );

  Widget _moonCore({required double size}) => _prop(0, 0, size);

  /// Displays one cell from the 3 by 2 transparent, generated 3D prop atlas.
  Widget _prop(int column, int row, double height) => ClipRect(
    child: SizedBox(
      width: height * 2 / 3,
      height: height,
      child: Align(
        alignment: Alignment((column - 1).toDouble(), row == 0 ? -1.0 : 1.0),
        child: Image.asset(
          'assets/images/puzzle_props_atlas.png',
          width: height * 2,
          height: height * 2,
          fit: BoxFit.fill,
        ),
      ),
    ),
  );

  Widget _portal({required double size, bool muted = false}) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          Colors.transparent,
          muted ? const Color(0xFF477B9D) : const Color(0xFF44F2FF),
          const Color(0xFF563CE4),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: (muted ? Colors.blueGrey : Colors.cyanAccent).withValues(
            alpha: .55,
          ),
          blurRadius: 28,
          spreadRadius: 3,
        ),
      ],
    ),
    child: Center(
      child: Container(
        width: size * .55,
        height: size * .55,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF08142B),
        ),
      ),
    ),
  );

  Widget _comet(double size, {required bool held}) => Container(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: held
              ? Colors.cyanAccent.withValues(alpha: .65)
              : Colors.deepOrangeAccent.withValues(alpha: .35),
          blurRadius: 25,
        ),
      ],
    ),
    child: _prop(1, 0, size * 1.35),
  );

  Widget _sun(double size, {required bool covered}) => Stack(
    alignment: Alignment.center,
    children: [
      _prop(2, 0, size),
      if (covered)
        Container(
          width: size * .65,
          height: size * .65,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xCC111A33),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: .7)),
          ),
        ),
    ],
  );

  Widget _gravityArrow(double size, {required bool flipped}) =>
      Transform.rotate(angle: flipped ? math.pi : 0, child: _prop(0, 1, size));

  Widget _planet(double size) => Container(
    decoration: const BoxDecoration(
      boxShadow: [
        BoxShadow(color: Color(0x88FF9D5C), blurRadius: 24, spreadRadius: 2),
      ],
    ),
    child: _prop(1, 1, size),
  );

  Widget _hiddenStar(bool revealed) =>
      Opacity(opacity: revealed ? 1 : .08, child: _prop(2, 1, 70));

  Widget _successMark() => const Icon(
    Icons.check_circle_rounded,
    color: Colors.greenAccent,
    size: 42,
  );
}
