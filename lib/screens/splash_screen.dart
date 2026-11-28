import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../widgets/developer_credit_dialog.dart';
import 'home_menu_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _timelineController;
  late AnimationController _ambientController;

  // Hidden Developer Credit Tap Tracker
  int _tapCount = 0;
  Timer? _tapResetTimer;
  bool _isCreditDialogOpen = false;
  Completer<void>? _creditDialogCompleter;

  @override
  void initState() {
    super.initState();

    // Master 5.8s splash choreography (6.0s total splash duration):
    // 0.00..0.24: Hero icon + Golden LUDO SUPREME ribbon reveal
    // 0.14..0.52: Luxury 3D Dice tumbles & spins with 3D wrapping golden light vortex
    // 0.52..0.66: Red glossy pawn leaps across the 3D square board toward Yellow
    // 0.66..0.88: Impact spark burst + board shake -> Yellow topples flat, Red victory glow
    // 0.00..1.00: Glossy golden loading bar smoothly fills 0% -> 100%
    _timelineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5800),
    )..forward();

    // Continuous subtle ambient motion (sparkles, swirl rings, shimmer)
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _initializeApp();
  }

  void _onSplashTap() {
    _tapResetTimer?.cancel();
    _tapCount++;
    HapticFeedback.selectionClick();

    if (_tapCount >= 5) {
      _tapCount = 0;
      HapticFeedback.mediumImpact();
      _showDeveloperCreditDialog();
    } else {
      _tapResetTimer = Timer(const Duration(milliseconds: 1800), () {
        _tapCount = 0;
      });
    }
  }

  Future<void> _showDeveloperCreditDialog() async {
    if (_isCreditDialogOpen || !mounted) return;
    _isCreditDialogOpen = true;
    _creditDialogCompleter = Completer<void>();

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Developer Credit",
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, anim1, anim2) => const DeveloperCreditDialog(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved =
            CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );

    _isCreditDialogOpen = false;
    if (_creditDialogCompleter != null &&
        !_creditDialogCompleter!.isCompleted) {
      _creditDialogCompleter!.complete();
    }
  }

  Future<void> _initializeApp() async {
    // Defer initial disk/JSON initialization by 280ms so the 60fps opening animation
    // has zero main-thread CPU competition during first-frame rendering.
    await Future.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    await AuthService.initSampleData();

    // Full 6-second total splash screen duration (minus the initial 280ms delay)
    await Future.delayed(const Duration(milliseconds: 5720));

    // If user is actively tapping or developer credit dialog is open, wait cleanly
    while (_tapCount > 0 || _isCreditDialogOpen) {
      if (_isCreditDialogOpen && _creditDialogCompleter != null) {
        await _creditDialogCompleter!.future;
        break;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (!mounted) return;

    final loggedIn = await AuthService.isLoggedIn();

    if (!mounted) return;

    // Pause heavy splash ambient shaders right as transition begins so GPU
    // dedicates 100% budget to a silky 60fps cross-fade into the dashboard.
    _ambientController.stop();

    final Widget nextScreen =
        loggedIn ? const HomeMenuScreen() : const LoginScreen();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 850),
        reverseTransitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fadeAnim = CurvedAnimation(
            parent: animation,
            curve: const Interval(0.08, 1.0, curve: Curves.easeOutCubic),
          );
          final scaleAnim = Tween<double>(begin: 1.045, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          );
          final slideAnim = Tween<Offset>(
            begin: const Offset(0.0, 0.025),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          );

          // Smooth royal-blue bridge veil prevents any harsh flash between screens
          final veilOpacity = Tween<double>(begin: 0.35, end: 0.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
            ),
          );

          return FadeTransition(
            opacity: fadeAnim,
            child: SlideTransition(
              position: slideAnim,
              child: ScaleTransition(
                scale: scaleAnim,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    child,
                    IgnorePointer(
                      child: FadeTransition(
                        opacity: veilOpacity,
                        child: const ColoredBox(color: Color(0xFF04143C)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tapResetTimer?.cancel();
    _timelineController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  double _interval(double t, double start, double end) {
    if (t <= start) return 0.0;
    if (t >= end) return 1.0;
    return (t - start) / (end - start);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020B2B),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onSplashTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_timelineController, _ambientController]),
          builder: (context, _) {
            final t = _timelineController.value;
            final ambient = _ambientController.value;

            return Stack(
              children: [
                // 1. Live Royal Blue Backdrop (clean bottom — no curved line)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _RoyalSplashBackdropPainter(
                        ambient: ambient,
                        progress: t,
                      ),
                    ),
                  ),
                ),

                // 2. Main Responsive Foreground Content inside SafeArea
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;
                      final isCompact = h < 640 || w < 350;

                      final heroIconSize = (h * 0.20).clamp(116.0, 166.0);
                      final stageWidth = (w * 0.88).clamp(260.0, 420.0);
                      final stageHeight = (h * 0.36).clamp(196.0, 300.0);

                      final heroFade =
                          Curves.easeOut.transform(_interval(t, 0.0, 0.22));
                      final heroScale = Curves.easeOutBack
                          .transform(_interval(t, 0.0, 0.26));

                      return SizedBox(
                        width: w,
                        height: h,
                        child: Column(
                          children: [
                            SizedBox(height: isCompact ? 18 : 28),

                            // TOP-CENTER: Ludo App Icon + Golden LUDO SUPREME Ribbon + PLAY • ROLL • WIN
                            Opacity(
                              opacity: heroFade.clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: 0.78 + 0.22 * heroScale,
                                child: _buildHeroBrandEmblem(
                                  heroIconSize,
                                  w,
                                  ambient,
                                  isCompact,
                                ),
                              ),
                            ),

                            // MIDDLE: Premium 3D Dice Spin + Square 3D Ludo Board + Red Knocks Yellow!
                            Expanded(
                              child: Center(
                                child: RepaintBoundary(
                                  child: _buildAnimatedLudoArena(
                                    width: stageWidth,
                                    height: stageHeight,
                                    t: t,
                                    ambient: ambient,
                                  ),
                                ),
                              ),
                            ),

                            // BOTTOM: Glossy Golden Loading Bar + Clean Footer
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: (w * 0.14).clamp(28.0, 90.0),
                              ),
                              child: _buildLoadingBar(t, ambient, isCompact),
                            ),
                            SizedBox(height: isCompact ? 8 : 12),
                            _buildFooter(isCompact),
                            SizedBox(height: isCompact ? 10 : 14),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroBrandEmblem(
      double iconSize, double maxWidth, double ambient, bool isCompact) {
    final double ribbonWidth = (iconSize * 1.92)
        .clamp(220.0, math.min(330.0, maxWidth * 0.88))
        .toDouble();
    final ribbonHeight = isCompact ? 40.0 : 48.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: ribbonWidth,
          height: iconSize + (ribbonHeight * 0.42),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Golden Bezel Ludo App Icon with Live Shimmer
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(iconSize * 0.22),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFF59D),
                      Color(0xFFFFCA28),
                      Color(0xFFFF8F00),
                      Color(0xFFFFE082),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFC107).withValues(alpha: 0.45),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: const Color(0xFF00B0FF).withValues(alpha: 0.35),
                      blurRadius: 26,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3.2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(iconSize * 0.20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/ludo_splash_icon.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: const Color(0xFF0A2472),
                          child: const Icon(
                            Icons.casino_rounded,
                            color: Color(0xFFFFD700),
                            size: 54,
                          ),
                        ),
                      ),
                      // Moving diagonal light gloss sweep
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _DiagonalShimmerPainter(progress: ambient),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Golden Curved "LUDO SUPREME" Ribbon overlapping bottom of icon
              Positioned(
                bottom: 0,
                child: SizedBox(
                  width: ribbonWidth,
                  height: ribbonHeight,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size(ribbonWidth, ribbonHeight),
                        painter: _GoldenRibbonPainter(),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ribbonWidth * 0.14,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "LUDO SUPREME PRO",
                            style: TextStyle(
                              fontSize: isCompact ? 20 : 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              color: const Color(0xFF072268),
                              shadows: const [
                                Shadow(
                                  color: Color(0xFFFFF8E1),
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // PLAY • ROLL • WIN Tagline with divider lines
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 1.2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    const Color(0xFF81D4FA),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "PLAY • ROLL • WIN",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.94),
                fontSize: isCompact ? 10.5 : 12.0,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.4,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 1.2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF81D4FA),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Animated centerpiece:
  /// - 3D perspective SQUARE golden-beveled Ludo board
  /// - Luxury 3D gold-trimmed ivory Dice spinning with front+back wrapping golden light vortex
  /// - 4 sculpted luxury glossy pawns (Red leaps across & knocks Yellow over!)
  Widget _buildAnimatedLudoArena({
    required double width,
    required double height,
    required double t,
    required double ambient,
  }) {
    final stageReveal = Curves.easeOutCubic.transform(_interval(t, 0.08, 0.28));

    // Dice entry (0.14 -> 0.52): swoops in & spins dynamically with intense golden light vortex
    final diceT = _interval(t, 0.14, 0.52);
    final diceEased = Curves.easeOutCubic.transform(diceT);
    // Spin energy is highest while actively spinning and gently settles into a warm golden halo
    final spinVelocity = diceT < 1.0
        ? math.sin(diceT * math.pi).clamp(0.25, 1.0)
        : 0.35;
    final vortexAngle = (diceEased * math.pi * 6.5) + (ambient * math.pi * 2.0);
    final diceBounce = diceT > 0.74
        ? math.sin(((diceT - 0.74) / 0.26) * math.pi) * 10.0
        : 0.0;
    final diceFloat =
        diceT >= 1.0 ? math.sin(ambient * math.pi * 2) * 3.5 : 0.0;
    final diceOpacity = _interval(t, 0.14, 0.24).clamp(0.0, 1.0);
    final diceSize = (width * 0.185).clamp(50.0, 68.0);

    // 3D rotation settles crisply showing an isometric-hero view of 6 (with 4 & 5 edges gleaming!)
    final spinRem = (1.0 - diceEased);
    final diceRotX = spinRem * math.pi * 4.0 + 0.34;
    final diceRotY = spinRem * math.pi * 6.0 - 0.42;
    final diceRotZ = spinRem * math.pi * 2.0 - 0.08;

    final diceCenterY = height * 0.24 -
        ((1.0 - diceEased) * 46.0) -
        diceBounce +
        diceFloat;

    // RED KNOCKS YELLOW CHOREOGRAPHY:
    // 0.52 -> 0.66: Red leaps from top-left base to Yellow's bottom-right base
    // 0.66: IMPACT! Golden spark burst + damped board micro-shake
    // 0.66 -> 0.88: Yellow tumbles & falls flat on its side; Red does a victory hop!
    final attackT = _interval(t, 0.52, 0.66);
    final attackEased = Curves.easeInOutCubic.transform(attackT);

    final impactT = _interval(t, 0.66, 0.88);
    final fallEased = Curves.easeOutCubic.transform(impactT);
    final burstT = _interval(t, 0.65, 0.85);

    // Damped board impact shake right at t = 0.65..0.76
    final shakeT = _interval(t, 0.65, 0.76);
    final boardShakeX = (shakeT > 0.0 && shakeT < 1.0)
        ? math.sin(shakeT * math.pi * 6.0) * (1.0 - shakeT) * 7.0
        : 0.0;
    final boardShakeY = (shakeT > 0.0 && shakeT < 1.0)
        ? math.cos(shakeT * math.pi * 5.0) * (1.0 - shakeT) * 3.0
        : 0.0;

    final pawnSize = (width * 0.132).clamp(36.0, 50.0);
    final squareBoardSize =
        math.min(width * 0.74, height * 1.02).clamp(170.0, 265.0);

    // True tabletop perspective anchors (/_____\):
    // Back corners (Red & Green) are slightly narrower/smaller;
    // Front corners (Blue & Yellow) are wider/larger, sitting grounded on the surface!
    final redStart = Offset(width * 0.30, height * 0.56);
    final greenPos = Offset(width * 0.70, height * 0.56);
    final bluePos = Offset(width * 0.21, height * 0.79);
    final yellowStart = Offset(width * 0.79, height * 0.79);

    // Red pawn dynamic position, arc leap & perspective depth scaling (0.86 back -> 1.06 front!)
    final redCurrent = Offset.lerp(redStart, yellowStart, attackEased)!;
    final redAttackArc = math.sin(attackT * math.pi) * (height * 0.24);
    final victoryT = _interval(t, 0.68, 0.84);
    final redVictoryHop = math.sin(victoryT * math.pi) * 14.0;
    final redTilt = math.sin(attackT * math.pi) * 0.28;
    final redDepthScale = 0.86 + (0.20 * attackEased);
    final redPos = Offset(
      redCurrent.dx,
      redCurrent.dy - redAttackArc - redVictoryHop,
    );

    // Yellow pawn knock-over physics (flies right-down, tilts 105° flat & bounces)
    final yellowKnockDx = fallEased * (width * 0.12);
    final yellowKnockBounce =
        math.sin(fallEased * math.pi) * 18.0 * (1.0 - fallEased * 0.4);
    final yellowKnockDy = fallEased * 10.0 - yellowKnockBounce;
    final yellowAngle = fallEased * 1.84;
    final yellowOpacity = (1.0 - (fallEased * 0.32)).clamp(0.65, 1.0);
    final yellowPos = Offset(
      yellowStart.dx + yellowKnockDx,
      yellowStart.dy + yellowKnockDy,
    );

    final swirlWidth = diceSize * 3.4;
    final swirlHeight = diceSize * 1.95;

    return Opacity(
      opacity: stageReveal.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(boardShakeX, boardShakeY + (1.0 - stageReveal) * 24.0),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // 1. 3D Tabletop Surface Square Ludo Board (/_____\)
              Positioned(
                bottom: -height * 0.02,
                child: _PerspectiveSquareLudoBoard(size: squareBoardSize),
              ),

              // 2. Back Pawn: Green (top-right corner — slightly smaller for 3D depth)
              Positioned(
                left: greenPos.dx - (pawnSize * 0.86) / 2,
                top: greenPos.dy - (pawnSize * 0.86) * 1.12,
                child: _LuxuryPawnWidget(
                  size: pawnSize * 0.86,
                  baseColor: const Color(0xFF00C853),
                  lightColor: const Color(0xFF69F0AE),
                  darkColor: const Color(0xFF0B4F1C),
                ),
              ),

              // 3. BACK Half of 3D Rotating Golden Light Vortex (wraps BEHIND dice)
              if (diceOpacity > 0.01)
                Positioned(
                  left: (width / 2) - (swirlWidth / 2),
                  top: diceCenterY - (swirlHeight / 2),
                  child: Opacity(
                    opacity: diceOpacity,
                    child: SizedBox(
                      width: swirlWidth,
                      height: swirlHeight,
                      child: CustomPaint(
                        painter: _DiceGoldenVortexPainter(
                          angle: vortexAngle,
                          spinEnergy: spinVelocity,
                          isFrontLayer: false,
                        ),
                      ),
                    ),
                  ),
                ),

              // 4. Luxury Gold-Trimmed 3D Rotating Dice
              if (diceOpacity > 0.01)
                Positioned(
                  left: (width / 2) - (diceSize / 2),
                  top: diceCenterY - (diceSize / 2),
                  child: Opacity(
                    opacity: diceOpacity,
                    child: Transform.scale(
                      scale: 0.45 + 0.55 * diceEased,
                      child: RepaintBoundary(
                        child: _PremiumGoldenDice3D(
                          size: diceSize,
                          rotX: diceRotX,
                          rotY: diceRotY,
                          rotZ: diceRotZ,
                          glowIntensity: spinVelocity,
                        ),
                      ),
                    ),
                  ),
                ),

              // 5. FRONT Half of 3D Rotating Golden Light Vortex (sweeps IN FRONT of dice!)
              if (diceOpacity > 0.01)
                Positioned(
                  left: (width / 2) - (swirlWidth / 2),
                  top: diceCenterY - (swirlHeight / 2),
                  child: Opacity(
                    opacity: diceOpacity,
                    child: SizedBox(
                      width: swirlWidth,
                      height: swirlHeight,
                      child: CustomPaint(
                        painter: _DiceGoldenVortexPainter(
                          angle: vortexAngle,
                          spinEnergy: spinVelocity,
                          isFrontLayer: true,
                        ),
                      ),
                    ),
                  ),
                ),

              // 6. Front-Left Pawn: Blue (bottom-left corner — closer/larger)
              Positioned(
                left: bluePos.dx - (pawnSize * 1.06) / 2,
                top: bluePos.dy - (pawnSize * 1.06) * 1.12,
                child: _LuxuryPawnWidget(
                  size: pawnSize * 1.06,
                  baseColor: const Color(0xFF1E88E5),
                  lightColor: const Color(0xFF82B1FF),
                  darkColor: const Color(0xFF0A2E73),
                ),
              ),

              // 7. Front-Right Pawn: Yellow (gets hit & knocked flat by Red!)
              Positioned(
                left: yellowPos.dx - (pawnSize * 1.06) / 2,
                top: yellowPos.dy - (pawnSize * 1.06) * 1.12,
                child: Opacity(
                  opacity: yellowOpacity,
                  child: Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.identity()..rotateZ(yellowAngle),
                    child: _LuxuryPawnWidget(
                      size: pawnSize * 1.06,
                      baseColor: const Color(0xFFFFB300),
                      lightColor: const Color(0xFFFFF59D),
                      darkColor: const Color(0xFFB25900),
                      showShadow: fallEased < 0.5,
                    ),
                  ),
                ),
              ),

              // 8. Red Pawn (leaps forward from back-left to front-right & knocks Yellow over!)
              Positioned(
                left: redPos.dx - (pawnSize * redDepthScale) / 2,
                top: redPos.dy - (pawnSize * redDepthScale) * 1.12,
                child: Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.identity()..rotateZ(redTilt),
                  child: _LuxuryPawnWidget(
                    size: pawnSize * redDepthScale,
                    baseColor: const Color(0xFFE53935),
                    lightColor: const Color(0xFFFF8A80),
                    darkColor: const Color(0xFF7F0000),
                    glowVictory: victoryT > 0.0 && victoryT < 1.0,
                  ),
                ),
              ),

              // 9. Golden Impact Shockwave & Spark Burst at Collision Point
              if (burstT > 0.0 && burstT < 1.0)
                Positioned(
                  left: yellowStart.dx - 58,
                  top: yellowStart.dy - pawnSize * 0.60 - 58,
                  child: SizedBox(
                    width: 116,
                    height: 116,
                    child: CustomPaint(
                      painter: _ImpactBurstPainter(progress: burstT),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBar(double t, double ambient, bool isCompact) {
    final fill = Curves.easeInOut.transform(t).clamp(0.06, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: isCompact ? 11 : 13,
          decoration: BoxDecoration(
            color: const Color(0xFF041136),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.78),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFC107).withValues(alpha: 0.25),
                blurRadius: 10,
              ),
            ],
          ),
          padding: const EdgeInsets.all(1.5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LayoutBuilder(
              builder: (context, barBox) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: barBox.maxWidth * fill,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFB300),
                          Color(0xFFFFEE58),
                          Color(0xFFFFA000),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Loading...",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: isCompact ? 12 : 13.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isCompact) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "POWERED BY",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.62),
            fontSize: isCompact ? 9 : 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 1.0,
              color: Colors.white24,
            ),
            const SizedBox(width: 8),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: isCompact ? 11 : 12.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
                children: const [
                  TextSpan(
                    text: "ALLCORE ",
                    style: TextStyle(color: Colors.white),
                  ),
                  TextSpan(
                    text: "SOLUTION",
                    style: TextStyle(color: Color(0xFF29B6F6)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 26,
              height: 1.0,
              color: Colors.white24,
            ),
          ],
        ),
      ],
    );
  }
}

/// Live animated royal-blue backdrop with glowing energy swooshes, sparkles & faint crowns
/// (clean bottom without any curved ribbon line).
class _RoyalSplashBackdropPainter extends CustomPainter {
  final double ambient;
  final double progress;

  _RoyalSplashBackdropPainter({
    required this.ambient,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Deep Royal Radial Gradient
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.0, -0.15),
        radius: 1.15,
        colors: [
          Color(0xFF0A39A6),
          Color(0xFF041A5E),
          Color(0xFF010B2C),
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // 2. Flowing Neon-Blue Energy Swooshes (layered stroke bloom avoids GPU offscreen blur pass)
    final waveShift = math.sin(ambient * math.pi * 2) * 14.0;
    final outerSwooshPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.5
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF00E5FF).withValues(alpha: 0.0),
          const Color(0xFF00E5FF).withValues(alpha: 0.18),
          const Color(0xFF2979FF).withValues(alpha: 0.0),
        ],
      ).createShader(rect);
    final swooshPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF00E5FF).withValues(alpha: 0.0),
          const Color(0xFF00E5FF).withValues(alpha: 0.48),
          const Color(0xFF2979FF).withValues(alpha: 0.0),
        ],
      ).createShader(rect);

    final topLeftArc = Path()
      ..moveTo(-20, size.height * 0.18 + waveShift)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.04,
        size.width * 0.55,
        -10,
      );
    canvas.drawPath(topLeftArc, outerSwooshPaint);
    canvas.drawPath(topLeftArc, swooshPaint);

    final midWave = Path()
      ..moveTo(-20, size.height * 0.42 - waveShift)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.30,
        size.width * 0.70,
        size.height * 0.50,
        size.width + 20,
        size.height * 0.34 + waveShift,
      );
    canvas.drawPath(midWave, outerSwooshPaint);
    canvas.drawPath(midWave, swooshPaint);

    // 3. Subtle Floating Royal Crown Silhouettes (Left & Right)
    _drawFaintCrown(
      canvas,
      Offset(size.width * 0.14, size.height * 0.20 + waveShift * 0.3),
      26,
      -0.22,
    );
    _drawFaintCrown(
      canvas,
      Offset(size.width * 0.87, size.height * 0.28 - waveShift * 0.3),
      24,
      0.20,
    );

    // 4. Twinkling Sparkle Particles
    const sparkleCoords = [
      Offset(0.12, 0.10),
      Offset(0.84, 0.12),
      Offset(0.24, 0.33),
      Offset(0.78, 0.38),
      Offset(0.16, 0.54),
      Offset(0.88, 0.52),
      Offset(0.32, 0.66),
      Offset(0.68, 0.64),
      Offset(0.10, 0.78),
      Offset(0.90, 0.76),
    ];
    for (int i = 0; i < sparkleCoords.length; i++) {
      final p = sparkleCoords[i];
      final twinkle = (0.3 +
          0.7 * (0.5 + 0.5 * math.sin((ambient * 2 * math.pi) + i * 1.1)));
      final isGold = i.isEven;
      final dotPaint = Paint()
        ..color = (isGold ? const Color(0xFFFFE082) : const Color(0xFF80D8FF))
            .withValues(alpha: 0.72 * twinkle)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(
        Offset(p.dx * size.width, p.dy * size.height),
        isGold ? 2.2 : 1.7,
        dotPaint,
      );
    }
  }

  void _drawFaintCrown(
      Canvas canvas, Offset center, double radius, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(-radius, radius * 0.5)
      ..lineTo(-radius * 0.85, -radius * 0.35)
      ..lineTo(-radius * 0.3, radius * 0.05)
      ..lineTo(0, -radius * 0.55)
      ..lineTo(radius * 0.3, radius * 0.05)
      ..lineTo(radius * 0.85, -radius * 0.35)
      ..lineTo(radius, radius * 0.5)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF4FC3F7).withValues(alpha: 0.13),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RoyalSplashBackdropPainter oldDelegate) =>
      oldDelegate.ambient != ambient || oldDelegate.progress != progress;
}

