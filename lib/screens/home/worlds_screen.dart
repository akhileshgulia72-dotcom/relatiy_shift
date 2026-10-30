import 'package:flutter/material.dart';
import '../level/level_screen.dart';

class WorldsScreen extends StatelessWidget {
  const WorldsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF070B19),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0B1225),
      title: const Text(
        'WORLDS',
        style: TextStyle(letterSpacing: 2, fontSize: 17),
      ),
    ),
    body: DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/starfield_purple_sky.png'),
          fit: BoxFit.cover,
          opacity: .42,
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 32),
          children: [
            const Text(
              'YOUR WORLDS',
              style: TextStyle(
                color: Color(0xFF81E8FF),
                fontSize: 11,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Every reality begins with wonder.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            Material(
              color: const Color(0xEE111C35),
              borderRadius: BorderRadius.circular(26),
              child: InkWell(
                borderRadius: BorderRadius.circular(26),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LevelScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xAA75DEFF)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x442E8DFF), blurRadius: 25),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          height: 205,
                          width: double.infinity,
                          child: Image.asset(
                            'assets/images/world_wonderverse.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'WORLD 01  •  OPEN NOW',
                        style: TextStyle(
                          color: Color(0xFF81E8FF),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'The Wonderverse',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'A universe of fractured moons, shifting paths, and twenty realities waiting to be restored.',
                        style: TextStyle(
                          color: Color(0xFFC4D0E6),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Row(
                        children: [
                          Text(
                            'ENTER WORLD',
                            style: TextStyle(
                              color: Color(0xFF81E8FF),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF81E8FF),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xDD25183F),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0x667E69BD)),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFFFD489),
                    size: 34,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'MORE WORLDS ARE COMING',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'A new world to fall in love with every week. Keep your curiosity close—our next adventure is on its way. ✨',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFD5C9ED), height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
