import 'dart:async';

import 'package:flutter/material.dart';
import '../core/widget/campaign_monetization_controls.dart';
import 'package:flutter/services.dart';

import '../services/level_progress_service.dart';
import '../services/ads_service.dart';
import 'level/level_screen.dart';

/// Level 16: The Vanishing Path.
///
/// Memorize the route, use scans to reveal the next legal move,
/// activate checkpoints, and reach the exit.
class Level16Screen extends StatefulWidget {
  const Level16Screen({super.key});

  @override
  State<Level16Screen> createState() => _Level16ScreenState();
}

class _Level16ScreenState extends State<Level16Screen>
    with SingleTickerProviderStateMixin {
  static const String _background =
      'assets/images/level16_vanishing_path_bg.png';

  static const Color _cyan = Color(0xFF6BEAFF);
  static const Color _violet = Color(0xFFCB8CFF);
  static const Color _danger = Color(0xFFFF667F);
  static const Color _panel = Color(0xE80A1024);

  static const int _rows = 7;
  static const int _cols = 5;

  // Coordinates are Offset(row, column).
  // Each successive tile is directly adjacent to the previous one.
  static const List<Offset> _route = [
    Offset(6, 0),
    Offset(6, 1),
    Offset(5, 1),
    Offset(5, 2),
    Offset(4, 2),
    Offset(4, 3),
    Offset(3, 3),
    Offset(3, 2),
    Offset(2, 2),
    Offset(2, 3),
    Offset(1, 3),
    Offset(1, 4),
    Offset(0, 4),
  ];

  static const Set<int> _checkpointIndices = {4, 8};
  static const int _exitIndex = 12;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  Timer? _introTimer;
  Timer? _scanTimer;

  int _playerIndex = 0;
  int _checkpointIndex = 0;
  int _scanCharges = 3;
  int _mistakes = 0;

  bool _introReveal = true;
  bool _scanning = false;
  bool _completed = false;
  bool _saving = false;
  bool _finishStarted = false;

  final Set<Offset> _collapsed = <Offset>{};

  String _status = 'Memorize the path before it vanishes.';

  @override
  void initState() {
    super.initState();
    _startIntroTimer();
  }

  void _startIntroTimer() {
    _introTimer?.cancel();

    _introTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || _completed) return;

      setState(() {
        _introReveal = false;
        _status = 'The path vanished. Remember the route and move carefully.';
      });
    });
  }

  @override
  void dispose() {
    _introTimer?.cancel();
    _scanTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Offset get _playerCell => _route[_playerIndex];

  /// Returns the exact next tile accepted by the movement logic.
  ///
  /// The scan and movement system both use this same route index.
  /// This prevents scan highlights from disagreeing with valid moves.
  Offset? get _nextRouteCell {
    final nextIndex = _playerIndex + 1;

    if (nextIndex >= _route.length) {
      return null;
    }

    final nextCell = _route[nextIndex];

    if (_collapsed.contains(nextCell)) {
      return null;
    }

    return nextCell;
  }

  Future<void> _scan() async {
    if (_completed || _saving || _scanning || _introReveal) {
      if (_introReveal && mounted) {
        setState(() {
          _status = 'Watch the glowing route first. Scanning starts afterward.';
        });
      }
      return;
    }

    if (_scanCharges <= 0) {
      setState(() {
        _status = 'No scan energy left. Reach a checkpoint to recharge.';
      });
      return;
    }

    if (_nextRouteCell == null) {
      setState(() {
        _status = 'No next tile is available. Restart the level.';
      });
      return;
    }

    setState(() {
      _scanCharges--;
      _scanning = true;
      _status = 'SCAN ACTIVE — follow the glowing tile.';
    });

    await HapticFeedback.selectionClick();

    _scanTimer?.cancel();

    _scanTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      setState(() {
        _scanning = false;
        _status = 'Scan ended. Trust your memory.';
      });
    });
  }

  Future<void> _move(int dx, int dy) async {
    if (_completed || _saving || _finishStarted) return;

    if (_introReveal) {
      setState(() {
        _status =
            'Memorize the route first. Movement unlocks after the reveal.';
      });
      return;
    }

    final current = _playerCell;

    // dx represents horizontal movement.
    // dy represents vertical movement.
    final target = Offset(current.dx + dy, current.dy + dx);

    // Prevent movement outside the board.
    if (target.dx < 0 ||
        target.dx >= _rows ||
        target.dy < 0 ||
        target.dy >= _cols) {
      setState(() {
        _status = 'There is no platform beyond the edge.';
      });
      return;
    }

    // A collapsed tile cannot be entered.
    if (_collapsed.contains(target)) {
      setState(() {
        _status = 'That platform has collapsed. Try another move.';
      });
      return;
    }

    final nextIndex = _route.indexOf(target);

    // The player stepped on a tile that isn't part of the safe route.
    if (nextIndex == -1) {
      await _handleWrongMove(
        'The platform was an illusion! Returning to the last checkpoint.',
        target: target,
      );
      return;
    }

    // Only the next route tile is legal.
    //
    // The scan highlights this exact tile, so a player following the
    // scan cannot accidentally skip forward to another safe route tile.
    if (nextIndex != _playerIndex + 1) {
      await _handleWrongMove(
        'Follow the route in order. Returning to the last checkpoint.',
      );
      return;
    }

    // Defensive adjacency check: all legal moves must be one tile away.
    final rowDistance = (target.dx - current.dx).abs();
    final colDistance = (target.dy - current.dy).abs();

    if (rowDistance + colDistance != 1) {
      await _handleWrongMove('That move is too far. Follow the next platform.');
      return;
    }

    // Cancel scan after the player makes a move.
    _scanTimer?.cancel();

    final previousIndex = _playerIndex;

    setState(() {
      _scanning = false;

      // The platform the player leaves collapses unless it is a checkpoint.
      if (previousIndex != _checkpointIndex &&
          !_checkpointIndices.contains(previousIndex)) {
        _collapsed.add(current);
      }

      _playerIndex = nextIndex;

      // Activate checkpoints and restore one scan charge.
      if (_checkpointIndices.contains(nextIndex)) {
        _checkpointIndex = nextIndex;
        _scanCharges = (_scanCharges + 1).clamp(0, 3).toInt();

        _status = 'Checkpoint secured! One scan charge restored.';
      } else if (nextIndex == _exitIndex) {
        _status = 'Gateway reached! Restoring the path...';
      } else {
        _status = 'Platform secured. Keep following the route.';
      }
    });

    await HapticFeedback.lightImpact();

    // Important: use the accepted nextIndex to detect the exit.
    // This avoids relying on a stale state value.
    if (nextIndex == _exitIndex) {
      await _finish();
    }
  }

  Future<void> _handleWrongMove(String message, {Offset? target}) async {
    _mistakes++;

    _scanTimer?.cancel();

    setState(() {
      _scanning = false;

      // Collapse unsafe platforms only.
      // Never collapse a valid route tile due to an out-of-order move.
      if (target != null && !_route.contains(target)) {
        _collapsed.add(target);
      }

      // Respawn at the last checkpoint.
      _playerIndex = _checkpointIndex;

      _status = message;
    });

    await HapticFeedback.heavyImpact();
  }

  Future<void> _finish() async {
    if (_completed || _saving || _finishStarted) return;

    _finishStarted = true;

    _introTimer?.cancel();
    _scanTimer?.cancel();

    setState(() {
      _completed = true;
      _saving = true;
      _scanning = false;
      _status = 'The Vanishing Path has been restored!';
    });

    final int stars = _mistakes == 0 ? 3 : (_mistakes < 3 ? 2 : 1);

    bool saved = false;

    try {
      await LevelProgressService.complete(level: 16, stars: stars);

      saved = true;
    } catch (error, stackTrace) {
      debugPrint('Level 16 progress saving failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (!mounted) return;

    setState(() {
      _saving = false;

      _status = saved
          ? 'Level complete! Your progress has been saved.'
          : 'Level complete, but progress could not be saved.';
    });

    // The completion panel remains visible even if saving fails.
    // The user can still return to the level menu.
  }

  void _restart() {
    _introTimer?.cancel();
    _scanTimer?.cancel();

    setState(() {
      _playerIndex = 0;
      _checkpointIndex = 0;
      _scanCharges = 3;
      _mistakes = 0;

      _collapsed.clear();

      _introReveal = true;
      _scanning = false;
      _completed = false;
      _saving = false;
      _finishStarted = false;

      _status = 'Memorize the path before it vanishes.';
    });

    _startIntroTimer();
  }

  void _hint() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF101831),
        title: const Text('Simple Hint', style: TextStyle(color: _cyan)),
        content: const Text(
          'Remember the glowing path. Tap SCAN to reveal your next move. '
          'Follow the glowing tile and reach the exit.',
          style: TextStyle(color: Color(0xFFE4EAFF), height: 1.45),
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

  Future<void> _continue() async {
    if (!_completed || _saving) return;
    await AdsService.instance.showInterstitialAtTransition();
    if (!mounted) return;

    final nextScreen = campaignPageForLevel(17);

    if (nextScreen == null) {
      setState(() {
        _status = 'Level 17 is not connected in campaign routing yet.';
      });
      return;
    }

    await Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute<void>(builder: (_) => nextScreen),
    );
  }

  Future<void> _backToLevels() async {
    await Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => const LevelScreen()),
      (route) => route.isFirst,
    );
  }

  Widget _glass({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(12),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cyan.withValues(alpha: .24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .22), blurRadius: 18),
        ],
      ),
      child: child,
    );
  }

  Widget _tile(int row, int col) {
    final cell = Offset(row.toDouble(), col.toDouble());
    final routeIndex = _route.indexOf(cell);

    final isPlayer = cell == _playerCell;
    final isStart = routeIndex == 0;
    final isExit = routeIndex == _exitIndex;
    final isCheckpoint =
        routeIndex >= 0 && _checkpointIndices.contains(routeIndex);

    final isCollapsed = _collapsed.contains(cell);

    // The opening reveal shows the complete route.
    final safeVisible = _introReveal && routeIndex >= 0;

    // IMPORTANT FIX:
    // Scan shows only the exact next route tile accepted by _move().
    final scanVisible =
        _scanning && routeIndex == _playerIndex + 1 && !isCollapsed;

    Color fill = Colors.white.withValues(alpha: .035);
    Color border = Colors.white.withValues(alpha: .07);

    Widget? icon;

    if (isCollapsed) {
      fill = _danger.withValues(alpha: .09);
      border = _danger.withValues(alpha: .22);

      icon = Icon(
        Icons.close_rounded,
        color: _danger.withValues(alpha: .6),
        size: 14,
      );
    } else if (safeVisible || scanVisible) {
      fill = (isCheckpoint ? _violet : _cyan).withValues(alpha: .20);
      border = (isCheckpoint ? _violet : _cyan).withValues(alpha: .9);

      icon = Icon(
        isStart
            ? Icons.radio_button_checked_rounded
            : isExit
            ? Icons.door_front_door_rounded
            : isCheckpoint
            ? Icons.adjust_rounded
            : Icons.blur_on_rounded,
        color: isCheckpoint ? _violet : _cyan,
        size: 18,
      );
    } else if (isStart || isExit || isCheckpoint) {
      fill = (isExit ? _violet : _cyan).withValues(alpha: .11);
      border = (isExit ? _violet : _cyan).withValues(alpha: .35);

      icon = Icon(
        isStart
            ? Icons.play_arrow_rounded
            : isExit
            ? Icons.door_front_door_rounded
            : Icons.flag_rounded,
        color: isExit ? _violet : _cyan.withValues(alpha: .8),
        size: 17,
      );
    }

    if (isPlayer) {
      fill = Colors.white.withValues(alpha: .16);
      border = Colors.white;

      icon = const Icon(
        Icons.person_pin_circle_rounded,
        color: Colors.white,
        size: 24,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: border, width: isPlayer ? 1.8 : 1),
        boxShadow: safeVisible || isPlayer
            ? [BoxShadow(color: border.withValues(alpha: .22), blurRadius: 10)]
            : null,
      ),
      child: Center(child: icon),
    );
  }

  Widget _arrow(IconData icon, String label, int dx, int dy) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () => _move(dx, dy),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF111D37),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _cyan.withValues(alpha: .3)),
          ),
          child: Icon(icon, color: _cyan, size: 23),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050817),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _background,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF07152E),
                    Color(0xFF160D32),
                    Color(0xFF050817),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, .22, .68, 1],
                colors: [
                  Color(0x99050A1B),
                  Color(0x33050A1B),
                  Color(0x44050A1B),
                  Color(0xF2050817),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      _roundButton(Icons.arrow_back_rounded, _backToLevels),
                      const Spacer(),
                      _glass(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: const Text(
                          'MISSION 16 / 20',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 8),
                      _roundButton(Icons.refresh_rounded, _restart),
                    ],
                  ),
                  const SizedBox(height: 13),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'THE DROWNED CONSTELLATION',
                      style: TextStyle(
                        color: _cyan,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'THE VANISHING PATH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Remember the hidden route. Scan nearby tiles. Reach the gateway.',
                      style: TextStyle(
                        color: Color(0xFFC2CBE3),
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _glass(
                      padding: const EdgeInsets.all(9),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _pill(
                                'SCAN ENERGY  $_scanCharges/3',
                                _scanCharges > 0 ? _cyan : _danger,
                              ),
                              const Spacer(),
                              Text(
                                '${_playerIndex + 1}/${_route.length}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: _cols / _rows,
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: _rows * _cols,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: _cols,
                                      childAspectRatio: 1,
                                    ),
                                itemBuilder: (_, index) =>
                                    _tile(index ~/ _cols, index % _cols),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 15,
                                color: _scanning ? _cyan : _violet,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _status,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFD7DFF5),
                                    fontSize: 10,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              if (_scanning)
                                AnimatedBuilder(
                                  animation: _pulse,
                                  builder: (_, __) => Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: _cyan.withValues(
                                        alpha: .35 + .65 * _pulse.value,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _glass(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _actionButton(
                                Icons.center_focus_strong_rounded,
                                _scanning ? 'SCANNING…' : 'SCAN PATH',
                                _scan,
                                primary: true,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: _actionButton(
                                Icons.restart_alt_rounded,
                                'RESTART',
                                _restart,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            const Spacer(),
                            SizedBox(
                              width: 52,
                              child: _arrow(
                                Icons.keyboard_arrow_up_rounded,
                                'Move up',
                                0,
                                -1,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Expanded(
                              child: _arrow(
                                Icons.keyboard_arrow_left_rounded,
                                'Move left',
                                -1,
                                0,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: _arrow(
                                Icons.keyboard_arrow_down_rounded,
                                'Move down',
                                0,
                                1,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: _arrow(
                                Icons.keyboard_arrow_right_rounded,
                                'Move right',
                                1,
                                0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  CampaignMonetizationControls(
                    level: 16,
                    onHint: _hint,
                    onSkipped: () => Navigator.maybePop(context),
                  ),
                  if (_completed) ...[
                    const SizedBox(height: 9),
                    _glass(
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PATH RESTORED',
                                  style: TextStyle(
                                    color: _cyan,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Your memory survived the void.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _saving ? null : _continue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _cyan,
                              foregroundColor: const Color(0xFF06101D),
                            ),
                            child: Text(_saving ? 'SAVING…' : 'CONTINUE'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 39,
        height: 39,
        decoration: BoxDecoration(
          color: const Color(0xCC0A1024),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: .12)),
        ),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: .7,
        ),
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool primary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: primary
              ? _cyan.withValues(alpha: .15)
              : const Color(0xFF111D37),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: primary
                ? _cyan.withValues(alpha: .7)
                : Colors.white.withValues(alpha: .12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: primary ? _cyan : Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: primary ? _cyan : Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: .5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
