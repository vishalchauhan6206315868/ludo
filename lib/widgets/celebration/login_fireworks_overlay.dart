import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A magnificent full-screen Diwali Fireworks & Sky Crackers Celebration Overlay.
/// Displays realistic rocket ascents, radial bursts with sparkling trails, sky flashes,
/// and a royal Gold & Dark "LOGIN SUCCESSFUL" centerpiece.
class LoginFireworksOverlay extends StatefulWidget {
  final String? playerName;
  final VoidCallback onComplete;

  const LoginFireworksOverlay({
    super.key,
    this.playerName,
    required this.onComplete,
  });

  @override
  State<LoginFireworksOverlay> createState() => _LoginFireworksOverlayState();
}

class _LoginFireworksOverlayState extends State<LoginFireworksOverlay>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _badgeController;
  late Animation<double> _badgeScale;
  late Animation<double> _badgeFade;

  final Random _rng = Random();
  final List<_FireworkRocket> _rockets = [];
  final List<_SparkParticle> _sparks = [];
  final List<_SkyFlash> _flashes = [];

  bool _hasTriggeredCompletion = false;
  Timer? _badgeTimer;

  @override
  void initState() {
    super.initState();

    // 2.4s total festive duration
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _badgeScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _badgeController, curve: Curves.easeOutBack),
    );

    _badgeFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _badgeController, curve: Curves.easeIn),
    );

    _mainController.addListener(_onAnimationTick);
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finish();
      }
    });

    _initializeFireworks();

    _mainController.forward();

    // Delay badge appearance slightly so first rocket explosion leads the scene
    _badgeTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        _badgeController.forward();
      }
    });
  }

  void _initializeFireworks() {
    // 4 Staggered rockets launching across the screen
    final rocketConfigs = [
      _RocketConfig(xRatio: 0.28, targetYRatio: 0.22, delayMs: 40, color: const Color(0xFFFFD700)), // Gold
      _RocketConfig(xRatio: 0.72, targetYRatio: 0.26, delayMs: 180, color: const Color(0xFF00E5FF)), // Cyan
      _RocketConfig(xRatio: 0.50, targetYRatio: 0.16, delayMs: 380, color: const Color(0xFFFF1744)), // Ruby Red
      _RocketConfig(xRatio: 0.85, targetYRatio: 0.35, delayMs: 700, color: const Color(0xFF00E676)), // Emerald Green
      _RocketConfig(xRatio: 0.15, targetYRatio: 0.32, delayMs: 850, color: const Color(0xFFD946EF)), // Purple
    ];

    for (final cfg in rocketConfigs) {
      _rockets.add(_FireworkRocket(
        xRatio: cfg.xRatio,
        targetYRatio: cfg.targetYRatio,
        launchTimeRatio: cfg.delayMs / 2400.0,
        primaryColor: cfg.color,
      ));
    }
  }

  void _onAnimationTick() {
    final progress = _mainController.value;

    // 1. Update Rockets
    for (final rocket in _rockets) {
      if (!rocket.hasLaunched && progress >= rocket.launchTimeRatio) {
        rocket.hasLaunched = true;
      }

      if (rocket.hasLaunched && !rocket.hasExploded) {
        // Rocket flies upwards towards target height
        final flightProgress = ((progress - rocket.launchTimeRatio) * 6.5).clamp(0.0, 1.0);
        rocket.currentYRatio = 1.0 - (flightProgress * (1.0 - rocket.targetYRatio));

        if (flightProgress >= 1.0) {
          rocket.hasExploded = true;
          _spawnExplosion(rocket);
        }
      }
    }

    // 2. Update Spark Particles Physics
    for (final spark in _sparks) {
      spark.update();
    }

    // 3. Update Sky Flashes
    for (final flash in _flashes) {
      flash.update();
    }

    _sparks.removeWhere((s) => s.isDead);
    _flashes.removeWhere((f) => f.isDead);

    setState(() {});
  }

  void _spawnExplosion(_FireworkRocket rocket) {
    HapticFeedback.mediumImpact();

    // Spawn ambient sky flash
    _flashes.add(_SkyFlash(
      centerRatio: Offset(rocket.xRatio, rocket.targetYRatio),
      color: rocket.primaryColor,
    ));

    // Color palette for this shell
    final List<Color> palette = [
      rocket.primaryColor,
      const Color(0xFFFFF9C4), // Golden white
      Colors.white,
      if (rocket.primaryColor == const Color(0xFFFFD700)) const Color(0xFFFF9100),
      if (rocket.primaryColor == const Color(0xFF00E5FF)) const Color(0xFF00B0FF),
      if (rocket.primaryColor == const Color(0xFFFF1744)) const Color(0xFFFF4081),
      if (rocket.primaryColor == const Color(0xFF00E676)) const Color(0xFF76FF03),
    ];

    // Spawn 45 radial burst sparks
    final int count = 42 + _rng.nextInt(12);
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi + (_rng.nextDouble() * 0.25 - 0.12);
      final speed = 3.5 + _rng.nextDouble() * 5.5;
      final color = palette[_rng.nextInt(palette.length)];
      final radius = 2.2 + _rng.nextDouble() * 2.4;
      final maxLife = 38 + _rng.nextInt(26);

      _sparks.add(_SparkParticle(
        originRatio: Offset(rocket.xRatio, rocket.targetYRatio),
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        color: color,
        radius: radius,
        maxLife: maxLife,
      ));
    }
  }

  void _finish() {
    if (_hasTriggeredCompletion) return;
    _hasTriggeredCompletion = true;
    widget.onComplete();
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    _mainController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final displayName = widget.playerName?.trim().isNotEmpty == true
        ? widget.playerName!
        : 'Player';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish, // Instant tap-to-skip
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF020716), // Deep midnight sky
        child: Stack(
          children: [
            // 1. Fireworks Night Sky Canvas (CustomPainter)
            Positioned.fill(
              child: CustomPaint(
                painter: _DiwaliFireworksPainter(
                  rockets: _rockets,
                  sparks: _sparks,
                  flashes: _flashes,
                  screenSize: size,
                ),
              ),
            ),

            // 2. Centerpiece Royal "Login Successful" 3D Badge
            Center(
              child: FadeTransition(
                opacity: _badgeFade,
                child: ScaleTransition(
                  scale: _badgeScale,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                    constraints: const BoxConstraints(maxWidth: 390),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0F2356),
                          Color(0xFF071434),
                          Color(0xFF030A1C),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: const Color(0xFFFFD700),
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.40),
                          blurRadius: 36,
                          spreadRadius: 3,
                        ),
                        const BoxShadow(
                          color: Colors.black87,
                          blurRadius: 30,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top Decorative Golden Ribbon
                          Container(
                            height: 4.5,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFFFEA75),
                                  Color(0xFFFFD700),
                                  Color(0xFFFF8F00),
                                ],
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Glowing Crown / Checkmark Medallion
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 78,
                                      height: 78,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const RadialGradient(
                                          colors: [
                                            Color(0xFF1E3A8A),
                                            Color(0xFF0A193E),
                                          ],
                                          center: Alignment(0.0, -0.2),
                                          radius: 0.85,
                                        ),
                                        border: Border.all(
                                          color: const Color(0xFFFFD700),
                                          width: 2.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFFD700).withValues(alpha: 0.50),
                                            blurRadius: 22,
                                            spreadRadius: 2,
                                          ),
                                          BoxShadow(
                                            color: const Color(0xFF00E5FF).withValues(alpha: 0.30),
                                            blurRadius: 16,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFFFFD700),
                                        size: 44,
                                      ),
                                    ),
                                    // Golden Crown Top Badge
                                    Positioned(
                                      top: -6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFD700),
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black45,
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.emoji_events_rounded,
                                          size: 14,
                                          color: Color(0xFF05112B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),

                                // "LOGIN SUCCESSFUL" Title
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [
                                      Color(0xFFFFF9C4),
                                      Color(0xFFFFD700),
                                      Color(0xFFFFB300),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                                  child: const Text(
                                    "LOGIN SUCCESSFUL!",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.8,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black87,
                                          offset: Offset(0, 2),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Welcome Message with User's Name
                                Text(
                                  "Welcome back, $displayName! ✨",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFE2E8F0),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Festive Tagline
                                const Text(
                                  "Entering Ludo Supreme Arena...",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Tap to continue hint
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.touch_app_rounded, size: 13, color: Color(0xFFFFD700)),
                                      SizedBox(width: 5),
                                      Text(
                                        "Tap anywhere to enter",
                                        style: TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Canvas CustomPainter for Fireworks, Rockets, Particles, and Sky Flashes
// -----------------------------------------------------------------------------

class _DiwaliFireworksPainter extends CustomPainter {
  final List<_FireworkRocket> rockets;
  final List<_SparkParticle> sparks;
  final List<_SkyFlash> flashes;
  final Size screenSize;

  _DiwaliFireworksPainter({
    required this.rockets,
    required this.sparks,
    required this.flashes,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Paint Sky Flashes (Ambient blast illumination)
    for (final flash in flashes) {
      final center = Offset(flash.centerRatio.dx * size.width, flash.centerRatio.dy * size.height);
      final radius = size.width * 0.75;
      final flashPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            flash.color.withValues(alpha: 0.28 * flash.opacity),
            flash.color.withValues(alpha: 0.08 * flash.opacity),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, flashPaint);
    }

    // 2. Paint Rockets & Ascending Trails
    for (final rocket in rockets) {
      if (rocket.hasLaunched && !rocket.hasExploded) {
        final x = rocket.xRatio * size.width;
        final y = rocket.currentYRatio * size.height;

        // Trail smoke/fire
        final trailPaint = Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              rocket.primaryColor.withValues(alpha: 0.4),
              Colors.white,
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ).createShader(Rect.fromLTWH(x - 2, y, 4, 35));

        canvas.drawRect(Rect.fromLTWH(x - 1.5, y, 3, 32), trailPaint);

        // Rocket head spark
        final headPaint = Paint()
          ..color = Colors.white
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
        canvas.drawCircle(Offset(x, y), 3.5, headPaint);
      }
    }

    // 3. Paint Explosion Sparks & Trails
    for (final spark in sparks) {
      final pos = Offset(spark.x(size.width), spark.y(size.height));
      final prevPos = Offset(spark.prevX(size.width), spark.prevY(size.height));

      final alpha = spark.opacity.clamp(0.0, 1.0);
      final sparkColor = spark.color.withValues(alpha: alpha);

      // Trailing tail
      final tailPaint = Paint()
        ..color = sparkColor.withValues(alpha: alpha * 0.6)
        ..strokeWidth = spark.radius * 0.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(prevPos, pos, tailPaint);

      // Glowing spark head
      final headPaint = Paint()
        ..color = sparkColor
        ..maskFilter = MaskFilter.blur(BlurStyle.solid, spark.radius * 0.9);
      canvas.drawCircle(pos, spark.radius, headPaint);

      // Center bright core
      if (spark.life < spark.maxLife * 0.6) {
        final corePaint = Paint()..color = Colors.white.withValues(alpha: alpha * 0.85);
        canvas.drawCircle(pos, spark.radius * 0.45, corePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DiwaliFireworksPainter oldDelegate) => true;
}

// -----------------------------------------------------------------------------
// Data Models & Physics Structures
// -----------------------------------------------------------------------------

class _RocketConfig {
  final double xRatio;
  final double targetYRatio;
  final int delayMs;
  final Color color;

  const _RocketConfig({
    required this.xRatio,
    required this.targetYRatio,
    required this.delayMs,
    required this.color,
  });
}

class _FireworkRocket {
  final double xRatio;
  final double targetYRatio;
  final double launchTimeRatio;
  final Color primaryColor;

  bool hasLaunched = false;
  bool hasExploded = false;
  double currentYRatio = 1.0;

  _FireworkRocket({
    required this.xRatio,
    required this.targetYRatio,
    required this.launchTimeRatio,
    required this.primaryColor,
  });
}

class _SkyFlash {
  final Offset centerRatio;
  final Color color;
  double opacity = 1.0;
  bool isDead = false;

  _SkyFlash({
    required this.centerRatio,
    required this.color,
  });

  void update() {
    opacity -= 0.085;
    if (opacity <= 0.0) {
      isDead = true;
    }
  }
}

class _SparkParticle {
  final Offset originRatio;
  double vx;
  double vy;
  final Color color;
  final double radius;
  final int maxLife;

  int life = 0;
  bool isDead = false;

  double currentX = 0;
  double currentY = 0;
  double lastX = 0;
  double lastY = 0;

  _SparkParticle({
    required this.originRatio,
    required this.vx,
    required this.vy,
    required this.color,
    required this.radius,
    required this.maxLife,
  }) {
    currentX = 0;
    currentY = 0;
    lastX = 0;
    lastY = 0;
  }

  void update() {
    life++;
    if (life >= maxLife) {
      isDead = true;
      return;
    }

    lastX = currentX;
    lastY = currentY;

    // Apply drag & gravity
    vx *= 0.94;
    vy = (vy * 0.94) + 0.18; // gravity

    currentX += vx;
    currentY += vy;
  }

  double x(double screenWidth) => (originRatio.dx * screenWidth) + currentX;
  double y(double screenHeight) => (originRatio.dy * screenHeight) + currentY;
  double prevX(double screenWidth) => (originRatio.dx * screenWidth) + lastX;
  double prevY(double screenHeight) => (originRatio.dy * screenHeight) + lastY;

  double get opacity {
    final progress = life / maxLife;
    return (1.0 - progress).clamp(0.0, 1.0);
  }
}

