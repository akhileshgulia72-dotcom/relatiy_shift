import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../core/widget/campaign_monetization_controls.dart';
import '../services/ads_service.dart';

import '../data/level_catalog.dart';
import '../services/level_progress_service.dart';
import 'chapter_puzzle_screen.dart';
import 'level/level_screen.dart';

const _void = Color(0xFF070A18);
const _cyan = Color(0xFF70E9FF);
const _purple = Color(0xFFB393FF);

/// The four advanced campaign puzzles. Each mission has a separate state
/// machine, while sharing the campaign's progress, hint, restart and victory UI.
class AdvancedPuzzleScreen extends StatefulWidget {
  const AdvancedPuzzleScreen({super.key, required this.level})
    : assert(level >= 7 && level <= 10);

  final int level;

  @override
  State<AdvancedPuzzleScreen> createState() => _AdvancedPuzzleScreenState();
}

class _AdvancedPuzzleScreenState extends State<AdvancedPuzzleScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat(reverse: true);
  late final Ticker _physicsTicker;
  final Map<int, Timer> _bridgeCollapseTimers = {};
  final Map<int, Timer> _bridgeParticleTimers = {};
  Timer? _bridgeFallTimer;
  Duration? _physicsElapsed;

  int _attempts = 0;
  bool _completed = false;
  bool _rewardReady = false;
  bool _nextStarted = false;
  String _status = '';

  // Level 7: project the light ray through the moved reliquary onto the floor.
  Offset _light = const Offset(.72, .18);
  Offset _relic = const Offset(.46, .53);
  bool _cageOpen = false;
  bool _keyHeld = false;

  // Level 8: normalized 2D ball state, integrated with bounded fixed-size steps.
  Offset _ball = const Offset(.84, .84);
  Offset _velocity = Offset.zero;
  int _gravity = 0;
  int _gravityRoute = 0;
  bool _collisionFeedback = false;

  // Level 9: follow the one-way zigzag bridge before its tiles collapse.
  int _bridgePlayerTile = 0;
  final Set<int> _collapsedBridgeTiles = {};
  final Set<int> _bridgeParticleTiles = {};
  bool _bridgeFalling = false;
  static const List<Offset> _bridgeRoute = [
    Offset(0, 5),
    Offset(1, 5),
    Offset(1, 4),
    Offset(2, 4),
    Offset(3, 4),
    Offset(3, 3),
    Offset(4, 3),
    Offset(4, 2),
    Offset(5, 2),
    Offset(5, 1),
  ];

  // Level 10: independent portal and connected-platform transforms.
  double _portalScale = .8;
  double _portalScaleAtGestureStart = .8;
  int _platformTurns = 0;
  Offset _moonPosition = const Offset(.20, .56);
  bool _moonSent = false;
  bool _switchActive = false;

  LevelStory get _story => storyForLevel(widget.level);
  String get _background => switch (widget.level) {
    7 => 'assets/images/level07_shadow_room_bg.png',
    8 => 'assets/images/level08_gravity_chamber_bg.png',
    9 => 'assets/images/level09_disappearing_bridge_bg.png',
    _ => 'assets/images/level10_mirror_bg.png',
  };

  @override
  void initState() {
    super.initState();
    _physicsTicker = createTicker(_stepPhysics);
    if (widget.level == 8) _physicsTicker.start();
    _status = switch (widget.level) {
      7 => 'Move the light. Keep the relic inside its safe halo.',
      8 => 'The sphere obeys gravity—and the surfaces around it.',
      9 =>
        'Cross the zigzag bridge before its tiles collapse. A fall resets your run.',
      _ => 'Make a route for the moon, then let it rewrite the room.',
    };
  }

  @override
  void dispose() {
    for (final timer in _bridgeCollapseTimers.values) {
      timer.cancel();
    }
    for (final timer in _bridgeParticleTimers.values) {
      timer.cancel();
    }
    _bridgeFallTimer?.cancel();
    _physicsTicker.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _restart() {
    for (final timer in _bridgeCollapseTimers.values) {
      timer.cancel();
    }
    _bridgeCollapseTimers.clear();
    for (final timer in _bridgeParticleTimers.values) {
      timer.cancel();
    }
    _bridgeParticleTimers.clear();
    _bridgeFallTimer?.cancel();
    _physicsElapsed = null;
    setState(() {
      _attempts = 0;
      _completed = false;
      _rewardReady = false;
      _nextStarted = false;
      _light = const Offset(.72, .18);
      _relic = const Offset(.46, .53);
      _cageOpen = false;
      _keyHeld = false;
      _ball = const Offset(.84, .84);
      _velocity = Offset.zero;
      _gravity = 0;
      _gravityRoute = 0;
      _collisionFeedback = false;
      _bridgePlayerTile = 0;
      _collapsedBridgeTiles.clear();
      _bridgeParticleTiles.clear();
      _bridgeFalling = false;
      _portalScale = .8;
      _portalScaleAtGestureStart = .8;
      _platformTurns = 0;
      _moonPosition = const Offset(.20, .56);
      _moonSent = false;
      _switchActive = false;
      _status = 'Puzzle reset. Try another approach.';
    });
    if (widget.level == 8 && !_physicsTicker.isActive) {
      _physicsTicker.start();
    }
  }

  Future<void> _finish() async {
    if (_completed) return;
    setState(() {
      _completed = true;
      _status = 'Reality has shifted.';
    });
    for (final timer in _bridgeCollapseTimers.values) {
      timer.cancel();
    }
    _bridgeFallTimer?.cancel();
    if (_physicsTicker.isActive) _physicsTicker.stop();
    final stars = _attempts == 0 ? 3 : (_attempts < 3 ? 2 : 1);
    await LevelProgressService.complete(level: widget.level, stars: stars);
    if (!mounted) return;
    setState(() => _rewardReady = true);
  }

  Future<void> _next() async {
    if (!_completed || !_rewardReady || _nextStarted) return;
    _nextStarted = true;
    await AdsService.instance.showInterstitialAtTransition();
    if (!mounted) return;
    final Widget next = switch (widget.level) {
      7 || 8 || 9 => AdvancedPuzzleScreen(level: widget.level + 1),
      10 => const ChapterPuzzleScreen(level: 11),
      _ => const LevelScreen(),
    };
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => next),
    );
  }

  void _showHintFromReward() {
    final hint = switch (widget.level) {
      7 =>
        'Drag the light until the relic’s shadow touches the floor switch. Then drag the relic into its glowing halo to open the portal.',
      8 =>
        'Swipe the gravity control to change the ball’s fall direction. Guide it around the wall: floor, side wall, ceiling, then the narrow ledge.',
      9 =>
        'Path: RIGHT, UP, RIGHT, RIGHT, UP, RIGHT, UP, RIGHT, UP. Each tile collapses shortly after you land, so keep moving toward the portal.',
      _ =>
        'Grow the portal until the moon fits. Turn the connected bridge once, move the moon onto its launch mark, then send it through.',
    };
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151832),
        title: const Text(
          'A hint from the archive',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          hint,
          style: const TextStyle(color: Color(0xFFD0D4E8), height: 1.45),
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

  void _miss(String message) {
    if (_completed) return;
    _attempts++;
    setState(() => _status = message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _void,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(_background, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xBC080A1A),
                  Color(0x54201A43),
                  Color(0xEC080A18),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 9, 16, 13),
              child: Column(
                children: [
                  _header(),
                  const SizedBox(height: 10),
                  _missionIntro(),
                  const SizedBox(height: 11),
                  Expanded(child: _board()),
                  const SizedBox(height: 9),
                  _statusCard(),
                  const SizedBox(height: 7),
                  _missionControls(),
                  const SizedBox(height: 8),
                  CampaignMonetizationControls(
                    level: widget.level,
                    onHint: _showHintFromReward,
                    onSkipped: () => Navigator.maybePop(context),
                  ),
                ],
              ),
            ),
          ),
          if (_completed) _completionOverlay(),
        ],
      ),
    );
  }

  Widget _header() => Row(
    children: [
      _iconButton(Icons.arrow_back_rounded, () => Navigator.pop(context)),
      const Spacer(),
      _chip('MISSION ${widget.level.toString().padLeft(2, '0')}', _cyan),
      const Spacer(),
      const SizedBox(width: 7),
      _iconButton(Icons.refresh_rounded, _restart),
    ],
  );

  Widget _missionIntro() => Column(
    children: [
      Text(
        _story.title.toUpperCase(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 21,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.25,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        _intro,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFD3D9EF),
          fontSize: 11.5,
          height: 1.35,
        ),
      ),
    ],
  );

  String get _intro => switch (widget.level) {
    7 => 'Put the shadow on the switch. Keep the object in its safe zone.',
    8 => 'Guide the sphere around the barrier with four directions of gravity.',
    9 =>
      'The bridge collapses a moment after you step on it. Keep moving toward the portal.',
    _ => 'Enlarge the portal, align the bridge, and send the moon through.',
  };

  Widget _board() => LayoutBuilder(
    builder: (context, bounds) => ClipRRect(
      borderRadius: BorderRadius.circular(23),
      child: Container(
        key: const ValueKey('puzzle-board'),
        decoration: BoxDecoration(
          color: const Color(0x55212847),
          border: Border.all(color: const Color(0x6679E9FF)),
          borderRadius: BorderRadius.circular(23),
        ),
        child: switch (widget.level) {
          7 => _shadowBoard(bounds.maxWidth, bounds.maxHeight),
          8 => _gravityBoard(bounds.maxWidth, bounds.maxHeight),
          9 => _bridgeBoard(bounds.maxWidth, bounds.maxHeight),
          _ => _moonBoard(bounds.maxWidth, bounds.maxHeight),
        },
      ),
    ),
  );

  Widget _shadowBoard(double w, double h) {
    final floorY = h * .84;
    final shadowX = _shadowProjection(floorY / h);
    final inSafeZone =
        (_relic.dx - .46).abs() < .12 && (_relic.dy - .53).abs() < .09;
    final onSwitch = (shadowX - .74).abs() < .045 && inSafeZone;
    final onPortal = (shadowX - .27).abs() < .045 && inSafeZone && _keyHeld;
    if (onSwitch && !_cageOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_cageOpen) {
          setState(() {
            _cageOpen = true;
            _status = 'Shadow switch engaged. The glass cage is open.';
          });
        }
      });
    }
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _ShadowBoardPainter(
              _light,
              _relic,
              shadowX,
              onSwitch,
              onPortal,
            ),
          ),
        ),
        Positioned(
          left: w * .04,
          top: h * .04,
          child: _chip(
            _keyHeld
                ? 'KEY SECURED'
                : (_cageOpen ? 'CAGE OPEN' : 'CAGE SEALED'),
            _keyHeld ? _cyan : _purple,
          ),
        ),
        Positioned(
          left: w * .68,
          top: floorY - 13,
          child: _floorMarker('SWITCH', _cyan, onSwitch),
        ),
        Positioned(
          left: w * .20,
          top: floorY - 13,
          child: _floorMarker('PORTAL MARK', _purple, onPortal),
        ),
        Positioned(
          left: _light.dx * w - 25,
          top: _light.dy * h - 25,
          child: GestureDetector(
            key: const ValueKey('shadow-light'),
            onPanUpdate: (d) => setState(
              () => _light = Offset(
                (_light.dx + d.delta.dx / w).clamp(.08, .92),
                (_light.dy + d.delta.dy / h).clamp(.07, .38),
              ),
            ),
            child: _glowingOrb(50, const Color(0xFFBDF8FF)),
          ),
        ),
        Positioned(
          left: _relic.dx * w - 28,
          top: _relic.dy * h - 28,
          child: GestureDetector(
            key: const ValueKey('shadow-object'),
            onPanUpdate: (d) => setState(
              () => _relic = Offset(
                (_relic.dx + d.delta.dx / w).clamp(.15, .85),
                (_relic.dy + d.delta.dy / h).clamp(.34, .70),
              ),
            ),
            child: _relicObject(inSafeZone),
          ),
        ),
        Positioned(
          right: w * .08,
          top: h * .48,
          child: GestureDetector(
            key: const ValueKey('shadow-cage'),
            onTap: () {
              if (!_cageOpen) {
                return _miss('The cage responds to the floor switch.');
              }
              if (!_keyHeld) {
                setState(() {
                  _keyHeld = true;
                  _status =
                      'The key hums in your hand. Aim the shadow at the portal mark.';
                });
              }
            },
            child: _cage(w, h),
          ),
        ),
        Positioned(
          left: w * .02,
          top: h * .24,
          child: GestureDetector(
            key: const ValueKey('shadow-exit'),
            onTap: () {
              if (!_keyHeld) {
                return _miss(
                  'The exit is locked. Find the key in the glass cage.',
                );
              }
              if (!onPortal) {
                return _miss(
                  'The shadow must touch the portal mark. Move the light across the relic.',
                );
              }
              _finish();
            },
            child: _exitPortal(ready: onPortal),
          ),
        ),
        Positioned(
          bottom: h * .025,
          right: w * .04,
          child: _chip(
            'SHADOW ${shadowX.toStringAsFixed(2)}',
            onSwitch || onPortal ? _cyan : Colors.white70,
          ),
        ),
        if (!inSafeZone)
          Positioned(
            left: w * .24,
            top: h * .61,
            child: _chip('RELIC OUTSIDE SAFE ZONE', const Color(0xFFFFB477)),
          ),
      ],
    );
  }

  double _shadowProjection(double floorY) {
    final denominator = _relic.dy - _light.dy;
    if (denominator.abs() < .04) return _relic.dx;
    final scale = (floorY - _light.dy) / denominator;
    return (_light.dx + (_relic.dx - _light.dx) * scale).clamp(.02, .98);
  }

  Widget _floorMarker(String label, Color color, bool active) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        width: 30,
        height: 15,
        decoration: BoxDecoration(
          color: color.withValues(alpha: active ? .9 : .22),
          borderRadius: BorderRadius.circular(50),
          boxShadow: active
              ? [BoxShadow(color: color.withValues(alpha: .8), blurRadius: 15)]
              : null,
          border: Border.all(color: color.withValues(alpha: .8)),
        ),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 7,
          letterSpacing: .6,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );

  Widget _relicObject(bool safe) => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE2EDFF), Color(0xFF657BBD), Color(0xFF27284F)],
      ),
      border: Border.all(
        color: safe ? _cyan : const Color(0xFFFFB477),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: (safe ? _cyan : const Color(0xFFFFB477)).withValues(alpha: .4),
          blurRadius: 18,
        ),
      ],
    ),
    child: const Icon(
      Icons.diamond_rounded,
      color: Color(0xFF13172E),
      size: 31,
    ),
  );

  Widget _cage(double w, double h) => Container(
    width: w * .22,
    height: h * .23,
    decoration: BoxDecoration(
      color: const Color(0x331A2846),
      border: Border.all(
        color: _cageOpen ? _cyan : const Color(0xAA9C8CFF),
        width: 2,
      ),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: (_cageOpen ? _cyan : _purple).withValues(alpha: .25),
          blurRadius: 17,
        ),
      ],
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        if (!_cageOpen)
          const Icon(
            Icons.grid_4x4_rounded,
            color: Color(0x99D5D4F5),
            size: 38,
          ),
        Icon(
          _keyHeld ? Icons.check_circle_rounded : Icons.key_rounded,
          color: _keyHeld ? _cyan : const Color(0xFFFFD477),
          size: 29,
        ),
      ],
    ),
  );

  Widget _gravityBoard(double w, double h) {
    final gravity = _gravityVector;
    final directions = ['DOWN', 'LEFT', 'UP', 'RIGHT'];
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _GravityCoursePainter(_gravityRoute, _collisionFeedback),
          ),
        ),
        Positioned(
          left: w * .04,
          top: h * .035,
          child: _chip('GRAVITY  ${directions[_gravity]}', _cyan),
        ),
        Positioned(
          right: w * .04,
          top: h * .035,
          child: Transform.rotate(
            angle: math.atan2(gravity.dy, gravity.dx) + math.pi / 2,
            child: Icon(Icons.arrow_upward_rounded, color: _cyan, size: 25),
          ),
        ),
        Positioned(
          left: _ball.dx * w - w * .04,
          top: _ball.dy * h - w * .04,
          child: _metalSphere(w * .08),
        ),
        Positioned(
          left: w * .76,
          top: h * .64,
          child: _exitPortal(ready: _gravityRoute >= 3),
        ),
        Positioned(
          left: w * .12,
          bottom: h * .06,
          child: _chip(
            'ROUTE ${_gravityRoute.clamp(0, 4)} / 4',
            _gravityRoute >= 3 ? _cyan : _purple,
          ),
        ),
        if (_collisionFeedback)
          Positioned(
            right: w * .07,
            bottom: h * .06,
            child: _chip('BARRIER CONTACT', const Color(0xFFFFB477)),
          ),
      ],
    );
  }

  Offset get _gravityVector => switch (_gravity) {
    0 => const Offset(0, 1),
    1 => const Offset(-1, 0),
    2 => const Offset(0, -1),
    _ => const Offset(1, 0),
  };

  void _stepPhysics(Duration elapsed) {
    if (_completed || widget.level != 8) return;
    final previous = _physicsElapsed;
    _physicsElapsed = elapsed;
    if (previous == null) return;
    final dt = ((elapsed - previous).inMicroseconds / 1000000).clamp(0, .025);
    if (dt <= 0) return;
    final g = _gravityVector;
    var velocity = Offset(
      (_velocity.dx + g.dx * 1.35 * dt).clamp(-.72, .72),
      (_velocity.dy + g.dy * 1.35 * dt).clamp(-.72, .72),
    );
    var next = Offset(_ball.dx + velocity.dx * dt, _ball.dy + velocity.dy * dt);
    const radius = .045;
    if (next.dx < .055 || next.dx > .945) {
      next = Offset(next.dx.clamp(.055, .945), next.dy);
      velocity = Offset(0, velocity.dy * .80);
    }
    if (next.dy < .09 || next.dy > .88) {
      next = Offset(next.dx, next.dy.clamp(.09, .88));
      velocity = Offset(velocity.dx * .82, 0);
    }
    // The amber obstruction occupies the floor route. Contact arrests the
    // sphere; reversing gravity lifts it above the barrier before it can pass.
    const obstacle = Rect.fromLTRB(.44, .64, .55, .88);
    final expanded = obstacle.inflate(radius);
    final hit =
        next.dx > expanded.left &&
        next.dx < expanded.right &&
        next.dy > expanded.top &&
        next.dy < expanded.bottom;
    var feedback = false;
    if (hit) {
      feedback = true;
      if (_gravity == 1 && _gravityRoute == 0) _gravityRoute = 1;
      if (g.dx != 0) velocity = Offset(0, velocity.dy);
      if (g.dy != 0) velocity = Offset(velocity.dx, 0);
      next = _ball;
    } else {
      if (_gravity == 2 && next.dy < .15 && _gravityRoute >= 1) {
        _gravityRoute = 2;
      }
      if (_gravity == 3 &&
          next.dx > .79 &&
          next.dy < .2 &&
          _gravityRoute >= 2) {
        _gravityRoute = 3;
      }
      if (_gravity == 0 &&
          _gravityRoute >= 3 &&
          next.dx > .75 &&
          next.dy > .68) {
        next = Offset(next.dx, .68);
        velocity = Offset(velocity.dx * .45, 0);
        _gravityRoute = 4;
      }
    }
    if (next != _ball ||
        velocity != _velocity ||
        feedback != _collisionFeedback) {
      setState(() {
        _ball = next;
        _velocity = velocity;
        _collisionFeedback = feedback;
        if (_gravityRoute == 1) {
          _status =
              'The barrier stopped the sphere. Lift it above the amber edge.';
        }
        if (_gravityRoute == 2) {
          _status = 'Ceiling reached. Cross over the obstruction.';
        }
        if (_gravityRoute == 3) {
          _status = 'Narrow ledge below. Let gravity carry it down.';
        }
        if (_gravityRoute == 4 && !_completed) {
          _status = 'Perfect landing. The exit is open.';
        }
      });
      if (_gravityRoute == 4 && !_completed) unawaited(_finish());
    }
  }

  Widget _gravityControls() => _controlButton(
    'SHIFT GRAVITY',
    Icons.rotate_90_degrees_cw_rounded,
    const ValueKey('gravity-shift'),
    () {
      if (_completed) return;
      setState(() {
        _gravity = (_gravity + 1) % 4;
        _velocity = Offset.zero;
        _status =
            'Gravity now pulls ${['down', 'left', 'up', 'right'][_gravity]}.';
        if (_gravity == 1 && _gravityRoute == 0) {
          _status = 'Cross the floor. The amber block will stop your path.';
        }
      });
    },
  );

  Widget _bridgeBoard(double w, double h) {
    final tileSize = math.min(w * .135, h * .105);
    final safeTile = _bridgePlayerTile.clamp(0, _bridgeRoute.length - 1);
    final progress = (safeTile / (_bridgeRoute.length - 1)).clamp(0.0, 1.0);
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _BridgeRoutePainter(_bridgeRoute)),
        ),
        Positioned(
          left: w * .035,
          top: h * .025,
          child: _chip('BRIDGE COLLAPSE  •  1.7 SEC', const Color(0xFFFFC978)),
        ),
        Positioned(
          right: w * .035,
          top: h * .025,
          child: _chip('STEP ${safeTile.clamp(0, 9)} / 9', _cyan),
        ),
        for (var i = 0; i < _bridgeRoute.length; i++)
          _bridgeTilePosition(i, w, h, tileSize),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          left: w * (.09 + _bridgeRoute[safeTile].dx * .15) - 18,
          top: _bridgeFalling
              ? h * .92
              : h * (.15 + _bridgeRoute[safeTile].dy * .13) - 27,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _bridgeFalling ? .15 : 1,
            child: _bridgeAvatar(),
          ),
        ),
        Positioned(
          left: w * .07,
          right: w * .07,
          bottom: h * .035,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    'PORTAL DISTANCE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 8,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: _cyan,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: const Color(0x66202A50),
                  valueColor: const AlwaysStoppedAnimation(_cyan),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Positioned _bridgeTilePosition(int index, double w, double h, double size) {
    final grid = _bridgeRoute[index];
    final collapsed = _collapsedBridgeTiles.contains(index);
    final isExit = index == _bridgeRoute.length - 1;
    final left = w * (.09 + grid.dx * .15) - size / 2;
    final top = h * (.15 + grid.dy * .13) - size / 2;
    return Positioned(
      left: left,
      top: top,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (_bridgeParticleTiles.contains(index))
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('bridge-particles-$index'),
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 680),
                  builder: (context, value, _) => CustomPaint(
                    painter: _BridgeParticlePainter(
                      value,
                      index.isEven ? _cyan : _purple,
                    ),
                  ),
                ),
              ),
            AnimatedScale(
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeInBack,
              scale: collapsed ? .15 : 1,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 330),
                opacity: collapsed ? 0 : 1,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size * .22),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isExit
                          ? const [Color(0xFF5B38AD), Color(0xFF141A39)]
                          : (index == 0
                                ? const [Color(0xFF176D8F), Color(0xFF15213E)]
                                : const [Color(0xFF34446C), Color(0xFF11182E)]),
                    ),
                    border: Border.all(
                      color: isExit
                          ? _purple
                          : (index == _bridgePlayerTile
                                ? _cyan
                                : const Color(0x997FA5E8)),
                      width: index == _bridgePlayerTile || isExit ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isExit ? _purple : _cyan).withValues(
                          alpha: isExit || index == _bridgePlayerTile
                              ? .65
                              : .25,
                        ),
                        blurRadius: isExit ? 20 : 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    isExit
                        ? Icons.blur_circular_rounded
                        : (index == 0
                              ? Icons.flag_rounded
                              : Icons.grid_4x4_rounded),
                    color: isExit ? Colors.white : _cyan,
                    size: size * .44,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bridgeAvatar() => Container(
    key: const ValueKey('bridge-player'),
    width: 38,
    height: 50,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      color: const Color(0xFFDBF4FF),
      border: Border.all(color: _cyan, width: 1.5),
      boxShadow: const [BoxShadow(color: Color(0xAA70E9FF), blurRadius: 16)],
      image: const DecorationImage(
        image: AssetImage('assets/images/level5_astronaut.png'),
        fit: BoxFit.cover,
      ),
    ),
  );

  void _moveBridge(int dx, int dy) {
    if (_completed || _bridgeFalling) return;
    final current =
        _bridgeRoute[_bridgePlayerTile.clamp(0, _bridgeRoute.length - 1)];
    final wanted = Offset(current.dx + dx, current.dy + dy);
    final nextIndex = _bridgeRoute.indexOf(wanted);
    if (nextIndex >= 0) {
      if (nextIndex == _bridgePlayerTile + 1) {
        if (nextIndex == _bridgeRoute.length - 1) {
          _bridgeCollapseTimers[_bridgePlayerTile]?.cancel();
          unawaited(_finish());
          return;
        }
        if (_collapsedBridgeTiles.contains(nextIndex)) {
          _fallFromBridge();
          return;
        }
        setState(() {
          _bridgePlayerTile = nextIndex;
          _status =
              'Keep moving—the tile beneath you will collapse in 1.7 seconds.';
        });
        _scheduleBridgeCollapse(nextIndex);
        return;
      }
      if (nextIndex == _bridgePlayerTile - 1 &&
          !_collapsedBridgeTiles.contains(nextIndex)) {
        setState(() {
          _bridgePlayerTile = nextIndex;
          _status = 'The path behind you is still solid. Find the next turn.';
        });
        _scheduleBridgeCollapse(nextIndex);
        return;
      }
    }
    _fallFromBridge();
  }

  void _scheduleBridgeCollapse(int index) {
    if (index <= 0 ||
        index >= _bridgeRoute.length - 1 ||
        _bridgeCollapseTimers.containsKey(index)) {
      return;
    }
    _bridgeCollapseTimers[index] = Timer(const Duration(milliseconds: 1700), () {
      if (!mounted || _completed) return;
      setState(() {
        _collapsedBridgeTiles.add(index);
        _bridgeParticleTiles.add(index);
        _status =
            'Tile ${index.toString().padLeft(2, '0')} collapsed into the void.';
      });
      if (_bridgePlayerTile == index) _fallFromBridge();
      _bridgeParticleTimers[index] = Timer(
        const Duration(milliseconds: 720),
        () {
          if (mounted) setState(() => _bridgeParticleTiles.remove(index));
        },
      );
    });
  }

  void _fallFromBridge() {
    if (_bridgeFalling || _completed) return;
    _attempts++;
    for (final timer in _bridgeCollapseTimers.values) {
      timer.cancel();
    }
    _bridgeCollapseTimers.clear();
    setState(() {
      _bridgeFalling = true;
      _status = 'You fell into the void. The bridge is rebuilding…';
    });
    _bridgeFallTimer?.cancel();
    _bridgeFallTimer = Timer(const Duration(milliseconds: 760), () {
      if (!mounted || _completed) return;
      setState(() {
        _bridgePlayerTile = 0;
        _collapsedBridgeTiles.clear();
        _bridgeParticleTiles.clear();
        _bridgeFalling = false;
        _status = 'Bridge restored. Follow the cyan and violet route.';
      });
    });
  }

  Widget _bridgeControls() => Column(
    children: [
      const Text(
        'MOVE  •  KEEP AHEAD OF THE COLLAPSE',
        style: TextStyle(
          color: Color(0xFFBFC8E8),
          fontSize: 8,
          letterSpacing: 1.05,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          _bridgeArrow(Icons.arrow_back_rounded, 'bridge-left', -1, 0),
          const SizedBox(width: 7),
          _bridgeArrow(Icons.arrow_upward_rounded, 'bridge-up', 0, -1),
          const SizedBox(width: 7),
          _bridgeArrow(Icons.arrow_downward_rounded, 'bridge-down', 0, 1),
          const SizedBox(width: 7),
          _bridgeArrow(Icons.arrow_forward_rounded, 'bridge-right', 1, 0),
        ],
      ),
    ],
  );

  Widget _bridgeArrow(IconData icon, String key, int dx, int dy) => Expanded(
    child: SizedBox(
      height: 44,
      child: IconButton.filledTonal(
        key: ValueKey(key),
        onPressed: _completed ? null : () => _moveBridge(dx, dy),
        icon: Icon(icon, color: _cyan),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xCC171B38),
          foregroundColor: _cyan,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
            side: const BorderSide(color: Color(0x6670E9FF)),
          ),
        ),
      ),
    ),
  );

  Widget _switchNode(String label, bool active, {required bool echo}) =>
      Container(
        width: 58,
        height: 42,
        decoration: BoxDecoration(
          color: active
              ? _cyan.withValues(alpha: .34)
              : const Color(0x88131B34),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: active ? _cyan : _purple.withValues(alpha: .7),
            width: 1.5,
          ),
          boxShadow: active
              ? [BoxShadow(color: _cyan.withValues(alpha: .55), blurRadius: 17)]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              echo ? Icons.history_rounded : Icons.radio_button_checked_rounded,
              color: active ? Colors.white : _purple,
              size: 16,
            ),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFFB5B9D1),
                fontSize: 7,
                letterSpacing: .8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );

  Widget _moonBoard(double w, double h) {
    final portalReady = _portalScale >= 1.38;
    final platformReady = _platformTurns % 4 == 1;
    final moonReady =
        (_moonPosition.dx - .34).abs() < .10 &&
        (_moonPosition.dy - .56).abs() < .11;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: w * .03,
          top: h * .04,
          child: _chip(
            'PORTAL ${_portalScale.toStringAsFixed(1)}×',
            portalReady ? _cyan : _purple,
          ),
        ),
        Positioned(
          left: w * .08,
          top: h * .25,
          child: _chip('LAUNCH MARK', moonReady ? _cyan : Colors.white70),
        ),
        Positioned(left: w * .24, top: h * .49, child: _targetRing(moonReady)),
        Positioned(
          left: w * .46,
          top: h * .42,
          child: Transform.rotate(
            angle: _platformTurns * math.pi / 2,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              width: w * .23,
              height: h * .06,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: LinearGradient(
                  colors: platformReady
                      ? [_cyan, _purple]
                      : [const Color(0xFF57617D), const Color(0xFF292E49)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (platformReady ? _cyan : _purple).withValues(
                      alpha: .4,
                    ),
                    blurRadius: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: w * .68,
          top: h * .25,
          child: GestureDetector(
            key: const ValueKey('moon-portal'),
            onScaleStart: (_) => _portalScaleAtGestureStart = _portalScale,
            onScaleUpdate: (details) => setState(
              () => _portalScale = (_portalScaleAtGestureStart * details.scale)
                  .clamp(.65, 1.8),
            ),
            child: _portalRing(w * .24 * _portalScale, portalReady),
          ),
        ),
        Positioned(
          left: w * .79,
          top: h * .64,
          child: _switchNode('FINAL', _switchActive, echo: false),
        ),
        Positioned(
          left: w * .79,
          top: h * .47,
          child: _exitPortal(ready: _switchActive),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 850),
          curve: Curves.easeInOutCubic,
          left: (_moonSent ? .77 : _moonPosition.dx) * w - w * .075,
          top: (_moonSent ? .68 : _moonPosition.dy) * h - w * .075,
          child: GestureDetector(
            key: const ValueKey('moon'),
            onPanUpdate: _moonSent
                ? null
                : (d) => setState(
                    () => _moonPosition = Offset(
                      (_moonPosition.dx + d.delta.dx / w).clamp(.08, .46),
                      (_moonPosition.dy + d.delta.dy / h).clamp(.30, .78),
                    ),
                  ),
            child: AnimatedScale(
              scale: _moonSent ? .65 : 1,
              duration: const Duration(milliseconds: 500),
              child: Image.asset(
                'assets/images/full_moon_icon.png',
                width: w * .15,
                height: w * .15,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: h * .04,
          left: w * .07,
          right: w * .07,
          child: _portalSlider(),
        ),
      ],
    );
  }

  Widget _portalSlider() => Column(
    children: [
      Row(
        children: [
          const Icon(Icons.open_in_full_rounded, color: _cyan, size: 13),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'PORTAL APERTURE  ·  PINCH OR SLIDE',
              style: TextStyle(
                color: Color(0xFFD9D9EF),
                fontSize: 8,
                letterSpacing: .7,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            _portalScale >= 1.38 ? 'MOON FITS' : 'TOO SMALL',
            style: TextStyle(
              color: _portalScale >= 1.38 ? _cyan : _purple,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      SizedBox(
        height: 26,
        child: Slider(
          key: const ValueKey('portal-slider'),
          value: _portalScale,
          min: .65,
          max: 1.8,
          onChanged: (v) => setState(() => _portalScale = v),
          activeColor: _cyan,
          inactiveColor: Colors.white24,
        ),
      ),
    ],
  );

  void _rotatePlatform() {
    if (_completed) return;
    setState(() {
      _platformTurns = (_platformTurns + 1) % 4;
      _status = _platformTurns % 4 == 1
          ? 'Bridge aligned. Put the moon on its launch mark.'
          : 'The linked bridge rotates with the room.';
    });
  }

  Future<void> _sendMoon() async {
    if (_completed || _moonSent) return;
    final ready =
        _portalScale >= 1.38 &&
        _platformTurns % 4 == 1 &&
        (_moonPosition.dx - .34).abs() < .10 &&
        (_moonPosition.dy - .56).abs() < .11;
    if (!ready) {
      return _miss('Portal, bridge, and launch mark must align first.');
    }
    setState(() {
      _moonSent = true;
      _switchActive = true;
      _status = 'The moon returns small enough to become a weight.';
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) await _finish();
  }

  Widget _moonControls() => Row(
    children: [
      Expanded(
        child: _controlButton(
          'ROTATE BRIDGE',
          Icons.sync_alt_rounded,
          const ValueKey('moon-rotate'),
          _rotatePlatform,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _controlButton(
          _moonSent ? 'SWITCH ACTIVE' : 'SEND MOON',
          Icons.brightness_7_rounded,
          const ValueKey('moon-send'),
          _sendMoon,
        ),
      ),
    ],
  );

  Widget _missionControls() => switch (widget.level) {
    7 => _controlButton(
      _keyHeld
          ? 'AIM SHADOW AT PORTAL'
          : (_cageOpen ? 'COLLECT THE KEY' : 'ALIGN SHADOW'),
      Icons.wb_incandescent_rounded,
      const ValueKey('shadow-step'),
      () {
        if (!_cageOpen) {
          _miss('Drag the light until the shadow reaches the switch.');
          return;
        }
        if (!_keyHeld) {
          setState(() {
            _keyHeld = true;
            _status = 'Key acquired. Now aim the shadow at the portal mark.';
          });
          return;
        }
        final x = _shadowProjection(.84);
        if ((x - .27).abs() < .045 && _isRelicSafe) {
          unawaited(_finish());
        } else {
          _miss('Move the light until the shadow reaches the portal target.');
        }
      },
    ),
    8 => _gravityControls(),
    9 => _bridgeControls(),
    _ => _moonControls(),
  };

  bool get _isRelicSafe =>
      (_relic.dx - .46).abs() < .12 && (_relic.dy - .53).abs() < .09;

  Widget _statusCard() => AnimatedContainer(
    duration: const Duration(milliseconds: 220),
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xCA10162B),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0x447E78FF)),
    ),
    child: Row(
      children: [
        const Icon(Icons.auto_awesome_rounded, color: _purple, size: 16),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            _status,
            key: const ValueKey('puzzle-status'),
            style: const TextStyle(
              color: Color(0xFFE4E6F4),
              fontSize: 10.5,
              height: 1.25,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _controlButton(
    String label,
    IconData icon,
    Key key,
    VoidCallback action,
  ) => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      key: key,
      onPressed: _completed ? null : action,
      icon: Icon(icon, size: 16, color: _cyan),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          letterSpacing: .85,
          fontWeight: FontWeight.w900,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xEE201F43),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF181A2B),
        padding: const EdgeInsets.symmetric(vertical: 11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0x6678DDF5)),
        ),
      ),
    ),
  );

  Widget _completionOverlay() => Positioned.fill(
    child: Container(
      color: const Color(0xE5070817),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A294A), Color(0xFF11152B)],
            ),
            border: Border.all(
              color: widget.level == 10 ? _cyan : _purple,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (widget.level == 10 ? _cyan : _purple).withValues(
                  alpha: .23,
                ),
                blurRadius: 35,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) => Transform.scale(
                  scale: 1 + _pulse.value * .09,
                  child: child,
                ),
                child: Icon(
                  widget.level == 10
                      ? Icons.auto_awesome_rounded
                      : Icons.check_circle_rounded,
                  color: _cyan,
                  size: 52,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.level == 10 ? 'REALITY REWRITTEN' : 'REALITY RESTORED',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                _completionLine,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFD0D5E8),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '${'★' * (_attempts == 0 ? 3 : (_attempts < 3 ? 2 : 1))}    +${(_attempts == 0 ? 3 : (_attempts < 3 ? 2 : 1)) * 15} SHARDS',
                style: const TextStyle(
                  color: Color(0xFFFFD875),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _rewardReady ? _next : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cyan,
                    foregroundColor: _void,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    widget.level == 10
                        ? 'ENTER THE NEXT CHAPTER'
                        : 'NEXT MISSION',
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: .9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  String get _completionLine => switch (widget.level) {
    7 => 'The shadow finds its way home. The cage remembers how to open.',
    8 => 'The sphere slips past the impossible barrier and lands true.',
    9 => 'The bridge vanishes behind you. The way forward is open.',
    _ => 'A broken moon, a new orbit. Reality rewrites its own rules.',
  };

  Widget _iconButton(IconData icon, VoidCallback action) => Material(
    color: const Color(0xAA202742),
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: action,
      child: SizedBox(
        width: 38,
        height: 38,
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    ),
  );

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xCC10142A),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: color.withValues(alpha: .55)),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 7.5,
        letterSpacing: .65,
        fontWeight: FontWeight.w900,
      ),
    ),
  );

  Widget _glowingOrb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [Colors.white, color, color.withValues(alpha: .12)],
      ),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: .7),
          blurRadius: 26,
          spreadRadius: 2,
        ),
      ],
    ),
  );

  Widget _exitPortal({required bool ready}) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    width: 47,
    height: 66,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: RadialGradient(
        colors: [
          ready ? _cyan.withValues(alpha: .55) : _purple.withValues(alpha: .3),
          Colors.transparent,
        ],
      ),
      border: Border.all(color: ready ? _cyan : _purple, width: 2),
      boxShadow: [
        BoxShadow(
          color: (ready ? _cyan : _purple).withValues(alpha: .4),
          blurRadius: 20,
        ),
      ],
    ),
    child: const Icon(
      Icons.door_sliding_rounded,
      color: Colors.white,
      size: 26,
    ),
  );

  Widget _metalSphere(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const RadialGradient(
        center: Alignment(-.4, -.45),
        colors: [
          Colors.white,
          Color(0xFFB8DFFF),
          Color(0xFF485C94),
          Color(0xFF151D3A),
        ],
      ),
      border: Border.all(color: _cyan, width: 1.5),
      boxShadow: const [BoxShadow(color: Color(0x9970E9FF), blurRadius: 18)],
    ),
  );

  Widget _targetRing(bool active) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    width: 54,
    height: 54,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: active ? _cyan : _purple.withValues(alpha: .8),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: (active ? _cyan : _purple).withValues(alpha: .28),
          blurRadius: 16,
        ),
      ],
    ),
  );

  Widget _portalRing(double size, bool active) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          Colors.transparent,
          (active ? _cyan : _purple).withValues(alpha: .18),
          const Color(0xE9101937),
        ],
      ),
      border: Border.all(color: active ? _cyan : _purple, width: 3),
      boxShadow: [
        BoxShadow(
          color: (active ? _cyan : _purple).withValues(alpha: .5),
          blurRadius: 25,
          spreadRadius: 3,
        ),
      ],
    ),
    child: Center(
      child: Container(
        width: size * .52,
        height: size * .52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFF2F416D), Color(0xFF070B19)],
          ),
          border: Border.all(color: const Color(0x8879E9FF)),
        ),
      ),
    ),
  );
}

