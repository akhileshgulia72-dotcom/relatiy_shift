import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/shadow_walker_state.dart';
import '../core/widget/campaign_monetization_controls.dart';
import '../core/widget/campaign_completion_screen.dart';
import '../services/level_progress_service.dart';
import 'level/level_screen.dart';

class Level20Screen extends StatefulWidget {
  const Level20Screen({super.key});
  @override
  State<Level20Screen> createState() => _Level20ScreenState();
}

class _Level20ScreenState extends State<Level20Screen>
    with SingleTickerProviderStateMixin {
  ShadowWalkerState game = ShadowWalkerState();
  late final AnimationController ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();
  bool saving = false;
  bool paused = false;
  String message = 'Block the light. Walk on its shadow. Recover the core.';
  @override
  void dispose() {
    ambient.dispose();
    super.dispose();
  }

  void reset() {
    if (saving) return;
    setState(() {
      game = ShadowWalkerState();
      message = 'New attempt. Align the first light with its blocker.';
    });
  }

  void archive() => Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const LevelScreen()),
  );
  Future<void> act(String Function() action) async {
    if (saving || paused) return;
    if (game.finished) {
      /* Retry persistence without another gameplay move. */
    } else {
      setState(() => message = action());
    }
    if (!game.finished) return;
    setState(() => saving = true);
    try {
      await LevelProgressService.complete(level: 20, stars: 3);
      if (!mounted) return;
      final navigator = Navigator.of(context);
      await navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => CampaignCompletionScreen(
            title: 'SHADOW WALKER',
            onContinue: () => navigator.pushReplacement(
              MaterialPageRoute(builder: (_) => const LevelScreen()),
            ),
          ),
        ),
      );
    } catch (_) {
      if (mounted)
        setState(() {
          saving = false;
          message = 'Could not save. Tap RETRY SAVE.';
        });
    }
  }

  Future<void> pause() async {
    if (saving) return;
    setState(() => paused = true);
    ambient.stop();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('MISSION PAUSED'),
        content: const Text('Your lights and platforms are holding position.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('RESUME'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              reset();
            },
            child: const Text('RESTART'),
          ),
        ],
      ),
    );
    if (mounted) {
      setState(() => paused = false);
      ambient.repeat();
    }
  }

  void hint() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Shadow Walker hint'),
      content: const Text(
        'On the starting island, choose Light 1 and rotate it to setting 2 in Reality A. Its beam strikes the blocker and creates the first bridge. Cross to the core at tile 7. Shift to Reality B on this metal island; choose Light 2 and set it to setting 2. Cross the second bridge and reach the portal. Never retune a light while standing on a shadow.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('GOT IT'),
        ),
      ],
    ),
  );
  static const cyan = Color(0xFF77E9FF);
  Widget panel(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xEE182C42), Color(0xF00B1527)],
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0x334C88A7)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
  Widget control(
    String label,
    IconData icon,
    VoidCallback action, {
    bool primary = false,
    bool selected = false,
  }) => SizedBox(
    height: 52,
    child: FilledButton.icon(
      onPressed: saving || paused ? null : action,
      icon: Icon(icon, size: 20),
      label: Text(label, maxLines: 1),
      style: FilledButton.styleFrom(
        backgroundColor: primary
            ? cyan
            : selected
            ? const Color(0xFF24485E)
            : const Color(0xFF182B40),
        foregroundColor: primary ? const Color(0xFF082131) : cyan,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: .5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? cyan : const Color(0x334D8BA6)),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF070F20),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0B192B),
      foregroundColor: Colors.white,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THE FINAL SECTOR / 20',
            style: TextStyle(color: cyan, fontSize: 9, letterSpacing: 2),
          ),
          SizedBox(height: 4),
          Text(
            'Shadow Walker',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Pause',
          onPressed: saving ? null : pause,
          icon: const Icon(Icons.pause_rounded),
        ),
        IconButton(
          tooltip: 'Restart',
          onPressed: saving ? null : reset,
          icon: const Icon(Icons.restart_alt_rounded),
        ),
      ],
    ),
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-.8, -.6),
          radius: 1.7,
          colors: [Color(0xFF18354A), Color(0xFF101C32), Color(0xFF060D1B)],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'MAKE THE DARKNESS YOUR PATH',
                      style: TextStyle(
                        color: cyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.7,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Align the lights. Cross the void.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Recover the core and reach the exit portal.',
                      style: TextStyle(color: Color(0xFF9EB4CA), fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0x665FA4BC)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x3300B8D4), blurRadius: 28),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(23),
                        child: Column(
                          children: [
                            Container(
                              color: const Color(0xFF14283B),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.blur_on_rounded,
                                    color: cyan,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'REALITY ${game.reality == 0 ? 'A' : 'B'}',
                                    style: const TextStyle(
                                      color: cyan,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    game.core
                                        ? Icons.check_circle_outline
                                        : Icons.diamond_outlined,
                                    color: const Color(0xFFFFD68A),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    game.core
                                        ? 'CORE SECURED'
                                        : 'FIND THE CORE',
                                    style: const TextStyle(
                                      color: Color(0xFFFFD68A),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AspectRatio(
                              aspectRatio: constraints.maxHeight > 750
                                  ? 1.12
                                  : 1.35,
                              child: AnimatedBuilder(
                                animation: ambient,
                                builder: (context, _) => CustomPaint(
                                  painter: _LabPainter(game, ambient.value),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x6613263B),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: cyan,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              message,
                              style: const TextStyle(
                                color: Color(0xFFBDD0E1),
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    panel(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'LIGHT CONTROL',
                            style: TextStyle(
                              color: Color(0xFF819DB7),
                              fontSize: 10,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              for (var i = 0; i < 2; i++) ...[
                                if (i > 0) const SizedBox(width: 10),
                                Expanded(
                                  child: control(
                                    'L${i + 1}  •  ${game.angles[i] + 1}/4',
                                    Icons.wb_incandescent_outlined,
                                    () => setState(() => game.selected = i),
                                    selected: game.selected == i,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: control(
                                  'TURN LEFT',
                                  Icons.rotate_left_rounded,
                                  () => act(() => game.tune(-1)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: control(
                                  'TURN RIGHT',
                                  Icons.rotate_right_rounded,
                                  () => act(() => game.tune(1)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          control(
                            'SHIFT REALITY',
                            Icons.auto_awesome_rounded,
                            () => act(game.shift),
                            primary: true,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(color: Color(0x334C88A7), height: 1),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: control(
                                  'MOVE LEFT',
                                  Icons.arrow_back_rounded,
                                  () => act(() => game.move(-1)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: control(
                                  'MOVE RIGHT',
                                  Icons.arrow_forward_rounded,
                                  () => act(() => game.move(1)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (game.finished && !saving)
                      control(
                        'RETRY SAVE',
                        Icons.save_outlined,
                        () => act(() => ''),
                      ),
                    if (!game.finished)
                      CampaignMonetizationControls(
                        level: 20,
                        onHint: hint,
                        onSkipped: archive,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _LabPainter extends CustomPainter {
  _LabPainter(this.game, this.time);
  final ShadowWalkerState game;
  final double time;
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 14, sy = size.height;
    Offset point(double x, double y) => Offset((x + 1) * sx, y * sy);
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF152840), Color(0xFF02040D)],
        ).createShader(bounds),
    );
    // Architectural scenery stays behind the logical collision surfaces.
    final wall = Paint()..color = const Color(0xFF1C334B);
    for (var i = 0; i < 6; i++) {
      final x = size.width * i / 5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 5, 0, 10, sy * .56),
          const Radius.circular(3),
        ),
        wall,
      );
      canvas.drawLine(
        Offset(x + 7, 0),
        Offset(x + 7, sy * .5),
        Paint()
          ..color = const Color(0x223DCEE5)
          ..strokeWidth = 1,
      );
    }
    final window = Rect.fromLTWH(
      size.width * .12,
      sy * .08,
      size.width * .76,
      sy * .43,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(window, const Radius.circular(18)),
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF20445F), Color(0xFF0B182C)],
        ).createShader(window),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(window, const Radius.circular(18)),
      Paint()
        ..color = const Color(0x3358CBE1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (var i = 0; i < 8; i++) {
      final y = sy * (.78 + i * .035);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()..color = const Color(0x152C87A4),
      );
      canvas.drawLine(
        Offset(size.width * .5, sy * .75),
        Offset(size.width * i / 7, sy),
        Paint()..color = const Color(0x152C87A4),
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(0, sy * .88, size.width, sy * .12),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00060B18), Color(0xFF060B18)],
        ).createShader(Rect.fromLTWH(0, sy * .88, size.width, sy * .12)),
    );
    for (var i = 0; i < 30; i++) {
      final x = (i * 67.1) % size.width;
      final y = ((i * 43.2) + time * 30) % size.height;
      canvas.drawCircle(
        Offset(x, y),
        1,
        Paint()..color = const Color(0x4465E9FF),
      );
    }
    for (var lamp = 0; lamp < 2; lamp++) {
      final x = ShadowWalkerState.lampX[lamp];
      final start = point(x, .15);
      final block = point(game.blockerX(lamp), .42);
      final end = point(
        x + 2 * ShadowWalkerState.settings[game.angles[lamp]],
        .69,
      );
      final hit = game.intercepted(lamp);
      final beamEnd = hit ? block : end;
      canvas.drawLine(
        start,
        beamEnd,
        Paint()
          ..color = const Color(0x4465E9FF)
          ..strokeWidth = 12
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawLine(
        start,
        beamEnd,
        Paint()
          ..color = const Color(0xFF94F4FF)
          ..strokeWidth = 2,
      );
      if (hit) {
        final center = game.shadowCenter(lamp);
        final shadow = Path()
          ..moveTo(block.dx - 5, block.dy)
          ..lineTo(point(center - 1.5, .69).dx, end.dy)
          ..lineTo(point(center + 1.5, .69).dx, end.dy)
          ..lineTo(block.dx + 5, block.dy)
          ..close();
        canvas.drawPath(shadow, Paint()..color = const Color(0x887D55C7));
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: block, width: sx * .7, height: 16),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF8998AD),
      );
      canvas.drawCircle(
        start,
        9,
        Paint()
          ..color = game.selected == lamp
              ? Colors.white
              : const Color(0xFF65E9FF),
      );
      final label = TextPainter(
        text: TextSpan(
          text: 'L${lamp + 1}',
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, start + const Offset(-8, -25));
    }
    for (var i = 0; i < 13; i++) {
      if (!game.supported(i)) continue;
      final metal = ShadowWalkerState.floor.contains(i);
      final p = point(i.toDouble(), .69);
      canvas.drawRect(
        Rect.fromLTWH(p.dx - sx / 2, p.dy, sx, metal ? 15 : 7),
        Paint()
          ..color = metal ? const Color(0xFF40556E) : const Color(0xFFB38BFF),
      );
      canvas.drawLine(
        Offset(p.dx - sx / 2, p.dy),
        Offset(p.dx + sx / 2, p.dy),
        Paint()
          ..color = metal ? const Color(0xFF65E9FF) : Colors.white
          ..strokeWidth = 2,
      );
    }
    final portal = point(12, .60);
    canvas.drawOval(
      Rect.fromCenter(center: portal, width: sx * .9, height: sy * .17),
      Paint()
        ..color = const Color(0xFF65E9FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 + math.sin(time * math.pi * 2),
    );
    if (!game.core) {
      final core = point(6, .59);
      canvas.drawCircle(core, 8, Paint()..color = const Color(0xFFFFD166));
    }
    final player = point(game.player.toDouble(), .65);
    canvas.drawCircle(
      player - const Offset(0, 12),
      5,
      Paint()..color = Colors.white,
    );
    canvas.drawLine(
      player - const Offset(0, 6),
      player + const Offset(0, 6),
      Paint()
        ..color = const Color(0xFF65E9FF)
        ..strokeWidth = 6,
    );
  }

  @override
  bool shouldRepaint(covariant _LabPainter oldDelegate) => true;
}
