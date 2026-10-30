import 'dart:async';
import 'package:flutter/material.dart';
import '../models/energy_circuit_state.dart';
import '../core/widget/campaign_monetization_controls.dart';
import '../core/widget/campaign_completion_screen.dart';
import '../services/level_progress_service.dart';
import 'level/level_screen.dart';
import 'level_18_screen.dart';

class Level17Screen extends StatefulWidget {
  const Level17Screen({super.key, this.onLevelComplete});
  final VoidCallback? onLevelComplete;
  @override
  State<Level17Screen> createState() => _Level17ScreenState();
}

class _Level17ScreenState extends State<Level17Screen> {
  final game = EnergyCircuitState();
  Timer? overloadTimer;
  Timer? reactorTimer;
  int seconds = 8;
  bool paused = false;
  bool saving = false;
  String message =
      'Connect BLUE first. Six rotations power all three channels.';
  static const colors = [
    Color(0xFF55CFFF),
    Color(0xFFFFAB58),
    Color(0xFFC47AFF),
  ];
  @override
  void dispose() {
    overloadTimer?.cancel();
    reactorTimer?.cancel();
    super.dispose();
  }

  void reset() {
    overloadTimer?.cancel();
    reactorTimer?.cancel();
    setState(() {
      game.reset();
      seconds = 8;
      message = 'Fresh circuit. Connect BLUE first.';
    });
  }

  void rotate(int cell) {
    if (paused || saving || game.complete) return;
    setState(() => message = game.rotate(cell));
    if (game.overload) {
      overloadTimer?.cancel();
      overloadTimer = Timer(const Duration(seconds: 2), () {
        if (mounted)
          setState(() {
            game.discharge();
            message =
                'Hazard discharged. Confirm the receiver when the route is stable.';
          });
      });
    }
  }

