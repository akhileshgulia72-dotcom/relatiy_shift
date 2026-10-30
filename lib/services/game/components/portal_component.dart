import 'package:flame/components.dart';
import 'dart:math' as math;

class PortalComponent extends SpriteComponent {
  PortalComponent({
    required Sprite sprite,
    required Vector2 position,
  }) : super(
          sprite: sprite,
          position: position,
          size: Vector2(120, 120),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);

    angle += dt * 0.5;

    final scaleValue = 1 + 0.05 * math.sin(timer);

    scale = Vector2.all(scaleValue);

    timer += dt * 3;
  }

  double timer = 0;
}