import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/menu_music_service.dart';

import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin, MenuMusicRoute<SplashScreen> {
  late final AnimationController _sceneController;
  late final AnimationController _brandController;
  late final Animation<double> _sceneScale;
  late final Animation<double> _brandGlow;

  @override
  void initState() {
    super.initState();

    _sceneController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
    _sceneScale = Tween<double>(begin: 1, end: 1.045).animate(
      CurvedAnimation(parent: _sceneController, curve: Curves.easeInOut),
    );

    _brandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _brandGlow = Tween<double>(begin: .72, end: 1).animate(
      CurvedAnimation(parent: _brandController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(seconds: 4), () async {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, _, _) => const HomeScreen(),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _sceneController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff050817),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _sceneScale,
            builder: (context, child) =>
                Transform.scale(scale: _sceneScale.value, child: child),
            child: Image.asset(
              'assets/images/splash_reality_hero.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, .19, .48, .76, 1],
                colors: [
                  Color(0xb8050817),
                  Color(0x26050817),
                  Color(0x00050817),
                  Color(0x12050817),
                  Color(0xe8050817),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                AnimatedBuilder(
                  animation: _brandGlow,
                  builder: (context, child) =>
                      Opacity(opacity: _brandGlow.value, child: child),
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xfff1f6ff),
                            Color(0xffb7d9ff),
                            Color(0xffe2c6ff),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'REALITY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 31,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 8,
                            height: 1,
                            shadows: [
                              Shadow(color: Color(0x997a8bff), blurRadius: 24),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'S H I F T',
                        style: TextStyle(
                          color: Color(0xff9cecff),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3.5,
                          shadows: [
                            Shadow(color: Color(0xff36cfff), blurRadius: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 202),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(34, 0, 34, 22),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(seconds: 4),
                    curve: Curves.easeInOutCubic,
                    builder: (context, progress, _) => Column(
                      children: [
                        Text(
                          progress < .34
                              ? 'Bending the stars into place'
                              : progress < .72
                              ? 'Opening another reality'
                              : 'Almost there',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xffd9e4ff),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.15,
                          ),
                        ),
                        const SizedBox(height: 15),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            height: 5,
                            color: Colors.white.withValues(alpha: .15),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: progress,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xff43dcff),
                                      Color(0xff8a72ff),
                                      Color(0xffe19cff),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xff71caff,
                                      ).withValues(alpha: .55),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${(progress * 100).round()}%',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .7),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
