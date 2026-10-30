import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:reality_shift/core/widget/campaign_monetization_controls.dart';

import '../models/quantum_puzzle_state.dart';
import '../services/level_progress_service.dart';
import 'advanced_puzzle_screen.dart';

const _ink = Color(0xFF070B19);
const _blue = Color(0xFF48DFFF);
const _purple = Color(0xFFD476FF);

/// Level 6 uses the same Flutter puzzle-screen architecture as the other
/// campaign levels, with a fixed tile board for reliable box collisions.
class Level6Screen extends StatefulWidget {
  const Level6Screen({super.key});

  @override
  State<Level6Screen> createState() => _Level6ScreenState();
}

class _Level6ScreenState extends State<Level6Screen>
    with TickerProviderStateMixin {
  QuantumPuzzleState _game = QuantumPuzzleState();
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat(reverse: true);
  late final AnimationController _shift = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  String _message = 'Two realities. Two quantum boxes. One way out.';
  bool _completionStarted = false;

  Color get _accent => _game.reality == QuantumReality.blue ? _blue : _purple;

  @override
  void dispose() {
    _ambient.dispose();
    _shift.dispose();
    super.dispose();
  }

  void _move(int direction) {
    if (_game.completed) return;
    setState(() {
      final result = _game.move(direction);
      _message = switch (result) {
        QuantumMoveResult.moved => 'Keep going. The marked ledge is ahead.',
        QuantumMoveResult.boxAhead =>
          'A quantum box blocks the path. Press PUSH to move it.',
        QuantumMoveResult.unsupported =>
          'You are above the ground. Jump toward the portal or stay on the stack.',
        QuantumMoveResult.edge => 'The platform ends here.',
      };
    });
  }

  void _push() {
    if (_game.completed) return;
    setState(() {
      if (!_game.canPush) {
        _message = 'Move beside the active box and face it to push.';
      } else if (!_game.push()) {
        _message = _game.activeBoxIsBlue
            ? 'The blue box is at the edge of its ledge.'
            : 'The purple box needs the blue box below it.';
      } else if (_game.staircaseStable) {
        _message = 'Boxes synchronized. The staircase holds in both realities.';
      } else if (_game.activeBoxIsBlue) {
        _message = _game.blueBoxColumn == 6
            ? 'Blue box secured on the lower step. Switch realities.'
            : 'Blue box moved. Push it to the glowing lower step.';
      } else {
        _message = 'Purple box moved. Set it above the blue box.';
      }
    });
  }

  void _switchReality() {
    if (_game.completed || _shift.isAnimating) return;
    setState(() {
      if (!_game.switchReality()) {
        _message =
            'Shift from the shared platform so the world can change safely.';
        return;
      }
      _message = _game.reality == QuantumReality.blue
          ? 'Reality A: the blue box is solid. The purple box is an echo.'
          : 'Reality B: the purple box is solid. Find a way around it.';
      _shift.forward(from: 0);
    });
  }

  void _jump() {
    if (_game.completed) return;
    final result = _game.jump();
    setState(() {
      _message = switch (result) {
        QuantumJumpResult.climbed when _game.playerHeight == 1 =>
          'You’re on the blue step. Jump again to reach the purple box.',
        QuantumJumpResult.climbed =>
          'The exit is within reach. Jump forward into the portal.',
        QuantumJumpResult.clearedBox =>
          'Nice hop. Turn around and push the box toward the staircase.',
        QuantumJumpResult.enteredPortal => 'Portal reached. Reality restored.',
        QuantumJumpResult.blocked =>
          _game.playerColumn == 5 &&
                  _game.blueBoxColumn == 6 &&
                  _game.reality == QuantumReality.purple &&
                  !_game.staircaseStable
              ? 'The lower step is only solid in Reality A.'
              : 'There is no safe landing yet.',
      };
    });
    if (result == QuantumJumpResult.enteredPortal) {
      unawaited(_completeLevel());
    }
  }

  Future<void> _completeLevel() async {
    if (_completionStarted) return;
    _completionStarted = true;
    await LevelProgressService.complete(level: 6, stars: 3);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF10172B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'LEVEL COMPLETE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: .7,
          ),
        ),
        content: const Text(
          'Quantum Boxes solved. The path between realities is restored.',
          style: TextStyle(color: Color(0xFFD1D9EA), height: 1.45),
        ),
        actions: [
          FilledButton.icon(
            key: const ValueKey('next-mission'),
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdvancedPuzzleScreen(level: 7),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('NEXT MISSION'),
          ),
        ],
      ),
    );
  }

  void _restart() {
    setState(() {
      _game = QuantumPuzzleState();
      _message = 'Two realities. Two quantum boxes. One way out.';
      _completionStarted = false;
    });
  }

  void _showHint() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF11182D),
        title: const Text(
          'A hint from the archive',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'In Reality A, walk beside the blue box and push it to the lower step. Shift while standing on the shared ledge. In Reality B, hop over the purple box, turn around, and push it onto the blue box. Shift back, jump up the two-box staircase, then jump into the portal.',
          style: TextStyle(color: Color(0xFFD0D8EA), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }

  Future<void> _pause() async {
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF11182D),
        title: const Text(
          'MISSION PAUSED',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Your quantum boxes are holding position.',
          style: TextStyle(color: Color(0xFFD0D8EA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'restart'),
            child: const Text('RESTART'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'resume'),
            child: const Text('RESUME'),
          ),
        ],
      ),
    );
    if (action == 'restart' && mounted) _restart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
          child: CampaignMonetizationControls(
            level: 6,
            onHint: _showHint,
            onSkipped: () => Navigator.maybePop(context),
          ),
        ),
      ),
      backgroundColor: _ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 9),
              _missionIntro(),
              const SizedBox(height: 8),
              Expanded(child: _scene()),
              const SizedBox(height: 8),
              _statusCard(),
              const SizedBox(height: 8),
              _movementControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => Row(
    children: [
      _iconButton(Icons.arrow_back_rounded, () => Navigator.pop(context)),
      const SizedBox(width: 9),
      _iconButton(
        Icons.pause_rounded,
        _pause,
        key: const ValueKey('pause-level'),
      ),
      const SizedBox(width: 9),
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: const Text(
            'MISSION 06 / 20',
            style: TextStyle(
              color: Color(0xFFB7C5E0),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
      const Spacer(),
    ],
  );

  Widget _missionIntro() => Column(
    children: [
      const Text(
        'QUANTUM BOXES',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.7,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Build the staircase, then jump for the exit portal.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: .75),
          fontSize: 12,
        ),
      ),
    ],
  );

  Widget _scene() => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;
      final tileWidth = width / 10;
      final tileHeight = math.min(tileWidth * 1.16, height * .19);
      final baseY = height * .83;
      final actorWidth = tileWidth * .96;
      final actorHeight = tileHeight * 1.66;
      final actorLeft = _game.playerColumn * tileWidth + tileWidth * .02;
      final actorTop = baseY - _game.playerHeight * tileHeight - actorHeight;

      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AnimatedBuilder(
          animation: Listenable.merge([_ambient, _shift]),
          builder: (context, _) => Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/level6_quantum_backdrop.png',
                fit: BoxFit.cover,
                alignment: const Alignment(0, .25),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x28060B18),
                      Color(0x12060B18),
                      Color(0x99060B18),
                    ],
                  ),
                ),
              ),
              CustomPaint(
                painter: _QuantumScenePainter(
                  reality: _game.reality,
                  phase: _ambient.value,
                  blueBoxColumn: _game.blueBoxColumn,
                  purpleBoxColumn: _game.purpleBoxColumn,
                  blueBoxVisible: _game.blueBoxVisible,
                  purpleBoxVisible: _game.purpleBoxVisible,
                  staircaseStable: _game.staircaseStable,
                  portalActive: _game.puzzleSolved,
                ),
              ),
              Positioned(
                left: actorLeft,
                top: actorTop,
                width: actorWidth,
                height: actorHeight,
                child: Transform.scale(
                  scaleX: _game.facing < 0 ? -1 : 1,
                  child: Image.asset(
                    'assets/images/level5_astronaut.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.rocket_launch_rounded,
                      color: Colors.white,
                      size: actorWidth * .8,
                    ),
                  ),
                ),
              ),
              Positioned(left: 11, top: 11, child: _realityBadge()),
              if (_shift.value < .8)
                IgnorePointer(
                  child: ColoredBox(
                    color: _accent.withValues(alpha: (1 - _shift.value) * .18),
                  ),
                ),
              if (_game.puzzleSolved)
                Positioned(
                  right: 10,
                  top: 10,
                  child: _chip('STAIRCASE STABLE', const Color(0xFFABFFE6)),
                ),
            ],
          ),
        ),
      );
    },
  );

  Widget _realityBadge() {
    final isBlue = _game.reality == QuantumReality.blue;
    final accent = isBlue ? _blue : _purple;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey(_game.reality),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xDD091124),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: .8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.blur_circular_rounded, size: 14, color: accent),
            const SizedBox(width: 6),
            Text(
              isBlue ? 'REALITY A · BLUE' : 'REALITY B · PURPLE',
              style: TextStyle(
                color: accent,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: .65,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCard() => Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 48),
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xCC11182D),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _accent.withValues(alpha: .35)),
    ),
    child: Row(
      children: [
        Icon(Icons.auto_awesome_rounded, size: 17, color: _accent),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            _message,
            key: ValueKey(_message),
            style: const TextStyle(
              color: Color(0xFFE1E7F4),
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _shiftButton() => SizedBox(
    width: 58,
    height: 58,
    child: OutlinedButton(
      key: const ValueKey('switch-reality'),
      onPressed: _game.completed || _shift.isAnimating ? null : _switchReality,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.zero,
        foregroundColor: _accent,
        backgroundColor: const Color(0x9911182D),
        side: BorderSide(color: _accent.withValues(alpha: .52)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sync_alt_rounded, size: 20),
          const SizedBox(height: 2),
          Text(
            _game.reality == QuantumReality.blue ? 'SHIFT B' : 'SHIFT A',
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    ),
  );

  Widget _movementControls() => SizedBox(
    height: 64,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xAA11182D),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: .2)),
          ),
          child: Row(
            children: [
              _directionButton(Icons.arrow_left_rounded, -1, 'move-left'),
              const SizedBox(width: 4),
              _directionButton(Icons.arrow_right_rounded, 1, 'move-right'),
            ],
          ),
        ),
        _actionButton(
          key: const ValueKey('push-box'),
          icon: Icons.open_with_rounded,
          label: 'PUSH',
          onPressed: _game.completed || !_game.canPush ? null : _push,
        ),
        _actionButton(
          key: const ValueKey('jump'),
          icon: Icons.arrow_upward_rounded,
          label: 'JUMP',
          primary: true,
          onPressed: _game.completed ? null : _jump,
        ),
        _shiftButton(),
      ],
    ),
  );

  Widget _directionButton(IconData icon, int direction, String keyName) =>
      Material(
        color: const Color(0xFF24314C),
        shape: const CircleBorder(),
        child: InkWell(
          key: ValueKey(keyName),
          customBorder: const CircleBorder(),
          onTap: _game.completed ? null : () => _move(direction),
          child: SizedBox(
            width: 43,
            height: 43,
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
      );

  Widget _actionButton({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool primary = false,
  }) => SizedBox(
    width: primary ? 60 : 56,
    height: 58,
    child: ElevatedButton(
      key: key,
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: primary ? _accent : const Color(0xFF202C45),
        foregroundColor: primary ? _ink : Colors.white,
        disabledBackgroundColor: const Color(0xFF141D31),
        disabledForegroundColor: Colors.white30,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: primary ? _accent : const Color(0x557D91B4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: .7,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _iconButton(IconData icon, VoidCallback onTap, {Key? key}) => Material(
    color: const Color(0xAA17223A),
    shape: const CircleBorder(),
    child: InkWell(
      key: key,
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 39,
        height: 39,
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    ),
  );

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xE6071020),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withValues(alpha: .65)),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 8,
        fontWeight: FontWeight.w900,
        letterSpacing: .7,
      ),
    ),
  );
}