/// Diagonal specular shimmer sweep across the hero Ludo app icon.
class _DiagonalShimmerPainter extends CustomPainter {
  final double progress;

  _DiagonalShimmerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final sweepX = -size.width + (progress * size.width * 3.0);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.28),
          Colors.white.withValues(alpha: 0.0),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(
        Rect.fromLTWH(sweepX, 0, size.width * 0.6, size.height),
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _DiagonalShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Custom 3D metallic golden curved ribbon banner for "LUDO".
class _GoldenRibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final tailPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFB86B00), Color(0xFFE69500)],
      ).createShader(Offset.zero & size);

    final leftTail = Path()
      ..moveTo(w * 0.12, h * 0.22)
      ..lineTo(0, h * 0.32)
      ..lineTo(w * 0.05, h * 0.58)
      ..lineTo(0, h * 0.88)
      ..lineTo(w * 0.14, h * 0.80)
      ..close();
    canvas.drawPath(leftTail, tailPaint);

    final rightTail = Path()
      ..moveTo(w * 0.88, h * 0.22)
      ..lineTo(w, h * 0.32)
      ..lineTo(w * 0.95, h * 0.58)
      ..lineTo(w, h * 0.88)
      ..lineTo(w * 0.86, h * 0.80)
      ..close();
    canvas.drawPath(rightTail, tailPaint);

    final mainPath = Path()
      ..moveTo(w * 0.09, h * 0.16)
      ..quadraticBezierTo(w * 0.5, -h * 0.06, w * 0.91, h * 0.16)
      ..lineTo(w * 0.89, h * 0.88)
      ..quadraticBezierTo(w * 0.5, h * 0.68, w * 0.11, h * 0.88)
      ..close();

    canvas.drawPath(
      mainPath.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    final frontPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFF59D),
          Color(0xFFFFCA28),
          Color(0xFFFFA000),
          Color(0xFFFFE082),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(mainPath, frontPaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xFFFFF8E1).withValues(alpha: 0.9);
    canvas.drawPath(mainPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// True 3D tabletop-surface SQUARE Ludo board (/_____\) with extruded golden front edge,
/// grounded surface contact shadow, pastel base courts, track grid & beveled finish triangles.
class _PerspectiveSquareLudoBoard extends StatelessWidget {
  final double size;

  const _PerspectiveSquareLudoBoard({required this.size});

  @override
  Widget build(BuildContext context) {
    // NEGATIVE rotateX makes top edge recede into depth (narrower) and bottom edge come forward (wider):
    // True tabletop surface perspective (/_____\) instead of upside-down hang!
    final tiltMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0020)
      ..rotateX(-0.78);

    return SizedBox(
      width: size * 1.15,
      height: size * 0.76,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Grounded Glossy Tabletop Surface Glow + Dark Contact Shadow
          Positioned(
            bottom: 2,
            child: Container(
              width: size * 1.16,
              height: size * 0.24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.elliptical(size * 0.58, size * 0.12),
                ),
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00B0FF).withValues(alpha: 0.34),
                    const Color(0xFF0A39A6).withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2. Extruded 3D Metallic Gold Slab Thickness seated directly on the surface
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.translationValues(0, 7.5, 0)
              ..multiply(tiltMatrix),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6B3C00),
                    Color(0xFFE69D12),
                    Color(0xFF9C5B00),
                    Color(0xFFFFD54F),
                    Color(0xFF6B3C00),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.78),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),

          // 3. Top Tilted Square Ludo Board Surface
          Transform(
            alignment: Alignment.center,
            transform: tiltMatrix,
            child: Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(5.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFF8C9),
                    Color(0xFFFFCA28),
                    Color(0xFFD48806),
                    Color(0xFFFFEE88),
                    Color(0xFFB26A00),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: const Color(0xFFFFFBE6).withValues(alpha: 0.85),
                  width: 1.2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                  size: Size.square(size - 11),
                  painter: _SquareLudoBoardFacePainter(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareLudoBoardFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final cell = s / 15.0;

    // 1. Crisp ivory-white track background
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFDFEFE));

    // 2. Track grid cells (15x15)
    final gridStroke = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    for (int r = 0; r < 15; r++) {
      for (int c = 0; c < 15; c++) {
        // Skip 4 corner bases (6x6) and center 3x3
        final inBase = (c < 6 && r < 6) ||
            (c >= 9 && r < 6) ||
            (c < 6 && r >= 9) ||
            (c >= 9 && r >= 9);
        final inCenter = c >= 6 && c <= 8 && r >= 6 && r <= 8;
        if (inBase || inCenter) continue;

        Color? fill;
        if (r == 7 && c >= 1 && c <= 5) {
          fill = const Color(0xFFE53935); // Red stretch
        } else if (c == 7 && r >= 1 && r <= 5) {
          fill = const Color(0xFF00C853); // Green stretch
        } else if (r == 7 && c >= 9 && c <= 13) {
          fill = const Color(0xFFFFB300); // Yellow stretch
        } else if (c == 7 && r >= 9 && r <= 13) {
          fill = const Color(0xFF1E88E5); // Blue stretch
        } else if (c == 1 && r == 6) {
          fill = const Color(0xFFE53935);
        } else if (c == 8 && r == 1) {
          fill = const Color(0xFF00C853);
        } else if (c == 13 && r == 8) {
          fill = const Color(0xFFFFB300);
        } else if (c == 6 && r == 13) {
          fill = const Color(0xFF1E88E5);
        }

        final rect = Rect.fromLTWH(c * cell, r * cell, cell, cell);
        if (fill != null) {
          canvas.drawRect(rect, Paint()..color = fill);
        }
        canvas.drawRect(rect, gridStroke);
      }
    }

    // 3. Four 6x6 Base Yards with white inner court & 4 colored slots
    _drawBaseYard(canvas, 0, 0, cell, const Color(0xFFD32F2F)); // Red
    _drawBaseYard(canvas, 9 * cell, 0, cell, const Color(0xFF00B248)); // Green
    _drawBaseYard(canvas, 0, 9 * cell, cell, const Color(0xFF1565C0)); // Blue
    _drawBaseYard(
        canvas, 9 * cell, 9 * cell, cell, const Color(0xFFF9A825)); // Yellow

    // 4. Center 3x3 Finish Triangles + Golden Medallion
    final centerRect = Rect.fromLTWH(6 * cell, 6 * cell, 3 * cell, 3 * cell);
    final cx = centerRect.center.dx;
    final cy = centerRect.center.dy;

    canvas.drawPath(
      Path()
        ..moveTo(centerRect.left, centerRect.top)
        ..lineTo(centerRect.right, centerRect.top)
        ..lineTo(cx, cy)
        ..close(),
      Paint()..color = const Color(0xFF00B248),
    );
    canvas.drawPath(
      Path()
        ..moveTo(centerRect.right, centerRect.top)
        ..lineTo(centerRect.right, centerRect.bottom)
        ..lineTo(cx, cy)
        ..close(),
      Paint()..color = const Color(0xFFFFB300),
    );
    canvas.drawPath(
      Path()
        ..moveTo(centerRect.left, centerRect.bottom)
        ..lineTo(centerRect.right, centerRect.bottom)
        ..lineTo(cx, cy)
        ..close(),
      Paint()..color = const Color(0xFF1565C0),
    );
    canvas.drawPath(
      Path()
        ..moveTo(centerRect.left, centerRect.top)
        ..lineTo(centerRect.left, centerRect.bottom)
        ..lineTo(cx, cy)
        ..close(),
      Paint()..color = const Color(0xFFD32F2F),
    );

    canvas.drawCircle(
      Offset(cx, cy),
      cell * 0.55,
      Paint()..color = const Color(0xFFFFD700),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      cell * 0.55,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF8D5500),
    );

    // 5. Subtle studio gloss sheen across top half
    canvas.drawRect(
      Rect.fromLTWH(0, 0, s, s * 0.55),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  void _drawBaseYard(
      Canvas canvas, double left, double top, double cell, Color color) {
    final yardRect = Rect.fromLTWH(left, top, 6 * cell, 6 * cell);
    canvas.drawRect(yardRect, Paint()..color = color);
    canvas.drawRect(
      yardRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.black26,
    );

    final innerRect = Rect.fromLTWH(
      left + cell * 0.85,
      top + cell * 0.85,
      cell * 4.3,
      cell * 4.3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, Radius.circular(cell * 0.6)),
      Paint()..color = Colors.white,
    );

    // 4 circular token home pads
    for (final dx in [2.0, 4.0]) {
      for (final dy in [2.0, 4.0]) {
        final c = Offset(left + dx * cell, top + dy * cell);
        canvas.drawCircle(
            c, cell * 0.56, Paint()..color = color.withValues(alpha: 0.20));
        canvas.drawCircle(
          c,
          cell * 0.56,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = color.withValues(alpha: 0.85),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Airtight studio-quality 3D hard luxury dice for the splash screen:
/// - True centered perspective (`setEntry(3, 2, -0.0020)`) with exact perspective backface culling
/// - Exact 3D-projected solid 24K gold convex hull backing guarantees 0px corner gaps at every spin angle
/// - Hard machined metallic gold casing + rounded warm porcelain ivory dish + 3D drilled ruby pips
class _PremiumGoldenDice3D extends StatelessWidget {
  final double size;
  final double rotX;
  final double rotY;
  final double rotZ;
  final double glowIntensity;

  const _PremiumGoldenDice3D({
    required this.size,
    required this.rotX,
    required this.rotY,
    required this.rotZ,
    required this.glowIntensity,
  });

  static ({double x, double y, double z}) _rotate(
      double x, double y, double z, double rx, double ry, double rz) {
    final cz = math.cos(rz), sz = math.sin(rz);
    final x1 = x * cz - y * sz;
    final y1 = x * sz + y * cz;
    final z1 = z;

    final cy = math.cos(ry), sy = math.sin(ry);
    final x2 = x1 * cy + z1 * sy;
    final y2 = y1;
    final z2 = -x1 * sy + z1 * cy;

    final cx = math.cos(rx), sx = math.sin(rx);
    final x3 = x2;
    final y3 = y2 * cx - z2 * sx;
    final z3 = y2 * sx + z2 * cx;

    return (x: x3, y: y3, z: z3);
  }

  static List<Offset> _computeConvexHull(List<Offset> points) {
    if (points.length <= 3) return points;
    points.sort((a, b) {
      final cmpX = a.dx.compareTo(b.dx);
      return cmpX != 0 ? cmpX : a.dy.compareTo(b.dy);
    });

    double cross(Offset o, Offset a, Offset b) =>
        (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);

    final lower = <Offset>[];
    for (final p in points) {
      while (lower.length >= 2 &&
          cross(lower[lower.length - 2], lower[lower.length - 1], p) <= 0) {
        lower.removeLast();
      }
      lower.add(p);
    }

    final upper = <Offset>[];
    for (int i = points.length - 1; i >= 0; i--) {
      final p = points[i];
      while (upper.length >= 2 &&
          cross(upper[upper.length - 2], upper[upper.length - 1], p) <= 0) {
        upper.removeLast();
      }
      upper.add(p);
    }

    lower.removeLast();
    upper.removeLast();
    return [...lower, ...upper];
  }

  @override
  Widget build(BuildContext context) {
    const double perspective = 0.0020;
    const double cameraZ = 1.0 / perspective;

    final cubeSize = size * 0.94;
    final h = cubeSize / 2.0;
    // +1.2px overlap welds neighboring faces cleanly across all mobile GPUs
    final fSize = cubeSize + 1.2;

    final rotMatrix = Matrix4.identity()
      ..rotateX(rotX)
      ..rotateY(rotY)
      ..rotateZ(rotZ);

    // Properly centered true 3D perspective: T(center) * P(-perspective) * R
    final projMatrix = Matrix4.translationValues(size / 2.0, size / 2.0, 0.0)
      ..multiply(Matrix4.identity()..setEntry(3, 2, -perspective))
      ..multiply(rotMatrix);

    final faces = <(int, Matrix4, (double, double, double), (double, double, double))>[
      // 6 on Front (+Z) so hero resting view showcases 6 prominently
      (6, Matrix4.translationValues(0, 0, h), (0, 0, h), (0, 0, 1)),
      (1, Matrix4.translationValues(0, 0, -h)..rotateY(math.pi), (0, 0, -h), (0, 0, -1)),
      (3, Matrix4.translationValues(h, 0, 0)..rotateY(math.pi / 2), (h, 0, 0), (1, 0, 0)),
      (4, Matrix4.translationValues(-h, 0, 0)..rotateY(-math.pi / 2), (-h, 0, 0), (-1, 0, 0)),
      (2, Matrix4.translationValues(0, -h, 0)..rotateX(-math.pi / 2), (0, -h, 0), (0, -1, 0)),
      (5, Matrix4.translationValues(0, h, 0)..rotateX(math.pi / 2), (0, h, 0), (0, 1, 0)),
    ];

    // Normalized studio key light from upper-left front
    const double lx = -0.38;
    const double ly = -0.55;
    const double lz = 0.74;

    final visible = <({
      int val,
      double z,
      double normalZ,
      double light,
      double specular,
      Matrix4 matrix,
    })>[];

    for (final (val, localMat, center, norm) in faces) {
      final rn = _rotate(norm.$1, norm.$2, norm.$3, rotX, rotY, rotZ);
      final rc = _rotate(center.$1, center.$2, center.$3, rotX, rotY, rotZ);

      // Exact perspective backface culling: N · (Camera - FaceCenter) > 0
      final toCamDot = rn.x * (-rc.x) + rn.y * (-rc.y) + rn.z * (cameraZ - rc.z);
      if (toCamDot <= 0.0) continue;

      final dot = (rn.x * lx + rn.y * ly + rn.z * lz).clamp(0.0, 1.0);
      final light = (0.56 + 0.44 * dot).clamp(0.52, 1.0);
      final specular = math.pow(dot, 5.0).toDouble().clamp(0.0, 1.0);

      final m = projMatrix.clone()
        ..multiply(localMat)
        ..multiply(Matrix4.translationValues(-fSize / 2.0, -fSize / 2.0, 0.0));

      visible.add((
        val: val,
        z: rc.z,
        normalZ: rn.z,
        light: light,
        specular: specular,
        matrix: m,
      ));
    }
    visible.sort((a, b) => a.z.compareTo(b.z));

    final frontNormalZ = visible.isNotEmpty ? visible.last.normalZ : 1.0;
    final flatBlend = visible.length <= 1
        ? 1.0
        : ((frontNormalZ - 0.96) / 0.04).clamp(0.0, 1.0);
    final outerCornerRatio = 0.032 + (0.083 * flatBlend);
    final hullOpacity = (1.0 - flatBlend).clamp(0.0, 1.0);

    List<Offset>? hullPoints;
    if (hullOpacity > 0.01) {
      final projectedCorners = <Offset>[];
      for (final sx in const [-1.0, 1.0]) {
        for (final sy in const [-1.0, 1.0]) {
          for (final sz in const [-1.0, 1.0]) {
            final p = _rotate(sx * h, sy * h, sz * h, rotX, rotY, rotZ);
            final w = 1.0 - perspective * p.z;
            projectedCorners.add(
              Offset(size / 2.0 + p.x / w, size / 2.0 + p.y / w),
            );
          }
        }
      }
      hullPoints = _computeConvexHull(projectedCorners);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Warm dynamic golden aura halo pulsing while rotating
          Container(
            width: size * 1.24,
            height: size * 1.24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD54F)
                      .withValues(alpha: 0.42 + 0.35 * glowIntensity),
                  blurRadius: 24 + 14 * glowIntensity,
                  spreadRadius: 4 + 4 * glowIntensity,
                ),
                BoxShadow(
                  color: const Color(0xFFFF8F00)
                      .withValues(alpha: 0.30 * glowIntensity),
                  blurRadius: 34,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),

          // Exact 3D-projected solid 24K gold silhouette hull -> ZERO corner gaps!
          if (hullPoints != null && hullPoints.length >= 3)
            Positioned.fill(
              child: CustomPaint(
                painter: _SplashDiceHullPainter(
                  hull: hullPoints,
                  opacity: hullOpacity,
                ),
              ),
            ),

          // Depth-sorted airtight 3D Cube Faces
          for (final f in visible)
            Transform(
              transform: f.matrix,
              child: _LuxuryGoldTrimDiceFace(
                faceSize: fSize,
                value: f.val,
                brightness: f.light,
                specular: f.specular,
                outerCornerRatio: outerCornerRatio,
              ),
            ),
        ],
      ),
    );
  }
}

class _SplashDiceHullPainter extends CustomPainter {
  final List<Offset> hull;
  final double opacity;

  const _SplashDiceHullPainter({
    required this.hull,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hull.length < 3 || opacity <= 0.01) return;

    final path = Path()..moveTo(hull.first.dx, hull.first.dy);
    for (int i = 1; i < hull.length; i++) {
      path.lineTo(hull[i].dx, hull[i].dy);
    }
    path.close();

    final bounds = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFD966).withValues(alpha: opacity),
            const Color(0xFFC47D08).withValues(alpha: opacity),
            const Color(0xFF5C3200).withValues(alpha: opacity),
          ],
        ).createShader(bounds),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF9C5E00).withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(covariant _SplashDiceHullPainter oldDelegate) {
    return (oldDelegate.opacity - opacity).abs() > 0.01 ||
        oldDelegate.hull.length != hull.length ||
        (hull.isNotEmpty && oldDelegate.hull.first != hull.first);
  }
}

