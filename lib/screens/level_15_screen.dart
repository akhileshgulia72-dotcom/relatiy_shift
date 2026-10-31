import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/widget/campaign_monetization_controls.dart';

import '../services/level_progress_service.dart';
import '../services/ads_service.dart';
import 'level/level_screen.dart';

/// Level 15: Gravity Collapse.
///
/// A standalone campaign screen. The player follows the floating-island route,
/// activates three gravity cores, then reaches the violet gateway. Gravity
/// cores are independent of the background artwork and remain fully tappable.
class Level15Screen extends StatefulWidget {
  const Level15Screen({super.key});

  @override
  State<Level15Screen> createState() => _Level15ScreenState();
}

class _Level15ScreenState extends State<Level15Screen> {
  static const _bg = 'assets/images/level15_gravity_collapse_bg.png';
  static const _night = Color(0xFF070B19);
  static const _cyan = Color(0xFF5DEBFF);
  static const _orange = Color(0xFFFFA544);
  static const _green = Color(0xFF55F2C0);
  static const _violet = Color(0xFFCB8CFF);

  // The route is deliberately a connected path on a 5 x 5 logical grid.
  // A checkpoint cannot be crossed until its matching gravity core is active.
  static const List<Offset> _route = [
    Offset(0, 4),
    Offset(1, 4),
    Offset(1, 3),
    Offset(2, 3),
    Offset(2, 2),
    Offset(3, 2),
    Offset(3, 1),
    Offset(4, 1),
    Offset(4, 0),
  ];
  static const Map<int, int> _checkpointCore = {2: 0, 4: 1, 6: 2};
  static const List<Color> _coreColors = [_cyan, _orange, _green];
  static const List<String> _coreNames = [
    'CYAN CORE',
    'SOLAR CORE',
    'EMERALD CORE',
  ];
  static const List<String> _coreDescriptions = [
    'Align the first bridge',
    'Redirect the broken path',
    'Stabilize the final platform',
  ];

  int _playerIndex = 0;
  final Set<int> _activeCores = <int>{};
  int _attempts = 0;
  bool _completed = false;
  bool _savingCompletion = false;
  bool _showHint = false;
  String _status = 'Activate the gravity cores, then follow the floating path.';

  Future<void> _activateCore(int core) async {
    if (_completed || _savingCompletion) return;
    if (_activeCores.contains(core)) {
      setState(() => _status = '${_coreNames[core]} is already stabilized.');
      return;
    }
    setState(() {
      _activeCores.add(core);
      _status =
          '${_coreNames[core]} stabilized. The gravity field has shifted.';
    });
    await HapticFeedback.mediumImpact();
  }

  Future<void> _move(int dx, int dy) async {
    if (_completed || _savingCompletion) return;
    final current = _route[_playerIndex];
    final target = Offset(current.dx + dx, current.dy + dy);
    final nextIndex = _route.indexOf(target);

    if (nextIndex < 0 || (nextIndex - _playerIndex).abs() != 1) {
      setState(() {
        _attempts++;
        _status = 'No stable platform there. Follow the glowing route.';
      });
      await HapticFeedback.selectionClick();
      return;
    }

    final requiredCore = _checkpointCore[nextIndex];
    if (requiredCore != null && !_activeCores.contains(requiredCore)) {
      setState(() {
        _attempts++;
        _status =
            'The bridge is unstable. Activate ${_coreNames[requiredCore]} first.';
      });
      await HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _playerIndex = nextIndex;
      _status = nextIndex == _route.length - 1
          ? 'Gateway reached. Stabilizing the rift…'
          : _checkpointCore.containsKey(nextIndex)
          ? 'Gravity checkpoint secured. Keep moving.'
          : 'Platform secured. Find the next gravity core.';
    });
    await HapticFeedback.lightImpact();

