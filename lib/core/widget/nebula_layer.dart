import 'package:flutter/material.dart';

class NebulaLayer extends StatefulWidget {
  final String image;
  final double opacity;
  final int duration;

  const NebulaLayer({
    super.key,
    required this.image,
    required this.opacity,
    required this.duration,
  });

  @override
  State<NebulaLayer> createState() => _NebulaLayerState();
}

class _NebulaLayerState extends State<NebulaLayer>
    with SingleTickerProviderStateMixin {

  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.duration),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) {

        final dx = (controller.value - .5) * 30;

        return Transform.translate(
          offset: Offset(dx, 0),
          child: Opacity(
            opacity: widget.opacity,
            child: child,
          ),
        );
      },

      child: Image.asset(
        widget.image,
        fit: BoxFit.cover,
      ),
    );
  }
}