class _LuxuryGoldTrimDiceFace extends StatelessWidget {
  final double faceSize;
  final int value;
  final double brightness;
  final double specular;
  final double outerCornerRatio;

  const _LuxuryGoldTrimDiceFace({
    required this.faceSize,
    required this.value,
    required this.brightness,
    required this.specular,
    required this.outerCornerRatio,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: faceSize,
      height: faceSize,
      child: CustomPaint(
        painter: _SplashLuxuryDiceFacePainter(
          value: value,
          brightness: brightness,
          specular: specular,
          outerCornerRatio: outerCornerRatio,
        ),
      ),
    );
  }
}

class _SplashLuxuryDiceFacePainter extends CustomPainter {
  final int value;
  final double brightness;
  final double specular;
  final double outerCornerRatio;

  const _SplashLuxuryDiceFacePainter({
    required this.value,
    required this.brightness,
    required this.specular,
    required this.outerCornerRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final outerRect = Rect.fromLTWH(0, 0, w, h);
    final outerRRect = RRect.fromRectAndRadius(
      outerRect,
      Radius.circular(w * outerCornerRatio),
    );

    // 1. Hard Machined 24K Metallic Gold Outer Casing
    final goldTop = Color.lerp(
        const Color(0xFFB87810), const Color(0xFFFFF7BF), brightness)!;
    final goldMid = Color.lerp(
        const Color(0xFF945800), const Color(0xFFFFCA28), brightness)!;
    final goldDeep = Color.lerp(
        const Color(0xFF472500), const Color(0xFFA66000), brightness)!;

    canvas.drawRRect(
      outerRRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [goldTop, goldMid, goldDeep, goldMid, goldDeep],
          stops: const [0.0, 0.25, 0.54, 0.78, 1.0],
        ).createShader(outerRect),
    );

    // Hard metallic edge bevel catchlight
    canvas.drawRRect(
      outerRRect.deflate(0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (w * 0.022).clamp(0.9, 1.6)
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.80 * brightness),
            const Color(0xFFFFD54F).withValues(alpha: 0.35 * brightness),
            const Color(0xFF4A2500).withValues(alpha: 0.78),
          ],
        ).createShader(outerRect),
    );

    // 2. Inset Pearl-Ivory Porcelain Plate
    final rimWidth = (w * 0.072).clamp(2.8, 5.4);
    final innerRect = outerRect.deflate(rimWidth);
    final innerRRect = RRect.fromRectAndRadius(
      innerRect,
      Radius.circular((w * 0.135).clamp(4.0, 12.0)),
    );

    canvas.drawRRect(
      innerRRect.inflate(0.7),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = const Color(0xFF5A3400).withValues(alpha: 0.55),
    );

    final ivoryLight = Color.lerp(
        const Color(0xFFD5CCB8), const Color(0xFFFFFFFF), brightness)!;
    final ivoryMid = Color.lerp(
        const Color(0xFFC2B7A0), const Color(0xFFFAF5E9), brightness)!;
    final ivoryShade = Color.lerp(
        const Color(0xFFA2967F), const Color(0xFFE5DAC2), brightness)!;

    canvas.drawRRect(
      innerRRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ivoryLight, ivoryMid, ivoryShade],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(innerRect),
    );

    // 3. Subtle Concave Casino Dish + Inner Specular Glint
    final dishRect = innerRect.deflate(w * 0.045);
    canvas.drawOval(
      dishRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.28, 0.28),
          radius: 0.85,
          colors: [
            Colors.white.withValues(alpha: 0.42 * brightness),
            Colors.transparent,
            const Color(0xFF9E8A6A).withValues(alpha: 0.18),
          ],
          stops: const [0.0, 0.62, 1.0],
        ).createShader(dishRect),
    );

    if (specular > 0.12) {
      final sheenRect = Rect.fromLTWH(
        innerRect.left + innerRect.width * 0.06,
        innerRect.top + innerRect.height * 0.05,
        innerRect.width * 0.55,
        innerRect.height * 0.26,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(sheenRect, Radius.circular(w * 0.10)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.34 * specular),
              Colors.white.withValues(alpha: 0.0),
            ],
          ).createShader(sheenRect),
      );
    }

    // 4. Recessed 3D Drilled Royal Ruby Pips (matching the splash icon's signature look)
    final pipRadius = value == 1 ? w * 0.125 : w * 0.084;
    for (final pt in _pipCoords(value)) {
      final c = Offset(
        innerRect.left + innerRect.width * pt.dx,
        innerRect.top + innerRect.height * pt.dy,
      );
      _drawRubyPip(canvas, c, pipRadius, isOne: value == 1);
    }
  }

  void _drawRubyPip(Canvas canvas, Offset center, double r, {required bool isOne}) {
    final pipRect = Rect.fromCircle(center: center, radius: r);

    if (isOne) {
      canvas.drawCircle(
        center,
        r * 1.15,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (r * 0.16).clamp(1.0, 1.8)
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF3B0), Color(0xFFD99100), Color(0xFF7A4400)],
          ).createShader(Rect.fromCircle(center: center, radius: r * 1.2)),
      );
    }

    // Drilled rim highlight (bottom-right) & recessed shadow (top-left)
    canvas.drawCircle(
      center + Offset(r * 0.10, r * 0.12),
      r * 1.03,
      Paint()..color = Colors.white.withValues(alpha: 0.78 * brightness),
    );
    canvas.drawCircle(
      center - Offset(r * 0.08, r * 0.08),
      r * 1.02,
      Paint()..color = const Color(0xFF3E2D16).withValues(alpha: 0.45),
    );

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.26, 0.30),
          radius: 0.92,
          colors: [
            Color.lerp(const Color(0xFFE53935), const Color(0xFFFF6B6B), brightness)!,
            Color.lerp(const Color(0xFFB71C1C), const Color(0xFFD91E18), brightness)!,
            const Color(0xFF7F0909),
            const Color(0xFF470303),
          ],
          stops: const [0.0, 0.45, 0.80, 1.0],
        ).createShader(pipRect),
    );

    canvas.drawCircle(
      center + Offset(r * 0.26, r * 0.28),
      r * 0.24,
      Paint()..color = Colors.white.withValues(alpha: 0.50 * brightness),
    );
  }

  static List<Offset> _pipCoords(int val) {
    const lo = 0.25;
    const mid = 0.50;
    const hi = 0.75;
    switch (val) {
      case 1:
        return const [Offset(mid, mid)];
      case 2:
        return const [Offset(lo, lo), Offset(hi, hi)];
      case 3:
        return const [Offset(lo, lo), Offset(mid, mid), Offset(hi, hi)];
      case 4:
        return const [
          Offset(lo, lo),
          Offset(hi, lo),
          Offset(lo, hi),
          Offset(hi, hi),
        ];
      case 5:
        return const [
          Offset(lo, lo),
          Offset(hi, lo),
          Offset(mid, mid),
          Offset(lo, hi),
          Offset(hi, hi),
        ];
      case 6:
      default:
        return const [
          Offset(lo, 0.22),
          Offset(hi, 0.22),
          Offset(lo, mid),
          Offset(hi, mid),
          Offset(lo, 0.78),
          Offset(hi, 0.78),
        ];
    }
  }

  @override
  bool shouldRepaint(covariant _SplashLuxuryDiceFacePainter oldDelegate) {
    return oldDelegate.value != value ||
        (oldDelegate.brightness - brightness).abs() > 0.008 ||
        (oldDelegate.specular - specular).abs() > 0.01 ||
        (oldDelegate.outerCornerRatio - outerCornerRatio).abs() > 0.002;
  }
}

