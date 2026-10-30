import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FuturisticButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const FuturisticButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  State<FuturisticButton> createState() => _FuturisticButtonState();
}

class _FuturisticButtonState extends State<FuturisticButton> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => pressed = true),
      onTapUp: (_) {
        setState(() => pressed = false);
        _activate();
      },
      onTapCancel: () => setState(() => pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: pressed ? 0.96 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 68,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xff00D4FF), Color(0xff8A2BE2)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff00D4FF).withValues(alpha: 0.35),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xff0A1025),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: Colors.cyanAccent, size: 26),
                const SizedBox(width: 12),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _activate() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    if (prefs.getBool('hapticsEnabled') ?? true) {
      await HapticFeedback.selectionClick();
    }
    if (mounted) widget.onTap();
  }
}
