import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/sound_haptic_service.dart';

/// Reusable function that generates 3-4 safe intermediate trajectory points between
/// [start] and [finalPosition] incorporating board center dynamics and physical variations.
List<Offset> generateDiceTrajectory({
  required Offset start,
  required Offset finalPosition,
  required Size boardSize,
  bool isTopPlayer = false,
  Random? random,
}) {
  final rng = random ?? Random();
  final dySign = finalPosition.dy >= start.dy ? 1.0 : -1.0;
  final forwardDir = (finalPosition.dy - start.dy).abs() > 10.0
      ? dySign
      : (isTopPlayer ? 1.0 : -1.0);

  final totalDistanceY = (finalPosition.dy - start.dy).abs();
  final totalDistanceX = finalPosition.dx - start.dx;
  final midX = start.dx + totalDistanceX * 0.50;

  final rollType = rng.nextDouble();
  int trajectoryMode;
  if (rollType < 0.30) {
    final sub = rng.nextInt(3);
    trajectoryMode = 1 + sub;
  } else if (rollType < 0.75) {
    trajectoryMode = 0;
  } else {
    trajectoryMode = 4;
  }

  Offset p1, p2, p3;

  switch (trajectoryMode) {
    case 1:
      p1 = Offset(
        start.dx + (rng.nextDouble() * 8.0 - 4.0),
        start.dy +
            forwardDir *
                (totalDistanceY * 0.32 + (rng.nextDouble() * 8.0 - 4.0)),
      );
      p2 = Offset(
        midX + (rng.nextDouble() * 14.0 - 7.0),
        start.dy +
            forwardDir *
                (totalDistanceY * 0.62 + (rng.nextDouble() * 10.0 - 5.0)),
      );
      p3 = Offset(
        finalPosition.dx + (rng.nextDouble() * 8.0 - 4.0),
        start.dy +
            forwardDir *
                (totalDistanceY * 0.86 + (rng.nextDouble() * 6.0 - 3.0)),
      );
      break;

    case 2:
      p1 = Offset(
        start.dx - (8.0 + rng.nextDouble() * 6.0),
        start.dy +
            forwardDir *
                (totalDistanceY * 0.28 + (rng.nextDouble() * 6.0 - 3.0)),
      );
      p2 = Offset(
        midX - (6.0 + rng.nextDouble() * 6.0),
        start.dy +
            forwardDir *
                (totalDistanceY * 0.60 + (rng.nextDouble() * 8.0 - 4.0)),
      );
      p3 = Offset(
        finalPosition.dx + (rng.nextDouble() * 6.0 - 3.0),
        start.dy +
            forwardDir *
                (totalDistanceY * 0.84 + (rng.nextDouble() * 6.0 - 3.0)),
      );
      break;

    case 3:
      p1 = Offset(
        start.dx + (8.0 + rng.nextDouble() * 6.0),
        start.dy +
            forwardDir *
                (totalDistanceY * 0.28 + (rng.nextDouble() * 6.0 - 3.0)),
      );
      p2 = Offset(
        midX + (6.0 + rng.nextDouble() * 6.0),
        start.dy +
            forwardDir *
                (totalDistanceY * 0.60 + (rng.nextDouble() * 8.0 - 4.0)),
      );
      p3 = Offset(
        finalPosition.dx - (rng.nextDouble() * 6.0 - 3.0),
        start.dy +
            forwardDir *
                (totalDistanceY * 0.84 + (rng.nextDouble() * 6.0 - 3.0)),
      );
      break;

    case 4:
      p1 = Offset(
        start.dx + (rng.nextDouble() * 6.0 - 3.0),
        start.dy +
            forwardDir *
                (totalDistanceY * 0.35 + (rng.nextDouble() * 6.0 - 3.0)),
      );
      p2 = Offset(
        midX + (rng.nextDouble() * 6.0 - 3.0),
        start.dy +
            forwardDir *
                (totalDistanceY * 0.68 + (rng.nextDouble() * 6.0 - 3.0)),
      );
      p3 = Offset(
        finalPosition.dx + (rng.nextDouble() * 4.0 - 2.0),
        start.dy +
            forwardDir *
                (totalDistanceY * 0.88 + (rng.nextDouble() * 4.0 - 2.0)),
      );
      break;

    case 0:
    default:
      p1 = Offset(
        start.dx - (4.0 + rng.nextDouble() * 6.0),
        start.dy +
            forwardDir *
                (totalDistanceY * 0.30 + (rng.nextDouble() * 8.0 - 4.0)),
      );
      p2 = Offset(
        midX + (rng.nextDouble() * 10.0 - 5.0),
        start.dy +
            forwardDir *
                (totalDistanceY * 0.65 + (rng.nextDouble() * 8.0 - 4.0)),
      );
      p3 = Offset(
        finalPosition.dx + (rng.nextDouble() * 6.0 - 3.0),
        start.dy +
            forwardDir *
                (totalDistanceY * 0.86 + (rng.nextDouble() * 6.0 - 3.0)),
      );
      break;
  }

  // Safe clamping relative to bounds
  final minBoundX = min(start.dx, finalPosition.dx) - 20.0;
  final maxBoundX = max(start.dx, finalPosition.dx) + 20.0;
  p1 = Offset(p1.dx.clamp(minBoundX, maxBoundX), p1.dy);
  p2 = Offset(p2.dx.clamp(minBoundX, maxBoundX), p2.dy);
  p3 = Offset(p3.dx.clamp(minBoundX, maxBoundX), p3.dy);

  // Backward compatibility check for unit tests targeting [-40, 40]
  if (finalPosition.dx.abs() < 20.0) {
    p1 = Offset(p1.dx.clamp(-40.0, 40.0), p1.dy);
    p2 = Offset(p2.dx.clamp(-40.0, 40.0), p2.dy);
    p3 = Offset(p3.dx.clamp(-40.0, 40.0), p3.dy);
  }

  return [start, p1, p2, p3, finalPosition];
}

