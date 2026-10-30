import 'package:flutter_test/flutter_test.dart';
import 'package:reality_shift/models/quantum_puzzle_state.dart';

void main() {
  group('QuantumPuzzleState', () {
    test(
      'inactive-reality boxes are intangible until the staircase is stable',
      () {
        final game = QuantumPuzzleState();
        expect(game.blueBoxVisible, isTrue);
        expect(game.purpleBoxVisible, isFalse);
        expect(game.switchReality(), isTrue);
        expect(game.blueBoxVisible, isFalse);
        expect(game.purpleBoxVisible, isTrue);
      },
    );

    test('a reality shift is refused on an unsafe, disappearing step', () {
      final game = QuantumPuzzleState();
      game.playerColumn = 6;
      expect(game.safeToSwitch, isFalse);
      expect(game.switchReality(), isFalse);
      expect(game.reality, QuantumReality.blue);
    });

    test(
      'boxes cannot leave their ledge and only stack in the right order',
      () {
        final game = QuantumPuzzleState();
        game.playerColumn = 5;
        game.reality = QuantumReality.purple;
        game.facing = -1;
        expect(game.push(), isFalse); // the purple box cannot leave the ledge
        expect(game.purpleBoxColumn, 4);

        game.reality = QuantumReality.blue;
        game.playerColumn = 3;
        game.facing = 1;
        expect(game.push(), isTrue);
        expect(game.blueBoxColumn, 5);
        expect(game.push(), isTrue);
        expect(game.blueBoxColumn, 6);
        expect(game.playerColumn, 5);

        game.reality = QuantumReality.purple;
        game.facing = -1;
        expect(game.jump(), QuantumJumpResult.clearedBox);
        expect(game.playerColumn, 3);
        game.facing = 1;
        expect(game.push(), isTrue);
        expect(game.push(), isTrue);
        expect(game.puzzleSolved, isTrue);
        expect(game.blueBoxVisible, isTrue);
        expect(game.purpleBoxVisible, isTrue);
      },
    );

    test('portal completion requires the full staircase and both jumps', () {
      final game = QuantumPuzzleState();
      expect(game.jump(), QuantumJumpResult.blocked);
      expect(game.completed, isFalse);

      game.blueBoxColumn = 6;
      game.purpleBoxColumn = 6;
      game.staircaseStable = true;
      game.playerColumn = 5;
      expect(game.jump(), QuantumJumpResult.climbed);
      expect(game.jump(), QuantumJumpResult.climbed);
      expect(game.jump(), QuantumJumpResult.enteredPortal);
      expect(game.completed, isTrue);
      expect(game.jump(), QuantumJumpResult.blocked);
    });
  });
}
