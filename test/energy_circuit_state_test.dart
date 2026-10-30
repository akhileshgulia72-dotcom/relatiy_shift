import 'package:flutter_test/flutter_test.dart';
import 'package:reality_shift/models/energy_circuit_state.dart';

void main() {
  test(
    'six rotations connect the ordered channels and reset restores budget',
    () {
      final game = EnergyCircuitState();
      expect(game.ready, false);
      expect(game.confirm(), contains('Connect'));
      for (final row in EnergyCircuitState.rows) {
        game.rotate(row * 5 + 1);
        game.rotate(row * 5 + 3);
        expect(
          game.powered.contains(EnergyCircuitState.targets[game.receiver]),
          true,
        );
        if (game.overload) {
          expect(game.ready, false);
          game.discharge();
        }
        expect(game.ready, true);
        game.confirm();
      }
      expect(game.complete, true);
      expect(game.rotationsLeft, 0);
      game.reset();
      expect(game.receiver, 0);
      expect(game.rotationsLeft, 6);
      expect(game.ready, false);
    },
  );
  test('invalid rotations do not consume budget', () {
    final game = EnergyCircuitState();
    game.rotate(6);
    game.rotate(11);
    expect(game.rotationsLeft, 6);
    game.rotate(1);
    expect(game.rotationsLeft, 5);
  });
}
