/// Logical side-view coordinates shared by rendering and collision.
class ShadowWalkerState {
  int player = 0;
  int reality = 0;
  int selected = 0;
  final angles = <int>[0, 0];
  bool core = false;
  int moves = 0;
  static const floor = <int>{0, 1, 2, 5, 6, 7, 10, 11, 12};
  static const lampX = <double>[1, 6];
  static const settings = <double>[.4, 1, 1.4, 2];
  double blockerX(int lamp) => lampX[lamp] + (lamp == reality ? 1 : 2);
  // A ray passes through a blocker halfway between lamp and walkway.
  bool intercepted(int lamp) =>
      (settings[angles[lamp]] - (blockerX(lamp) - lampX[lamp])).abs() < .1;
  double shadowCenter(int lamp) =>
      lampX[lamp] + 2 * (blockerX(lamp) - lampX[lamp]);
  bool supported(int cell) =>
      floor.contains(cell) ||
      List.generate(
        2,
        (lamp) => intercepted(lamp) && (cell - shadowCenter(lamp)).abs() <= 1,
      ).any((v) => v);
  bool get finished => player == 12 && core;
  String move(int direction) {
    final next = player + direction;
    if (next < 0 || next > 12) return 'The laboratory ends here.';
    if (!supported(player) || !supported(next))
      return 'Void ahead. Align a light with its blocker first.';
    player = next;
    moves++;
    if (player == 6) {
      core = true;
      return 'Energy core recovered. Reach the exit in the far sector.';
    }
    return finished
        ? 'Shadow Walker complete. Reality stabilized.'
        : 'Stable footing. Continue toward the portal.';
  }

  String tune(int direction) {
    if (!floor.contains(player))
      return 'Return to a metal island before changing the light.';
    angles[selected] = (angles[selected] + direction) % settings.length;
    return intercepted(selected)
        ? 'Beam blocked: a solid shadow platform has formed.'
        : 'Beam misses the blocker: shadow platform dissolved.';
  }

  String shift() {
    if (!floor.contains(player))
      return 'Reality shift requires a metal island.';
    reality = 1 - reality;
    return 'Reality shifted. Blockers moved; check both shadow bridges.';
  }
}
