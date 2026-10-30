import 'package:flutter/material.dart';

class LevelStory {
  const LevelStory({
    required this.title,
    required this.chapter,
    required this.chapterTitle,
    required this.teaser,
    required this.icon,
    required this.accent,
  });

  final String title;
  final int chapter;
  final String chapterTitle;
  final String teaser;
  final IconData icon;
  final Color accent;
}

const levelStories = <LevelStory>[
  LevelStory(
    title: 'The Broken Moon',
    chapter: 1,
    chapterTitle: 'THE FIRST FRACTURE',
    teaser: 'A crack in the sky. A moon that no longer fits.',
    icon: Icons.dark_mode_rounded,
    accent: Color(0xFF73E5FF),
  ),
  LevelStory(
    title: 'The Lost Star',
    chapter: 1,
    chapterTitle: 'THE FIRST FRACTURE',
    teaser: 'One light is real. The rest remember it.',
    icon: Icons.star_rounded,
    accent: Color(0xFFFFD16B),
  ),
  LevelStory(
    title: 'Shadow Constellation',
    chapter: 1,
    chapterTitle: 'THE FIRST FRACTURE',
    teaser: 'The stars vanish. Your memory becomes the map.',
    icon: Icons.auto_awesome_rounded,
    accent: Color(0xFFB69AFF),
  ),
  LevelStory(
    title: 'The Moon’s Missing Memory',
    chapter: 1,
    chapterTitle: 'THE FIRST FRACTURE',
    teaser: 'Move the old chart. Return the missing fragment.',
    icon: Icons.nightlight_round,
    accent: Color(0xFFFFB779),
  ),
  LevelStory(
    title: 'The Missing Gravity',
    chapter: 1,
    chapterTitle: 'THE FIRST FRACTURE',
    teaser: 'Free the astronaut. Teach the sky which way is down.',
    icon: Icons.public_rounded,
    accent: Color(0xFF67E8D1),
  ),
  LevelStory(
    title: 'Quantum Boxes',
    chapter: 2,
    chapterTitle: 'ECHOES OF THE ORIGIN',
    teaser: 'Shift realities. Stack the quantum boxes. Reach the portal.',
    icon: Icons.all_inclusive_rounded,
    accent: Color(0xFFD28CFF),
  ),
  LevelStory(
    title: 'The Shadow Thief',
    chapter: 2,
    chapterTitle: 'ECHOES OF THE ORIGIN',
    teaser: 'Move the light. Keep the relic still. Follow its shadow.',
    icon: Icons.swap_vert_rounded,
    accent: Color(0xFFB8A0FF),
  ),
  LevelStory(
    title: 'The Gravity Thief',
    chapter: 2,
    chapterTitle: 'ECHOES OF THE ORIGIN',
    teaser: 'Rotate gravity to guide the sphere around the impossible wall.',
    icon: Icons.star_border_rounded,
    accent: Color(0xFFFFD87A),
  ),
  LevelStory(
    title: 'The Disappearing Bridge',
    chapter: 2,
    chapterTitle: 'ECHOES OF THE ORIGIN',
    teaser: 'Race across a bridge that vanishes beneath your feet.',
    icon: Icons.route_rounded,
    accent: Color(0xFF73E5FF),
  ),
  LevelStory(
    title: 'The Broken Moon Finale',
    chapter: 2,
    chapterTitle: 'ECHOES OF THE ORIGIN',
    teaser: 'Resize the portal. Turn the bridge. Rewrite the moon’s path.',
    icon: Icons.flip_rounded,
    accent: Color(0xFFC4A4FF),
  ),
  LevelStory(
    title: 'Parallel Worlds',
    chapter: 3,
    chapterTitle: 'THE DROWNED CONSTELLATION',
    teaser:
        'Shift between blue and violet worlds to cross the disappearing path.',
    icon: Icons.compare_arrows_rounded,
    accent: Color(0xFF72DFFF),
  ),
  LevelStory(
    title: 'Time Freeze',
    chapter: 3,
    chapterTitle: 'THE DROWNED CONSTELLATION',
    teaser: 'Freeze moving lasers and energy barriers to cross the void.',
    icon: Icons.ac_unit_rounded,
    accent: Color(0xFF91E9FF),
  ),
  LevelStory(
    title: 'The Shattered Mirror',
    chapter: 3,
    chapterTitle: 'THE DROWNED CONSTELLATION',
    teaser:
        'Rotate six mirror fragments to charge the receivers and open the sky bridge.',
    icon: Icons.diamond_rounded,
    accent: Color(0xFFFFC85A),
  ),
  LevelStory(
    title: 'Portal Architect',
    chapter: 3,
    chapterTitle: 'THE DROWNED CONSTELLATION',
    teaser:
        'Reposition the portals across floating stone isles to trigger all three switches and breach the ancient gateway.',
    icon: Icons.door_sliding_rounded,
    accent: Color(0xFF70E5FF),
  ),
  LevelStory(
    title: 'The Liar’s Portal',
    chapter: 3,
    chapterTitle: 'THE DROWNED CONSTELLATION',
    teaser: 'The brightest door is telling the oldest lie.',
    icon: Icons.blur_circular_rounded,
    accent: Color(0xFFFF8EAB),
  ),
  LevelStory(
    title: 'Dust Remembers',
    chapter: 4,
    chapterTitle: 'THE HEART OF REALITY',
    teaser: 'Trace the pattern that the universe tried to erase.',
    icon: Icons.grain_rounded,
    accent: Color(0xFFB8A0FF),
  ),
  LevelStory(
    title: 'The Clock Runs Backward',
    chapter: 4,
    chapterTitle: 'THE HEART OF REALITY',
    teaser: 'Undo the final second before the fracture.',
    icon: Icons.history_rounded,
    accent: Color(0xFF7DE7D9),
  ),
  LevelStory(
    title: 'Gravity Loom',
    chapter: 4,
    chapterTitle: 'THE HEART OF REALITY',
    teaser: 'Tilt gravity, shift the walls, and unlock the core.',
    icon: Icons.hub_rounded,
    accent: Color(0xFFFFD16B),
  ),
  LevelStory(
    title: 'The Quiet Before',
    chapter: 4,
    chapterTitle: 'THE HEART OF REALITY',
    teaser: 'Still the storm long enough to hear the answer.',
    icon: Icons.nights_stay_rounded,
    accent: Color(0xFF82DFFF),
  ),
  LevelStory(
    title: 'Shadow Walker',
    chapter: 4,
    chapterTitle: 'THE HEART OF REALITY',
    teaser: 'Block the light. Cross the shadows. Recover the final core.',
    icon: Icons.diamond_rounded,
    accent: Color(0xFFFF8FCE),
  ),
];

LevelStory storyForLevel(int level) => levelStories[level - 1];
