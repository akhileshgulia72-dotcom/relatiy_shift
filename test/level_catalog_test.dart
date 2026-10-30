import 'package:flutter_test/flutter_test.dart';
import 'package:reality_shift/data/level_catalog.dart';

void main() {
  test('the archive has twenty distinct level stories in four chapters', () {
    expect(levelStories, hasLength(20));
    expect(levelStories.map((story) => story.title).toSet(), hasLength(20));

    for (var chapter = 1; chapter <= 4; chapter++) {
      final entries = levelStories.where((story) => story.chapter == chapter);
      expect(entries, hasLength(5));
      expect(entries.map((story) => story.chapterTitle).toSet(), hasLength(1));
    }
  });
}
