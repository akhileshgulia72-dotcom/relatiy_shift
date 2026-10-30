/// The two quantum phases used by Level 6.
enum QuantumReality { blue, purple }

enum QuantumMoveResult { moved, boxAhead, unsupported, edge }

enum QuantumJumpResult { climbed, clearedBox, enteredPortal, blocked }

/// Deterministic tile rules for the Quantum Boxes puzzle.
///
/// The rendered scene is free to animate between cells, while collision and
/// completion checks stay on this small, predictable board.
class QuantumPuzzleState {
  QuantumReality reality = QuantumReality.blue;
  int playerColumn = 1;
  int playerHeight = 0;
  int facing = 1;
  int blueBoxColumn = 4;
  int purpleBoxColumn = 4;
  bool staircaseStable = false;
  bool completed = false;

  bool get puzzleSolved =>
      blueBoxColumn == 6 && purpleBoxColumn == 6 && staircaseStable;

  bool get blueBoxVisible => reality == QuantumReality.blue || staircaseStable;

  bool get purpleBoxVisible =>
      reality == QuantumReality.purple || staircaseStable;

  bool get activeBoxIsBlue => reality == QuantumReality.blue;

  bool get canPush =>
      playerHeight == 0 &&
      (activeBoxIsBlue
          ? blueBoxColumn == playerColumn + facing
          : purpleBoxColumn == playerColumn + facing);

  bool get safeToSwitch =>
      (playerHeight == 0 && playerColumn <= 5) ||
      (staircaseStable && playerColumn == 6 && playerHeight <= 2);

  QuantumMoveResult move(int direction) {
    if (completed || (direction != -1 && direction != 1)) {
      return QuantumMoveResult.edge;
    }
    facing = direction;
    if (playerHeight != 0) return QuantumMoveResult.unsupported;

    final next = playerColumn + direction;
    if (next < 0 || next > 5) return QuantumMoveResult.edge;
    final boxColumn = activeBoxIsBlue ? blueBoxColumn : purpleBoxColumn;
    if (next == boxColumn) return QuantumMoveResult.boxAhead;

    playerColumn = next;
    return QuantumMoveResult.moved;
  }

  bool push() {
    if (!canPush || completed) return false;
    final boxColumn = activeBoxIsBlue ? blueBoxColumn : purpleBoxColumn;
    final target = boxColumn + facing;
    // The floating ledge ends at column 6. Boxes cannot fall into the gap.
    if (target < 4 || target > 6) return false;

    if (activeBoxIsBlue) {
      if (target == purpleBoxColumn) return false;
      blueBoxColumn = target;
    } else {
      if (target == blueBoxColumn) {
        if (blueBoxColumn != 6) return false;
        purpleBoxColumn = target;
        staircaseStable = true;
      } else {
        purpleBoxColumn = target;
      }
    }
    playerColumn = boxColumn;
    return true;
  }

  bool switchReality() {
    if (completed || !safeToSwitch) return false;
    reality = reality == QuantumReality.blue
        ? QuantumReality.purple
        : QuantumReality.blue;
    return true;
  }

  QuantumJumpResult jump() {
    if (completed) return QuantumJumpResult.blocked;

    // Hop over an active box to get around it before pushing from the other
    // side. This is a one-cell hop and only lands on the shared safe walkway.
    if (playerHeight == 0) {
      final adjacent = playerColumn + facing;
      final landing = playerColumn + facing * 2;
      final activeBox = activeBoxIsBlue ? blueBoxColumn : purpleBoxColumn;
      if (adjacent == activeBox && landing >= 0 && landing <= 5) {
        playerColumn = landing;
        return QuantumJumpResult.clearedBox;
      }
      if (playerColumn == 5 && blueBoxColumn == 6 && staircaseStable) {
        playerColumn = 6;
        playerHeight = 1;
        return QuantumJumpResult.climbed;
      }
    }

    if (playerColumn == 6 &&
        playerHeight == 1 &&
        puzzleSolved &&
        purpleBoxColumn == 6) {
      playerHeight = 2;
      return QuantumJumpResult.climbed;
    }

    if (playerColumn == 6 && playerHeight == 2 && puzzleSolved) {
      playerColumn = 8;
      completed = true;
      return QuantumJumpResult.enteredPortal;
    }

    return QuantumJumpResult.blocked;
  }
}
