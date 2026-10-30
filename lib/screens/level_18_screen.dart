import 'package:flutter/material.dart';
import '../models/gravity_loom_state.dart';
import '../core/widget/campaign_monetization_controls.dart';
import '../core/widget/campaign_completion_screen.dart';
import '../services/level_progress_service.dart';
import 'level/level_screen.dart';
import 'level_19_screen.dart';

class Level18Screen extends StatefulWidget {
  const Level18Screen({super.key});
  @override
  State<Level18Screen> createState() => _Level18ScreenState();
}

class _Level18ScreenState extends State<Level18Screen> {
  GravityLoomState game = GravityLoomState();
  bool paused = false, saving = false;
  String message =
      'Tilt gravity to slide the probe. Shift reality to change the walls.';
  static const cyan = Color(0xFF6DE9FF),
      violet = Color(0xFFC39BFF),
      amber = Color(0xFFFFD17A);
  void reset() {
    if (saving) return;
    setState(() {
      game = GravityLoomState();
      message = 'Loom reset. Find a route to both switches.';
    });
  }

  Future<void> tilt(int direction) async {
    if (paused || saving) return;
    if (!game.completed) setState(() => message = game.tilt(direction));
    if (!game.completed) return;
    setState(() => saving = true);
    try {
      await LevelProgressService.complete(
        level: 18,
        stars: game.moves <= 21
            ? 3
            : game.moves <= 29
            ? 2
            : 1,
      );
      if (!mounted) return;
      final navigator = Navigator.of(context);
      await navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => CampaignCompletionScreen(
            title: 'GRAVITY LOOM',
            onContinue: () => navigator.pushReplacement(
              MaterialPageRoute(builder: (_) => const Level19Screen()),
            ),
          ),
        ),
      );
    } catch (_) {
      if (mounted)
        setState(() {
          saving = false;
          message = 'Progress could not be saved. Tap RETRY SAVE.';
        });
    }
  }

  void shift() {
    if (paused || saving || game.completed) return;
    setState(() => message = game.shift());
  }

  Future<void> pause() async {
    if (saving) return;
    setState(() => paused = true);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('LOOM PAUSED'),
        content: const Text(
          'The probe and shifting walls are holding position.',
        ),
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
      title: const Text('Gravity Loom hint'),
      content: Text(
        game.switchesActive == 0
            ? 'The probe slides until something stops it. Begin by shifting to Violet, then tilt UP and RIGHT. Use the new wall pattern to reach the first switch.'
            : game.switchesActive != 3
            ? 'One switch is active. Shift reality to change your stopping points; the other switch is near the lower right. A wall can be useful as a brake.'
            : game.core
            ? 'The core is secured. The exit is at the upper right. Change realities to find a stopping point beside it.'
            : 'Both switches are active. Land on the center core before going to the exit.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('GOT IT'),
        ),
      ],
    ),
  );
  void archive() => Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const LevelScreen()),
  );
  Widget action(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool bright = false,
  }) => SizedBox(
    height: 54,
    child: FilledButton.icon(
      onPressed: saving || paused ? null : onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: bright ? cyan : const Color(0xFF20344E),
        foregroundColor: bright ? const Color(0xFF061927) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: .6,
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF070C19),
    appBar: AppBar(
      backgroundColor: const Color(0xFF101B2E),
      title: const Text(
        '18 • GRAVITY LOOM',
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
          center: Alignment(-.6, -.7),
          radius: 1.6,
          colors: [Color(0xFF20354E), Color(0xFF0A1225), Color(0xFF060A15)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  const Text(
                    'BEND GRAVITY. REWRITE THE ROOM.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Slide the probe onto both switches. Claim the center core, then reach the exit.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF192B42), Color(0xFF0D172B)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0x665CA8C3)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x4400D6FF), blurRadius: 24),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.blur_on_rounded,
                              color: game.reality == 0 ? cyan : violet,
                              size: 18,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'REALITY ${game.reality == 0 ? 'CYAN' : 'VIOLET'}',
                              style: TextStyle(
                                color: game.reality == 0 ? cyan : violet,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${game.moves} TILTS',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
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
                            itemBuilder: (context, i) => _cell(i),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFC4D5E7),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _status('SWITCH A', game.switchesActive & 1 != 0),
                      _status('SWITCH B', game.switchesActive & 2 != 0),
                      _status('CORE', game.core),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xE815253C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x335CA8C3)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'GRAVITY CONTROL',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Spacer(),
                            Expanded(
                              child: action(
                                'UP',
                                Icons.keyboard_arrow_up_rounded,
                                () => tilt(0),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: action(
                                'LEFT',
                                Icons.keyboard_arrow_left_rounded,
                                () => tilt(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: action(
                                'DOWN',
                                Icons.keyboard_arrow_down_rounded,
                                () => tilt(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: action(
                                'RIGHT',
                                Icons.keyboard_arrow_right_rounded,
                                () => tilt(1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: action(
                            'SHIFT REALITY',
                            Icons.auto_awesome_rounded,
                            shift,
                            bright: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (game.completed && !saving)
                    action('RETRY SAVE', Icons.save_outlined, () => tilt(0)),
                  if (!game.completed)
                    CampaignMonetizationControls(
                      level: 18,
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
  );
  Widget _status(String label, bool active) => Column(
    children: [
      Icon(
        active
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        color: active ? amber : Colors.white30,
        size: 19,
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          color: active ? amber : Colors.white54,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
  Widget _cell(int i) {
    final wall = game.isWall(i),
        phaseWall =
            GravityLoomState.cyanWalls.contains(i) ||
            GravityLoomState.violetWalls.contains(i),
        player = game.position == i,
        sw = GravityLoomState.switches.indexOf(i),
        active = sw >= 0 && (game.switchesActive & (1 << sw)) != 0;
    return Semantics(
      label:
          'Row ${i ~/ 5 + 1}, column ${i % 5 + 1}${wall ? ', wall' : ''}${player ? ', probe' : ''}',
      child: Container(
        decoration: BoxDecoration(
          color: wall
              ? phaseWall
                    ? (game.reality == 0
                          ? const Color(0xFF325D78)
                          : const Color(0xFF5A467B))
                    : const Color(0xFF344054)
              : const Color(0xFF18283C),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: player
                ? cyan
                : active
                ? amber
                : wall
                ? Colors.white24
                : const Color(0x333987A5),
            width: player ? 2 : 1,
          ),
          boxShadow: player
              ? [const BoxShadow(color: Color(0x886DE9FF), blurRadius: 14)]
              : null,
        ),
        child: Center(
          child: wall
              ? Icon(
                  phaseWall ? Icons.grid_4x4_rounded : Icons.block_rounded,
                  color: Colors.white38,
                  size: 18,
                )
              : player
              ? const Icon(
                  Icons.radio_button_checked_rounded,
                  color: cyan,
                  size: 32,
                )
              : sw >= 0
              ? Icon(Icons.bolt_rounded, color: active ? amber : Colors.white38)
              : i == GravityLoomState.coreCell
              ? Icon(
                  Icons.diamond_rounded,
                  color: game.core ? Colors.white24 : amber,
                )
              : i == GravityLoomState.exitCell
              ? Icon(
                  Icons.door_front_door_rounded,
                  color: game.core ? cyan : Colors.white38,
                )
              : null,
        ),
      ),
    );
  }
}