/// Multi-layered 3D golden light vortex wrapping BEHIND and IN FRONT of the spinning dice,
/// with luminous light ribbons, motion-trail glints & orbiting golden dust sparks!
class _DiceGoldenVortexPainter extends CustomPainter {
  final double angle;
  final double spinEnergy;
  final bool isFrontLayer;

  _DiceGoldenVortexPainter({
    required this.angle,
    required this.spinEnergy,
    required this.isFrontLayer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // 3 tilted orbital planes wrapping around the 3D dice
    final configs = [
      (tilt: -0.18, rx: 0.46, ry: 0.30, speed: 1.0, width: 3.4),
      (tilt: 0.22, rx: 0.40, ry: 0.24, speed: -1.35, width: 2.6),
      (tilt: -0.04, rx: 0.34, ry: 0.20, speed: 1.75, width: 2.0),
    ];

    for (int i = 0; i < configs.length; i++) {
      final cfg = configs[i];
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(cfg.tilt);

      final rx = size.width * cfg.rx;
      final ry = size.height * cfg.ry;
      final oval = Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);

      // Back layer draws upper arc (pi..2*pi); Front layer draws lower arc (0..pi)
      // so golden ribbons literally weave behind & across the front of the 3D dice!
      final halfStart = isFrontLayer ? 0.0 : math.pi;
      final rot = angle * cfg.speed + i * 1.4;

      // Soft outer bloom trail (layered stroke bloom preserves luminous glow with 0 offscreen blur passes)
      final bloomPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cfg.width * (2.8 + 1.8 * spinEnergy)
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          transform: GradientRotation(rot),
          colors: [
            const Color(0xFFFFB300).withValues(alpha: 0.0),
            const Color(0xFFFFE082).withValues(alpha: (0.36 + 0.36 * spinEnergy).clamp(0.0, 0.85)),
            const Color(0xFFFF8F00).withValues(alpha: 0.22 + 0.28 * spinEnergy),
            const Color(0xFFFFB300).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.38, 0.72, 1.0],
        ).createShader(oval);
      canvas.drawArc(oval, halfStart, math.pi, false, bloomPaint);

      // Mid golden sheen
      final midBloomPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cfg.width * (1.6 + 0.9 * spinEnergy)
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          transform: GradientRotation(rot),
          colors: [
            const Color(0xFFFFD54F).withValues(alpha: 0.0),
            const Color(0xFFFFF176).withValues(alpha: (0.55 + 0.35 * spinEnergy).clamp(0.0, 0.95)),
            const Color(0xFFFFB300).withValues(alpha: 0.35 + 0.25 * spinEnergy),
            const Color(0xFFFFD54F).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.38, 0.72, 1.0],
        ).createShader(oval);
      canvas.drawArc(oval, halfStart, math.pi, false, midBloomPaint);