    if (_playerIndex == _route.length - 1) {
      await _finish();
    }
  }

  Future<void> _finish() async {
    if (_completed || _savingCompletion) return;
    setState(() {
      _savingCompletion = true;
      _completed = true;
      _status = 'Gravity restored. The gateway is open!';
    });
    final stars = _attempts == 0 ? 3 : (_attempts < 3 ? 2 : 1);
    try {
      await LevelProgressService.complete(level: 15, stars: stars);
    } finally {
      if (mounted) setState(() => _savingCompletion = false);
    }
  }

  void _restart() {
    setState(() {
      _playerIndex = 0;
      _activeCores.clear();
      _attempts = 0;
      _completed = false;
      _savingCompletion = false;
      _showHint = false;
      _status = 'Puzzle reset. Activate the cores in order and cross the void.';
    });
  }

  void _showHintDialog() {
    setState(() => _showHint = !_showHint);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101831),
        title: const Text('Gravity guidance', style: TextStyle(color: _cyan)),
        content: const Text(
          'Activate the Cyan Core, then move to the first checkpoint. Activate the Solar Core before crossing the middle bridge, and the Emerald Core before the final platform. Follow the glowing route to the violet gateway.',
          style: TextStyle(color: Color(0xFFE0E8FF), height: 1.45),
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

  Future<void> _continue() async {
    if (!_completed) return;
    await AdsService.instance.showInterstitialAtTransition();
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => campaignPageForLevel(16)!),
    );
  }

  Future<void> _backToLevels() async {
    await Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => const LevelScreen()),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _night,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _bg,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) => const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF101C45),
                    Color(0xFF080A18),
                    Color(0xFF24103D),
                  ],
                ),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, .12, .47, .76, 1],
                colors: [
                  Color(0xE8070B1B),
                  Color(0x66070B1B),
                  Color(0x22070B1B),
                  Color(0x99070B1B),
                  Color(0xF5070B1B),
                ],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 760;
                return Column(
                  children: [
                    _header(compact),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, compact ? 2 : 8, 16, 8),
                      child: _objectiveCard(),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: _playfield(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: CampaignMonetizationControls(
                        level: 15,
                        onHint: _showHintDialog,
                        onSkipped: () => Navigator.maybePop(context),
                      ),
                    ),
                    _bottomControls(compact),
                  ],
                );
              },
            ),
          ),
          if (_completed) _victoryOverlay(),
        ],
      ),
    );
  }

  Widget _header(bool compact) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14, compact ? 4 : 8, 14, 0),
      child: Row(
        children: [
          _roundButton(Icons.arrow_back_rounded, () => Navigator.pop(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MISSION 15 / 20',
                  style: TextStyle(
                    color: Color(0xFFFFD18A),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'THE DROWNED CONSTELLATION',
                  style: TextStyle(
                    color: _cyan.withValues(alpha: .95),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.25,
                  ),
                ),
                Text(
                  'GRAVITY COLLAPSE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 20 : 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .3,
                  ),
                ),
              ],
            ),
          ),
          _roundButton(Icons.refresh_rounded, _restart),
        ],
      ),
    );
  }

  Widget _objectiveCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xB9081026),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _cyan.withValues(alpha: .28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: _cyan, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _status,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFE2E9FF),
                fontSize: 11,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_activeCores.length}/3',
            style: const TextStyle(
              color: _cyan,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _playfield() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0x44060B20),
              border: Border.all(
                color: _cyan.withValues(alpha: .45),
                width: 1.2,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Stack(
              children: [
                // Soft glass overlay improves contrast while retaining the artwork.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: .08),
                          Colors.black.withValues(alpha: .35),
                        ],
                      ),
                    ),
                  ),
                ),
                ...List.generate(_route.length, (index) {
                  final point = _route[index];
                  final left = 0.09 + point.dx / 4 * .78;
                  final top = 0.12 + point.dy / 4 * .70;
                  final requiredCore = _checkpointCore[index];
                  final unlocked =
                      requiredCore == null ||
                      _activeCores.contains(requiredCore);
                  final isPlayer = index == _playerIndex;
                  final isExit = index == _route.length - 1;
                  final color = isExit
                      ? _violet
                      : (requiredCore == null
                            ? _cyan
                            : _coreColors[requiredCore]);
                  return Positioned(
                    left: (w * left) - 17,
                    top: (h * top) - 17,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      width: isPlayer ? 38 : 32,
                      height: isPlayer ? 38 : 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (unlocked ? color : const Color(0xFF65718C))
                            .withValues(alpha: isPlayer ? .96 : .72),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: isPlayer ? .95 : .62,
                          ),
                          width: isPlayer ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: isPlayer ? .8 : .38),
                            blurRadius: isPlayer ? 22 : 11,
                            spreadRadius: isPlayer ? 2 : 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        isPlayer
                            ? Icons.person_rounded
                            : isExit
                            ? Icons.blur_circular_rounded
                            : requiredCore != null
                            ? Icons.bolt_rounded
                            : Icons.circle,
                        color: Colors.white,
                        size: isPlayer ? 23 : 17,
                      ),
                    ),
                  );
                }),
                // Core controls float over the art and are separate from the image.
                Positioned(
                  left: 10,
                  right: 10,
                  top: 10,
                  child: Row(
                    children: List.generate(
                      3,
                      (core) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: core == 0 ? 0 : 5),
                          child: _coreButton(core, compact: true),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xD9070B1B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .15),
                      ),
                    ),
                    child: Text(
                      'ROUTE  ${_playerIndex + 1}/${_route.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xD9070B1B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _violet.withValues(alpha: .4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.door_front_door_rounded,
                          color: _violet,
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _completed ? 'GATE OPEN' : 'GATE SEALED',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _coreButton(int core, {bool compact = false}) {
    final active = _activeCores.contains(core);
    final color = _coreColors[core];
    return GestureDetector(
      onTap: () => _activateCore(core),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 10,
          vertical: compact ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: .22)
              : const Color(0xD90A1024),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: color.withValues(alpha: active ? .95 : .55),
            width: active ? 1.6 : 1,
          ),
          boxShadow: active
              ? [BoxShadow(color: color.withValues(alpha: .25), blurRadius: 14)]
              : const [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? Icons.bolt_rounded : Icons.circle_outlined,
              color: color,
              size: compact ? 13 : 18,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                compact ? ['CYAN', 'SOLAR', 'EMERALD'][core] : _coreNames[core],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 8 : 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomControls(bool compact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, compact ? 8 : 12, 16, compact ? 8 : 12),
      decoration: BoxDecoration(
        color: const Color(0xF0070B19),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: _cyan.withValues(alpha: .3))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'GRAVITY CORES',
                  style: TextStyle(
                    color: Color(0xFFAFBCD9),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              Text(
                '${_activeCores.length} OF 3 STABILIZED',
                style: const TextStyle(
                  color: _cyan,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: List.generate(
              3,
              (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                  child: _coreButton(i),
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: Text(
                  'MOVE  •  FOLLOW THE GLOWING ROUTE',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .58),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
              ),
              _directionButton(Icons.arrow_back_rounded, () => _move(-1, 0)),
              const SizedBox(width: 5),
              _directionButton(Icons.arrow_upward_rounded, () => _move(0, -1)),
              const SizedBox(width: 5),
              _directionButton(Icons.arrow_downward_rounded, () => _move(0, 1)),
              const SizedBox(width: 5),
              _directionButton(Icons.arrow_forward_rounded, () => _move(1, 0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _directionButton(IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 38,
      height: 38,
      child: Material(
        color: const Color(0xFF111C36),
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: Icon(icon, color: _cyan, size: 20),
        ),
      ),
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 39,
      height: 39,
      child: Material(
        color: const Color(0xC9101830),
        shape: CircleBorder(
          side: BorderSide(color: Colors.white.withValues(alpha: .17)),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _victoryOverlay() {
    final stars = _attempts == 0 ? 3 : (_attempts < 3 ? 2 : 1);
    return Container(
      color: const Color(0xD9070A18),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xF0101830),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: _violet.withValues(alpha: .7)),
          boxShadow: [
            BoxShadow(color: _violet.withValues(alpha: .18), blurRadius: 30),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded, color: _violet, size: 54),
            const SizedBox(height: 12),
            const Text(
              'GRAVITY RESTORED',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w900,
                letterSpacing: .6,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'The gateway opens. Reality bends to your will.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFBFCBE8), height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.star_rounded,
                    size: 31,
                    color: i < stars
                        ? const Color(0xFFFFD16B)
                        : const Color(0xFF47516C),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _violet,
                  foregroundColor: _night,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'CONTINUE TO LEVEL 16',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: _backToLevels,
              child: const Text(
                'BACK TO LEVEL SELECT',
                style: TextStyle(
                  color: Color(0xFFAFBCD9),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
