import '../models/level.dart';
import 'level_catalog.dart';

final List<Level> chapter1 = List.generate(
  20,
  (index) => Level(
    id: index + 1,
    title: levelStories[index].title,
    unlocked: false,
    stars: 0,
  ),
);
