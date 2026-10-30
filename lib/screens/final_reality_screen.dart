import 'package:flutter/material.dart';
import '../core/widget/campaign_monetization_controls.dart';
import '../services/level_progress_service.dart';
import '../services/ads_service.dart';
import 'level/level_screen.dart';

/// Reversible, deterministic spatial puzzles. Every starting board is produced
/// from the goal by legal moves, so every mission has a valid solution.
class FinalRealityScreen extends StatefulWidget {
  const FinalRealityScreen({super.key, required this.level, this.onComplete});
  final int level;
  final VoidCallback? onComplete;
  @override
  State<FinalRealityScreen> createState() => _FinalRealityScreenState();
}

class _FinalRealityScreenState extends State<FinalRealityScreen> {
  static const cyan = Color(0xFF66E9FF);
  final List<int> _history = [];
  late List<int> _board;
  int _initialDepth = 0;
  int _phase = 0;
  int _moves = 0;
  bool _done = false;
  bool _saving = false;
  bool _leaving = false;
  String _message = 'Study the target. Every move changes several cells.';
  int get n => widget.level == 20 ? 5 : 4;
  List<int> get goal => List.generate(
    n * n,
    (i) => widget.level == 18 ? i ~/ n : ((i ~/ n + i % n) % 2),
  );
  String get title => switch (widget.level) {
    17 => 'PARADOX CIRCUIT',
    18 => 'MAGNETIC ORBITS',
    19 => 'SHADOW ENTANGLEMENT',
    _ => 'THE LAST REALITY',
  };
  String get rule => switch (widget.level) {
    17 =>
      'Tap a cell to invert it and its four neighbours. Rebuild the checkerboard target.',
    18 =>
      'Tap a cell to slide its entire row right. SHIFT changes control to columns: tap to slide down. Restore the coloured rows.',
    19 =>
      'Tap a cell to invert both diagonals through it. Overlapping cells change only once. Rebuild the target.',
    _ =>
      'Each move switches reality. CYAN inverts a cross; VIOLET inverts diagonals. Restore the target across both realities.',
  };
  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _board = goal;
    _phase = 0;
    _moves = 0;
    _done = false;
    _history.clear();
    // Fixed varied sequences, rather than random boards with unknown solvability.
    final seed = switch (widget.level) {
      17 => [0, 6, 13, 3, 8, 10, 15],
      18 => [1, 18, 5, 23, 9, 16, 13, 26, 2, 21],
      19 => [0, 2, 5, 7, 8, 11, 14],
      _ => [0, 7, 19, 11, 3, 24, 16, 8, 21, 13, 5, 17],
    };
    for (final move in seed) {
      _apply(move);
      _history.add(move);
    }
    _initialDepth = _history.length;
    _message = 'Study the target. Undo your moves freely.';
  }

  void _apply(int encoded, {bool reverse = false}) {
    final cell = encoded % (n * n);
    final row = cell ~/ n, col = cell % n;
    if (widget.level == 18) {
      final vertical = encoded >= n * n;
      final indices = List.generate(
        n,
        (i) => vertical ? i * n + col : row * n + i,
      );
      final values = indices.map((i) => _board[i]).toList();
      for (var i = 0; i < n; i++) {
        _board[indices[i]] = values[(i + (reverse ? 1 : n - 1)) % n];
      }
      return;
    }
    if (reverse && widget.level == 20) _phase = 1 - _phase;
    final diagonals = widget.level == 19 || (widget.level == 20 && _phase == 1);
    for (var i = 0; i < n * n; i++) {
      final dr = (i ~/ n - row).abs(), dc = (i % n - col).abs();
      if (diagonals ? dr == dc : dr + dc <= 1) _board[i] = 1 - _board[i];
    }
    if (!reverse && widget.level == 20) _phase = 1 - _phase;
  }

  Future<void> _tap(int cell) async {
    if (_done || _saving) return;
    setState(() {
      final move = cell + (widget.level == 18 && _phase == 1 ? n * n : 0);
      _apply(move);
      _history.add(move);
      _moves++;
      _message =
          'Compare the pattern with the target. Undo can recover any move.';
    });
    if (List.generate(n * n, (i) => _board[i] == goal[i]).every((v) => v)) {
      setState(() {
        _done = true;
        _saving = true;
      });
      try {
        await LevelProgressService.complete(
          level: widget.level,
          stars: _moves <= 20
              ? 3
              : _moves <= 40
              ? 2
              : 1,
        );
        widget.onComplete?.call();
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  void _undo({bool rewarded = false}) {
    if (_history.isEmpty ||
        _done ||
        (!rewarded && _history.length <= _initialDepth))
      return;
    setState(() {
      _apply(_history.removeLast(), reverse: true);
      _moves++;
      if (rewarded && _history.length < _initialDepth)
        _initialDepth = _history.length;
      _message = 'One change reversed. Continue rebuilding the target.';
    });
    // Undo may restore the goal; use the same completion path without a move.
    if (_board.asMap().entries.every((e) => e.value == goal[e.key]))
      _finishUndo();
  }

  Future<void> _finishUndo() async {
    setState(() {
      _done = true;
      _saving = true;
    });
    try {
      await LevelProgressService.complete(level: widget.level, stars: 1);
      widget.onComplete?.call();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _hint() {
    final move = _history.isEmpty ? 0 : _history.last;
    final cell = move % (n * n);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('A path through the fracture'),
        content: Text(
          widget.level == 18
              ? 'Reverse the most recent displacement: select ${move >= n * n ? "COLUMNS" : "ROWS"}, then tap row ${cell ~/ n + 1}, column ${cell % n + 1} three times. This brings the board closer along a guaranteed solution path. Apply the guided reversal below to perform it immediately.'
              : 'Reverse the latest change to return toward a guaranteed solution. The affected anchor is row ${cell ~/ n + 1}, column ${cell % n + 1}. ${widget.level == 20 ? "The guided reversal also restores the previous reality." : "Tapping that anchor again reverses its pattern."}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _undo(rewarded: true);
            },
            child: const Text('APPLY GUIDED REVERSAL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }

  Future<void> _next({bool skipped = false}) async {
    if (_leaving || _saving) return;
    _leaving = true;
    if (!skipped) await AdsService.instance.showInterstitialAtTransition();
    if (!mounted) return;
    final next = campaignPageForLevel(widget.level + 1);
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => next ?? const LevelScreen()),
    );
  }

  Color _color(int value) => widget.level == 18
      ? const [
          Color(0xFF66E9FF),
          Color(0xFFFFBD69),
          Color(0xFFD19AFF),
          Color(0xFF69ECC0),
        ][value]
      : value == 1
      ? cyan
      : const Color(0xFF23304E);
  Widget _grid(List<int> cells, {required bool target}) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: n * n,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: n,
      crossAxisSpacing: target ? 3 : 7,
      mainAxisSpacing: target ? 3 : 7,
    ),
    itemBuilder: (context, i) => Semantics(
      label: 'Row ${i ~/ n + 1}, column ${i % n + 1}, state ${cells[i]}',
      button: !target,
      child: InkWell(
        onTap: target || _done ? null : () => _tap(i),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: _color(cells[i]),
            borderRadius: BorderRadius.circular(target ? 3 : 10),
            border: Border.all(color: Colors.white24),
            boxShadow: target || cells[i] == 0
                ? []
                : [
                    BoxShadow(
                      color: _color(cells[i]).withValues(alpha: .25),
                      blurRadius: 12,
                    ),
                  ],
          ),
          child: target
              ? null
              : Center(
                  child: Text(
                    widget.level == 18
                        ? '${cells[i] + 1}'
                        : cells[i] == 1
                        ? '✦'
                        : '·',
                    style: const TextStyle(fontSize: 22, color: Colors.white),
                  ),
                ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF080D20),
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      title: Text(
        'REALITY ${widget.level}',
        style: const TextStyle(fontSize: 14, letterSpacing: 3),
      ),
      actions: [
        IconButton(
          tooltip: 'Restart puzzle',
          onPressed: _saving ? null : () => setState(_reset),
          icon: const Icon(Icons.restart_alt),
        ),
      ],
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, size) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: cyan,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    rule,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'TARGET',
                            style: TextStyle(
                              color: Colors.white70,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(width: 90, child: _grid(goal, target: true)),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '$_moves MOVES',
                            style: const TextStyle(
                              color: cyan,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.level == 18
                                ? (_phase == 0 ? 'ROWS →' : 'COLUMNS ↓')
                                : widget.level == 20
                                ? (_phase == 0
                                      ? 'CYAN CROSS'
                                      : 'VIOLET DIAGONALS')
                                : 'ALL MOVES REVERSIBLE',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _grid(_board, target: false),
                  const SizedBox(height: 16),
                  if (_done) ...[
                    const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFFFD166),
                      size: 48,
                    ),
                    const Text(
                      'REALITY RESTORED',
                      style: TextStyle(
                        color: cyan,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Congratulations. You untangled the fracture.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    FilledButton(
                      onPressed: _saving ? null : () => _next(),
                      child: Text(
                        _saving
                            ? 'SAVING…'
                            : widget.level == 20
                            ? 'RETURN TO LEVELS'
                            : 'NEXT REALITY',
                      ),
                    ),
                  ] else ...[
                    Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white60),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => _undo(),
                          icon: const Icon(Icons.undo),
                          label: const Text('UNDO'),
                        ),
                        if (widget.level == 18)
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => _phase = 1 - _phase),
                            icon: const Icon(Icons.swap_vert),
                            label: const Text('SHIFT AXIS'),
                          ),
                      ],
                    ),
                    CampaignMonetizationControls(
                      level: widget.level,
                      onHint: _hint,
                      onSkipped: () => _next(skipped: true),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