class _QuantumScenePainter extends CustomPainter {
  const _QuantumScenePainter({
    required this.reality,
    required this.phase,
    required this.blueBoxColumn,
    required this.purpleBoxColumn,
    required this.blueBoxVisible,
    required this.purpleBoxVisible,
    required this.staircaseStable,
    required this.portalActive,
  });

  final QuantumReality reality;
  final double phase;
  final int blueBoxColumn;
  final int purpleBoxColumn;
  final bool blueBoxVisible;
  final bool purpleBoxVisible;
  final bool staircaseStable;
  final bool portalActive;

  Color get accent => reality == QuantumReality.blue ? _blue : _purple;

  @override
  void paint(Canvas canvas, Size size) {
    final tileW = size.width / 10;
    final tileH = math.min(tileW * 1.16, size.height * .19);
    final baseY = size.height * .83;
    // Shared ledge keeps reality shifts safe. The colored seam identifies the
    // active world's floor, while the separate edge pad is the lower box step.
    _drawPlatform(
      canvas,
      0,
      tileW * 2.85,
      baseY,
      tileH * .27,
      const Color(0xFF59627A),
      1,
    );
    _drawPlatform(
      canvas,
      tileW * 3.02,
      tileW * 3.1,
      baseY,
      tileH * .3,
      const Color(0xFF566078),
      1,
    );
    _drawPlatform(
      canvas,
      tileW * 6.04,
      tileW * .9,
      baseY,
      tileH * .26,
      const Color(0xFF515B74),
      .98,
    );
    _drawPlatform(
      canvas,
      tileW * 8.03,
      tileW * 1.97,
      baseY - tileH * 2,
      tileH * .27,
      const Color(0xFF59627A),
      1,
    );

    _drawActiveSeam(canvas, tileW * 3.05, tileW * 3.0, baseY, accent);
    _drawActiveSeam(canvas, tileW * 6.04, tileW * .9, baseY, accent);
    _drawActiveSeam(
      canvas,
      tileW * 8.03,
      tileW * 1.97,
      baseY - tileH * 2,
      accent,
    );
    _drawGroundFog(canvas, size, accent);

    // Portal pad and elevated exit sit beyond the gap; only the built staircase
    // lights the portal strongly enough to invite the final jump.
    final portalCenter = Offset(tileW * 9.03, baseY - tileH * 2 - tileH * .78);
    _drawPortal(canvas, portalCenter, tileW * .43, phase, portalActive, accent);

    if (blueBoxVisible) {
      _drawBox(
        canvas,
        tileW * (blueBoxColumn + .5),
        baseY,
        tileW * .76,
        tileH * .92,
        _blue,
        phase,
        false,
      );
    }
    if (purpleBoxVisible) {
      final stackLevel = staircaseStable && purpleBoxColumn == 6 ? 1 : 0;
      _drawBox(
        canvas,
        tileW * (purpleBoxColumn + .5),
        baseY - tileH * stackLevel,
        tileW * .76,
        tileH * .92,
        _purple,
        phase,
        true,
      );
    }
  }

