import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/widget/campaign_monetization_controls.dart';
import '../services/ads_service.dart';

enum ShiftMechanic { light, magnet, shadow, maze }

class ShiftLevelConfig {
  const ShiftLevelConfig({
    required this.level,
    required this.title,
    required this.subtitle,
    required this.background,
    required this.mechanic,
    required this.hint,
  });
  final int level;
  final String title;
  final String subtitle;
  final String background;
  final ShiftMechanic mechanic;
  final String hint;
}

/// Shared, self-contained gameplay engine for Reality Shift levels 17–20.
/// No third-party packages required. Connect completion to your save service
/// from onLevelCompleted if your project uses a different progress API.
class RealityShiftPuzzleScreen extends StatefulWidget {
  const RealityShiftPuzzleScreen({
    super.key,
    required this.config,
    this.onLevelCompleted,
  });

  final ShiftLevelConfig config;
  final ValueChanged<int>? onLevelCompleted;

  @override
  State<RealityShiftPuzzleScreen> createState() =>
      _RealityShiftPuzzleScreenState();
}

class _RealityShiftPuzzleScreenState extends State<RealityShiftPuzzleScreen> {
  static const int _n = 5;
  late List<int> _tiles;
  late List<int> _mirrorAngles;
  int _moves = 0;
  int _polarity = 1;
  int _lightPosition = 0;
  int _mazePhase = 0;
  bool _done = false;
  String _status = 'Solve the puzzle to open the exit.';

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _tiles = List<int>.filled(_n * _n, 0);
    _mirrorAngles = List<int>.filled(4, 0);
    _moves = 0;
    _polarity = 1;
    _lightPosition = 0;
    _mazePhase = 0;
    _done = false;
    _status = _initialStatus;
    _configureBoard();
  }

  String get _initialStatus => switch (widget.config.mechanic) {
    ShiftMechanic.light => 'Rotate mirrors to guide light to both crystals.',
    ShiftMechanic.magnet =>
      'Switch polarity, then move the blocks onto both plates.',
    ShiftMechanic.shadow =>
      'Move the light until the shadow touches the switch.',
    ShiftMechanic.maze => 'Find the gate. The maze changes after every move.',
  };

  void _configureBoard() {
    // Tile codes: 0 floor, 1 wall, 2 objective, 3 player/block, 4 exit, 5 mirror.
    if (widget.config.mechanic == ShiftMechanic.light) {
      _tiles[2 * _n + 1] = 5;
      _tiles[1 * _n + 3] = 5;
      _tiles[3 * _n + 3] = 5;
      _tiles[1 * _n + 4] = 2;
      _tiles[3 * _n + 4] = 2;
      _tiles[4 * _n + 4] = 4;
    } else if (widget.config.mechanic == ShiftMechanic.magnet) {
      _tiles[1 * _n + 1] = 3;
      _tiles[3 * _n + 1] = 3;
      _tiles[1 * _n + 3] = 2;
      _tiles[3 * _n + 3] = 2;
      _tiles[0 * _n + 4] = 4;
    } else if (widget.config.mechanic == ShiftMechanic.shadow) {
      _tiles[2 * _n + 2] = 2;
      _tiles[4 * _n + 4] = 4;
    } else {
      for (final p in <int>[1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23]) {
        _tiles[p] = 1;
      }
      // Clear a deterministic winding path.
      for (final p in <int>[0, 5, 10, 11, 12, 7, 2, 3, 4, 9, 14, 19, 24]) {
        _tiles[p] = 0;
      }
      _tiles[0] = 3;
      _tiles[24] = 4;
    }
  }

  bool get _objectiveReached {
    switch (widget.config.mechanic) {
      case ShiftMechanic.light:
        return _mirrorAngles[0] == 1 &&
            _mirrorAngles[1] == 2 &&
            _mirrorAngles[2] == 3;
      case ShiftMechanic.magnet:
        return _polarity == -1 && _moves >= 3;
      case ShiftMechanic.shadow:
        return _lightPosition == 2;
      case ShiftMechanic.maze:
        return _mazePhase >= 4 && _moves >= 6;
    }
  }

  void _tapCell(int index) {
    if (_done) return;
    setState(() {
      _moves++;
      switch (widget.config.mechanic) {
        case ShiftMechanic.light:
          final mirrorPositions = <int>[11, 8, 18];
          final i = mirrorPositions.indexOf(index);
          if (i >= 0) {
            _mirrorAngles[i] = (_mirrorAngles[i] + 1) % 4;
            _status = 'Mirror ${i + 1} rotated. Check the beam direction.';
          } else {
            _status = 'Tap one of the three mirrors to redirect the beam.';
          }
          break;
        case ShiftMechanic.magnet:
          if (index == 0 || index == 10 || index == 20) {
            _polarity *= -1;
            _status = _polarity == 1
                ? 'Positive polarity: blocks attract.'
                : 'Negative polarity: blocks repel.';
          } else if (_tiles[index] == 3) {
            final target = index + (_polarity == 1 ? 1 : 2);
            if (target < _tiles.length && _tiles[target] != 1) {
              _tiles[target] = 3;
              _tiles[index] = 0;
              _status = 'Block moved by the magnetic field.';
            } else {
              _status = 'Blocked. Change polarity or choose another block.';
            }
          } else {
            _status =
                'Tap a block to move it, or tap the left column to change polarity.';
          }
          break;
        case ShiftMechanic.shadow:
          _lightPosition = (_lightPosition + 1) % 3;
          _status = switch (_lightPosition) {
            0 => 'Light moved left. Watch where the shadow falls.',
            1 => 'Light moved to the centre. Check the switch.',
            _ => 'Light aligned! The shadow switch is active.',
          };
          break;
        case ShiftMechanic.maze:
          _mazePhase++;
          _status =
              'The maze shifted to phase ${_mazePhase % 3 + 1}. Find the safe route.';
          if (_tiles[index] == 1) {
            _status =
                'That passage is blocked in this phase. Try another tile.';
          }
          break;
      }
      if (_objectiveReached) {
        _done = true;
        _status = 'Puzzle solved! The exit is open.';
      }
    });
    if (_done) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onLevelCompleted?.call(widget.config.level);
        _showWin();
      });
    }
  }

  Future<void> _showWin() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111A30),
        title: const Text(
          'LEVEL COMPLETE',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Text(
          '${widget.config.title} complete in $_moves moves.',
          style: const TextStyle(color: Color(0xFFDCE8FF)),
        ),
        actions: [
          FilledButton(
            onPressed: () async {
              await AdsService.instance.showInterstitialAtTransition();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('CONTINUE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B18),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            widget.config.background,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF111B3A),
                    Color(0xFF070B18),
                    Color(0xFF27173C),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Container(color: const Color(0xCC050817)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  child: Row(
                    children: [
                      _button(
                        Icons.arrow_back_rounded,
                        () => Navigator.maybePop(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LEVEL ${widget.config.level}',
                              style: const TextStyle(
                                color: Color(0xFFFFD166),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              widget.config.title.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _button(Icons.refresh_rounded, () => setState(_reset)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _status,
                      style: const TextStyle(
                        color: Color(0xFFDCE8FF),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _n * _n,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _n,
                                crossAxisSpacing: 5,
                                mainAxisSpacing: 5,
                              ),
                          itemBuilder: (context, index) => _buildTile(index),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: CampaignMonetizationControls(
                    level: widget.config.level,
                    onHint: () => _showHintFromReward(),
                    onSkipped: () => Navigator.maybePop(context),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xE611172A),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x6677CFFF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.touch_app_rounded,
                        color: Color(0xFF75DFFF),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.config.subtitle,
                          style: const TextStyle(
                            color: Color(0xFFE3E9F8),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                      Text(
                        'MOVES $_moves',
                        style: const TextStyle(
                          color: Color(0xFFFFD166),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHintFromReward() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111A30),
        title: const Text(
          'A hint from the archive',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          widget.config.hint,
          style: const TextStyle(
            color: Color(0xFFDCE8FF),
            fontSize: 16,
            height: 1.4,
          ),
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

  Widget _buildTile(int index) {
    final code = _tiles[index];
    final isWall = code == 1;
    final isObjective = code == 2;
    final isBlock = code == 3;
    final isExit = code == 4;
    final isMirror = code == 5;
    final bg = isWall ? const Color(0xFF10162B) : const Color(0xB91C2946);
    IconData? icon;
    Color color = const Color(0xFF536989);
    if (isWall) {
      icon = Icons.square_rounded;
      color = const Color(0xFF28344D);
    }
    if (isObjective) {
      icon = Icons.diamond_rounded;
      color = const Color(0xFF6DE5FF);
    }
    if (isBlock) {
      icon = Icons.view_in_ar_rounded;
      color = _polarity == 1
          ? const Color(0xFFFF5367)
          : const Color(0xFF5BBFFF);
    }
    if (isExit) {
      icon = Icons.door_front_door_rounded;
      color = _done ? const Color(0xFF71F0C1) : const Color(0xFFFFC15D);
    }
    if (isMirror) {
      icon = Icons.change_history_rounded;
      final mirrorPositions = <int>[11, 8, 18];
      final i = mirrorPositions.indexOf(index);
      color = const Color(0xFFFFD166);
      if (i >= 0 && widget.config.mechanic == ShiftMechanic.light) {
        return InkWell(
          onTap: () => _tapCell(index),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF263552),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFD166), width: 1.6),
            ),
            child: Transform.rotate(
              angle: (_mirrorAngles[i] * math.pi / 2),
              child: const Icon(
                Icons.remove_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
        );
      }
    }
    if (widget.config.mechanic == ShiftMechanic.shadow && index == 12) {
      icon = Icons.wb_shade_rounded;
      color = _lightPosition == 2
          ? const Color(0xFFBD8CFF)
          : const Color(0xFF687A9B);
    }
    if (widget.config.mechanic == ShiftMechanic.shadow &&
        index == _lightPosition * 5) {
      icon = Icons.light_mode_rounded;
      color = const Color(0xFFFFD166);
    }
    return InkWell(
      onTap: () => _tapCell(index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isExit && _done
                ? const Color(0xFF71F0C1)
                : const Color(0x335E7AA9),
          ),
        ),
        child: Center(
          child: icon == null
              ? const SizedBox.shrink()
              : Icon(icon, color: color, size: isExit ? 27 : 24),
        ),
      ),
    );
  }

  Widget _button(IconData icon, VoidCallback onTap) => Material(
    color: const Color(0xCC151D35),
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 42,
        height: 42,
        child: Icon(icon, color: Colors.white, size: 21),
      ),
    ),
  );
}
