import 'package:flutter/material.dart';
import 'package:reality_shift/services/ads_service.dart';
import 'package:reality_shift/services/level_progress_service.dart';

/// Shared rewarded hint and skip controls for campaign levels.
class CampaignMonetizationControls extends StatefulWidget {
  const CampaignMonetizationControls({
    super.key,
    required this.level,
    required this.onHint,
    required this.onSkipped,
  });

  final int level;
  final VoidCallback onHint;
  final VoidCallback onSkipped;

  @override
  State<CampaignMonetizationControls> createState() =>
      _CampaignMonetizationControlsState();
}

class _CampaignMonetizationControlsState
    extends State<CampaignMonetizationControls>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);
  bool _busy = false;
  bool _hintShown = false;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _getHint() async {
    if (_busy || _hintShown) {
      if (_hintShown) widget.onHint();
      return;
    }
    setState(() => _busy = true);
    final rewarded = await AdsService.instance.showRewardedHint();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _hintShown = rewarded;
    });
    if (rewarded) {
      widget.onHint();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reward ad unavailable. Keep playing!')),
      );
    }
  }

  Future<void> _skip() async {
    if (_busy) return;
    setState(() => _busy = true);
    final rewarded = await AdsService.instance.showRewardedSkip();
    if (!mounted) return;
    if (rewarded) {
      await LevelProgressService.skip(level: widget.level);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (rewarded) {
      widget.onSkipped();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reward ad unavailable. Keep playing!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF35DFFF,
                    ).withValues(alpha: .22 + _pulse.value * .32),
                    blurRadius: 12 + _pulse.value * 13,
                    spreadRadius: _pulse.value * 2,
                  ),
                ],
              ),
              child: child,
            ),
            child: FilledButton.icon(
              onPressed: _busy ? null : _getHint,
              icon: Icon(_busy ? Icons.hourglass_top : Icons.lightbulb_rounded),
              label: Text(_busy ? 'LOADING AD…' : 'HINT  •  WATCH AD'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF23CDEB),
                foregroundColor: const Color(0xFF04131C),
                minimumSize: const Size(0, 54),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _skip,
            icon: const Icon(Icons.fast_forward_rounded, size: 18),
            label: const Text('SKIP'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFFD166),
              side: const BorderSide(color: Color(0x99FFD166)),
              minimumSize: const Size(0, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