class _ShadowBoardPainter extends CustomPainter {
  const _ShadowBoardPainter(
    this.light,
    this.relic,
    this.shadowX,
    this.switchActive,
    this.portalActive,
  );
  final Offset light;
  final Offset relic;
  final double shadowX;
  final bool switchActive;
  final bool portalActive;
  @override
  void paint(Canvas canvas, Size size) {
    final floorY = size.height * .84;
    final l = Offset(light.dx * size.width, light.dy * size.height);
    final o = Offset(relic.dx * size.width, relic.dy * size.height);
    final s = Offset(shadowX * size.width, floorY);
    canvas.drawLine(
      l,
      o,
      Paint()
        ..color = const Color(0x667AF6FF)
        ..strokeWidth = 1.5,
    );
    canvas.drawLine(
      o,
      s,
      Paint()
        ..color = const Color(0x447AF6FF)
        ..strokeWidth = 1.2,
    );
    canvas.drawOval(
      Rect.fromCenter(center: s, width: 84, height: 14),
      Paint()
        ..color = const Color(0xCC060814)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    final floor = Paint()
      ..shader =
          LinearGradient(
            colors: [
              const Color(0xFF7DEBFF).withValues(alpha: .08),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromLTWH(0, floorY, size.width, size.height - floorY),
          );
    canvas.drawRect(
      Rect.fromLTWH(0, floorY, size.width, size.height - floorY),
      floor,
    );
    canvas.drawLine(
      Offset(0, floorY),
      Offset(size.width, floorY),
      Paint()
        ..color = const Color(0x99A394FF)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _ShadowBoardPainter oldDelegate) =>
      light != oldDelegate.light ||
      relic != oldDelegate.relic ||
      shadowX != oldDelegate.shadowX ||
      switchActive != oldDelegate.switchActive ||
      portalActive != oldDelegate.portalActive;
}

class _GravityCoursePainter extends CustomPainter {
  const _GravityCoursePainter(this.route, this.hit);
  final int route;
  final bool hit;
  @override
  void paint(Canvas canvas, Size size) {
    final floor = size.height * .88;
    final paint = Paint()
      ..color = const Color(0xDD68E6FF)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * .06, floor),
      Offset(size.width * .94, floor),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * .06, size.height * .09),
      Offset(size.width * .94, size.height * .09),
      paint..color = const Color(0x997CB7FF),
    );
    canvas.drawLine(
      Offset(size.width * .06, size.height * .09),
      Offset(size.width * .06, floor),
      paint..color = const Color(0x996CB8FF),
    );
    canvas.drawLine(
      Offset(size.width * .94, size.height * .09),
      Offset(size.width * .94, floor),
      paint..color = const Color(0x996CB8FF),
    );
    final obstacle = Rect.fromLTRB(
      size.width * .44,
      size.height * .64,
      size.width * .55,
      size.height * .88,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(obstacle, const Radius.circular(12)),
      Paint()
        ..color = hit ? const Color(0xFFFFA866) : const Color(0xFFB886FF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(obstacle, const Radius.circular(12)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xCCAB85FF), Color(0xBB334472)],
        ).createShader(obstacle),
    );
    final ledge = Rect.fromLTRB(
      size.width * .76,
      size.height * .68,
      size.width * .96,
      size.height * .72,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(ledge, const Radius.circular(7)),
      Paint()
        ..color = const Color(0xFF70E9FF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(ledge, const Radius.circular(7)),
      Paint()..color = const Color(0xFFB8F8FF),
    );
  }

  @override
  bool shouldRepaint(covariant _GravityCoursePainter oldDelegate) =>
      route != oldDelegate.route || hit != oldDelegate.hit;
}

class _BridgeRoutePainter extends CustomPainter {
  const _BridgeRoutePainter(this.route);
  final List<Offset> route;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var i = 0; i < route.length; i++) {
      final node = route[i];
      final point = Offset(
        size.width * (.09 + node.dx * .15),
        size.height * (.15 + node.dy * .13),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xAA78E9FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x889E7BFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _BridgeRoutePainter oldDelegate) => false;
}

class _BridgeParticlePainter extends CustomPainter {
  const _BridgeParticlePainter(this.progress, this.color);
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = color.withValues(alpha: (1 - progress) * .9);
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final distance = size.width * (.12 + progress * .58);
      final point =
          center +
          Offset(math.cos(angle) * distance, math.sin(angle) * distance);
      canvas.drawCircle(
        point,
        size.width * (.035 + (i % 3) * .012) * (1 - progress * .45),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BridgeParticlePainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}