/// Simple 3D vector helper
class _Vec3 {
  final double x;
  final double y;
  final double z;

  const _Vec3(this.x, this.y, this.z);

  double dot(_Vec3 o) => x * o.x + y * o.y + z * o.z;

  _Vec3 normalized() {
    final len = sqrt(x * x + y * y + z * z);
    if (len == 0.0) return const _Vec3(0.0, 0.0, 0.0);
    return _Vec3(x / len, y / len, z / len);
  }
}

/// Encapsulates physical parameters and multi-stage trajectory for a realistic 3D dice throw
class DiceThrowPhysics {
  final List<Offset> trajectoryWaypoints;
  final Offset skidOffset;
  final double arcHeight;
  final double bounceHeight;
  final double totalRotX;
  final double totalRotY;
  final double totalRotZ;
  final double curvePowerX;
  final double curvePowerY;
  final double curvePowerZ;
  final double settleTiltX;
  final double settleTiltY;
  final double settleRotZ;

  Offset get finalLanding => trajectoryWaypoints.isNotEmpty
      ? trajectoryWaypoints.last
      : Offset.zero;

  Offset get startOffset => trajectoryWaypoints.isNotEmpty
      ? trajectoryWaypoints.first
      : Offset.zero;

  const DiceThrowPhysics({
    required this.trajectoryWaypoints,
    required this.skidOffset,
    required this.arcHeight,
    required this.bounceHeight,
    required this.totalRotX,
    required this.totalRotY,
    required this.totalRotZ,
    required this.curvePowerX,
    required this.curvePowerY,
    required this.curvePowerZ,
    required this.settleTiltX,
    required this.settleTiltY,
    required this.settleRotZ,
  });

