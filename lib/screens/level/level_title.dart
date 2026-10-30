import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LevelTile extends StatefulWidget {
  const LevelTile({
    super.key,
    required this.level,
    required this.title,
    required this.chapter,
    required this.accent,
    required this.icon,
    required this.unlocked,
    required this.isCurrent,
    required this.stars,
    required this.onTap,
    this.teaser,
  });

  final int level;
  final String title;
  final String chapter;
  final Color accent;
  final IconData icon;
  final bool unlocked;
  final bool isCurrent;
  final int stars;
  final VoidCallback onTap;
  final String? teaser;

  @override
  State<LevelTile> createState() => _LevelTileState();
}

class _LevelTileState extends State<LevelTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isCurrent) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant LevelTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isCurrent && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMastered = widget.unlocked && widget.stars >= 3;
    final isCleared = widget.unlocked && widget.stars > 0;

    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final pulseVal = widget.isCurrent ? _pulseAnimation.value : 1.0;

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                if (widget.isCurrent) ...[
                  BoxShadow(
                    color: widget.accent.withValues(alpha: 0.38 * pulseVal),
                    blurRadius: 24 * pulseVal,
                    spreadRadius: 1.5 * pulseVal,
                  ),
                  BoxShadow(
                    color: const Color(0xFF73E5FF).withValues(alpha: 0.18),
                    blurRadius: 32,
                  ),
                ] else if (isMastered) ...[
                  BoxShadow(
                    color: const Color(0xFFFFD15C).withValues(alpha: 0.22),
                    blurRadius: 18,
                    spreadRadius: 0.5,
                  ),
                ] else if (widget.unlocked) ...[
                  BoxShadow(
                    color: widget.accent.withValues(alpha: 0.12),
                    blurRadius: 14,
                  ),
                ],
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: (highlighted) {
                  setState(() => _isPressed = highlighted);
                },
                borderRadius: BorderRadius.circular(22),
                splashColor: widget.accent.withValues(alpha: 0.25),
                highlightColor: widget.accent.withValues(alpha: 0.12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.45, 1.0],
                      colors: widget.unlocked
                          ? [
                              widget.isCurrent
                                  ? Color.lerp(
                                      const Color(0xFF162544),
                                      widget.accent,
                                      0.16,
                                    )!
                                  : const Color(0xFF142038),
                              const Color(0xFF0D1629),
                              const Color(0xFF070B16),
                            ]
                          : [
                              const Color(0xCC0E1524),
                              const Color(0xCC090E1A),
                              const Color(0xDD050810),
                            ],
                    ),
                    border: Border.all(
                      color: widget.isCurrent
                          ? widget.accent.withValues(
                              alpha: (0.75 * pulseVal).clamp(0.0, 1.0),
                            )
                          : isMastered
                          ? const Color(0xFFFFD76F).withValues(alpha: 0.65)
                          : widget.unlocked
                          ? widget.accent.withValues(alpha: 0.42)
                          : const Color(0x22485E86),
                      width: widget.isCurrent ? 1.8 : 1.2,
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Watermark Background Icon
                      Positioned(
                        right: -16,
                        top: -14,
                        child: IgnorePointer(
                          child: Icon(
                            widget.icon,
                            size: 96,
                            color: widget.accent.withValues(
                              alpha: widget.unlocked ? 0.055 : 0.02,
                            ),
                          ),
                        ),
                      ),

                      // Orbital particle rings behind content
                      Positioned(
                        right: 8,
                        top: 36,
                        child: IgnorePointer(
                          child: SizedBox(
                            width: 60,
                            height: 30,
                            child: CustomPaint(
                              painter: _OrbitAccentPainter(
                                widget.accent,
                                widget.unlocked,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Content Column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Level Badge & Status Pill
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Number Emblem
                              _LevelNumberBadge(
                                level: widget.level,
                                accent: widget.accent,
                                unlocked: widget.unlocked,
                                isCurrent: widget.isCurrent,
                                isMastered: isMastered,
                              ),
                              const Spacer(),
                              // Status Pill
                              _StatusBadge(
                                unlocked: widget.unlocked,
                                isCurrent: widget.isCurrent,
                                isCleared: isCleared,
                                isMastered: isMastered,
                                accent: widget.accent,
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Center Emblem with glowing halo
                          Row(
                            children: [
                              _CenterEmblem(
                                icon: widget.unlocked
                                    ? widget.icon
                                    : Icons.lock_rounded,
                                accent: widget.accent,
                                unlocked: widget.unlocked,
                                isCurrent: widget.isCurrent,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.orbitron(
                                        color: widget.unlocked
                                            ? Colors.white
                                            : const Color(0x66FFFFFF),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        height: 1.15,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      widget.chapter.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.rajdhani(
                                        color: widget.unlocked
                                            ? widget.accent.withValues(
                                                alpha: 0.9,
                                              )
                                            : const Color(0x44FFFFFF),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Footer: Stars / Progress indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x66080E1C),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: widget.unlocked
                                    ? widget.accent.withValues(alpha: 0.18)
                                    : const Color(0x11FFFFFF),
                              ),
                            ),
                            child: Row(
                              children: [
                                if (widget.unlocked) ...[
                                  _StarsRow(
                                    stars: widget.stars,
                                    accent: widget.accent,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${widget.stars}/3 ★',
                                    style: GoogleFonts.orbitron(
                                      color: widget.stars > 0
                                          ? const Color(0xFFFFD15C)
                                          : const Color(0x77FFFFFF),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ] else ...[
                                  const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 11,
                                    color: Color(0x55FFFFFF),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'RESTRICTED',
                                    style: GoogleFonts.rajdhani(
                                      color: const Color(0x66FFFFFF),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'LOCKED',
                                    style: GoogleFonts.orbitron(
                                      color: const Color(0x44FFFFFF),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LevelNumberBadge extends StatelessWidget {
  const _LevelNumberBadge({
    required this.level,
    required this.accent,
    required this.unlocked,
    required this.isCurrent,
    required this.isMastered,
  });

  final int level;
  final Color accent;
  final bool unlocked;
  final bool isCurrent;
  final bool isMastered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrent
            ? accent.withValues(alpha: 0.22)
            : isMastered
            ? const Color(0xFFFFD15C).withValues(alpha: 0.2)
            : unlocked
            ? const Color(0x6616233B)
            : const Color(0x33101828),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: isCurrent
              ? accent
              : isMastered
              ? const Color(0xFFFFD15C).withValues(alpha: 0.7)
              : unlocked
              ? accent.withValues(alpha: 0.35)
              : const Color(0x22FFFFFF),
          width: isCurrent || isMastered ? 1.4 : 1.0,
        ),
      ),
      child: Text(
        level.toString().padLeft(2, '0'),
        style: GoogleFonts.orbitron(
          color: isCurrent
              ? accent
              : isMastered
              ? const Color(0xFFFFDF88)
              : unlocked
              ? Colors.white
              : const Color(0x55FFFFFF),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.unlocked,
    required this.isCurrent,
    required this.isCleared,
    required this.isMastered,
    required this.accent,
  });

  final bool unlocked;
  final bool isCurrent;
  final bool isCleared;
  final bool isMastered;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (isCurrent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.65)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: accent, blurRadius: 6, spreadRadius: 1),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'ACTIVE',
              style: GoogleFonts.orbitron(
                color: accent,
                fontSize: 8,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    if (isMastered) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0x33FFD15C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x88FFD15C)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.stars_rounded,
              size: 10,
              color: Color(0xFFFFD15C),
            ),
            const SizedBox(width: 3),
            Text(
              'PERFECT',
              style: GoogleFonts.orbitron(
                color: const Color(0xFFFFE082),
                fontSize: 7.5,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    if (isCleared) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0x224CD69B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x664CD69B)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              size: 10,
              color: Color(0xFF4CD69B),
            ),
            const SizedBox(width: 3),
            Text(
              'CLEARED',
              style: GoogleFonts.orbitron(
                color: const Color(0xFF4CD69B),
                fontSize: 7.5,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    if (unlocked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0x2273E5FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x4473E5FF)),
        ),
        child: Text(
          'READY',
          style: GoogleFonts.orbitron(
            color: const Color(0xFF73E5FF),
            fontSize: 7.5,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Color(0x22131C2D),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.lock_rounded,
        size: 12,
        color: Color(0x55FFFFFF),
      ),
    );
  }
}

class _CenterEmblem extends StatelessWidget {
  const _CenterEmblem({
    required this.icon,
    required this.accent,
    required this.unlocked,
    required this.isCurrent,
  });

  final IconData icon;
  final Color accent;
  final bool unlocked;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.25, -0.35),
          colors: unlocked
              ? [
                  isCurrent
                      ? accent.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.28),
                  accent.withValues(alpha: 0.22),
                  const Color(0xFF0F182B),
                ]
              : [const Color(0xFF252D3E), const Color(0xFF0F1420)],
        ),
        border: Border.all(
          color: isCurrent
              ? accent
              : unlocked
              ? accent.withValues(alpha: 0.55)
              : const Color(0x22FFFFFF),
          width: isCurrent ? 1.5 : 1.0,
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: isCurrent ? 0.35 : 0.16),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Icon(
          icon,
          color: unlocked
              ? (isCurrent ? Colors.white : accent)
              : const Color(0x55FFFFFF),
          size: 22,
          shadows: unlocked
              ? [Shadow(color: accent, blurRadius: isCurrent ? 10 : 6)]
              : null,
        ),
      ),
    );
  }
}

class _StarsRow extends StatelessWidget {
  const _StarsRow({required this.stars, required this.accent});

  final int stars;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isFilled = index < stars;
        return Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Icon(
            isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 13,
            color: isFilled
                ? const Color(0xFFFFD15C)
                : const Color(0x33FFFFFF),
            shadows: isFilled
                ? const [
                    Shadow(
                      color: Color(0xFFFFB300),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class _OrbitAccentPainter extends CustomPainter {
  const _OrbitAccentPainter(this.color, this.enabled);

  final Color color;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: enabled ? 0.22 : 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.95,
        height: size.height * 0.44,
      ),
      paint,
    );

    if (enabled) {
      canvas.drawCircle(
        Offset(size.width * 0.76, size.height * 0.36),
        2.4,
        Paint()
          ..color = color.withValues(alpha: 0.85)
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitAccentPainter oldDelegate) =>
      color != oldDelegate.color || enabled != oldDelegate.enabled;
}