      // Crisp incandescent golden-white core filament
      final corePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cfg.width * (0.75 + 0.45 * spinEnergy)
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          transform: GradientRotation(rot),
          colors: [
            const Color(0xFFFFF8E1).withValues(alpha: 0.0),
            const Color(0xFFFFFFFF).withValues(alpha: (0.65 + 0.35 * spinEnergy).clamp(0.0, 1.0)),
            const Color(0xFFFFD54F).withValues(alpha: 0.6 + 0.35 * spinEnergy),
            const Color(0xFFFFF8E1).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.35, 0.68, 1.0],
        ).createShader(oval);
      canvas.drawArc(oval, halfStart, math.pi, false, corePaint);

      // Orbiting bright golden star-sparks traveling along the ribbon
      for (int s = 0; s < 3; s++) {
        final sparkA = (rot + s * 2.1) % (math.pi * 2);
        final isInThisHalf = isFrontLayer
            ? (sparkA >= 0 && sparkA <= math.pi)
            : (sparkA > math.pi && sparkA < math.pi * 2);
        if (!isInThisHalf) continue;

        final sx = math.cos(sparkA) * rx;
        final sy = math.sin(sparkA) * ry;
        final r = (s == 0 ? 3.8 : 2.3) * (0.7 + 0.45 * spinEnergy);

        // Soft golden halo (dual-circle soft bloom)
        canvas.drawCircle(
          Offset(sx, sy),
          r * 2.2,
          Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.28 * spinEnergy),
        );
        canvas.drawCircle(
          Offset(sx, sy),
          r * 1.5,
          Paint()..color = const Color(0xFFFFE082).withValues(alpha: 0.48 * spinEnergy),
        );
        // Bright white-gold core star
        canvas.drawCircle(
          Offset(sx, sy),
          r,
          Paint()..color = const Color(0xFFFFFDE7),
        );

        // Tiny 4-point lens glint on leading spark
        if (s == 0 && spinEnergy > 0.3) {
          final glintLen = r * 3.2;
          final glintPaint = Paint()
            ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.85 * spinEnergy)
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(
              Offset(sx - glintLen, sy), Offset(sx + glintLen, sy), glintPaint);
          canvas.drawLine(
              Offset(sx, sy - glintLen), Offset(sx, sy + glintLen), glintPaint);
        }
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _DiceGoldenVortexPainter oldDelegate) =>
      oldDelegate.angle != angle ||
      oldDelegate.spinEnergy != spinEnergy ||
      oldDelegate.isFrontLayer != isFrontLayer;
}

