import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/widget/campaign_monetization_controls.dart';
import '../services/ads_service.dart';

import '../data/level_catalog.dart';
import '../services/level_progress_service.dart';
import 'level/level_screen.dart';

class ChapterPuzzleScreen extends StatefulWidget {
  const ChapterPuzzleScreen({super.key, required this.level});

  final int level;

  @override
  State<ChapterPuzzleScreen> createState() => _ChapterPuzzleScreenState();
}

class _ChapterPuzzleScreenState extends State<ChapterPuzzleScreen>
    with TickerProviderStateMixin {
  static const _night = Color(0xFF080D1B);
  late final AnimationController _pulse;
  late final AnimationController _hazardMotion;
  int _attempts = 0;
  int _step = 0;
  bool _completed = false;
  bool _armed = false;
  bool _nextStarted = false;
  double _slider = .12;
  double _dial = -math.pi / 2;
  List<int> _mirrorAngles = [0, 0, 1, 1, 0, 1];
  late _MirrorRayTrace _mirrorTrace;
  String _mirrorStatus =
      'Rotate the six mirrors to send the beam through all three receivers.';
  int _parallelWorld = 0;
  int _parallelPlayer = 0;
  int _parallelBurstId = 0;
  String _parallelStatus = 'Start in Blue World. Follow the glowing path.';
  AudioPlayer? _parallelAudio;
  int _timePlayer = 0;
  bool _timeFrozen = false;
  bool _timeCollisionFlash = false;
  double _freezeRemaining = 0;
  double _cooldownRemaining = 0;
  int _timeBurstId = 0;
  String _timeStatus =
      'Use the arrow pad. Freeze the moving lasers to cross safely.';
  Timer? _timeAbilityTimer;
  Timer? _timeFeedbackTimer;

  // Level 14: Portal Architect
  int _archPlayerNode = 0;
  bool _archTeleporting = false;
  int _archSelectedPortal = 0; // 0: Cyan, 1: Orange, 2: Magenta
  List<int> _archPortalAnchors = [
    0,
    1,
    2,
  ]; // Portals 0, 1, 2 at Anchors 0, 1, 2
  final Set<int> _archActivatedSwitches = {}; // 1, 2, 3
  bool _archExitOpen = false;
  String _archStatus =
      'Move portals between anchor pads to activate all 3 switches.';

  static const List<Offset> _timeRoute = [
    Offset(0, 4),
    Offset(1, 4),
    Offset(2, 4),
    Offset(2, 3),
    Offset(3, 3),
    Offset(3, 2),
    Offset(4, 2),
    Offset(4, 1),
    Offset(5, 1),
    Offset(5, 0),
  ];

  static const List<Offset> _parallelRoute = [
    Offset(0, 4),
    Offset(1, 4),
    Offset(2, 4),
    Offset(2, 3),
    Offset(3, 3),
    Offset(3, 2),
    Offset(4, 2),
    Offset(4, 1),
    Offset(5, 1),
  ];
  // 0 = Blue only, 1 = Purple only, 2 = safe in both worlds.
  static const List<int> _parallelPlatformWorlds = [0, 0, 2, 1, 2, 0, 2, 1, 1];

  static const Offset _mirrorEmitter = Offset(0, 3);
  static const Offset _mirrorPortal = Offset(1, 4);
  static const List<Offset> _mirrorPositions = [
    Offset(2, 3),
    Offset(2, 6),
    Offset(6, 6),
    Offset(6, 2),
    Offset(8, 2),
    Offset(8, 4),
  ];
  static const List<Offset> _mirrorReceiverPositions = [
    Offset(2, 4),
    Offset(4, 6),
    Offset(6, 4),
  ];

  LevelStory get story => storyForLevel(widget.level);
  Color get accent => story.accent;
  String get backdrop => widget.level == 14
      ? 'assets/images/portal_architect_bg.png'
      : 'assets/images/level${widget.level.toString().padLeft(2, '0')}_'
            '${switch (widget.level) {
              9 => 'echo',
              10 => 'mirror',
              11 => 'parallel_worlds',
              12 => 'time_freeze',
              13 => 'shattered_mirror',
              14 => 'portal_architect',
              15 => 'liars',
              16 => 'dust',
              17 => 'reverse_time',
              18 => 'anchors',
              19 => 'quiet',
              _ => 'first_reality',
            }}_bg.png';

  @override
  void initState() {
    super.initState();
    if (widget.level == 14) _restartPortalArchitect();
    _mirrorTrace = _traceMirrorBeam(_mirrorAngles);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    )..repeat(reverse: true);
    _hazardMotion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
    if (widget.level == 12) {
      _hazardMotion
        ..addListener(_checkTimeLaserCollision)
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _timeAbilityTimer?.cancel();
    _timeFeedbackTimer?.cancel();
    _hazardMotion.dispose();
    final audio = _parallelAudio;
    if (audio != null) unawaited(audio.dispose());
    _pulse.dispose();
    super.dispose();
  }

  void _miss(String message) {
    if (_completed) return;
    _attempts++;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF202943),
          duration: const Duration(milliseconds: 1400),
        ),
      );
  }

  Future<void> _finish() async {
    if (_completed) return;
    setState(() {
      _completed = true;
      if (widget.level == 12) {
        _timeFrozen = false;
        _freezeRemaining = 0;
      }
    });
    if (widget.level == 12) {
      _timeAbilityTimer?.cancel();
      _hazardMotion.stop();
    }
    if (widget.level == 11) {
      unawaited(_playParallelSound('parallel_complete.wav'));
    }
    if (widget.level == 12) {
      unawaited(_playParallelSound('parallel_complete.wav'));
    }
    if (widget.level == 13) {
      unawaited(_playParallelSound('parallel_complete.wav'));
    }
    final stars = _attempts == 0
        ? 3
        : _attempts < 3
        ? 2
        : 1;
    await LevelProgressService.complete(level: widget.level, stars: stars);
  }

  void _restartParallel() {
    if (widget.level != 11) return;
    setState(() {
      _attempts = 0;
      _step = 0;
      _parallelWorld = 0;
      _parallelPlayer = 0;
      _parallelBurstId++;
      _parallelStatus = 'Start in Blue World. Follow the glowing path.';
      _completed = false;
      _nextStarted = false;
    });
    unawaited(_playParallelSound('parallel_shift.wav'));
  }

  void _restartTimeFreeze() {
    if (widget.level != 12) return;
    _timeAbilityTimer?.cancel();
    _timeFeedbackTimer?.cancel();
    setState(() {
      _attempts = 0;
      _step = 0;
      _timePlayer = 0;
      _timeFrozen = false;
      _timeCollisionFlash = false;
      _freezeRemaining = 0;
      _cooldownRemaining = 0;
      _timeBurstId++;
      _timeStatus = 'Puzzle reset. Freeze the moving lasers to cross safely.';
      _completed = false;
      _nextStarted = false;
    });
    _hazardMotion
      ..stop()
      ..reset()
      ..repeat(reverse: true, period: const Duration(milliseconds: 5200));
    unawaited(_playParallelSound('parallel_shift.wav'));
  }

  void _restartShatteredMirror() {
    if (widget.level != 13) return;
    const resetAngles = [0, 0, 1, 1, 0, 1];
    setState(() {
      _attempts = 0;
      _step = 0;
      _mirrorAngles = [...resetAngles];
      _mirrorTrace = _traceMirrorBeam(_mirrorAngles);
      _mirrorStatus =
          'Puzzle reset. Rotate the mirrors to guide the beam to every receiver.';
      _completed = false;
      _nextStarted = false;
    });
    unawaited(_playParallelSound('parallel_shift.wav'));
  }

  void _rotateMirror(int index) {
    if (widget.level != 13 || _completed) return;
    setState(() {
      _mirrorAngles[index] = (_mirrorAngles[index] + 1) % 4;
      _mirrorTrace = _traceMirrorBeam(_mirrorAngles);
      _step = _mirrorTrace.activatedReceivers.length;
      _mirrorStatus = _step == 3
          ? 'All three receivers are charged. The bridge to the portal is open.'
          : 'Receivers charged: $_step / 3. Rotate another mirror to continue the beam.';
    });
    unawaited(_playParallelSound('parallel_step.wav'));
    unawaited(HapticFeedback.selectionClick());
  }

  _MirrorRayTrace _traceMirrorBeam(List<int> angles) {
    final points = <Offset>[_mirrorEmitter];
    final receivers = <int>{};
    final visited = <String>{};
    var cell = _mirrorEmitter;
    var direction = const Offset(1, 0);

    for (var iteration = 0; iteration < 128; iteration++) {
      cell += direction;
      if (cell.dx < 0 || cell.dx > 8 || cell.dy < 0 || cell.dy > 6) break;
      points.add(cell);
      final receiverIndex = _mirrorReceiverPositions.indexOf(cell);
      if (receiverIndex >= 0) receivers.add(receiverIndex);
      if (cell == _mirrorPortal) {
        break;
      }

      final mirrorIndex = _mirrorPositions.indexOf(cell);
      if (mirrorIndex >= 0) {
        final slash = angles[mirrorIndex].isEven;
        direction = switch ((direction.dx, direction.dy, slash)) {
          (1, 0, true) => const Offset(0, -1),
          (0, -1, true) => const Offset(1, 0),
          (-1, 0, true) => const Offset(0, 1),
          (0, 1, true) => const Offset(-1, 0),
          (1, 0, false) => const Offset(0, 1),
          (0, 1, false) => const Offset(1, 0),
          (-1, 0, false) => const Offset(0, -1),
          (0, -1, false) => const Offset(-1, 0),
          _ => direction,
        };
      }
      final state = '${cell.dx},${cell.dy},${direction.dx},${direction.dy}';
      if (!visited.add(state)) break;
    }
    return _MirrorRayTrace(points: points, activatedReceivers: receivers);
  }

  void _enterMirrorPortal() {
    if (_mirrorTrace.activatedReceivers.length != 3) {
      _attempts++;
      setState(
        () => _mirrorStatus =
            'The portal is waiting. Redirect the beam through all three receivers first.',
      );
      return;
    }
    unawaited(_finish());
  }

  void _activateTimeFreeze() {
    if (widget.level != 12 || _completed || _cooldownRemaining > 0) return;
    _timeAbilityTimer?.cancel();
    setState(() {
      _timeFrozen = true;
      _freezeRemaining = 3;
      _cooldownRemaining = 6;
      _timeBurstId++;
      _timeStatus = 'TIME FROZEN. Move now while the lasers are suspended.';
    });
    _hazardMotion.stop();
    unawaited(_playParallelSound('parallel_shift.wav'));
    unawaited(HapticFeedback.selectionClick());
    _timeAbilityTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (!mounted || _completed) {
        timer.cancel();
        return;
      }
      var resumeHazards = false;
      setState(() {
        _cooldownRemaining = math.max(0.0, _cooldownRemaining - .1);
        if (_timeFrozen) {
          _freezeRemaining = math.max(0.0, _freezeRemaining - .1);
          if (_freezeRemaining <= 0) {
            _timeFrozen = false;
            resumeHazards = true;
            _timeStatus = 'Time resumed. Watch the laser patterns.';
          }
        }
      });
      if (resumeHazards && !_completed) {
        _hazardMotion.repeat(
          reverse: true,
          period: const Duration(milliseconds: 5200),
        );
      }
      if (_cooldownRemaining <= 0 && !_timeFrozen) timer.cancel();
    });
  }

  double get _firstLaserPosition => 2 + _hazardMotion.value * 2.15;
  double get _secondLaserPosition => 7.8 - _hazardMotion.value * 2.1;

  void _checkTimeLaserCollision() {
    if (widget.level != 12 || _timeFrozen || _completed) return;
    if ((_timePlayer - _firstLaserPosition).abs() < .34 ||
        (_timePlayer - _secondLaserPosition).abs() < .34) {
      _resetTimePlayer();
    }
  }

  void _resetTimePlayer() {
    if (_completed || _timePlayer == 0) return;
    setState(() {
      _attempts++;
      _timePlayer = 0;
      _step = 0;
      _timeCollisionFlash = true;
      _timeBurstId++;
      _timeStatus = 'Laser contact. Reset to the starting platform.';
    });
    _timeFeedbackTimer?.cancel();
    _timeFeedbackTimer = Timer(const Duration(milliseconds: 620), () {
      if (mounted) setState(() => _timeCollisionFlash = false);
    });
    unawaited(_playParallelSound('parallel_step.wav'));
    unawaited(HapticFeedback.mediumImpact());
  }

  void _moveTimePlayer(int dx, int dy) {
    if (widget.level != 12 || _completed) return;
    final current = _timeRoute[_timePlayer];
    final next = _timeRoute.indexOf(Offset(current.dx + dx, current.dy + dy));
    if (next < 0 || (next - _timePlayer).abs() != 1) {
      setState(() => _timeStatus = 'Stay on the illuminated platform route.');
      return;
    }
    if (!_timeFrozen &&
        ((next - _firstLaserPosition).abs() < .34 ||
            (next - _secondLaserPosition).abs() < .34)) {
      setState(() => _timePlayer = next);
      _resetTimePlayer();
      return;
    }
    if (next == _timeRoute.length - 1) {
      setState(() {
        _timePlayer = next;
        _step = next;
        _timeStatus = 'Exit reached. The timeline stabilizes.';
      });
      unawaited(_playParallelSound('parallel_complete.wav'));
      unawaited(_finish());
      return;
    }
    setState(() {
      _timePlayer = next;
      _step = next;
      _timeStatus = _timeFrozen
          ? 'Keep moving. The laser grid is frozen for ${_freezeRemaining.toStringAsFixed(1)} seconds.'
          : 'Move between beams. Freeze time when a laser crosses your route.';
    });
    unawaited(_playParallelSound('parallel_step.wav'));
    unawaited(HapticFeedback.lightImpact());
    _checkTimeLaserCollision();
  }

  Future<void> _playParallelSound(String file) async {
    try {
      final player = _parallelAudio ??= AudioPlayer();
      await player.play(AssetSource('audio/$file'));
    } catch (_) {
      // Gameplay remains usable on platforms where audio output is unavailable.
    }
  }

  void _switchParallelWorld() {
    if (_completed) return;
    if (_parallelPlatformWorlds[_parallelPlayer] != 2) {
      setState(() {
        _parallelStatus =
            'You need a shared anchor platform to change dimensions.';
        _attempts++;
      });
      unawaited(HapticFeedback.selectionClick());
      return;
    }
    setState(() {
      _parallelWorld = 1 - _parallelWorld;
      _parallelBurstId++;
      _parallelStatus = _parallelWorld == 0
          ? 'Blue World restored. The path continues.'
          : 'Purple World aligned. Follow its glowing platforms.';
    });
    unawaited(_playParallelSound('parallel_shift.wav'));
    unawaited(HapticFeedback.selectionClick());
  }

  void _moveParallelPlayer(int dx, int dy) {
    if (widget.level != 11 || _completed) return;
    final current = _parallelRoute[_parallelPlayer];
    final target = Offset(current.dx + dx, current.dy + dy);
    final nextIndex = _parallelRoute.indexOf(target);
    if (nextIndex < 0 || (nextIndex - _parallelPlayer).abs() != 1) {
      setState(
        () => _parallelStatus = 'Follow the glowing platforms in order.',
      );
      return;
    }
    final platformWorld = _parallelPlatformWorlds[nextIndex];
    if (platformWorld != 2 && platformWorld != _parallelWorld) {
      final needed = platformWorld == 0 ? 'Blue World' : 'Purple World';
      setState(
        () => _parallelStatus = 'That platform is only solid in $needed.',
      );
      return;
    }
    if (nextIndex == _parallelRoute.length - 1) {
      setState(() {
        _parallelPlayer = nextIndex;
        _step = nextIndex;
        _parallelStatus = 'Portal reached. Reality is synchronizing…';
      });
      unawaited(_playParallelSound('parallel_shift.wav'));
      unawaited(_finish());
      return;
    }
    setState(() {
      _parallelPlayer = nextIndex;
      _step = nextIndex;
      _parallelStatus = _parallelPlatformWorlds[nextIndex] == 2
          ? 'Anchor reached. Safe to switch worlds here.'
          : 'Platform secured. Keep moving to the next anchor.';
    });
    unawaited(_playParallelSound('parallel_step.wav'));
    unawaited(HapticFeedback.lightImpact());
  }

  Future<void> _next() async {
    if (!_completed || _nextStarted) return;
    _nextStarted = true;
    await AdsService.instance.showInterstitialAtTransition();
    if (!mounted) return;
    if (widget.level < 20) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChapterPuzzleScreen(level: widget.level + 1),
        ),
      );
    } else {
      await Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LevelScreen()),
        (route) => route.isFirst,
      );
    }
  }

  String get clue => switch (widget.level) {
    9 =>
      'Watch the nodes light up, then tap REPLAY ECHO. When the sequence is ready, tap those same nodes in reverse order.',
    10 =>
      'Drag the moon all the way to the bright mark at the far end of the mirror lane.',
    11 =>
      'Walk the blue platforms to a shared anchor. Switch to Purple there, cross to the next anchor, and continue alternating worlds until the portal.',
    12 =>
      'Route: RIGHT, RIGHT, UP, RIGHT, UP, RIGHT, UP, RIGHT, UP. Freeze time for 3 seconds before crossing a laser lane; the ability recharges in 6 seconds.',
    13 =>
      'Tap each of the six mirror fragments once to rotate it 90 degrees. Follow the cyan beam until all three receivers glow, then tap the magenta portal.',
    14 =>
      'Reposition portals on anchor pads to connect floating isles. Activate Switches 1, 2, and 3 to awaken the ancient purple gateway.',
    15 =>
      'Choose the portal whose shadow points directly toward the broken moon.',
    16 =>
      'Tap the constellation points in the order they lit up during the preview.',
    17 =>
      'Drag the clock hand counterclockwise until it points to nine o’clock.',
    18 => 'Tap the planets in size order: smallest first, largest last.',
    19 =>
      'Press and hold the moon until the storm stops moving, then tap the silent star.',
    _ =>
      'Move the moon first, turn the clock back, choose the dark door, then restore the heart.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.level == 13 ? const Color(0xFFBFEAFF) : _night,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(backdrop, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: widget.level == 13
                    ? const [
                        Color(0x08FFFFFF),
                        Color(0x10FFFFFF),
                        Color(0x24E8F9FF),
                      ]
                    : const [
                        Color(0xB8070B19),
                        Color(0x8C0A1123),
                        Color(0xF2070914),
                      ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(17, 10, 17, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _roundIcon(
                        Icons.arrow_back_rounded,
                        () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      _glassPill(
                        'MISSION ${widget.level.toString().padLeft(2, '0')}  /  20',
                      ),
                      const Spacer(),
                      if (widget.level == 11 ||
                          widget.level == 12 ||
                          widget.level == 13 ||
                          widget.level == 14) ...[
                        const SizedBox(width: 6),
                        _roundIcon(
                          Icons.refresh_rounded,
                          widget.level == 11
                              ? _restartParallel
                              : widget.level == 12
                              ? _restartTimeFreeze
                              : _restartShatteredMirror,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 17),
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 42,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: .5),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story.chapterTitle,
                              style: TextStyle(
                                color: accent,
                                fontSize: 9,
                                letterSpacing: 1.6,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              story.title.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: widget.level == 13
                                    ? const Color(0xFF173C63)
                                    : Colors.white,
                                fontSize: 19,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w900,
                                shadows: widget.level == 13
                                    ? const [
                                        Shadow(
                                          color: Color(0x55FFFFFF),
                                          blurRadius: 7,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      story.teaser,
                      style: TextStyle(
                        color: widget.level == 13
                            ? const Color(0xFF1B456B)
                            : const Color(0xFFCCD4E6),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  Expanded(child: _gameBoard()),
                  const SizedBox(height: 12),
                  _brief(_instruction, icon: Icons.touch_app_rounded),
                  const SizedBox(height: 9),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: accent, size: 14),
                      const SizedBox(width: 7),
                      Text(
                        widget.level == 11
                            ? 'TWO WORLDS. ONE PATH.'
                            : widget.level == 12
                            ? 'FREEZE TIME. CROSS THE VOID.'
                            : widget.level == 13
                            ? 'ALIGN THE LIGHT. REVEAL THE WAY.'
                            : 'A DIFFERENT RULE. A DIFFERENT REALITY.',
                        style: TextStyle(
                          color: accent.withValues(alpha: .9),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CampaignMonetizationControls(
                    level: widget.level,
                    onHint: () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF111A30),
                        title: const Text(
                          'A hint from the archive',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: Text(
                          clue,
                          style: const TextStyle(
                            color: Color(0xFFDCE8FF),
                            height: 1.45,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('GOT IT'),
                          ),
                        ],
                      ),
                    ),
                    onSkipped: () => Navigator.maybePop(context),
                  ),
                ],
              ),
            ),
          ),
          if (_completed) _winOverlay(),
        ],
      ),
    );
  }

  String get _instruction => switch (widget.level) {
    9 =>
      _armed
          ? 'Tap the memory nodes in the reverse sequence.'
          : 'Study the signal, then tap REPLAY ECHO.',
    10 => 'Drag the moon onto the bright mark at the end of the mirror lane.',
    11 => _parallelStatus,
    12 => _timeStatus,
    13 => _mirrorStatus,
    14 => _archStatus,
    15 => 'Choose the portal whose shadow points toward the moon.',
    16 => 'Tap the constellation points in the order the light first appeared.',
    17 => 'Drag the clock hand counterclockwise to the nine-hour mark.',
    18 => 'Anchor the planets from smallest to largest.',
    19 =>
      _armed
          ? 'The storm is still. Touch the silent star.'
          : 'Press and hold the moon until the storm calms.',
    _ => 'Return the moon, turn time, then choose the dark portal.',
  };

  Widget _gameBoard() => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: widget.level == 13
            ? const [Color(0xC8F7FDFF), Color(0xB6DCEFFF)]
            : const [Color(0xC51A2945), Color(0xDC0A1224)],
      ),
      border: Border.all(
        color: widget.level == 13
            ? const Color(0xCCF6D384)
            : accent.withValues(alpha: .35),
      ),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: .08),
          blurRadius: 26,
          spreadRadius: 2,
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: LayoutBuilder(
        builder: (context, bounds) => Stack(
          children: [
            if (widget.level == 11)
              Positioned.fill(
                child: Image.asset(
                  'assets/images/level11_parallel_worlds_bg.png',
                  fit: BoxFit.cover,
                ),
              ),
            if (widget.level == 12)
              Positioned.fill(
                child: Image.asset(
                  'assets/images/level12_time_freeze_bg.png',
                  fit: BoxFit.cover,
                ),
              ),
            if (widget.level == 13)
              Positioned.fill(
                child: Image.asset(
                  'assets/images/level13_shattered_mirror_bg.png',
                  fit: BoxFit.cover,
                ),
              ),
            if (widget.level == 14)
              Positioned.fill(
                child: Image.asset(
                  'assets/images/portal_architect_bg.png',
                  fit: BoxFit.cover,
                ),
              ),
            Positioned.fill(
              child: CustomPaint(
                painter: _BoardStars(
                  widget.level == 11 ? Colors.white : accent,
                ),
              ),
            ),
            Positioned(
              left: 15,
              right: 15,
              top: 13,
              child: Row(
                children: [
                  _tinyChip(
                    widget.level == 11
                        ? (_parallelWorld == 0 ? 'BLUE WORLD' : 'PURPLE WORLD')
                        : widget.level == 12
                        ? (_timeFrozen ? 'TIME FROZEN' : 'HAZARDS ACTIVE')
                        : widget.level == 13
                        ? 'RECEIVERS $_step / 3'
                        : 'FRAGMENT ${widget.level - 5}',
                    widget.level == 11
                        ? (_parallelWorld == 0
                              ? const Color(0xFF61D7FF)
                              : const Color(0xFFDB73FF))
                        : widget.level == 12
                        ? (_timeFrozen
                              ? const Color(0xFF84E9FF)
                              : const Color(0xFFFF658D))
                        : widget.level == 13
                        ? const Color(0xFFAA741F)
                        : accent,
                  ),
                  const Spacer(),
                  Text(
                    widget.level == 11
                        ? '${_parallelPlayer.clamp(0, 8)} / 8'
                        : widget.level == 12
                        ? '${_timePlayer.clamp(0, 9)} / 9'
                        : widget.level == 13
                        ? '6 MIRRORS'
                        : '${_step.clamp(0, 3)} / ${widget.level == 20 ? 3 : 1}',
                    style: TextStyle(
                      color: widget.level == 13
                          ? const Color(0xFF416B8D)
                          : Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              top: 36,
              child: _puzzleScene(bounds.maxWidth, bounds.maxHeight - 36),
            ),
            Positioned(
              right: 13,
              bottom: 12,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, _) => Icon(
                  Icons.circle,
                  size: 6 + _pulse.value * 3,
                  color: accent.withValues(alpha: .45 + .45 * _pulse.value),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _puzzleScene(double width, double height) => switch (widget.level) {
    9 => _reverseEcho(width, height),
    10 => _mirrorMoon(width, height),
    11 => _parallelWorlds(width, height),
    12 => _timeFreezeBoard(width, height),
    13 => _shatteredMirrorBoard(width, height),
    14 => _portalArchitectBoard(width, height),
    15 => _liarsPortal(width, height),
    16 => _constellation(width, height),
    17 => _clockDial(width, height, finalClock: true),
    18 => _anchors(width, height),
    19 => _quietStorm(width, height),
    _ => _finalHeart(width, height),
  };

  Widget _reverseEcho(double w, double h) {
    const sequence = [1, 3, 0];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _armed ? 'RETURN THE ECHO BACKWARDS' : 'SIGNAL RECEIVED',
          style: TextStyle(
            color: accent,
            fontSize: 10,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final index in sequence)
              _node(index, 46, accent, glow: !_armed),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 15,
          children: List.generate(
            4,
            (index) => GestureDetector(
              onTap: () {
                if (!_armed) return;
                final expected = sequence.reversed.elementAt(_step);
                if (index == expected) {
                  setState(() => _step++);
                  if (_step == sequence.length) _finish();
                } else {
                  _step = 0;
                  _miss(
                    'That echo does not belong there. Start the return again.',
                  );
                }
              },
              child: _node(
                index,
                58,
                index == 0
                    ? const Color(0xFFFAA9D5)
                    : index == 1
                    ? accent
                    : index == 2
                    ? const Color(0xFFFFCF72)
                    : const Color(0xFFA997FF),
                glow:
                    _armed &&
                    sequence.reversed.elementAt(_step.clamp(0, 2)) == index,
              ),
            ),
          ),
        ),
        const SizedBox(height: 23),
        if (!_armed)
          _actionButton(
            'REPLAY ECHO',
            () => setState(() {
              _armed = true;
              _step = 0;
            }),
          ),
        if (_armed) _stepDots(3),
      ],
    );
  }

  Widget _mirrorMoon(double w, double h) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const SizedBox(height: 20),
      SizedBox(
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    accent.withValues(alpha: .3),
                    accent,
                    accent.withValues(alpha: .3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              left: w * .73,
              child: Icon(Icons.adjust_rounded, color: accent, size: 24),
            ),
            Positioned(
              left: _slider * (w - 80) + 10,
              child: GestureDetector(
                onPanUpdate: (d) => setState(
                  () => _slider = (_slider + d.delta.dx / (w - 80)).clamp(
                    .08,
                    .82,
                  ),
                ),
                onPanEnd: (_) => _slider > .66
                    ? _finish()
                    : _miss('The reflection is still out of phase.'),
                child: _moonOrb(58, accent),
              ),
            ),
            Positioned(
              left: 8,
              child: Text(
                'REAL',
                style: TextStyle(
                  color: accent.withValues(alpha: .5),
                  fontSize: 8,
                  letterSpacing: 1,
                ),
              ),
            ),
            Positioned(
              right: 7,
              child: Text(
                'MIRROR',
                style: TextStyle(
                  color: accent.withValues(alpha: .7),
                  fontSize: 8,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      _stepDots(1),
    ],
  );

  Widget _parallelWorlds(double w, double h) {
    final worldColor = _parallelWorld == 0
        ? const Color(0xFF50CFFF)
        : const Color(0xFFD65BFF);
    final tileSize = math.min(w * .15, 53.0);
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 420),
            color: worldColor.withValues(alpha: .12),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _ParallelWorldPathPainter(_parallelRoute, worldColor),
          ),
        ),
        Positioned(
          top: h * .015,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _tinyChip(
                _parallelWorld == 0
                    ? 'REALITY A  •  BLUE WORLD'
                    : 'REALITY B  •  PURPLE WORLD',
                worldColor,
              ),
            ),
          ),
        ),
        for (var index = 0; index < _parallelRoute.length; index++)
          _parallelTile(index, w, h, tileSize),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          left: w * (.11 + _parallelRoute[_parallelPlayer].dx * .155) - 18,
          top: h * (.18 + _parallelRoute[_parallelPlayer].dy * .105) - 24,
          child: Container(
            key: const ValueKey('parallel-player'),
            width: 36,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFDAF6FF),
              border: Border.all(color: worldColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: worldColor.withValues(alpha: .8),
                  blurRadius: 17,
                ),
              ],
              image: const DecorationImage(
                image: AssetImage('assets/images/level5_astronaut.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        if (_parallelBurstId > 0)
          Positioned(
            left: w * (.11 + _parallelRoute[_parallelPlayer].dx * .155) - 38,
            top: h * (.18 + _parallelRoute[_parallelPlayer].dy * .105) - 39,
            width: 76,
            height: 76,
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                key: ValueKey('parallel-burst-$_parallelBurstId'),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 650),
                builder: (context, value, _) => CustomPaint(
                  painter: _ParallelBurstPainter(value, worldColor),
                ),
              ),
            ),
          ),
        Positioned(
          left: w * .08,
          right: w * .08,
          bottom: h * .19,
          child: ElevatedButton.icon(
            key: const ValueKey('parallel-switch'),
            onPressed: _completed ? null : _switchParallelWorld,
            icon: const Icon(Icons.swap_horiz_rounded, size: 20),
            label: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                _parallelWorld == 0
                    ? 'SHIFT TO PURPLE WORLD'
                    : 'SHIFT TO BLUE WORLD',
                key: ValueKey(_parallelWorld),
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: .7,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xE9171A37),
              foregroundColor: worldColor,
              minimumSize: const Size.fromHeight(43),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: worldColor.withValues(alpha: .7)),
              ),
              shadowColor: worldColor.withValues(alpha: .42),
              elevation: 10,
            ),
          ),
        ),
        Positioned(
          left: w * .06,
          right: w * .06,
          bottom: h * .025,
          child: Row(
            children: [
              _parallelDirection(
                Icons.arrow_back_rounded,
                'parallel-left',
                -1,
                0,
              ),
              const SizedBox(width: 7),
              _parallelDirection(
                Icons.arrow_upward_rounded,
                'parallel-up',
                0,
                -1,
              ),
              const SizedBox(width: 7),
              _parallelDirection(
                Icons.arrow_downward_rounded,
                'parallel-down',
                0,
                1,
              ),
              const SizedBox(width: 7),
              _parallelDirection(
                Icons.arrow_forward_rounded,
                'parallel-right',
                1,
                0,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Positioned _parallelTile(int index, double w, double h, double size) {
    final grid = _parallelRoute[index];
    final world = _parallelPlatformWorlds[index];
    final active = world == 2 || world == _parallelWorld;
    final isExit = index == _parallelRoute.length - 1;
    final color = world == 0
        ? const Color(0xFF53CEFF)
        : world == 1
        ? const Color(0xFFD55AFF)
        : const Color(0xFFA6D8FF);
    return Positioned(
      left: w * (.11 + grid.dx * .155) - size / 2,
      top: h * (.18 + grid.dy * .105) - size / 2,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 360),
        scale: active ? 1 : .83,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 320),
          opacity: active ? 1 : .18,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 420),
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * .2),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isExit
                    ? [const Color(0xFF6E39BC), const Color(0xFF171B3C)]
                    : [color.withValues(alpha: .78), const Color(0xFF151C36)],
              ),
              border: Border.all(
                color: color.withValues(alpha: active ? .95 : .35),
                width: 1.6,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: .68),
                        blurRadius: isExit ? 20 : 13,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isExit
                  ? Icons.door_sliding_rounded
                  : world == 2
                  ? Icons.all_inclusive_rounded
                  : Icons.grid_4x4_rounded,
              color: Colors.white.withValues(alpha: active ? .95 : .45),
              size: size * .45,
            ),
          ),
        ),
      ),
    );
  }

  Widget _parallelDirection(IconData icon, String key, int dx, int dy) =>
      Expanded(
        child: SizedBox(
          height: 43,
          child: IconButton.filledTonal(
            key: ValueKey(key),
            onPressed: _completed ? null : () => _moveParallelPlayer(dx, dy),
            icon: Icon(
              icon,
              color: _parallelWorld == 0
                  ? const Color(0xFF70DFFF)
                  : const Color(0xFFE181FF),
            ),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xD9141933),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: accent.withValues(alpha: .4)),
              ),
            ),
          ),
        ),
      );

  Widget _timeFreezeBoard(double w, double h) {
    final currentPoint = _timePoint(_timePlayer.toDouble(), w, h);
    final freezeReady = _cooldownRemaining <= 0 && !_timeFrozen;
    final cooldownValue = (1 - (_cooldownRemaining / 6)).clamp(0.0, 1.0);
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 420),
            color: _timeFrozen
                ? const Color(0x5534DFFF)
                : (_timeCollisionFlash
                      ? const Color(0x44FF3478)
                      : Colors.transparent),
          ),
        ),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _hazardMotion,
            builder: (_, _) => CustomPaint(
              painter: _TimeFreezeCoursePainter(
                _timeRoute,
                _hazardMotion.value,
                _timeFrozen,
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: h * .012,
          child: _tinyChip(
            _timeFrozen ? 'OBSTACLES SUSPENDED' : 'LASER GRID LIVE',
            _timeFrozen ? const Color(0xFF85EDFF) : const Color(0xFFFF7A9C),
          ),
        ),
        for (var index = 0; index < _timeRoute.length; index++)
          _timeTile(index, w, h, math.min(w * .145, 49.0)),
        if (_timeBurstId > 0)
          Positioned(
            left: currentPoint.dx - 37,
            top: currentPoint.dy - 37,
            width: 74,
            height: 74,
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                key: ValueKey('time-hit-burst-$_timeBurstId'),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 620),
                builder: (_, value, _) => CustomPaint(
                  painter: _ParallelBurstPainter(
                    value,
                    _timeCollisionFlash
                        ? const Color(0xFFFF587F)
                        : const Color(0xFF8CEBFF),
                  ),
                ),
              ),
            ),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 230),
          curve: Curves.easeOutCubic,
          left: currentPoint.dx - 17,
          top: currentPoint.dy - 25,
          child: _timeAvatar(),
        ),
        Positioned(
          left: w * .07,
          right: w * .07,
          bottom: h * .18,
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    key: const ValueKey('time-freeze'),
                    onPressed: freezeReady ? _activateTimeFreeze : null,
                    icon: Icon(
                      _timeFrozen
                          ? Icons.ac_unit_rounded
                          : Icons.hourglass_bottom_rounded,
                      color: const Color(0xFF9CEEFF),
                      size: 21,
                    ),
                    label: Text(
                      _timeFrozen
                          ? 'FROZEN  ${_freezeRemaining.toStringAsFixed(1)}s'
                          : freezeReady
                          ? 'TIME FREEZE'
                          : 'RECHARGING',
                      style: const TextStyle(
                        fontSize: 9,
                        letterSpacing: .7,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xE9141B39),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xCC11182E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: const Color(
                            0xFF73E6FF,
                          ).withValues(alpha: _timeFrozen ? .95 : .62),
                        ),
                      ),
                      shadowColor: const Color(0xFF70DFFF),
                      elevation: _timeFrozen ? 14 : 6,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: cooldownValue,
                        strokeWidth: 4,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation(
                          freezeReady
                              ? const Color(0xFF69E5FF)
                              : const Color(0xFFB66BFF),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          freezeReady
                              ? 'READY'
                              : '${_cooldownRemaining.toStringAsFixed(1)}s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'COOLDOWN',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 5.5,
                            letterSpacing: .35,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: w * .06,
          right: w * .06,
          bottom: h * .022,
          child: Row(
            children: [
              _timeDirection(Icons.arrow_back_rounded, 'time-left', -1, 0),
              const SizedBox(width: 7),
              _timeDirection(Icons.arrow_upward_rounded, 'time-up', 0, -1),
              const SizedBox(width: 7),
              _timeDirection(Icons.arrow_downward_rounded, 'time-down', 0, 1),
              const SizedBox(width: 7),
              _timeDirection(Icons.arrow_forward_rounded, 'time-right', 1, 0),
            ],
          ),
        ),
      ],
    );
  }

  Offset _timePoint(double routeIndex, double w, double h) {
    final low = routeIndex.floor().clamp(0, _timeRoute.length - 1);
    final high = math.min(low + 1, _timeRoute.length - 1);
    final fraction = (routeIndex - low).clamp(0.0, 1.0);
    final a = _timeRoute[low];
    final b = _timeRoute[high];
    final grid = Offset(
      a.dx + (b.dx - a.dx) * fraction,
      a.dy + (b.dy - a.dy) * fraction,
    );
    return Offset(w * (.11 + grid.dx * .155), h * (.12 + grid.dy * .10));
  }

  Positioned _timeTile(int index, double w, double h, double size) {
    final grid = _timeRoute[index];
    final color = index.isEven
        ? const Color(0xFF58D8FF)
        : const Color(0xFFC96EFF);
    final isExit = index == _timeRoute.length - 1;
    return Positioned(
      left: w * (.11 + grid.dx * .155) - size / 2,
      top: h * (.12 + grid.dy * .10) - size / 2,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * .2),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isExit
                ? const [Color(0xFF793FD1), Color(0xFF181B3C)]
                : [color.withValues(alpha: .7), const Color(0xFF171D36)],
          ),
          border: Border.all(color: color.withValues(alpha: .88), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isExit ? .8 : .38),
              blurRadius: isExit ? 19 : 11,
            ),
          ],
        ),
        child: Icon(
          isExit
              ? Icons.door_sliding_rounded
              : index == 0
              ? Icons.flag_rounded
              : Icons.grid_4x4_rounded,
          color: Colors.white,
          size: size * .42,
        ),
      ),
    );
  }

  Widget _timeAvatar() => Container(
    key: const ValueKey('time-player'),
    width: 34,
    height: 48,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: const Color(0xFFE1F7FF),
      border: Border.all(color: const Color(0xFF8FEAFF), width: 1.5),
      boxShadow: const [BoxShadow(color: Color(0xAA67DFFF), blurRadius: 15)],
      image: const DecorationImage(
        image: AssetImage('assets/images/level5_astronaut.png'),
        fit: BoxFit.cover,
      ),
    ),
  );

  Widget _timeDirection(IconData icon, String key, int dx, int dy) => Expanded(
    child: SizedBox(
      height: 43,
      child: IconButton.filledTonal(
        key: ValueKey(key),
        onPressed: _completed ? null : () => _moveTimePlayer(dx, dy),
        icon: Icon(icon, color: const Color(0xFFA7EFFF)),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xD9141933),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0x667AE7FF)),
          ),
        ),
      ),
    ),
  );

  Widget _clockDial(double w, double h, {required bool finalClock}) => Center(
    child: GestureDetector(
      onPanUpdate: (details) {
        final dialSize = math.min(w * .67, 240.0);
        final local =
            details.localPosition - Offset(dialSize / 2, dialSize / 2);
        setState(() => _dial = math.atan2(local.dy, local.dx));
      },
      onPanEnd: (_) {
        final target = finalClock ? math.pi : math.pi / 2;
        final difference = math
            .atan2(math.sin(_dial - target), math.cos(_dial - target))
            .abs();
        if (difference < .32) {
          _finish();
        } else {
          _miss(
            finalClock
                ? 'Turn the hand counterclockwise to the nine mark.'
                : 'The clock mark is at six o’clock.',
          );
        }
      },
      child: SizedBox(
        width: math.min(w * .67, 240),
        height: math.min(w * .67, 240),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withValues(alpha: .20),
                    const Color(0xFF11192E),
                    const Color(0xFF080E1C),
                  ],
                ),
                border: Border.all(
                  color: accent.withValues(alpha: .52),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: .18),
                    blurRadius: 24,
                  ),
                ],
              ),
            ),
            for (var i = 0; i < 12; i++)
              Transform.rotate(
                angle: math.pi * i / 6,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 13),
                    child: Container(
                      width: i % 3 == 0 ? 3 : 2,
                      height: i % 3 == 0 ? 11 : 6,
                      color: i == (finalClock ? 9 : 6)
                          ? accent
                          : Colors.white54,
                    ),
                  ),
                ),
              ),
            Transform.rotate(
              angle: _dial + math.pi / 2,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 4,
                  height: math.min(w * .25, 78),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: accent, blurRadius: 8)],
                  ),
                ),
              ),
            ),
            Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
                boxShadow: [BoxShadow(color: accent, blurRadius: 16)],
              ),
            ),
            Positioned(
              top: 36,
              child: Text(
                finalClock ? 'REVERSAL' : 'CLOCKWORK',
                style: TextStyle(
                  color: accent,
                  fontSize: 9,
                  letterSpacing: 1.7,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _shatteredMirrorBoard(double w, double h) {
    final bridgeOpen = _mirrorTrace.activatedReceivers.length == 3;
    final portalPoint = _mirrorBoardPoint(_mirrorPortal, w, h);
    final emitterPoint = _mirrorBoardPoint(_mirrorEmitter, w, h);
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (_, _) => CustomPaint(
              painter: _ShatteredRayPainter(
                _mirrorTrace.points,
                _mirrorTrace.activatedReceivers,
                bridgeOpen,
                _pulse.value,
              ),
            ),
          ),
        ),
        for (var i = 0; i < _mirrorPositions.length; i++)
          _mirrorFragment(i, w, h),
        for (var i = 0; i < _mirrorReceiverPositions.length; i++)
          _mirrorReceiver(i, w, h),
        Positioned(
          left: emitterPoint.dx - 18,
          top: emitterPoint.dy - 18,
          child: Container(
            key: const ValueKey('mirror-emitter'),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0xFFE8FFFF),
                  Color(0xFF4DCBFF),
                  Color(0xFF1D5C88),
                ],
              ),
              border: Border.all(color: const Color(0xFFD8F8FF), width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0xBB47D8FF), blurRadius: 19),
              ],
            ),
            child: const Icon(
              Icons.flash_on_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
        ),
        Positioned(
          left: portalPoint.dx - 25,
          top: portalPoint.dy - 32,
          child: GestureDetector(
            key: const ValueKey('mirror-portal'),
            onTap: _enterMirrorPortal,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 420),
              width: 50,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(27),
                gradient: RadialGradient(
                  colors: bridgeOpen
                      ? const [
                          Color(0xFFEFB6FF),
                          Color(0xFF9D3DDA),
                          Color(0xFF572496),
                        ]
                      : const [
                          Color(0xFFCCB1D9),
                          Color(0xFF8657A0),
                          Color(0xFF493664),
                        ],
                ),
                border: Border.all(
                  color: bridgeOpen
                      ? const Color(0xFFFFD1FE)
                      : const Color(0xFFCCA9D7),
                  width: 2.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFFDF63FF,
                    ).withValues(alpha: bridgeOpen ? .9 : .35),
                    blurRadius: bridgeOpen ? 27 : 13,
                    spreadRadius: bridgeOpen ? 3 : 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.diamond_rounded,
                color: Colors.white,
                size: 27,
              ),
            ),
          ),
        ),
        Positioned(
          left: 10,
          top: h * .015,
          child: _tinyChip(
            bridgeOpen ? 'BRIDGE OPEN' : 'ENERGY PATH',
            bridgeOpen ? const Color(0xFFB74BE8) : const Color(0xFF188FBC),
          ),
        ),
      ],
    );
  }

  Offset _mirrorBoardPoint(Offset grid, double w, double h) =>
      Offset(w * (.08 + grid.dx * .105), h * (.12 + grid.dy * .11));

  Positioned _mirrorFragment(int index, double w, double h) {
    final size = math.min(w * .105, 42.0);
    final point = _mirrorBoardPoint(_mirrorPositions[index], w, h);
    return Positioned(
      left: point.dx - size * .42,
      top: point.dy - size * .62,
      child: GestureDetector(
        key: ValueKey('mirror-$index'),
        onTap: () => _rotateMirror(index),
        child: AnimatedRotation(
          turns: _mirrorAngles[index] / 4,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOutCubic,
          child: Container(
            width: size * .84,
            height: size * 1.24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF4C8),
                  Color(0xFFFFD35F),
                  Color(0xFFB87B21),
                ],
              ),
              border: Border.all(color: const Color(0xFFAE7121), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x88DBA341),
                  blurRadius: 11,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: size * .52,
                height: size * 1.02,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFF71E5FF),
                      Color(0xFF208AC3),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFFFFFFFF),
                    width: 1.1,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x8874E7FF), blurRadius: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Positioned _mirrorReceiver(int index, double w, double h) {
    final point = _mirrorBoardPoint(_mirrorReceiverPositions[index], w, h);
    final active = _mirrorTrace.activatedReceivers.contains(index);
    return Positioned(
      left: point.dx - 15,
      top: point.dy - 15,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, _) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: active
                  ? const [
                      Color(0xFFFFFFFF),
                      Color(0xFFFFE878),
                      Color(0xFFEB9F20),
                    ]
                  : const [
                      Color(0xFFDBFFFF),
                      Color(0xFF6FBCD2),
                      Color(0xFF43819C),
                    ],
            ),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color:
                    (active ? const Color(0xFFFFD64D) : const Color(0xFF54DAFF))
                        .withValues(alpha: active ? .8 : .35),
                blurRadius: active ? 15 + _pulse.value * 7 : 9,
              ),
            ],
          ),
          child: Icon(
            active ? Icons.check_rounded : Icons.brightness_7_rounded,
            color: Colors.white,
            size: 19,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // LEVEL 14: PORTAL ARCHITECT IMPLEMENTATION
  // ==========================================

  void _restartPortalArchitect() {
    setState(() {
      _attempts = 0;
      _archPlayerNode = 0;
      _archTeleporting = false;
      _archSelectedPortal = 0;
      _archPortalAnchors = [0, 1, 2]; // Cyan on 0, Orange on 1, Magenta on 2
      _archActivatedSwitches.clear();
      _archExitOpen = false;
      _archStatus =
          'Reposition portals on anchor pads to connect floating isles and hit all 3 switches.';
      _completed = false;
      _nextStarted = false;
    });
    unawaited(_playParallelSound('parallel_shift.wav'));
  }

  static const List<Color> _archPortalColors = [
    Color(0xFF32D8FF), // Portal 0: Cyan
    Color(0xFFFF9436), // Portal 1: Orange
    Color(0xFFE243FF), // Portal 2: Magenta
  ];

  static const List<String> _archPortalNames = [
    'CYAN PORTAL',
    'ORANGE PORTAL',
    'MAGENTA PORTAL',
  ];

  static const List<int> _archAnchorNodeMap = [
    1, // Anchor 0: Island 0 (Origin)
    2, // Anchor 1: Island 1 (Sanctuary)
    5, // Anchor 2: Island 2 (Cascade Isle A)
    6, // Anchor 3: Island 2 (Cascade Isle B)
    7, // Anchor 4: Island 3 (Sunstone Isle)
    10, // Anchor 5: Island 4 (Sky Citadel)
  ];

  static const List<_ArchNodeData> _archNodes = [
    // Island 0 (Origin - Bottom-Left)
    _ArchNodeData(
      id: 0,
      island: 0,
      pos: Offset(0.18, 0.62),
      neighbors: [1],
      label: 'START',
      isStart: true,
    ),
    _ArchNodeData(
      id: 1,
      island: 0,
      pos: Offset(0.24, 0.52),
      neighbors: [0],
      anchorIndex: 0,
    ),

    // Island 1 (Cascading Sanctuary - Top-Left)
    _ArchNodeData(
      id: 2,
      island: 1,
      pos: Offset(0.31, 0.33),
      neighbors: [3],
      anchorIndex: 1,
    ),
    _ArchNodeData(id: 3, island: 1, pos: Offset(0.39, 0.36), neighbors: [2, 4]),
    _ArchNodeData(
      id: 4,
      island: 1,
      pos: Offset(0.48, 0.37),
      neighbors: [3],
      switchIndex: 1,
    ),

    // Island 2 (Lower-Center / Cascade Isle)
    _ArchNodeData(
      id: 5,
      island: 2,
      pos: Offset(0.50, 0.64),
      neighbors: [6],
      anchorIndex: 2,
    ),
    _ArchNodeData(
      id: 6,
      island: 2,
      pos: Offset(0.55, 0.74),
      neighbors: [5],
      anchorIndex: 3,
    ),

    // Island 3 (Sunstone Isle - Mid-Right)
    _ArchNodeData(
      id: 7,
      island: 3,
      pos: Offset(0.67, 0.56),
      neighbors: [8],
      anchorIndex: 4,
    ),
    _ArchNodeData(id: 8, island: 3, pos: Offset(0.72, 0.53), neighbors: [7, 9]),
    _ArchNodeData(
      id: 9,
      island: 3,
      pos: Offset(0.72, 0.49),
      neighbors: [8],
      switchIndex: 2,
    ),

    // Island 4 (Sky Citadel & Exit - Top-Right)
    _ArchNodeData(
      id: 10,
      island: 4,
      pos: Offset(0.69, 0.35),
      neighbors: [11],
      anchorIndex: 5,
    ),
    _ArchNodeData(
      id: 11,
      island: 4,
      pos: Offset(0.76, 0.32),
      neighbors: [10, 12, 13],
    ),
    _ArchNodeData(
      id: 12,
      island: 4,
      pos: Offset(0.88, 0.44),
      neighbors: [11],
      switchIndex: 3,
    ),
    _ArchNodeData(
      id: 13,
      island: 4,
      pos: Offset(0.78, 0.25),
      neighbors: [11, 14],
    ),
    _ArchNodeData(
      id: 14,
      island: 4,
      pos: Offset(0.83, 0.15),
      neighbors: [13],
      isExit: true,
    ),
  ];

  int? _getPortalAtAnchor(int anchorIndex) {
    final idx = _archPortalAnchors.indexOf(anchorIndex);
    return idx != -1 ? idx : null;
  }

  int? _getPortalAtNode(int nodeId) {
    final node = _archNodes[nodeId];
    if (node.anchorIndex == null) return null;
    return _getPortalAtAnchor(node.anchorIndex!);
  }

  void _moveArchToNode(int targetNodeId) {
    if (_completed || _archTeleporting) return;
    final currentNode = _archNodes[_archPlayerNode];
    final targetNode = _archNodes[targetNodeId];

    if (currentNode.id == targetNode.id) return;

    // Same island movement: direct neighbor or path
    if (currentNode.island == targetNode.island) {
      if (currentNode.neighbors.contains(targetNode.id)) {
        _setArchPlayerNode(targetNode.id);
        return;
      }
      for (final n in currentNode.neighbors) {
        if (_archNodes[n].island == targetNode.island &&
            _archNodes[n].neighbors.contains(targetNode.id)) {
          _setArchPlayerNode(n);
          Future.delayed(const Duration(milliseconds: 180), () {
            if (mounted && !_completed) _setArchPlayerNode(targetNode.id);
          });
          return;
        }
      }
    }

    final curPortal = _getPortalAtNode(currentNode.id);
    if (curPortal != null) {
      _teleportArchPlayer(curPortal);
      return;
    }

    setState(() {
      _archStatus =
          'Island is disconnected! Move a portal onto this island to cross.';
    });
    unawaited(HapticFeedback.lightImpact());
  }

  void _setArchPlayerNode(int nodeId) {
    setState(() {
      _archPlayerNode = nodeId;
    });
    unawaited(_playParallelSound('parallel_step.wav'));
    unawaited(HapticFeedback.lightImpact());

    final node = _archNodes[nodeId];

    // Check if player landed on an anchor with a portal
    final portalOnNode = _getPortalAtNode(nodeId);
    if (portalOnNode != null) {
      Future.delayed(const Duration(milliseconds: 260), () {
        if (mounted && !_completed && _archPlayerNode == nodeId) {
          _teleportArchPlayer(portalOnNode);
        }
      });
      return;
    }

    // Check switch
    if (node.switchIndex != null) {
      final sw = node.switchIndex!;
      if (!_archActivatedSwitches.contains(sw)) {
        setState(() {
          _archActivatedSwitches.add(sw);
          if (_archActivatedSwitches.length == 3) {
            _archExitOpen = true;
            _archStatus =
                'ALL 3 SWITCHES ACTIVATED! THE GRAND EXIT GATEWAY IS UNSEALED!';
          } else {
            _archStatus =
                'Switch $sw activated! [${_archActivatedSwitches.length}/3 switches ready]';
          }
        });
        unawaited(_playParallelSound('parallel_complete.wav'));
        unawaited(HapticFeedback.heavyImpact());
      }
    }

    // Check exit gateway
    if (node.isExit) {
      if (_archExitOpen && !_completed) {
        setState(() {
          _archStatus = 'Ancient gateway breached! Reality synchronizing...';
        });
        unawaited(_playParallelSound('parallel_complete.wav'));
        unawaited(_finish());
      } else if (!_archExitOpen) {
        setState(() {
          _archStatus =
              'Gateway is sealed! Activate all three diamond switches to enter.';
        });
        unawaited(HapticFeedback.selectionClick());
      }
    }
  }

  void _teleportArchPlayer(int fromPortal) {
    if (_archTeleporting || _completed) return;

    final destPortal = (fromPortal + 1) % 3;
    final destAnchor = _archPortalAnchors[destPortal];
    final destNodeId = _archAnchorNodeMap[destAnchor];

    setState(() {
      _archTeleporting = true;
      _archStatus =
          'Teleporting through ${_archPortalNames[fromPortal]} ➔ ${_archPortalNames[destPortal]}...';
    });
    unawaited(_playParallelSound('parallel_shift.wav'));
    unawaited(HapticFeedback.mediumImpact());

    Future.delayed(const Duration(milliseconds: 380), () {
      if (!mounted) return;
      final destNeighbors = _archNodes[destNodeId].neighbors;
      final stepNodeId = destNeighbors.isNotEmpty
          ? destNeighbors.first
          : destNodeId;

      setState(() {
        _archPlayerNode = stepNodeId;
        _archTeleporting = false;
        _archStatus =
            'Emerged from ${_archPortalNames[destPortal]}! Explore the island.';
      });
      unawaited(_playParallelSound('parallel_step.wav'));

      final stepNode = _archNodes[stepNodeId];
      if (stepNode.switchIndex != null) {
        final sw = stepNode.switchIndex!;
        if (!_archActivatedSwitches.contains(sw)) {
          setState(() {
            _archActivatedSwitches.add(sw);
            if (_archActivatedSwitches.length == 3) {
              _archExitOpen = true;
              _archStatus =
                  'ALL 3 SWITCHES ACTIVATED! THE GRAND EXIT GATEWAY IS UNSEALED!';
            } else {
              _archStatus =
                  'Switch $sw activated! [${_archActivatedSwitches.length}/3 switches ready]';
            }
          });
          unawaited(_playParallelSound('parallel_complete.wav'));
        }
      }
    });
  }

  void _setPortalAnchor(int portalIndex, int anchorIndex) {
    if (_completed || _archTeleporting) return;

    final currentAnchor = _archPortalAnchors[portalIndex];
    final currentNodeId = _archAnchorNodeMap[currentAnchor];

    if (_archPlayerNode == currentNodeId) {
      setState(() {
        _archStatus = 'Cannot move a portal while standing in its gateway!';
      });
      unawaited(HapticFeedback.vibrate());
      return;
    }

    setState(() {
      final existingPortal = _archPortalAnchors.indexOf(anchorIndex);
      if (existingPortal != -1) {
        _archPortalAnchors[existingPortal] = currentAnchor;
      }
      _archPortalAnchors[portalIndex] = anchorIndex;
      _archStatus =
          '${_archPortalNames[portalIndex]} placed on Anchor Pad ${anchorIndex + 1}.';
    });
    unawaited(_playParallelSound('parallel_step.wav'));
    unawaited(HapticFeedback.selectionClick());
  }

  void _moveArchDirection(int dx, int dy) {
    if (_completed || _archTeleporting) return;
    final currentNode = _archNodes[_archPlayerNode];
    int? bestNeighbor;
    double bestScore = -1.0;

    for (final nId in currentNode.neighbors) {
      final n = _archNodes[nId];
      final dirX = n.pos.dx - currentNode.pos.dx;
      final dirY = n.pos.dy - currentNode.pos.dy;
      final mag = math.sqrt(dirX * dirX + dirY * dirY);
      if (mag == 0) continue;
      final normX = dirX / mag;
      final normY = dirY / mag;
      final dot = normX * dx + normY * dy;
      if (dot > 0.35 && dot > bestScore) {
        bestScore = dot;
        bestNeighbor = nId;
      }
    }

    if (bestNeighbor != null) {
      _moveArchToNode(bestNeighbor);
    } else {
      final p = _getPortalAtNode(currentNode.id);
      if (p != null) {
        _teleportArchPlayer(p);
      } else {
        setState(() {
          _archStatus = 'No path in that direction. Move a portal to cross.';
        });
      }
    }
  }

  Widget _portalArchitectBoard(double w, double h) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Waterfalls and misty cascades
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (_, _) =>
                CustomPaint(painter: _ArchWaterfallPainter(_pulse.value)),
          ),
        ),

        // Glowing Wormhole Conduits (Cyan -> Orange -> Magenta -> Cyan)
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (_, _) => CustomPaint(
              painter: _ArchConduitPainter(
                anchors: _archPortalAnchors,
                anchorNodes: _archAnchorNodeMap,
                nodes: _archNodes,
                pulse: _pulse.value,
              ),
            ),
          ),
        ),

        // Floating island path lines
        Positioned.fill(
          child: CustomPaint(painter: _ArchPathwaysPainter(_archNodes)),
        ),

        // Interactive Anchors & Portals
        for (var anchorIdx = 0; anchorIdx < 6; anchorIdx++)
          _buildAnchorWidget(anchorIdx, w, h),

        // Switches 1, 2, 3
        _buildSwitchWidget(1, 4, const Color(0xFF32D8FF), w, h),
        _buildSwitchWidget(2, 9, const Color(0xFFFF9436), w, h),
        _buildSwitchWidget(3, 12, const Color(0xFFE243FF), w, h),

        // Grand Ancient Exit Gateway
        _buildExitGateway(w, h),

        // Astronaut Player Character
        _buildArchPlayer(w, h),

        // Bottom Portal Relocation Dock & Controls
        Positioned(left: 8, right: 8, bottom: 6, child: _buildArchBottomBar()),
      ],
    );
  }

  Widget _buildAnchorWidget(int anchorIdx, double w, double h) {
    final nodeId = _archAnchorNodeMap[anchorIdx];
    final node = _archNodes[nodeId];
    final portalIdx = _getPortalAtAnchor(anchorIdx);
    final px = node.pos.dx * w;
    final py = node.pos.dy * h;
    final isSelected = _archSelectedPortal == portalIdx;

    return Positioned(
      left: px - 26,
      top: py - 32,
      child: GestureDetector(
        key: ValueKey('anchor-$anchorIdx'),
        onTap: () {
          if (portalIdx != null) {
            if (_archPlayerNode == nodeId ||
                _archNodes[_archPlayerNode].neighbors.contains(nodeId)) {
              _moveArchToNode(nodeId);
            } else {
              setState(() => _archSelectedPortal = portalIdx);
            }
          } else {
            _setPortalAnchor(_archSelectedPortal, anchorIdx);
          }
        },
        child: SizedBox(
          width: 52,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: 2,
                child: Container(
                  width: 44,
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0x9918233C),
                    border: Border.all(
                      color: portalIdx != null
                          ? _archPortalColors[portalIdx].withValues(alpha: 0.6)
                          : Colors.white24,
                      width: 1.2,
                    ),
                    boxShadow: portalIdx != null
                        ? [
                            BoxShadow(
                              color: _archPortalColors[portalIdx].withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      'P${anchorIdx + 1}',
                      style: TextStyle(
                        color: portalIdx != null
                            ? _archPortalColors[portalIdx]
                            : Colors.white38,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),

              if (portalIdx != null)
                Positioned(
                  top: 0,
                  child: _ArchPortalGate(
                    color: _archPortalColors[portalIdx],
                    label: '${portalIdx + 1}',
                    isSelected: isSelected,
                    pulse: _pulse.value,
                  ),
                )
              else
                Positioned(
                  top: 8,
                  child: Container(
                    width: 32,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      border: Border.all(color: Colors.white12, width: 1.2),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white24,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchWidget(
    int swNum,
    int nodeId,
    Color color,
    double w,
    double h,
  ) {
    final node = _archNodes[nodeId];
    final active = _archActivatedSwitches.contains(swNum);
    final px = node.pos.dx * w;
    final py = node.pos.dy * h;

    return Positioned(
      left: px - 22,
      top: py - 26,
      child: GestureDetector(
        key: ValueKey('switch-$swNum'),
        onTap: () => _moveArchToNode(nodeId),
        child: SizedBox(
          width: 44,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: 0,
                child: Container(
                  width: 36,
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: const Color(0xBB11182C),
                    border: Border.all(
                      color: active ? color : color.withValues(alpha: 0.4),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: active ? 0.6 : 0.15),
                        blurRadius: active ? 12 : 5,
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                top: 4,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, _) => Transform.translate(
                    offset: Offset(
                      0,
                      active ? math.sin(_pulse.value * math.pi * 2) * 2.5 : 0,
                    ),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: active
                              ? [
                                  Colors.white,
                                  color,
                                  color.withValues(alpha: 0.4),
                                ]
                              : [
                                  color.withValues(alpha: 0.6),
                                  const Color(0xFF131A30),
                                ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: active ? 0.8 : 0.25),
                            blurRadius: active ? 16 : 6,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$swNum',
                          style: TextStyle(
                            color: active ? Colors.black87 : Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
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

  Widget _buildExitGateway(double w, double h) {
    final node = _archNodes[14];
    final px = node.pos.dx * w;
    final py = node.pos.dy * h;
    final open = _archExitOpen;

    return Positioned(
      left: px - 28,
      top: py - 32,
      child: GestureDetector(
        key: const ValueKey('exit-gateway'),
        onTap: () => _moveArchToNode(14),
        child: SizedBox(
          width: 56,
          height: 68,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 48,
                height: 62,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: open
                        ? [const Color(0xFF9845FF), const Color(0xFF220D47)]
                        : [const Color(0xFF2C2248), const Color(0xFF0F0B1E)],
                  ),
                  border: Border.all(
                    color: open
                        ? const Color(0xFFC978FF)
                        : const Color(0x669845FF),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF9845FF,
                      ).withValues(alpha: open ? 0.75 : 0.2),
                      blurRadius: open ? 24 : 10,
                      spreadRadius: open ? 2 : 0,
                    ),
                  ],
                ),
                child: Center(
                  child: open
                      ? AnimatedBuilder(
                          animation: _pulse,
                          builder: (_, _) => Container(
                            width: 32,
                            height: 44,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white,
                                  Color(0xFFB545FF),
                                  Color(0xFF24064B),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.diamond_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 1; i <= 3; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: Icon(
                                  _archActivatedSwitches.contains(i)
                                      ? Icons.diamond_rounded
                                      : Icons.diamond_outlined,
                                  size: 10,
                                  color: _archActivatedSwitches.contains(i)
                                      ? const Color(0xFFC978FF)
                                      : Colors.white24,
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArchPlayer(double w, double h) {
    final node = _archNodes[_archPlayerNode];
    final px = node.pos.dx * w;
    final py = node.pos.dy * h;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      left: px - 18,
      top: py - 26,
      child: AnimatedScale(
        scale: _archTeleporting ? 0.1 : 1.0,
        duration: const Duration(milliseconds: 240),
        child: AnimatedOpacity(
          opacity: _archTeleporting ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            key: const ValueKey('portal-player'),
            width: 36,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFE4F7FF),
              border: Border.all(color: const Color(0xFF38D9FF), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x9938D9FF),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
              image: const DecorationImage(
                image: AssetImage('assets/images/level5_astronaut.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArchBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xEE0B1224),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x4438D9FF)),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 16)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                'PORTALS:',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              for (var i = 0; i < 3; i++) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _archSelectedPortal = i);
                      unawaited(HapticFeedback.selectionClick());
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: _archSelectedPortal == i
                            ? _archPortalColors[i].withValues(alpha: 0.28)
                            : const Color(0x66141D34),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _archSelectedPortal == i
                              ? _archPortalColors[i]
                              : _archPortalColors[i].withValues(alpha: 0.35),
                          width: _archSelectedPortal == i ? 1.6 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _archPortalColors[i],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ['CYAN', 'ORANGE', 'MAGENTA'][i],
                            style: TextStyle(
                              color: _archSelectedPortal == i
                                  ? Colors.white
                                  : Colors.white70,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (i < 2) const SizedBox(width: 6),
              ],
            ],
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              Row(
                children: [
                  for (var sw = 1; sw <= 3; sw++) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: _archActivatedSwitches.contains(sw)
                            ? const Color(0x334CD69B)
                            : const Color(0x331E2844),
                        border: Border.all(
                          color: _archActivatedSwitches.contains(sw)
                              ? const Color(0xFF4CD69B)
                              : Colors.white24,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _archActivatedSwitches.contains(sw)
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 10,
                            color: _archActivatedSwitches.contains(sw)
                                ? const Color(0xFF4CD69B)
                                : Colors.white38,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'SW$sw',
                            style: TextStyle(
                              color: _archActivatedSwitches.contains(sw)
                                  ? const Color(0xFF4CD69B)
                                  : Colors.white38,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              const Spacer(),

              _archArrowBtn(Icons.arrow_back_rounded, -1, 0),
              const SizedBox(width: 5),
              _archArrowBtn(Icons.arrow_upward_rounded, 0, -1),
              const SizedBox(width: 5),
              _archArrowBtn(Icons.arrow_downward_rounded, 0, 1),
              const SizedBox(width: 5),
              _archArrowBtn(Icons.arrow_forward_rounded, 1, 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _archArrowBtn(IconData icon, int dx, int dy) {
    return SizedBox(
      width: 32,
      height: 30,
      child: IconButton.filledTonal(
        padding: EdgeInsets.zero,
        onPressed: _completed ? null : () => _moveArchDirection(dx, dy),
        icon: Icon(icon, color: const Color(0xFF70E9FF), size: 16),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xCC1A2340),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0x4470E9FF)),
          ),
        ),
      ),
    );
  }

  Widget _liarsPortal(double w, double h) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        'THREE DOORS. ONE TRUE SHADOW.',
        style: TextStyle(
          color: accent,
          fontSize: 9,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 19),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (index) => GestureDetector(
            onTap: () => index == 2
                ? _finish()
                : _miss('That portal’s shadow points away from the moon.'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: _portalDoor(index, accent),
            ),
          ),
        ),
      ),
      const SizedBox(height: 13),
      const Text(
        'Watch where each shadow falls.',
        style: TextStyle(color: Colors.white60, fontSize: 11),
      ),
    ],
  );

  Widget _constellation(double w, double h) {
    const path = [0, 2, 1, 3];
    final points = [
      Offset(w * .25, h * .34),
      Offset(w * .73, h * .32),
      Offset(w * .38, h * .69),
      Offset(w * .78, h * .70),
    ];
    final route = [points[0], points[2], points[1], points[3]];
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _ConstellationLines(route, accent)),
        ),
        for (var i = 0; i < points.length; i++)
          Positioned(
            left: points[i].dx - 24,
            top: points[i].dy - 24,
            child: GestureDetector(
              onTap: () {
                if (i == path[_step]) {
                  setState(() => _step++);
                  if (_step == path.length) _finish();
                } else {
                  setState(() => _step = 0);
                  _miss('The constellation begins at the smallest star.');
                }
              },
              child: _orb(48, accent, Icons.star_rounded),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 15,
          child: Center(child: _stepDots(4)),
        ),
      ],
    );
  }

  Widget _anchors(double w, double h) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text(
        'A WORLD IS NOT ITS SIZE.',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 10,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 25),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          3,
          (index) => GestureDetector(
            onTap: () {
              if (index == _step) {
                setState(() => _step++);
                if (_step == 3) _finish();
              } else {
                setState(() => _step = 0);
                _miss('The smallest world anchors first.');
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11),
              child: _planetOrb(
                36.0 + 22.0 * index,
                index == _step ? accent : accent.withValues(alpha: .42),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 25),
      _stepDots(3),
    ],
  );

  Widget _quietStorm(double w, double h) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      GestureDetector(
        onLongPressStart: (_) => setState(() => _armed = true),
        onLongPressEnd: (_) {},
        onTap: () =>
            _miss('Hold the moon still. A quick touch only wakes the storm.'),
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, _) => Container(
            width: 125,
            height: 125,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accent.withValues(alpha: _armed ? .7 : .25),
                  const Color(0xFF151C33),
                  _night,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: _armed ? .32 : .12),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Icon(
              _armed ? Icons.nights_stay_rounded : Icons.bolt_rounded,
              color: _armed ? Colors.white : accent,
              size: 58,
            ),
          ),
        ),
      ),
      const SizedBox(height: 15),
      if (_armed)
        _actionButton('TOUCH THE QUIET STAR', _finish)
      else
        const Text(
          'PRESS AND HOLD',
          style: TextStyle(
            color: Colors.white54,
            letterSpacing: 1.5,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
    ],
  );

  Widget _finalHeart(double w, double h) {
    final labels = ['RETURN MOON', 'TURN TIME', 'DARK PORTAL'];
    final icons = [
      Icons.brightness_2_rounded,
      Icons.schedule_rounded,
      Icons.blur_circular_rounded,
    ];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, _) => Icon(
            Icons.diamond_rounded,
            size: 77 + _pulse.value * 10,
            color: accent,
            shadows: [
              Shadow(color: accent.withValues(alpha: .55), blurRadius: 24),
            ],
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'THE FRACTURE IS LISTENING',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 9,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (index) => GestureDetector(
              onTap: () {
                if (index == _step) {
                  setState(() => _step++);
                  if (_step == 3) _finish();
                } else {
                  setState(() => _step = 0);
                  _miss(
                    'The heart remembers the order: moon, time, dark portal.',
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Container(
                      width: 61,
                      height: 61,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(
                          alpha: _step == index ? .28 : .08,
                        ),
                        border: Border.all(
                          color: accent.withValues(alpha: .55),
                        ),
                        boxShadow: _step == index
                            ? [
                                BoxShadow(
                                  color: accent.withValues(alpha: .27),
                                  blurRadius: 17,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(icons[index], color: accent, size: 27),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      labels[index],
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 7,
                        letterSpacing: .55,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        _stepDots(3),
      ],
    );
  }

  Widget _node(int index, double size, Color color, {bool glow = false}) =>
      AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: .86),
              color,
              color.withValues(alpha: .3),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: glow ? .9 : .3),
            width: glow ? 2 : 1,
          ),
          boxShadow: glow
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: .55),
                    blurRadius: 19,
                    spreadRadius: 1,
                  ),
                ]
              : [BoxShadow(color: color.withValues(alpha: .18), blurRadius: 7)],
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .8),
              fontSize: size * .24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );

  Widget _moonOrb(double size, Color color) =>
      _orb(size, color, Icons.brightness_2_rounded);
  Widget _lensOrb(double size, Color color) =>
      _orb(size, color, Icons.lens_blur_rounded);
  Widget _planetOrb(double size, Color color) =>
      _orb(size, color, Icons.public_rounded);

  Widget _orb(double size, Color color, IconData icon) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        center: const Alignment(-.3, -.35),
        radius: .95,
        colors: [
          Colors.white.withValues(alpha: .8),
          color,
          Color.lerp(color, _night, .72)!,
        ],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: .45)),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: .28),
          blurRadius: 17,
          spreadRadius: 1,
        ),
      ],
    ),
    child: Icon(
      icon,
      color: Colors.white.withValues(alpha: .86),
      size: size * .47,
    ),
  );

  Widget _portalDoor(int index, Color color) => Column(
    children: [
      Container(
        width: 68,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(40),
            bottom: Radius.circular(12),
          ),
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: index == 1 ? .42 : .17),
              const Color(0xFF0A1020),
            ],
          ),
          border: Border.all(color: color.withValues(alpha: .68), width: 2),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: .16), blurRadius: 16),
          ],
        ),
        child: Icon(Icons.circle_outlined, color: color, size: 36),
      ),
      const SizedBox(height: 9),
      Container(
        width: 42,
        height: 3,
        decoration: BoxDecoration(
          color: index == 2 ? color.withValues(alpha: .85) : Colors.white24,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    ],
  );

  Widget _actionButton(String label, VoidCallback onTap) => ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
      backgroundColor: accent,
      foregroundColor: _night,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 10,
      shadowColor: accent.withValues(alpha: .35),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
        fontSize: 11,
      ),
    ),
  );

  Widget _stepDots(int total) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      total,
      (index) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: index < _step ? 18 : 7,
        height: 7,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: index < _step ? accent : Colors.white24,
          borderRadius: BorderRadius.circular(99),
          boxShadow: index < _step
              ? [BoxShadow(color: accent.withValues(alpha: .55), blurRadius: 8)]
              : null,
        ),
      ),
    ),
  );

  Widget _tinyChip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withValues(alpha: .3)),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 8,
        letterSpacing: 1,
        fontWeight: FontWeight.w900,
      ),
    ),
  );

  Widget _glassPill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xB5202B48),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Colors.white12),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 9,
        letterSpacing: .9,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _roundIcon(IconData icon, VoidCallback onTap) => Material(
    color: const Color(0xAA202B47),
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 39,
        height: 39,
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    ),
  );

  Widget _brief(String text, {required IconData icon}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: const Color(0xA5162036),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: .09)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: accent),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFD7DDEF),
              fontSize: 11,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  String get _completionLine => switch (widget.level) {
    9 => 'The echo returns to its source. A memory stirs.',
    10 => 'The moon crosses its own reflection. The path opens.',
    11 => 'The comet steals one breath of daylight.',
    12 => 'You pause the hazard grid long enough to reach the exit.',
    13 => 'The six fragments align. A radiant bridge reaches the portal.',
    14 => 'The ancient gateway blazes to life. The sky realm is restored.',
    15 => 'The honest shadow reveals a safe passage.',
    16 => 'The constellation takes shape again.',
    17 => 'One second slips back into place.',
    18 => 'The three worlds hold together.',
    19 => 'In the quiet, you hear the heart beating.',
    _ => 'The fracture closes. Reality remembers you.',
  };

  Widget _winOverlay() => Positioned.fill(
    child: Container(
      color: widget.level == 13
          ? const Color(0xAAF4FBFF)
          : const Color(0xD8070A15),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.level == 11 ||
              widget.level == 12 ||
              widget.level == 13 ||
              widget.level == 14)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, _) => CustomPaint(
                    painter: _ParallelCompletionPainter(_pulse.value, accent),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(26),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: widget.level == 13
                      ? const [Color(0xFFFFFEF9), Color(0xFFE6F7FF)]
                      : const [Color(0xFF1B2A49), Color(0xFF10182B)],
                ),
                border: Border.all(color: accent.withValues(alpha: .65)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: .19),
                    blurRadius: 32,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) => Transform.scale(
                      scale:
                          widget.level == 11 ||
                              widget.level == 12 ||
                              widget.level == 13
                          ? 1 + _pulse.value * .13
                          : 1,
                      child: child,
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: accent,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    'REALITY REPAIRED',
                    style: TextStyle(
                      color: widget.level == 13
                          ? const Color(0xFF173D62)
                          : Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    _completionLine,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.level == 13
                          ? const Color(0xFF315878)
                          : Colors.white70,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    '${'★' * (_attempts == 0
                            ? 3
                            : _attempts < 3
                            ? 2
                            : 1)}   +${(_attempts == 0
                            ? 3
                            : _attempts < 3
                            ? 2
                            : 1) * 15}',
                    style: const TextStyle(
                      color: Color(0xFFFFD36B),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _next,
                      icon: Icon(
                        widget.level == 20
                            ? Icons.flag_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(
                        widget.level == 20
                            ? 'RETURN TO ARCHIVE'
                            : 'NEXT REALITY',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: _night,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
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
  );
}

class _MirrorRayTrace {
  const _MirrorRayTrace({
    required this.points,
    required this.activatedReceivers,
  });

  final List<Offset> points;
  final Set<int> activatedReceivers;
}

class _BoardStars extends CustomPainter {
  const _BoardStars(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(90);
    for (var i = 0; i < 36; i++) {
      final point = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      canvas.drawCircle(
        point,
        .6 + random.nextDouble() * 1.2,
        Paint()
          ..color = (i % 4 == 0 ? color : Colors.white).withValues(
            alpha: .14 + random.nextDouble() * .28,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BoardStars oldDelegate) =>
      oldDelegate.color != color;
}

class _ParallelWorldPathPainter extends CustomPainter {
  const _ParallelWorldPathPainter(this.route, this.color);
  final List<Offset> route;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var i = 0; i < route.length; i++) {
      final node = route[i];
      final point = Offset(
        size.width * (.11 + node.dx * .155),
        size.height * (.18 + node.dy * .105),
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
        ..color = color.withValues(alpha: .36)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: .42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ParallelWorldPathPainter oldDelegate) =>
      color != oldDelegate.color;
}

class _ParallelBurstPainter extends CustomPainter {
  const _ParallelBurstPainter(this.progress, this.color);
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withValues(alpha: (1 - progress) * .95);
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final distance = size.width * (.12 + progress * .43);
      final point =
          center +
          Offset(math.cos(angle) * distance, math.sin(angle) * distance);
      canvas.drawCircle(point, size.width * .035 * (1 - progress * .45), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParallelBurstPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}

class _ParallelCompletionPainter extends CustomPainter {
  const _ParallelCompletionPainter(this.progress, this.color);
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withValues(alpha: .5 + .3 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, 62 + progress * 28, paint);
    canvas.drawCircle(
      center,
      92 + progress * 42,
      paint..color = color.withValues(alpha: .25),
    );
    for (var i = 0; i < 24; i++) {
      final angle = i * math.pi / 12;
      final radius = 76 + (i % 3) * 26 + progress * 34;
      canvas.drawCircle(
        center + Offset(math.cos(angle) * radius, math.sin(angle) * radius),
        1.4 + progress * 1.4,
        paint..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParallelCompletionPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}

class _ShatteredRayPainter extends CustomPainter {
  const _ShatteredRayPainter(
    this.cells,
    this.receivers,
    this.bridgeOpen,
    this.pulse,
  );

  final List<Offset> cells;
  final Set<int> receivers;
  final bool bridgeOpen;
  final double pulse;

  Offset _point(Offset grid, Size size) => Offset(
    size.width * (.08 + grid.dx * .105),
    size.height * (.12 + grid.dy * .11),
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (bridgeOpen) {
      for (var column = 1; column <= 6; column++) {
        final point = _point(Offset(column.toDouble(), 4), size);
        final rect = Rect.fromCenter(
          center: point,
          width: size.width * .087,
          height: size.height * .045,
        );
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = const Color(0x66E15CFF)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
        );
        canvas.drawRRect(
          rrect,
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFFD891FF), Color(0xFFB14CFF), Color(0xFF7D52E8)],
            ).createShader(rect),
        );
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = const Color(0xCCF7D8FF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }

    if (cells.length < 2) return;
    final path = Path()
      ..moveTo(_point(cells.first, size).dx, _point(cells.first, size).dy);
    for (final cell in cells.skip(1)) {
      final point = _point(cell, size);
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x9954DFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF68E8FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xEFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // A few traveling glints make the beam feel energized without creating
    // per-frame widgets or expensive particle simulations.
    for (var i = 0; i < 3; i++) {
      final index = math.min(
        cells.length - 1,
        1 + ((cells.length - 2) * ((pulse + i / 3) % 1)).round(),
      );
      final point = _point(cells[index], size);
      canvas.drawCircle(
        point,
        2.2 + pulse * 1.3,
        Paint()
          ..color = Colors.white.withValues(alpha: .65 + .3 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ShatteredRayPainter oldDelegate) =>
      !identical(cells, oldDelegate.cells) ||
      !identical(receivers, oldDelegate.receivers) ||
      bridgeOpen != oldDelegate.bridgeOpen ||
      pulse != oldDelegate.pulse;
}

class _TimeFreezeCoursePainter extends CustomPainter {
  const _TimeFreezeCoursePainter(this.route, this.phase, this.frozen);
  final List<Offset> route;
  final double phase;
  final bool frozen;

  Offset _point(double routeIndex, Size size) {
    final low = routeIndex.floor().clamp(0, route.length - 1);
    final high = math.min(low + 1, route.length - 1);
    final fraction = (routeIndex - low).clamp(0.0, 1.0);
    final a = route[low];
    final b = route[high];
    final x = a.dx + (b.dx - a.dx) * fraction;
    final y = a.dy + (b.dy - a.dy) * fraction;
    return Offset(size.width * (.11 + x * .155), size.height * (.12 + y * .10));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var i = 0; i < route.length; i++) {
      final point = _point(i.toDouble(), size);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x7759DFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    _drawLaser(canvas, size, 2 + phase * 2.15, const Color(0xFFFF5A9F));
    _drawLaser(canvas, size, 7.8 - phase * 2.1, const Color(0xFF67DEFF));
  }

  void _drawLaser(Canvas canvas, Size size, double routeIndex, Color color) {
    final center = _point(routeIndex, size);
    final before = _point(
      (routeIndex - .08).clamp(0.0, route.length - 1.0),
      size,
    );
    final after = _point(
      (routeIndex + .08).clamp(0.0, route.length - 1.0),
      size,
    );
    final tangent = after - before;
    final length = math.max(
      1.0,
      math.sqrt(tangent.dx * tangent.dx + tangent.dy * tangent.dy),
    );
    final perpendicular = Offset(-tangent.dy / length, tangent.dx / length);
    final halfLength = size.width * .075;
    final start = center - perpendicular * halfLength;
    final end = center + perpendicular * halfLength;
    final beamColor = frozen ? const Color(0xFF8DEFFF) : color;
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = beamColor.withValues(alpha: frozen ? .24 : .54)
        ..strokeWidth = frozen ? 13 : 11
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = beamColor.withValues(alpha: frozen ? .62 : .96)
        ..strokeWidth = frozen ? 2.5 : 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      center,
      frozen ? 9 : 7,
      Paint()
        ..color = beamColor.withValues(alpha: .9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(center, frozen ? 5 : 4, Paint()..color = Colors.white);
    if (frozen) {
      canvas.drawCircle(
        center,
        15,
        Paint()
          ..color = beamColor.withValues(alpha: .75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimeFreezeCoursePainter oldDelegate) =>
      phase != oldDelegate.phase || frozen != oldDelegate.frozen;
}

class _ConstellationLines extends CustomPainter {
  const _ConstellationLines(this.points, this.color);
  final List<Offset> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .3)
      ..strokeWidth = 1.4;
    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationLines oldDelegate) => false;
}

// ==========================================
// PORTAL ARCHITECT DATA MODELS & PAINTERS
// ==========================================

class _ArchNodeData {
  const _ArchNodeData({
    required this.id,
    required this.island,
    required this.pos,
    required this.neighbors,
    this.anchorIndex,
    this.switchIndex,
    this.label,
    this.isExit = false,
    this.isStart = false,
  });

  final int id;
  final int island;
  final Offset pos;
  final List<int> neighbors;
  final int? anchorIndex;
  final int? switchIndex;
  final String? label;
  final bool isExit;
  final bool isStart;
}

class _ArchPortalGate extends StatelessWidget {
  const _ArchPortalGate({
    required this.color,
    required this.label,
    required this.isSelected,
    required this.pulse,
  });

  final Color color;
  final String label;
  final bool isSelected;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.85), const Color(0xFF0F1626)],
        ),
        border: Border.all(
          color: isSelected ? Colors.white : color,
          width: isSelected ? 2.0 : 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isSelected ? 0.8 : 0.4),
            blurRadius: isSelected ? 18 : 10,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 24,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            gradient: RadialGradient(
              colors: [Colors.white, color, const Color(0xFF0B101E)],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.door_sliding_rounded,
              color: Colors.white.withValues(alpha: 0.85),
              size: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArchPathwaysPainter extends CustomPainter {
  const _ArchPathwaysPainter(this.nodes);
  final List<_ArchNodeData> nodes;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0x6676A8D8)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = const Color(0x9950B6FF)
      ..style = PaintingStyle.fill;

    for (final node in nodes) {
      final p1 = Offset(node.pos.dx * size.width, node.pos.dy * size.height);
      for (final nId in node.neighbors) {
        if (nId > node.id) {
          final n = nodes[nId];
          final p2 = Offset(n.pos.dx * size.width, n.pos.dy * size.height);
          canvas.drawLine(p1, p2, linePaint);
        }
      }
      canvas.drawCircle(p1, 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArchConduitPainter extends CustomPainter {
  const _ArchConduitPainter({
    required this.anchors,
    required this.anchorNodes,
    required this.nodes,
    required this.pulse,
  });

  final List<int> anchors;
  final List<int> anchorNodes;
  final List<_ArchNodeData> nodes;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFF32D8FF), // Cyan -> Orange
      const Color(0xFFFF9436), // Orange -> Magenta
      const Color(0xFFE243FF), // Magenta -> Cyan
    ];

    for (var i = 0; i < 3; i++) {
      final next = (i + 1) % 3;
      final startAnchor = anchors[i];
      final endAnchor = anchors[next];
      final startNode = nodes[anchorNodes[startAnchor]];
      final endNode = nodes[anchorNodes[endAnchor]];

      final p1 = Offset(
        startNode.pos.dx * size.width,
        startNode.pos.dy * size.height,
      );
      final p2 = Offset(
        endNode.pos.dx * size.width,
        endNode.pos.dy * size.height,
      );

      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2 - 24);

      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, p2.dx, p2.dy);

      final paint = Paint()
        ..color = colors[i].withValues(alpha: 0.55 + pulse * 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArchConduitPainter oldDelegate) =>
      pulse != oldDelegate.pulse || anchors != oldDelegate.anchors;
}

class _ArchWaterfallPainter extends CustomPainter {
  const _ArchWaterfallPainter(this.pulse);
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final streams = [
      Offset(size.width * 0.35, size.height * 0.40),
      Offset(size.width * 0.52, size.height * 0.70),
      Offset(size.width * 0.86, size.height * 0.46),
    ];

    final paint = Paint()
      ..color = const Color(0x6676E9FF)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final mistPaint = Paint()
      ..color = const Color(0x2280E5FF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    for (final s in streams) {
      final flowLen = 32.0 + math.sin(pulse * math.pi * 2) * 4;
      canvas.drawLine(s, Offset(s.dx + 2, s.dy + flowLen), paint);
      canvas.drawCircle(Offset(s.dx, s.dy + flowLen), 14, mistPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArchWaterfallPainter oldDelegate) =>
      pulse != oldDelegate.pulse;
}
