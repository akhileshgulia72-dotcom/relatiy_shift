import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:reality_shift/core/widget/campaign_monetization_controls.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'level_6_screen.dart';
import '../services/level_progress_service.dart';

class Level5Screen extends StatefulWidget {
  const Level5Screen({super.key});

  @override
  State<Level5Screen> createState() => _Level5ScreenState();
}

class _Level5ScreenState extends State<Level5Screen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _ink = Color(0xFF07101F);
  static const _cyan = Color(0xFF65E7F5);
  static const _violet = Color(0xFF9C79FF);

  late final AnimationController _fallController;
  late final AnimationController _ambientController;
  StreamSubscription<AccelerometerEvent>? _sensorSubscription;
  Timer? _sensorTimeout;
  final List<Offset> _calibrationSamples = [];
  Offset? _gravityReference;
  Offset? _filteredGravity;
  int _invertedSamples = 0;
  bool _gravityReversed = false;
  bool _magLockReleased = false;
  bool _triedGravityTooEarly = false;
  bool _sensorAvailable = true;
  bool _hintVisible = false;
  bool _completed = false;
  bool _nextStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fallController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 2100),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) _completeLanding();
        });
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _startSensor();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startSensor(recalibrate: true);
    } else {
      _stopSensor();
      _gravityReference = null;
      _filteredGravity = null;
      _calibrationSamples.clear();
      _invertedSamples = 0;
    }
  }

  void _startSensor({bool recalibrate = false}) {
    if (_completed || _gravityReversed) return;
    if (recalibrate) {
      _gravityReference = null;
      _filteredGravity = null;
      _calibrationSamples.clear();
      _invertedSamples = 0;
    }
    if (_sensorSubscription != null) return;
    _sensorTimeout?.cancel();
    _sensorTimeout = Timer(const Duration(seconds: 3), () {
      if (mounted && _gravityReference == null) {
        setState(() => _sensorAvailable = false);
      }
    });
    try {
      _sensorSubscription =
          accelerometerEventStream(
            samplingPeriod: SensorInterval.gameInterval,
          ).listen(
            _onAccelerometer,
            onError: (Object _) => _sensorFailed(),
            cancelOnError: true,
          );
    } catch (_) {
      _sensorFailed();
    }
  }

  void _onAccelerometer(AccelerometerEvent event) {
    if (_completed || _gravityReversed) return;
    _sensorTimeout?.cancel();
    final current = Offset(event.x, event.y);
    if (current.distance < 4.5) {
      // A face-up phone has little gravity on the screen axes; keep the touch
      // control available and wait for a useful upright reference.
      if (mounted && _sensorAvailable) {
        setState(() => _sensorAvailable = false);
      }
      return;
    }
    if (_gravityReference == null) {
      _calibrationSamples.add(current);
      if (_calibrationSamples.length >= 12) {
        final avg =
            _calibrationSamples.reduce((a, b) => a + b) /
            _calibrationSamples.length.toDouble();
        if (avg.distance >= 4.5) {
          _gravityReference = avg / avg.distance;
          _filteredGravity = _gravityReference;
          if (mounted) setState(() => _sensorAvailable = true);
        }
        _calibrationSamples.clear();
      }
      return;
    }
    if (!_magLockReleased) return;
    final filtered = (_filteredGravity! * .68 + current * .32);
    _filteredGravity = filtered / filtered.distance;
    final alignment =
        _filteredGravity!.dx * _gravityReference!.dx +
        _filteredGravity!.dy * _gravityReference!.dy;
    if (alignment < -.72) {
      _invertedSamples++;
      if (_invertedSamples >= 4) _reverseGravity(fromSensor: true);
    } else if (alignment > -.35) {
      _invertedSamples = 0;
    }
  }

  void _sensorFailed() {
    _sensorTimeout?.cancel();
    _sensorSubscription?.cancel();
    _sensorSubscription = null;
    if (mounted && !_sensorAvailable) return;
    if (mounted) setState(() => _sensorAvailable = false);
  }

  void _stopSensor() {
    _sensorTimeout?.cancel();
    _sensorTimeout = null;
    _sensorSubscription?.cancel();
    _sensorSubscription = null;
  }

  void _reverseGravity({bool fromSensor = false}) {
    if (_gravityReversed || _completed) return;
    if (!_magLockReleased) {
      setState(() => _triedGravityTooEarly = true);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'The astronaut is still magnetically locked to the ceiling.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }
    setState(() {
      _gravityReversed = true;
      _sensorAvailable = fromSensor || _sensorAvailable;
    });
    _stopSensor();
    _fallController.forward();
  }

  void _tapAstronautBoots(TapDownDetails details, Size suitSize) {
    if (_magLockReleased) return;
    if (details.localPosition.dy / suitSize.height < .69) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Something on the suit is still holding him up.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(milliseconds: 1400),
          ),
        );
      return;
    }
    setState(() {
      _magLockReleased = true;
      _triedGravityTooEarly = false;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Mag-lock released. Now reverse gravity.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1500),
        ),
      );
  }

  Future<void> _completeLanding() async {
    if (_completed) return;
    // Set the guard before storage work so repeated animation/sensor events
    // cannot grant a second reward or create a second success state.
    setState(() => _completed = true);
    _stopSensor();
    await LevelProgressService.complete(level: 5, stars: 3);
  }

  Future<void> _nextLevel() async {
    if (_nextStarted || !_completed) return;
    _nextStarted = true;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Level6Screen()),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopSensor();
    _fallController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
          child: CampaignMonetizationControls(
            level: 5,
            onHint: () => setState(() => _hintVisible = true),
            onSkipped: () => Navigator.maybePop(context),
          ),
        ),
      ),
      backgroundColor: _ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/space_bg.png', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xAA070B1B),
                  Color(0x55101A38),
                  Color(0xDD070B1B),
                ],
              ),
            ),
          ),
          const Positioned.fill(child: _StarField()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      _roundButton(
                        Icons.arrow_back_rounded,
                        () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      _pill('MISSION 05'),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'THE MISSING GRAVITY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: _violet, blurRadius: 20)],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bring the astronaut to the planet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFD5D9F0), fontSize: 15),
                  ),
                  if (_hintVisible) ...[
                    const SizedBox(height: 12),
                    _glassCard(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.tips_and_updates_outlined,
                            color: _cyan,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Release the astronaut’s magnetic boot lock first. Then rotate your phone about halfway around (180°) so gravity reverses and pulls the astronaut down to the planet. If rotation is unavailable, tap REVERSE GRAVITY.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Expanded(child: _scene()),
                  _sensorStatus(),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton.icon(
                      onPressed: _gravityReversed || _completed
                          ? null
                          : () => _reverseGravity(),
                      icon: Icon(
                        _gravityReversed
                            ? Icons.check_rounded
                            : Icons.sync_rounded,
                      ),
                      label: Text(
                        _gravityReversed
                            ? 'GRAVITY REVERSED'
                            : 'REVERSE GRAVITY',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cyan,
                        foregroundColor: const Color(0xFF06101B),
                        disabledBackgroundColor: const Color(0xFF34415B),
                        disabledForegroundColor: Colors.white70,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 12,
                        shadowColor: _cyan.withValues(alpha: .32),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_completed) _successOverlay(),
        ],
      ),
    );
  }

  Widget _scene() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final astronautSize = math.min(constraints.maxWidth * .48, 190.0);
        final startY = height * .06;
        final endY = height * .62;
        return AnimatedBuilder(
          animation: Listenable.merge([_fallController, _ambientController]),
          builder: (context, _) {
            final fall = Curves.easeInCubic.transform(_fallController.value);
            final bob = _gravityReversed
                ? 0.0
                : math.sin(_ambientController.value * math.pi) * 8;
            final astronautY = startY + (endY - startY) * fall + bob;
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: height * .23,
                  child: Container(
                    width: 2,
                    height: height * .31,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _gravityReversed
                              ? _cyan.withValues(alpha: .7)
                              : _violet.withValues(alpha: .6),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _cyan.withValues(alpha: .2),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: height * .68,
                  child: AnimatedBuilder(
                    animation: _ambientController,
                    builder: (_, child) => Transform.scale(
                      scale: 1 + _ambientController.value * .025,
                      child: child,
                    ),
                    child: Image.asset(
                      'assets/images/level5_planet.png',
                      width: math.min(constraints.maxWidth * .75, 300.0),
                      height: math.min(constraints.maxWidth * .75, 300.0),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.public, color: _violet, size: 200),
                    ),
                  ),
                ),
                Positioned(
                  top: astronautY,
                  child: SizedBox(
                    width: astronautSize,
                    height: astronautSize * 1.16,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        GestureDetector(
                          key: const ValueKey('astronaut-boots'),
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (details) => _tapAstronautBoots(
                            details,
                            Size(astronautSize, astronautSize * 1.16),
                          ),
                          child: Transform.rotate(
                            angle: _gravityReversed
                                ? fall * math.pi * 2
                                : math.sin(_ambientController.value * math.pi) *
                                      .045,
                            child: Image.asset(
                              'assets/images/level5_astronaut.png',
                              width: astronautSize,
                              height: astronautSize * 1.16,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => Icon(
                                Icons.rocket_launch_rounded,
                                size: astronautSize * .72,
                                color: _cyan,
                              ),
                            ),
                          ),
                        ),
                        if (!_magLockReleased)
                          Positioned(
                            bottom: -4,
                            child: IgnorePointer(
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: 0.82 + _ambientController.value * .18,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xEE302317),
                                    borderRadius: BorderRadius.circular(99),
                                    border: Border.all(
                                      color: const Color(0xFFFFBA62),
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x66FF9A40),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.lock_rounded,
                                        size: 11,
                                        color: Color(0xFFFFD08B),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'MAG-LOCK',
                                        style: TextStyle(
                                          color: Color(0xFFFFD08B),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: height * .50,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: _gravityReversed ? 1 : .55,
                    child: Text(
                      _gravityReversed
                          ? '↓  GRAVITY RESTORED  ↓'
                          : '↑  GRAVITY PULLING UP  ↑',
                      style: TextStyle(
                        color: _gravityReversed
                            ? _cyan
                            : const Color(0xFFC7B4FF),
                        fontSize: 11,
                        letterSpacing: 1.7,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sensorStatus() => _glassCard(
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _sensorAvailable ? Icons.sensors_rounded : Icons.touch_app_rounded,
          size: 17,
          color: _sensorAvailable ? _cyan : const Color(0xFFFFD48A),
        ),
        const SizedBox(width: 8),
        Text(
          !_magLockReleased
              ? _triedGravityTooEarly
                    ? 'Free the astronaut from the magnetic ceiling lock'
                    : 'The astronaut is stuck to the ceiling'
              : _sensorAvailable
              ? 'Rotate your phone upside down'
              : 'Use the button if rotation is unavailable',
          style: const TextStyle(
            color: Color(0xFFDDE3F5),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _successOverlay() => Positioned.fill(
    child: Container(
      color: const Color(0xCC050916),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _glassCard(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome_rounded, color: _cyan, size: 48),
              const SizedBox(height: 14),
              const Text(
                'MISSION COMPLETE',
                style: TextStyle(
                  color: _cyan,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Bro discovered gravity before physics class 💀',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '★★★   +45',
                style: TextStyle(
                  color: Color(0xFFFFD36C),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _nextLevel,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('NEXT LEVEL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cyan,
                    foregroundColor: _ink,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _glassCard(Widget child) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xB51A2440),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: .15)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );

  Widget _pill(String title) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0x99182238),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: _violet.withValues(alpha: .65)),
    ),
    child: Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    ),
  );

  Widget _roundButton(IconData icon, VoidCallback onTap) => Material(
    color: const Color(0x99182238),
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 42,
        height: 42,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    ),
  );
}

class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) =>
      IgnorePointer(child: CustomPaint(painter: _StarPainter()));
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(17);
    for (var i = 0; i < 70; i++) {
      final point = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final radius = .5 + random.nextDouble() * 1.6;
      final paint = Paint()
        ..color = Colors.white.withValues(
          alpha: .18 + random.nextDouble() * .45,
        );
      canvas.drawCircle(point, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
