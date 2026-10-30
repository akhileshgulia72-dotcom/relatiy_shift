import 'package:flutter/material.dart';

class PuzzleObject {
  final String id;
  final String image;
  Offset position;
  final Offset startPosition;
  final Offset targetPosition;
  final double size;

  PuzzleObject({
    required this.id,
    required this.image,
    required this.position,
    required this.startPosition,
    required this.targetPosition,
    required this.size,
  });
}