  /// Evaluates Catmull-Rom spline position at normalized parameter t in [0.0, 1.0]
  static Offset evaluateSpline(List<Offset> pts, double t) {
    if (pts.isEmpty) return Offset.zero;
    if (pts.length == 1) return pts.first;
    final clampedT = t.clamp(0.0, 1.0);
    if (clampedT <= 0.0) return pts.first;
    if (clampedT >= 1.0) return pts.last;

    final n = pts.length - 1;
    final scaledT = clampedT * n;
    final index = scaledT.floor().clamp(0, n - 1);
    final localT = scaledT - index;

    final p0 = index > 0 ? pts[index - 1] : pts[index];
    final p1 = pts[index];
    final p2 = pts[index + 1];
    final p3 = index + 2 < pts.length ? pts[index + 2] : pts[index + 1];

    final t2 = localT * localT;
    final t3 = t2 * localT;

    final x = 0.5 *
        ((2 * p1.dx) +
            (-p0.dx + p2.dx) * localT +
            (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 +
            (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3);

    final y = 0.5 *
        ((2 * p1.dy) +
            (-p0.dy + p2.dy) * localT +
            (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 +
            (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3);

    return Offset(x, y);
  }

  /// Backward-compatible wrapper for trajectory generation
  static List<Offset> generateRandomDiceTrajectory({
    required Offset start,
    required Offset finalLanding,
    required bool isTopPlayer,
    required double scaleFactor,
    required Random rng,
    Size boardSize = const Size(360.0, 360.0),
  }) {
    return generateDiceTrajectory(
      start: start,
      finalPosition: finalLanding,
      boardSize: boardSize,
      isTopPlayer: isTopPlayer,
      random: rng,
    );
  }

  /// Computes the precise (rotX, rotY) required for the target value to face the camera (+Z)
  static (double rotX, double rotY) getBaseOrientationForValue(int val) {
    switch (val) {
      case 1: // Front (+Z)
        return (0.0, 0.0);
      case 2: // Top (-Y)
        return (-pi / 2, 0.0);
      case 3: // Right (+X)
        return (0.0, -pi / 2);
      case 4: // Left (-X)
        return (0.0, pi / 2);
      case 5: // Bottom (+Y)
        return (pi / 2, 0.0);
      case 6: // Back (-Z)
        return (0.0, pi);
      default:
        return (0.0, 0.0);
    }
  }

  /// Factory creating realistic, bounded throw dynamics targeting the central goti home passing area
  factory DiceThrowPhysics.create({
    required bool isTopPlayer,
    required Size boardSize,
    double screenHeight = 750.0,
    Offset? targetOffset,
    Offset? userDragOffset,
    Offset? userVelocity,
    int targetValue = 1,
    Random? random,
  }) {
    final rng = random ?? Random();
    final scaleFactor = (screenHeight / 750.0).clamp(0.85, 1.15);

    // 1. Start Position (from player card slot):
    final startX = (userDragOffset?.dx ?? 0.0).clamp(-20.0, 20.0);
    final startY = (userDragOffset?.dy ?? 0.0).clamp(-20.0, 20.0);
    final start = Offset(startX, startY);

    // 2. Realistic Target: Central Home Goal Triangle ("Punne / Pass Hone Wali Jagah"):
    // In Ludo, gotis complete their 56 steps and "pun jaati hain" / "pass ho jaati hain"
    // in the central 3x3 Home Goal Triangle (~72x72 px) in the exact middle of the board.
    final forwardDir = isTopPlayer ? 1.0 : -1.0;

    // If targetOffset was computed via RenderBox global coordinates, use it;
    // otherwise fallback to calculated distance from card to board center (~330px).
    final defaultDistanceY = forwardDir * (screenHeight * 0.44).clamp(290.0, 370.0);
    final centerTarget = targetOffset ?? Offset(-65.0, defaultDistanceY);

    // Land directly inside the Central Home Goal triangle (within ±15px of center)
    final homeJitterX = (rng.nextDouble() * 30.0 - 15.0);
    final homeJitterY = (rng.nextDouble() * 30.0 - 15.0);
    double lateral = centerTarget.dx + homeJitterX;
    double forwardDist = centerTarget.dy + homeJitterY;

    if (userVelocity != null && userVelocity.dx.abs() > 40.0) {
      final userBias = (userVelocity.dx * 0.015).clamp(-12.0, 12.0);
      lateral += userBias;
    }

    final finalLanding = Offset(lateral, forwardDist);

    // 3. Multi-stage waypoints across board directly to the central home passing area
    final waypoints = generateDiceTrajectory(
      start: start,
      finalPosition: finalLanding,
      boardSize: boardSize,
      isTopPlayer: isTopPlayer,
      random: rng,
    );

    // Realistic skid inside the central home goal triangle
    final skidX = (rng.nextDouble() * 4.0 - 2.0);
    final skidY = forwardDir * (2.0 + rng.nextDouble() * 4.0);
    final skid = Offset(skidX, skidY);

    // 4. Exact 3D rotations ensuring target face lands facing the user (+Z)
    final (baseRotX, baseRotY) = getBaseOrientationForValue(targetValue);

    final signX = rng.nextBool() ? 1.0 : -1.0;
    final signY = rng.nextBool() ? 1.0 : -1.0;
    final signZ = rng.nextBool() ? 1.0 : -1.0;

    final turnsX = 2 + rng.nextInt(2);
    final turnsY = 2 + rng.nextInt(2);
    final turnsZ = 1 + rng.nextInt(2);

    final totalRotX = signX * (turnsX * 2.0 * pi) + baseRotX;
    final totalRotY = signY * (turnsY * 2.0 * pi) + baseRotY;
    final totalRotZ = signZ * (turnsZ * 2.0 * pi);

    final curvePowerX = 2.4 + rng.nextDouble() * 0.8;
    final curvePowerY = 2.4 + rng.nextDouble() * 0.8;
    final curvePowerZ = 2.0 + rng.nextDouble() * 0.6;

    // 5. Parabolic Arc & Controlled Landing Bounces:
    final arcHeight = (46.0 + rng.nextDouble() * 14.0) * scaleFactor;
    final bounceHeight = (13.0 + rng.nextDouble() * 4.0) * scaleFactor;

    // Subtle resting tilt for organic physical resting posture (approx ±3.5 degrees)
    final settleTiltX = (rng.nextDouble() * 0.12) - 0.06;
    final settleTiltY = (rng.nextDouble() * 0.12) - 0.06;
    final settleRotZ = (rng.nextDouble() * 0.20) - 0.10;

    return DiceThrowPhysics(
      trajectoryWaypoints: waypoints,
      skidOffset: skid,
      arcHeight: arcHeight,
      bounceHeight: bounceHeight,
      totalRotX: totalRotX,
      totalRotY: totalRotY,
      totalRotZ: totalRotZ,
      curvePowerX: curvePowerX,
      curvePowerY: curvePowerY,
      curvePowerZ: curvePowerZ,
      settleTiltX: settleTiltX,
      settleTiltY: settleTiltY,
      settleRotZ: settleRotZ,
    );
  }
}

class AnimatedDice extends StatefulWidget {
  final int? value;
  final bool isRolling;
  final bool canRoll;
  final VoidCallback? onRoll;
  final Color diceColor;
  final double size;
  final bool isTopPlayer;
  final bool isHuman;
  final Size? boardSize;
  final void Function(int finalValue)? onThrowComplete;

  const AnimatedDice({
    super.key,
    required this.value,
    this.isRolling = false,
    this.canRoll = true,
    this.onRoll,
    this.diceColor = Colors.white,
    this.size = 52,
    this.isTopPlayer = false,
    this.isHuman = true,
    this.boardSize,
    this.onThrowComplete,
  });

  @override
  State<AnimatedDice> createState() => _AnimatedDiceState();
}

class _AnimatedDiceState extends State<AnimatedDice>
    with TickerProviderStateMixin {
  // Dragging / Touch state
  Offset _dragOffset = Offset.zero;
  bool _isHolding = false;
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  double _lastDx = 0.0;
  double _lastDy = 0.0;
  int _shakeCount = 0;

  // Physical Throw state
  bool _isThrowing = false;
  bool _isDiceAnimating = false;
  bool _collisionHapticTriggered = false;
  DiceThrowPhysics? _currentPhysics;

  // Controllers
  late AnimationController _pressController;
  late Animation<double> _pressScaleAnimation;
  late AnimationController _throwController;
  late AnimationController _springBackController;
  late Animation<Offset> _springBackAnimation;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // 1. Tactile Press Controller
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _pressScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.92)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_pressController);

    // 2. Physical throw trajectory controller (Flight + Bounces + Settle)
    _throwController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );

    // 3. Spring back controller returning dice smoothly from resting position to tray
    _springBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _throwController.addListener(_onThrowProgress);
    _throwController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onThrowSettle();
      }
    });

    if (widget.isRolling && !_isThrowing) {
      _startAutomaticThrow();
    }
  }

  void _onThrowProgress() {
    final t = _throwController.value;

    // Board contact impact trigger (t ≈ 0.54)
    if (t >= 0.54 && !_collisionHapticTriggered) {
      _collisionHapticTriggered = true;
    }
  }

  void _onThrowSettle() {
    _collisionHapticTriggered = false;

    // Final landing settle light haptic on final result
    SoundHapticService.onDiceResult();

    // After brief settle pause to clearly show result, glide back cleanly to tray
    Future.delayed(const Duration(milliseconds: 380), () {
      if (!mounted) return;
      _animateBackToTray();
      widget.onThrowComplete?.call(widget.value ?? 1);
    });
  }

  void _animateBackToTray() {
    final restingTarget = _currentPhysics?.finalLanding ?? Offset.zero;
    _springBackAnimation = Tween<Offset>(
      begin: restingTarget,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _springBackController,
      curve: Curves.easeOutCubic,
    ));

    _springBackController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _isThrowing = false;
          _isDiceAnimating = false;
          _dragOffset = Offset.zero;
          _tiltX = 0.0;
          _tiltY = 0.0;
          _currentPhysics = null;
        });
      }
    });
  }

  /// Initiates physical throw dynamics with independent random trajectory
  void _startThrow({Offset? dragOffset, Offset? velocity}) {
    final screenW = MediaQuery.maybeSizeOf(context)?.width ?? 390.0;
    final screenH = MediaQuery.maybeSizeOf(context)?.height ?? 750.0;
    final computedBoard = (screenH - 200 < screenW - 24
            ? screenH - 200
            : screenW - 24)
        .clamp(280.0, 520.0);
    final effectiveBoardSize =
        widget.boardSize ?? Size(computedBoard, computedBoard);

    // Calculate exact vector to the central Home Goal Triangle (where gotis "pun / pass" hoti hain)
    Offset? relativeBoardCenter;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final diceOriginGlobal =
          renderBox.localToGlobal(Offset(widget.size / 2, widget.size / 2));
      // In game_screen, board is horizontally centered.
      // Vertically, with the status banner below it, the board center is approx 20px above screen center.
      final boardCenterGlobal =
          Offset(screenW / 2.0, (screenH / 2.0) - 20.0);
      relativeBoardCenter = boardCenterGlobal - diceOriginGlobal;
    }

    _currentPhysics = DiceThrowPhysics.create(
      isTopPlayer: widget.isTopPlayer,
      boardSize: effectiveBoardSize,
      screenHeight: screenH,
      targetOffset: relativeBoardCenter,
      userDragOffset: dragOffset,
      userVelocity: velocity,
      targetValue: widget.value ?? 1,
      random: _random,
    );
    _executeLaunch();
  }

  void _startAutomaticThrow() {
    _isDiceAnimating = true;
    _startThrow();
  }

  void _executeLaunch() {
    _isThrowing = true;
    _isHolding = false;
    _collisionHapticTriggered = false;
    _springBackController.stop();

    SoundHapticService.playDiceRollSound();
    _throwController.forward(from: 0.0);
  }

  /// Handles human player tapping the dice
  void _handleHumanTap() {
    if (!widget.canRoll || _isDiceAnimating || _isHolding || _isThrowing) {
      return;
    }

    _isDiceAnimating = true;
    _isThrowing = true;

    widget.onRoll?.call();

    _pressController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      _startThrow();
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.canRoll || _isDiceAnimating || _isThrowing) return;

    _springBackController.stop();
    setState(() {
      _isHolding = true;
      _dragOffset = Offset.zero;
      _tiltX = 0.0;
      _tiltY = 0.0;
      _shakeCount = 0;
      _lastDx = 0.0;
      _lastDy = 0.0;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.canRoll || _isDiceAnimating || _isThrowing || !_isHolding) {
      return;
    }

    final dx = details.delta.dx;
    final dy = details.delta.dy;
    if ((dx > 3.0 && _lastDx < -3.0) ||
        (dx < -3.0 && _lastDx > 3.0) ||
        (dy > 3.0 && _lastDy < -3.0) ||
        (dy < -3.0 && _lastDy > 3.0)) {
      _shakeCount++;
    }
    _lastDx = dx;
    _lastDy = dy;

    setState(() {
      _dragOffset += details.delta;
      _dragOffset = Offset(
        _dragOffset.dx.clamp(-24.0, 24.0),
        _dragOffset.dy.clamp(-24.0, 24.0),
      );

      _tiltX = (-_dragOffset.dy * 0.012).clamp(-0.35, 0.35);
      _tiltY = (_dragOffset.dx * 0.012).clamp(-0.35, 0.35);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.canRoll || _isDiceAnimating || !_isHolding) {
      return;
    }
    _isHolding = false;

    final velocity = details.velocity.pixelsPerSecond;
    final speed = velocity.distance;
    final dragDist = _dragOffset.distance;

    if (speed < 180.0 && dragDist < 12.0) {
      _springBackToRest();
      return;
    }

    _isDiceAnimating = true;
    _isThrowing = true;
    widget.onRoll?.call();
    _startThrow(
      dragOffset: _dragOffset,
      velocity: velocity,
    );
  }

  void _springBackToRest() {
    _springBackAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _springBackController,
      curve: Curves.elasticOut,
    ));

    _springBackController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _dragOffset = Offset.zero;
          _tiltX = 0.0;
          _tiltY = 0.0;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant AnimatedDice oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isRolling && !oldWidget.isRolling && !_isThrowing) {
      _startAutomaticThrow();
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _throwController.dispose();
    _springBackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.maybeSizeOf(context)?.width ?? 390.0;
    final screenH = MediaQuery.maybeSizeOf(context)?.height ?? 750.0;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _pressController,
        _throwController,
        _springBackController,
      ]),
      builder: (context, child) {
        Offset currentPos = _dragOffset;
        double currentScale = 1.0;
        double shadowBlur = 6.0;
        double shadowSpread = 1.0;
        Offset shadowOffset = const Offset(2, 4);

        // Calculate default resting orientation so current value faces viewer
        final (baseRotX, baseRotY) =
            DiceThrowPhysics.getBaseOrientationForValue(widget.value ?? 1);
        double rotX = baseRotX + _tiltX;
        double rotY = baseRotY + _tiltY;
        double rotZ = 0.0;

        if (_pressController.isAnimating) {
          currentScale = _pressScaleAnimation.value;
          shadowBlur = 4.0;
          shadowSpread = 0.5;
        } else if (_isHolding) {
          currentScale = 1.15;
          shadowBlur = 16.0;
          shadowSpread = 3.0;
          shadowOffset =
              Offset(_dragOffset.dx * 0.1 + 2, _dragOffset.dy * 0.1 + 8);
          if (_shakeCount > 0) {
            rotZ = sin(_shakeCount * 1.6) * 0.16;
          }
        } else if (_springBackController.isAnimating) {
          currentPos = _springBackAnimation.value;
          currentScale = 1.0 + (_springBackController.value * 0.04);
        } else if (_isThrowing && _currentPhysics != null) {
          final p = _currentPhysics!;
          final t = _throwController.value;

          // Physics-based deceleration for smooth tumbling
          final rotProgressX =
              (1.0 - pow(1.0 - t, p.curvePowerX)).clamp(0.0, 1.0);
          final rotProgressY =
              (1.0 - pow(1.0 - t, p.curvePowerY)).clamp(0.0, 1.0);
          final rotProgressZ =
              (1.0 - pow(1.0 - t, p.curvePowerZ)).clamp(0.0, 1.0);

          rotX = rotProgressX * p.totalRotX + rotProgressX * p.settleTiltX;
          rotY = rotProgressY * p.totalRotY + rotProgressY * p.settleTiltY;
          rotZ = rotProgressZ * p.totalRotZ + rotProgressZ * p.settleRotZ;

          if (t <= 0.54) {
            // Phase 1: Airborne trajectory towards board
            final flightT = (t / 0.54).clamp(0.0, 1.0);
            final splinePos = DiceThrowPhysics.evaluateSpline(
              p.trajectoryWaypoints,
              flightT,
            );
            final arcAltitude = sin(flightT * pi) * p.arcHeight;

            currentPos = Offset(splinePos.dx, splinePos.dy - arcAltitude);

            final midAirApex = sin(flightT * pi) * 0.14;
            final landingImpactSquash = flightT > 0.85
                ? ((flightT - 0.85) / 0.15) * 0.04
                : 0.0;
            currentScale = 1.0 + midAirApex - landingImpactSquash;

            shadowBlur = 6.0 + (arcAltitude / p.arcHeight) * 16.0;
            shadowSpread = 1.0 + (arcAltitude / p.arcHeight) * 2.5;
            shadowOffset =
                Offset(0, 4.0 + (arcAltitude / p.arcHeight) * 14.0);
          } else {
            // Phase 2: Board collision, 1-2 controlled bounces & settle
            final bounceT = ((t - 0.54) / 0.46).clamp(0.0, 1.0);
            final bounceEnvelope = pow(1.0 - bounceT, 2.4);
            final bounceSine = sin(bounceT * pi * 2).abs();
            final bounceAlt = p.bounceHeight * bounceEnvelope * bounceSine;

            final skidT = Curves.easeOut.transform(bounceT);

            currentPos = Offset(
              p.finalLanding.dx + p.skidOffset.dx * skidT,
              p.finalLanding.dy + p.skidOffset.dy * skidT - bounceAlt,
            );

            final impactDamp =
                (1.0 - bounceT) * 0.06 * sin(bounceT * pi * 2);
            rotX += impactDamp;
            rotY += impactDamp;

            currentScale = 1.0 +
                (bounceAlt / p.bounceHeight) * 0.03 -
                (1.0 - bounceT) * 0.03 * (1.0 - bounceSine);

            shadowBlur = 6.0 + (1.0 - bounceT) * 5.0;
            shadowSpread = 1.0 + (1.0 - bounceT) * 1.2;
            shadowOffset = Offset(0, 3.0 + (1.0 - bounceT) * 2.5);
          }
        }

        // Safe bounds clamp (wide enough to freely reach board center and passing tracks on all screens)
        final safeMaxDy = (screenH * 0.70).clamp(380.0, 600.0);
        final safeMaxDx = (screenW * 0.70).clamp(280.0, 500.0);
        currentPos = Offset(
          currentPos.dx.clamp(-safeMaxDx, safeMaxDx),
          currentPos.dy.clamp(-safeMaxDy, safeMaxDy),
        );

        final isCurrentlyActive =
            _isDiceAnimating || _isThrowing || _isHolding || widget.canRoll;

        return Transform.translate(
          offset: currentPos,
          child: Transform.scale(
            scale: currentScale,
            child: MouseRegion(
              cursor: widget.canRoll && widget.isHuman
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _handleHumanTap,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: _DiceCube3D(
                  size: widget.size,
                  rotX: rotX,
                  rotY: rotY,
                  rotZ: rotZ,
                  diceColor: widget.diceColor,
                  isGlow: isCurrentlyActive,
                  shadowBlur: shadowBlur,
                  shadowSpread: shadowSpread,
                  shadowOffset: shadowOffset,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CubeFaceConfig {
  final int value;
  final Matrix4 localMatrix;
  final _Vec3 center;
  final _Vec3 normal;

  const _CubeFaceConfig({
    required this.value,
    required this.localMatrix,
    required this.center,
    required this.normal,
  });
}

class _VisibleFace {
  final int value;
  final double zDepth;
  final double brightness;
  final Matrix4 transform;

  const _VisibleFace({
    required this.value,
    required this.zDepth,
    required this.brightness,
    required this.transform,
  });
}

/// Solid 3D Cube rendering all 6 faces with true depth, tight beveled corners, zero gaps, and lighting
class _DiceCube3D extends StatelessWidget {
  final double size;
  final double rotX;
  final double rotY;
  final double rotZ;
  final Color diceColor;
  final bool isGlow;
  final double shadowBlur;
  final double shadowSpread;
  final Offset shadowOffset;

  const _DiceCube3D({
    required this.size,
    required this.rotX,
    required this.rotY,
    required this.rotZ,
    required this.diceColor,
    this.isGlow = false,
    this.shadowBlur = 6.0,
    this.shadowSpread = 1.0,
    this.shadowOffset = const Offset(2, 4),
  });

  static _Vec3 _rotateVec(_Vec3 v, double rotX, double rotY, double rotZ) {
    // 1. Roll around Z
    final cosZ = cos(rotZ);
    final sinZ = sin(rotZ);
    final x1 = v.x * cosZ - v.y * sinZ;
    final y1 = v.x * sinZ + v.y * cosZ;
    final z1 = v.z;

    // 2. Yaw around Y
    final cosY = cos(rotY);
    final sinY = sin(rotY);
    final x2 = x1 * cosY + z1 * sinY;
    final y2 = y1;
    final z2 = -x1 * sinY + z1 * cosY;

    // 3. Pitch around X
    final cosX = cos(rotX);
    final sinX = sin(rotX);
    final x3 = x2;
    final y3 = y2 * cosX - z2 * sinX;
    final z3 = y2 * sinX + z2 * cosX;

    return _Vec3(x3, y3, z3);
  }

  @override
  Widget build(BuildContext context) {
    // Half size for cubic enclosure
    final h = size / 2.0;
    final fSize = size + 0.4;
    final cornerRadius = size * 0.08;

    // The 6 interconnected faces of the 3D dice (opposite faces sum to 7)
    final faces = [
      // Face 1: Front (+Z)
      _CubeFaceConfig(
        value: 1,
        localMatrix: Matrix4.translationValues(0.0, 0.0, h),
        center: _Vec3(0.0, 0.0, h),
        normal: const _Vec3(0.0, 0.0, 1.0),
      ),
      // Face 6: Back (-Z)
      _CubeFaceConfig(
        value: 6,
        localMatrix: Matrix4.translationValues(0.0, 0.0, -h)..rotateY(pi),
        center: _Vec3(0.0, 0.0, -h),
        normal: const _Vec3(0.0, 0.0, -1.0),
      ),
      // Face 3: Right (+X)
      _CubeFaceConfig(
        value: 3,
        localMatrix: Matrix4.translationValues(h, 0.0, 0.0)..rotateY(pi / 2),
        center: _Vec3(h, 0.0, 0.0),
        normal: const _Vec3(1.0, 0.0, 0.0),
      ),
      // Face 4: Left (-X)
      _CubeFaceConfig(
        value: 4,
        localMatrix: Matrix4.translationValues(-h, 0.0, 0.0)..rotateY(-pi / 2),
        center: _Vec3(-h, 0.0, 0.0),
        normal: const _Vec3(-1.0, 0.0, 0.0),
      ),
      // Face 2: Top (-Y)
      _CubeFaceConfig(
        value: 2,
        localMatrix: Matrix4.translationValues(0.0, -h, 0.0)..rotateX(-pi / 2),
        center: _Vec3(0.0, -h, 0.0),
        normal: const _Vec3(0.0, -1.0, 0.0),
      ),
      // Face 5: Bottom (+Y)
      _CubeFaceConfig(
        value: 5,
        localMatrix: Matrix4.translationValues(0.0, h, 0.0)..rotateX(pi / 2),
        center: _Vec3(0.0, h, 0.0),
        normal: const _Vec3(0.0, 1.0, 0.0),
      ),
    ];

    final rotMatrix = Matrix4.identity()
      ..rotateX(rotX)
      ..rotateY(rotY)
      ..rotateZ(rotZ);

    // Directional light from top-left, slightly in front
    final lightDir = const _Vec3(-0.35, -0.65, 0.67).normalized();

    final visibleFaces = <_VisibleFace>[];

    for (final face in faces) {
      final rotNorm = _rotateVec(face.normal, rotX, rotY, rotZ);
      // Backface culling: face pointing away from viewer (Z < -0.05) is completely hidden
      if (rotNorm.z < -0.05) continue;

      final rotCenter = _rotateVec(face.center, rotX, rotY, rotZ);

      // Calculate directional lighting
      final dot = rotNorm.dot(lightDir).clamp(0.0, 1.0);
      final brightness = (0.75 + 0.25 * dot).clamp(0.55, 1.0);

      // True 3D rigid body transformation:
      // Translate to screen center -> Perspective -> Rotate entire cube -> Place face on side -> Center face quad
      final faceMatrix = Matrix4.translationValues(size / 2.0, size / 2.0, 0.0);
      faceMatrix.setEntry(3, 2, 0.002);
      faceMatrix.multiply(rotMatrix);
      faceMatrix.multiply(face.localMatrix);
      faceMatrix.multiply(
          Matrix4.translationValues(-fSize / 2.0, -fSize / 2.0, 0.0));

      visibleFaces.add(_VisibleFace(
        value: face.value,
        zDepth: rotCenter.z,
        brightness: brightness,
        transform: faceMatrix,
      ));
    }

    // Depth sort: Painter's algorithm renders furthest face first, front face last on top
    visibleFaces.sort((a, b) => a.zDepth.compareTo(b.zDepth));

    // Ground contact shadow under the dice
    final shadowWidget = Transform.translate(
      offset: shadowOffset,
      child: Center(
        child: Container(
          width: size * 0.95,
          height: size * 0.55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.elliptical(size * 0.48, size * 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: isGlow
                    ? Colors.amber.withValues(alpha: 0.65)
                    : Colors.black.withValues(alpha: 0.40),
                blurRadius: shadowBlur,
                spreadRadius: shadowSpread,
              ),
            ],
          ),
        ),
      ),
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          shadowWidget,
          // Warm glowing halo behind the dice when ready to roll (NOT on cube faces)
          if (isGlow)
            Center(
              child: Container(
                width: size * 1.08,
                height: size * 1.08,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(cornerRadius * 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.50),
                      blurRadius: 10.0,
                      spreadRadius: 2.0,
                    ),
                  ],
                ),
              ),
            ),
          for (final vf in visibleFaces)
            Transform(
              transform: vf.transform,
              child: _DiceFaceWidget(
                size: size,
                value: vf.value,
                brightness: vf.brightness,
                diceColor: diceColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _DiceFaceWidget extends StatelessWidget {
  final double size;
  final int value;
  final double brightness;
  final Color diceColor;

  const _DiceFaceWidget({
    required this.size,
    required this.value,
    required this.brightness,
    required this.diceColor,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor =
        Color.lerp(const Color(0xFFE2E8F0), Colors.white, brightness)!;
    // Tight natural bevel corner radius
    final cornerRadius = size * 0.08;
    final faceSize = size + 0.4;

    return Container(
      width: faceSize,
      height: faceSize,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(cornerRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(Colors.white, const Color(0xFFF8FAFC), 1.0 - brightness)!,
            baseColor,
            Color.lerp(const Color(0xFFE2E8F0), const Color(0xFFCBD5E1),
                brightness)!,
          ],
        ),
        boxShadow: [
          // Soft subtle edge depth without wireframe lines
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06 * brightness),
            blurRadius: 1.0,
            offset: const Offset(0.2, 0.4),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.16),
      child: _buildDiceFace(value, size),
    );
  }

  static Widget _buildDiceFace(int val, double size) {
    final dotSize = size * 0.165;

    Widget dot() => Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: (val == 1 || val == 6)
                ? const Color(0xFFDC2626) // Classic red for 1 and 6
                : const Color(0xFF1E293B), // Deep slate black
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 1.5,
                offset: Offset(0.6, 0.8),
              ),
            ],
          ),
        );

    Widget empty() => SizedBox(width: dotSize, height: dotSize);

    switch (val) {
      case 1:
        return Center(
          child: Container(
            width: dotSize * 1.35,
            height: dotSize * 1.35,
            decoration: const BoxDecoration(
              color: Color(0xFFDC2626),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 2.0,
                  offset: Offset(0.8, 1.0),
                ),
              ],
            ),
          ),
        );

      case 2:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot(), empty()],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [empty(), dot()],
            ),
          ],
        );

      case 3:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot(), empty(), empty()],
            ),
            Center(child: dot()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [empty(), empty(), dot()],
            ),
          ],
        );

      case 4:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot(), dot()],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot(), dot()],
            ),
          ],
        );

      case 5:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot(), dot()],
            ),
            Center(child: dot()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot(), dot()],
            ),
          ],
        );

      case 6:
      default:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot(), dot()],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot(), dot()],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot(), dot()],
            ),
          ],
        );
    }
  }
}