/// Luxury lacquered 3D Ludo pawn with metallic golden base/neck rings,
/// multi-stop specular sheen, cool rim lighting & realistic contact shadow.
class _LuxuryPawnWidget extends StatelessWidget {
  final double size;
  final Color baseColor;
  final Color lightColor;
  final Color darkColor;
  final bool showShadow;
  final bool glowVictory;

  const _LuxuryPawnWidget({
    required this.size,
    required this.baseColor,
    required this.lightColor,
    required this.darkColor,
    this.showShadow = true,
    this.glowVictory = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.28,
      child: CustomPaint(
        painter: _LuxuryPawnPainter(
          baseColor: baseColor,
          lightColor: lightColor,
          darkColor: darkColor,
          showShadow: showShadow,
          glowVictory: glowVictory,
        ),
      ),
    );
  }
}

class _LuxuryPawnPainter extends CustomPainter {
  final Color baseColor;
  final Color lightColor;
  final Color darkColor;
  final bool showShadow;
  final bool glowVictory;

  _LuxuryPawnPainter({
    required this.baseColor,
    required this.lightColor,
    required this.darkColor,
    required this.showShadow,
    required this.glowVictory,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    if (glowVictory) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, h * 0.58),
          width: w * 1.25,
          height: h * 0.96,
        ),
        Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: 0.48)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

    // 1. Dual-layer Ground Contact Shadow + Colored Bounce Glow
    if (showShadow) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, h * 0.93),
          width: w * 0.92,
          height: h * 0.17,
        ),
        Paint()
          ..color = baseColor.withValues(alpha: 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, h * 0.92),
          width: w * 0.80,
          height: h * 0.12,
        ),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
      );
    }

    // 2. Brushed Gold Bottom Rim Pedestal
    final goldBaseRect = Rect.fromCenter(
      center: Offset(cx, h * 0.875),
      width: w * 0.86,
      height: h * 0.18,
    );
    canvas.drawOval(
      goldBaseRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFFFF59D),
            Color(0xFFFFB300),
            Color(0xFF9C5B00),
            Color(0xFFFFE082),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(goldBaseRect),
    );

    // Colored lacquered pedestal flange
    final colorBaseRect = Rect.fromCenter(
      center: Offset(cx, h * 0.845),
      width: w * 0.80,
      height: h * 0.17,
    );
    canvas.drawOval(
      colorBaseRect,
      Paint()
        ..shader = LinearGradient(
          colors: [lightColor, baseColor, darkColor],
          stops: const [0.08, 0.50, 0.96],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(colorBaseRect),
    );

    // 3. Sculpted High-Gloss Hourglass Pawn Body
    final bodyPath = Path()
      ..moveTo(cx - w * 0.36, h * 0.83)
      ..cubicTo(
        cx - w * 0.30,
        h * 0.65,
        cx - w * 0.19,
        h * 0.52,
        cx - w * 0.15,
        h * 0.38,
      )
      ..lineTo(cx + w * 0.15, h * 0.38)
      ..cubicTo(
        cx + w * 0.19,
        h * 0.52,
        cx + w * 0.30,
        h * 0.65,
        cx + w * 0.36,
        h * 0.83,
      )
      ..quadraticBezierTo(cx, h * 0.91, cx - w * 0.36, h * 0.83)
      ..close();

    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(lightColor, Colors.white, 0.35)!,
            lightColor,
            baseColor,
            darkColor,
            Color.lerp(darkColor, const Color(0xFF80D8FF), 0.18)!,
          ],
          stops: const [0.0, 0.18, 0.48, 0.84, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Offset.zero & size),
    );

    // Crisp glossy highlight ribbon along left body curve
    final bodyGloss = Path()
      ..moveTo(cx - w * 0.24, h * 0.79)
      ..quadraticBezierTo(cx - w * 0.16, h * 0.58, cx - w * 0.09, h * 0.42)
      ..lineTo(cx - w * 0.03, h * 0.42)
      ..quadraticBezierTo(cx - w * 0.08, h * 0.58, cx - w * 0.14, h * 0.79)
      ..close();
    canvas.drawPath(
      bodyGloss,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.62),
            Colors.white.withValues(alpha: 0.18),
          ],
        ).createShader(Offset.zero & size),
    );

    // 4. Metallic Gold Neck Collar Ring
    final collarRect = Rect.fromCenter(
      center: Offset(cx, h * 0.385),
      width: w * 0.40,
      height: h * 0.09,
    );
    canvas.drawOval(
      collarRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFFFF59D),
            Color(0xFFFFB300),
            Color(0xFF8C5200),
            Color(0xFFFFE082),
          ],
        ).createShader(collarRect),
    );

    // 5. High-Gloss Porcelain/Enamel Spherical Head
    final headCenter = Offset(cx, h * 0.23);
    final headR = w * 0.285;
    canvas.drawCircle(
      headCenter,
      headR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.42, -0.45),
          radius: 0.92,
          colors: [
            Colors.white,
            Color.lerp(lightColor, Colors.white, 0.35)!,
            baseColor,
            darkColor,
          ],
          stops: const [0.0, 0.22, 0.60, 1.0],
        ).createShader(Rect.fromCircle(center: headCenter, radius: headR)),
    );

    // Cool bottom-right rim reflection on head
    canvas.drawArc(
      Rect.fromCircle(center: headCenter, radius: headR * 0.90),
      0.2,
      1.2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: 0.32),
    );

    // Crisp glossy specular catchlight on top-left of head
    canvas.save();
    canvas.translate(cx - headR * 0.35, headCenter.dy - headR * 0.36);
    canvas.rotate(-0.45);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: headR * 0.46,
        height: headR * 0.24,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LuxuryPawnPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor ||
      oldDelegate.showShadow != showShadow ||
      oldDelegate.glowVictory != glowVictory;
}

