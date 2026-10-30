/// Deterministic sliding puzzle. Gravity moves the probe until a wall or edge.
/// Reality shifts swap the phase barriers without moving the probe.
class GravityLoomState {
  static const permanentWalls = <int>{10, 21, 22, 23, 24};
  static const cyanWalls = <int>{5, 13, 15};
  static const violetWalls = <int>{1, 7, 14};
  static const switches = <int>[6, 18];
  static const coreCell = 12;
  static const exitCell = 4;
  int position = 20;
  int reality = 0;
  int switchesActive = 0;
  bool core = false;
  int moves = 0;
  bool get completed => position == exitCell && core;
  Set<int> get walls =>
      permanentWalls.union(reality == 0 ? cyanWalls : violetWalls);
  bool isWall(int cell) => walls.contains(cell);
  bool get coreAvailable => switchesActive == 3;
  String shift() {
    final targetWalls = permanentWalls.union(
      reality == 0 ? violetWalls : cyanWalls,
    );
    if (targetWalls.contains(position)) {
      return 'Reality is anchored here. Slide clear of the shifting barrier.';
    }
    reality = 1 - reality;
    moves++;
    return 'Reality shifted. The wall pattern has changed.';
  }

  String tilt(int direction) {
    final delta = switch (direction) {
      0 => (-1, 0),
      1 => (0, 1),
      2 => (1, 0),
      _ => (0, -1),
    };
    var row = position ~/ 5, col = position % 5;
    while (true) {
      final nextRow = row + delta.$1, nextCol = col + delta.$2;
      if (nextRow < 0 ||
          nextRow >= 5 ||
          nextCol < 0 ||
          nextCol >= 5 ||
          walls.contains(nextRow * 5 + nextCol)) {
        break;
      }
      row = nextRow;
      col = nextCol;
    }
    final next = row * 5 + col;
    if (next == position) return 'Blocked. Shift reality or tilt another way.';
    position = next;
    moves++;
    for (var i = 0; i < switches.length; i++) {
      if (position == switches[i]) switchesActive |= 1 << i;
    }
    if (position == coreCell && coreAvailable) core = true;
    if (completed) return 'The loom is aligned. The exit is open!';
    if (position == coreCell && !coreAvailable)
      return 'The core is sealed. Activate both switches first.';
    if (position == coreCell && core)
      return 'Core collected. Reach the upper exit.';
    if (switches.contains(position))
      return 'Switch activated! The loom changed its signal.';
    return 'The probe slid to row ${row + 1}, column ${col + 1}.';
  }
}
