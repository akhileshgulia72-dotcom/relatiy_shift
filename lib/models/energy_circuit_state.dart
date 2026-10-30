/// A deterministic five-column circuit. Port matching, rather than artwork,
/// decides which tiles carry energy.
enum CircuitShape { blocked, straight, corner, tee, cross }

class CircuitTile {
  CircuitTile(this.shape, this.rotation, {this.rotatable = false});
  final CircuitShape shape;
  int rotation;
  final bool rotatable;
  int get ports {
    final base = switch (shape) {
      CircuitShape.blocked => 0,
      CircuitShape.straight => 5,
      CircuitShape.corner => 3,
      CircuitShape.tee => 7,
      CircuitShape.cross => 15,
    };
    var value = base;
    for (var i = 0; i < rotation; i++) {
      value = ((value << 1) | (value >> 3)) & 15;
    }
    return value;
  }
}

class EnergyCircuitState {
  EnergyCircuitState() {
    reset();
  }
  late List<CircuitTile> tiles;
  int receiver = 0;
  int rotationsLeft = 6;
  bool overload = false;
  final Set<int> powered = {};
  static const rows = [0, 2, 4];
  static const sources = [0, 10, 20];
  static const targets = [4, 14, 24];
  static const hazard = 17;
  void reset() {
    tiles = List.generate(25, (i) => CircuitTile(CircuitShape.blocked, 0));
    for (final row in rows) {
      final start = row * 5;
      tiles[start] = CircuitTile(CircuitShape.straight, 1);
      tiles[start + 1] = CircuitTile(CircuitShape.straight, 0, rotatable: true);
      tiles[start + 2] = CircuitTile(CircuitShape.cross, 0);
      tiles[start + 3] = CircuitTile(CircuitShape.straight, 0, rotatable: true);
      tiles[start + 4] = CircuitTile(CircuitShape.straight, 1);
    }
    tiles[5] = CircuitTile(CircuitShape.corner, 0);
    tiles[7] = CircuitTile(CircuitShape.tee, 0);
    tiles[9] = CircuitTile(CircuitShape.corner, 2);
    tiles[17] = CircuitTile(CircuitShape.tee, 0);
    receiver = 0;
    rotationsLeft = 6;
    overload = false;
    powered.clear();
    trace();
  }

  bool get complete => receiver == 3;
  Set<int> trace() {
    powered.clear();
    if (complete) return powered;
    final queue = <int>[sources[receiver]];
    const offsets = [-5, 1, 5, -1];
    while (queue.isNotEmpty) {
      final cell = queue.removeAt(0);
      if (!powered.add(cell)) continue;
      final ports = tiles[cell].ports;
      for (var direction = 0; direction < 4; direction++) {
        if ((ports & (1 << direction)) == 0) continue;
        final neighbor = cell + offsets[direction];
        if (neighbor < 0 || neighbor >= 25) continue;
        if (direction == 1 && cell % 5 == 4 || direction == 3 && cell % 5 == 0)
          continue;
        if ((tiles[neighbor].ports & (1 << ((direction + 2) % 4))) != 0)
          queue.add(neighbor);
      }
    }
    overload = powered.contains(hazard) && receiver == 1;
    return powered;
  }

  String rotate(int cell) {
    if (complete) return 'The reactor is already stable.';
    if (cell < 0 || cell >= 25 || !tiles[cell].rotatable)
      return 'This junction is fixed. Rotate an unlit straight tile.';
    if (cell ~/ 5 != rows[receiver])
      return 'Route the active colour before adjusting the next channel.';
    if (rotationsLeft == 0)
      return 'Rotation budget exhausted. Restart to try a new route.';
    tiles[cell].rotation = (tiles[cell].rotation + 1) % 4;
    rotationsLeft--;
    trace();
    if (overload)
      return 'Overload! The false branch energized a red hazard. It will discharge.';
    return powered.contains(targets[receiver])
        ? 'Receiver charged! Confirm this channel to continue.'
        : 'Energy rerouted. Check every connected port.';
  }

  bool get ready =>
      !complete && powered.contains(targets[receiver]) && !overload;
  String confirm() {
    if (!ready)
      return overload
          ? 'Electrical overload. Wait for discharge.'
          : 'Connect the active source to its receiver first.';
    receiver++;
    if (complete) {
      powered.clear();
      return 'All receivers charged in order. Stabilize the reactor!';
    }
    trace();
    return 'Receiver locked. The next energy channel is now active.';
  }

  void discharge() {
    overload = false;
  }
}