/// Golden impact shockwave ring + radial spark burst when Red knocks Yellow over!
class _ImpactBurstPainter extends CustomPainter {
  final double progress;

  _ImpactBurstPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final fade = (1.0 - progress).clamp(0.0, 1.0);

    // Expanding golden shockwave ring (dual-stroke bloom avoids offscreen blur pass)
    final ringRadius = 10.0 + progress * (size.width * 0.45);
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (6.8 * fade).clamp(1.0, 6.8)
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.45 * fade),
    );
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (3.2 * fade).clamp(0.5, 3.2)
        ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.95 * fade),
    );

    // 12 radial sparks bursting outward
    const sparkCount = 12;
    for (int i = 0; i < sparkCount; i++) {
      final angle = (i / sparkCount) * math.pi * 2 + 0.25;
      final dist = 8.0 + progress * (size.width * 0.47);
      final p1 = Offset(
        center.dx + math.cos(angle) * (dist * 0.52),
        center.dy + math.sin(angle) * (dist * 0.52),
      );
      final p2 = Offset(
        center.dx + math.cos(angle) * dist,
        center.dy + math.sin(angle) * dist,
      );

      final sparkPaint = Paint()
        ..color = (i.isEven ? const Color(0xFFFFEE58) : const Color(0xFFFF5252))
            .withValues(alpha: 0.95 * fade)
        ..strokeWidth = (3.2 * fade).clamp(0.8, 3.2)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p1, p2, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ImpactBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