  void _drawPlatform(
    Canvas canvas,
    double left,
    double width,
    double surfaceY,
    double depth,
    Color stone,
    double opacity,
  ) {
    final top = Path()
      ..moveTo(left, surfaceY)
      ..lineTo(left + width * .12, surfaceY - depth * .52)
      ..lineTo(left + width, surfaceY - depth * .52)
      ..lineTo(left + width * .88, surfaceY)
      ..close();
    final front = Path()
      ..moveTo(left, surfaceY)
      ..lineTo(left + width * .88, surfaceY)
      ..lineTo(left + width * .88, surfaceY + depth)
      ..lineTo(left + width, surfaceY + depth * .55)
      ..lineTo(left + width, surfaceY - depth * .52)
      ..lineTo(left + width * .88, surfaceY)
      ..close();
    canvas.drawPath(
      front,
      Paint()
        ..color = Color.lerp(
          stone,
          const Color(0xFF111827),
          .42,
        )!.withValues(alpha: opacity),
    );
    canvas.drawPath(
      top,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            stone.withValues(alpha: opacity),
            Color.lerp(
              stone,
              const Color(0xFF28344A),
              .4,
            )!.withValues(alpha: opacity),
          ],
        ).createShader(top.getBounds()),
    );
    canvas.drawPath(
      top,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .19 * opacity),
    );
  }

  void _drawActiveSeam(
    Canvas canvas,
    double left,
    double width,
    double y,
    Color color,
  ) {
    final paint = Paint()
      ..color = color.withValues(alpha: .88)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(left + 3, y - 1),
      Offset(left + width * .86, y - 1),
      paint,
    );
    canvas.drawCircle(
      Offset(left + width * .55, y - 2),
      2,
      paint..style = PaintingStyle.fill,
    );
  }

  void _drawBox(
    Canvas canvas,
    double centerX,
    double bottomY,
    double width,
    double height,
    Color color,
    double phase,
    bool isPurple,
  ) {
    final rect = Rect.fromLTWH(
      centerX - width / 2,
      bottomY - height,
      width,
      height,
    );
    final glow = Paint()
      ..color = color.withValues(alpha: .24 + .08 * phase)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(3), const Radius.circular(6)),
      glow,
    );
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: .67),
          Color.lerp(
            color,
            const Color(0xFF10172D),
            .67,
          )!.withValues(alpha: .95),
        ],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
    final inset = rect.deflate(width * .18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inset, const Radius.circular(4)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color.withValues(alpha: .75),
    );
    canvas.drawCircle(
      rect.center,
      width * .095,
      Paint()
        ..color = color.withValues(alpha: .18)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      rect.center,
      width * .095,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final runePaint = Paint()
      ..color = color.withValues(alpha: .9)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    final runeX = centerX + (isPurple ? -1 : 1) * width * .24;
    canvas.drawLine(
      Offset(runeX, rect.top + height * .25),
      Offset(runeX, rect.top + height * .49),
      runePaint,
    );
    canvas.drawCircle(
      Offset(runeX, rect.top + height * .21),
      1.6,
      runePaint..style = PaintingStyle.fill,
    );
  }

  void _drawPortal(
    Canvas canvas,
    Offset center,
    double radius,
    double phase,
    bool active,
    Color color,
  ) {
    final glow = Paint()
      ..color = color.withValues(alpha: active ? .32 : .11)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center, radius * 1.35, glow);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            (active ? _blue : color).withValues(alpha: .88),
            color.withValues(alpha: .35),
            const Color(0xFF11142F),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    for (var ring = 0; ring < 3; ring++) {
      final r = radius * (.48 + ring * .25);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        phase * math.pi * 2 + ring * 1.5,
        math.pi * (1.25 + ring * .12),
        false,
        Paint()
          ..color = (ring.isEven ? _blue : _purple).withValues(
            alpha: active ? .95 : .48,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring == 0 ? 2.1 : 1.2,
      );
    }
    if (!active) {
      canvas.drawLine(
        Offset(center.dx - radius * .5, center.dy),
        Offset(center.dx + radius * .5, center.dy),
        Paint()..color = Colors.white.withValues(alpha: .55),
      );
    }
  }

  void _drawGroundFog(Canvas canvas, Size size, Color color) {
    final rect = Rect.fromLTWH(
      0,
      size.height * .72,
      size.width,
      size.height * .28,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            color.withValues(alpha: .09),
            const Color(0xAA070B19),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _QuantumScenePainter oldDelegate) =>
      oldDelegate.reality != reality ||
      oldDelegate.phase != phase ||
      oldDelegate.blueBoxColumn != blueBoxColumn ||
      oldDelegate.purpleBoxColumn != purpleBoxColumn ||
      oldDelegate.blueBoxVisible != blueBoxVisible ||
      oldDelegate.purpleBoxVisible != purpleBoxVisible ||
      oldDelegate.staircaseStable != staircaseStable ||
      oldDelegate.portalActive != portalActive;
}
