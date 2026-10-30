import 'package:flame/components.dart';
import 'package:flame/events.dart';

class MoonComponent extends SpriteComponent with DragCallbacks {
  MoonComponent({
    required Sprite sprite,
    required Vector2 position,
  }) : super(
          sprite: sprite,
          position: position,
          size: Vector2(110, 110),
          anchor: Anchor.center,
        );

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.localDelta;
  }
}