  void confirm() {
    if (paused || saving) return;
    setState(() => message = game.confirm());
    if (game.complete) {
      reactorTimer?.cancel();
      reactorTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || paused) return;
        setState(() => seconds--);
        if (seconds <= 0) {
          timer.cancel();
          setState(() {
            game.reset();
            message = 'Reactor window expired. Circuit reset.';
            seconds = 8;
          });
        }
      });
    }
  }

  Future<void> stabilize() async {
    if (!game.complete || seconds <= 0 || saving) return;
    reactorTimer?.cancel();
    setState(() => saving = true);
    try {
      await LevelProgressService.complete(
        level: 17,
        stars: game.rotationsLeft == 0 ? 3 : 2,
      );
      widget.onLevelComplete?.call();
      if (!mounted) return;
      final navigator = Navigator.of(context);
      await navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => CampaignCompletionScreen(
            title: 'ENERGY CIRCUIT',
            onContinue: () => navigator.pushReplacement(
              MaterialPageRoute(builder: (_) => const Level18Screen()),
            ),
          ),
        ),
      );
    } catch (_) {
      if (mounted)
        setState(() {
          saving = false;
          message = 'Progress could not be saved. Tap STABILIZE to retry.';
        });
    }
  }

  Future<void> pause() async {
    if (saving) return;
    setState(() => paused = true);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('REACTOR PAUSED'),
        content: const Text('Circuit state and countdown are held.'),
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
    if (mounted) setState(() => paused = false);
  }

  void hint() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Circuit hint'),
      content: Text(
        game.complete
            ? 'The three receivers are active. Stabilize the reactor before the countdown ends.'
            : 'Work on ${['BLUE', 'ORANGE', 'PURPLE'][game.receiver]} only. The two unlit straight tiles in its row must each turn once to connect west to east. Watch the shared junction: it can send power into a dangerous branch.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('GOT IT'),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF070C1A),
    appBar: AppBar(
      backgroundColor: const Color(0xFF101B2E),
      title: const Text(
        '17 • ENERGY CIRCUIT',
        style: TextStyle(fontSize: 16, letterSpacing: 1),
      ),
      actions: [
        IconButton(
          tooltip: 'Pause',
          onPressed: pause,
          icon: const Icon(Icons.pause_rounded),
        ),
        IconButton(
          tooltip: 'Restart',
          onPressed: reset,
          icon: const Icon(Icons.restart_alt_rounded),
        ),
      ],
    ),
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [Color(0xFF1A2C47), Color(0xFF080D1C)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  const Text(
                    'REACTOR ROUTING ARRAY',
                    style: TextStyle(
                      color: Color(0xFF88E9FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    game.complete
                        ? 'FINAL REACTOR • $seconds s'
                        : '${['BLUE PLATFORM', 'ORANGE GATE', 'PURPLE REACTOR'][game.receiver]}  •  ${game.rotationsLeft}/6 TURNS LEFT',
                    style: TextStyle(
                      color: game.complete ? colors[2] : colors[game.receiver],
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF142238),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x664BAFCB)),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SOURCE',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              'RECEIVER / EXIT',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        AspectRatio(
                          aspectRatio: 1,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 25,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5,
                                  crossAxisSpacing: 5,
                                  mainAxisSpacing: 5,
                                ),
                            itemBuilder: (context, i) => _tile(i),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      3,
                      (i) => Column(
                        children: [
                          Icon(
                            i < game.receiver
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: colors[i],
                            size: 20,
                          ),
                          Text(
                            ['PLATFORM', 'GATE', 'REACTOR'][i],
                            style: TextStyle(
                              color: colors[i],
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (game.complete)
                    FilledButton.icon(
                      onPressed: stabilize,
                      icon: const Icon(Icons.bolt),
                      label: Text('STABILIZE • $seconds s'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: game.ready ? confirm : null,
                      icon: const Icon(Icons.bolt_rounded),
                      label: const Text('CHARGE RECEIVER'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: colors[game.receiver],
                        foregroundColor: const Color(0xFF081324),
                      ),
                    ),
                  const SizedBox(height: 16),
                  CampaignMonetizationControls(
                    level: 17,
                    onHint: hint,
                    onSkipped: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LevelScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Widget _tile(int i) {
    final tile = game.tiles[i];
    final active = game.powered.contains(i);
    final hazard = i == EnergyCircuitState.hazard;
    final color = hazard && game.overload
        ? const Color(0xFFFF5369)
        : colors[game.receiver.clamp(0, 2)];
    return Semantics(
      button: tile.rotatable,
      label:
          'Circuit tile row ${i ~/ 5 + 1}, column ${i % 5 + 1}, ${tile.shape.name}, ${tile.rotatable ? 'rotatable' : 'fixed'}',
      child: Material(
        color: const Color(0xFF24354A),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: tile.rotatable ? () => rotate(i) : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? color : Colors.white12,
                width: active ? 2 : 1,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: .35),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: CustomPaint(
              painter: _CircuitTilePainter(
                tile.ports,
                active ? color : const Color(0xFF6E849B),
                hazard: hazard && game.overload,
              ),
              child: Center(
                child: Text(
                  i == EnergyCircuitState.hazard
                      ? '⚠'
                      : EnergyCircuitState.sources.contains(i)
                      ? 'S'
                      : EnergyCircuitState.targets.contains(i)
                      ? 'R'
                      : tile.rotatable
                      ? '↻'
                      : '',
                  style: TextStyle(
                    color: active ? Colors.white : Colors.white54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircuitTilePainter extends CustomPainter {
  _CircuitTilePainter(this.ports, this.color, {required this.hazard});
  final int ports;
  final Color color;
  final bool hazard;
  @override
  void paint(Canvas canvas, Size size) {
    if (ports == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final points = [
      Offset(center.dx, 0),
      Offset(size.width, center.dy),
      Offset(center.dx, size.height),
      Offset(0, center.dy),
    ];
    for (var d = 0; d < 4; d++) {
      if (ports & (1 << d) == 0) continue;
      canvas.drawLine(
        center,
        points[d],
        Paint()
          ..color = color.withValues(alpha: .2)
          ..strokeWidth = 13
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        center,
        points[d],
        Paint()
          ..color = hazard ? Colors.redAccent : color
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(center, 5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CircuitTilePainter old) =>
      old.ports != ports || old.color != color || old.hazard != hazard;
}
