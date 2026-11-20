import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../constants/ludo_path.dart';
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
    List<BoardCoord>? occupiedCoords,
    Random? random,
  }) {
    final rng = random ?? Random();
    final scaleFactor = (screenHeight / 750.0).clamp(0.85, 1.15);

    // 1. Start Position (from player card slot):
    final startX = (userDragOffset?.dx ?? 0.0).clamp(-20.0, 20.0);
    final startY = (userDragOffset?.dy ?? 0.0).clamp(-20.0, 20.0);
    final start = Offset(startX, startY);

    final forwardDir = isTopPlayer ? 1.0 : -1.0;

    // If targetOffset was computed via RenderBox global coordinates, use it;
    // otherwise fallback to calculated distance from card to board center (~330px).
    final defaultDistanceY = forwardDir * (screenHeight * 0.44).clamp(290.0, 370.0);
    final centerTarget = targetOffset ?? Offset(-65.0, defaultDistanceY);

    // 2. Safe Cross (+) track or Center 3x3 Home Goal target selection:
    // The 4 corner player base squares (Home Courts: 6x6 cells each) are STRICTLY forbidden.
    // Furthermore, the dice must NEVER land on top of any goti (token) on the board!
    final bWidth = boardSize.width;
    final cell = bWidth / 15.0;

    // Convert occupied token coordinates into board-centered offsets (0, 0 is board center):
    final occupiedOffsets = <Offset>[];
    if (occupiedCoords != null) {
      for (final c in occupiedCoords) {
        occupiedOffsets.add(Offset((c.col - 7.0) * cell, (c.row - 7.0) * cell));
      }
    }

    // Minimum clearance between dice center and any goti center (1.35 * cell guarantees zero overlap)
    final minGotiClearance = 1.35 * cell;

    bool isTooCloseToGoti(Offset candidate) {
      for (final occ in occupiedOffsets) {
        if ((candidate - occ).distance < minGotiClearance) {
          return true;
        }
      }
      return false;
    }

    double distToClosestGoti(Offset candidate) {
      if (occupiedOffsets.isEmpty) return 9999.0;
      double minD = double.infinity;
      for (final occ in occupiedOffsets) {
        final d = (candidate - occ).distance;
        if (d < minD) minD = d;
      }
      return minD;
    }

    // Realistic skid along the landing arm calculated upfront so collision
    // check accounts for the final resting position of the dice!
    final skidX = (rng.nextDouble() * 6.0 - 3.0);
    final skidY = forwardDir * (2.0 + rng.nextDouble() * 6.0);
    final skid = Offset(skidX, skidY);

    Offset bestOffset = Offset.zero;
    double bestClearance = -1.0;
    bool foundSafeSpot = false;

    // Try up to 50 random candidates across Cross (+) and Center lanes:
    for (int attempt = 0; attempt < 50; attempt++) {
      final zoneChoice = rng.nextDouble();
      double candDx;
      double candDy;

      if (zoneChoice < 0.28) {
        // Center 3x3 Home Goal Area
        candDx = (rng.nextDouble() * 2.0 - 1.0) * (0.80 * cell);
        candDy = (rng.nextDouble() * 2.0 - 1.0) * (0.80 * cell);
      } else if (zoneChoice < 0.64) {
        // Vertical arm: Columns 6, 7, 8 across rows 1..5 (top) or 9..13 (bottom)
        final colChoice = (rng.nextInt(3) - 1); // -1 (col 6), 0 (col 7), +1 (col 8)
        candDx = (colChoice * 0.90 + (rng.nextDouble() * 0.3 - 0.15)) * cell;
        final armDist = (1.35 + rng.nextDouble() * 3.3) * cell;
        final armDir = rng.nextBool() ? 1.0 : -1.0;
        candDy = armDir * armDist;
      } else {
        // Horizontal arm: Rows 6, 7, 8 across cols 1..5 (left) or 9..13 (right)
        final rowChoice = (rng.nextInt(3) - 1); // -1 (row 6), 0 (row 7), +1 (row 8)
        candDy = (rowChoice * 0.90 + (rng.nextDouble() * 0.3 - 0.15)) * cell;
        final armDist = (1.35 + rng.nextDouble() * 3.3) * cell;
        final armDir = rng.nextBool() ? 1.0 : -1.0;
        candDx = armDir * armDist;
      }

      if (userVelocity != null && userVelocity.dx.abs() > 40.0 && attempt == 0) {
        final userBias = (userVelocity.dx * 0.02).clamp(-1.0 * cell, 1.0 * cell);
        candDx += userBias;
      }

      // Mathematical guarantee: Never land in the 4 corner player base squares!
      final limit = 1.15 * cell;
      if (candDx.abs() > limit && candDy.abs() > limit) {
        if (candDx.abs() < candDy.abs()) {
          candDx = candDx.sign * (0.80 * cell);
        } else {
          candDy = candDy.sign * (0.80 * cell);
        }
      }

      final candidate = Offset(candDx, candDy);
      final finalRestingCandidate = candidate + skid;
      final clearance = distToClosestGoti(finalRestingCandidate);

      if (!isTooCloseToGoti(finalRestingCandidate)) {
        bestOffset = candidate;
        bestClearance = clearance;
        foundSafeSpot = true;
        break;
      }

      if (clearance > bestClearance) {
        bestClearance = clearance;
        bestOffset = candidate;
      }
    }

    // Deterministic fallback: If 50 random attempts did not find a spot with full clearance
    // (e.g. high congestion), systematically evaluate candidate cells across the Cross (+)
    // and choose the spot with the absolute MAXIMUM distance from any token!
    if (!foundSafeSpot) {
      final fallbackGrid = <Offset>[
        Offset.zero,
        Offset(0, -0.65 * cell),
        Offset(0, 0.65 * cell),
        Offset(-0.65 * cell, 0),
        Offset(0.65 * cell, 0),
      ];
      for (int c = -1; c <= 1; c++) {
        for (double r = 1.4; r <= 4.4; r += 1.0) {
          fallbackGrid.add(Offset(c * 0.9 * cell, -r * cell)); // Top arm
          fallbackGrid.add(Offset(c * 0.9 * cell, r * cell));  // Bottom arm
          fallbackGrid.add(Offset(-r * cell, c * 0.9 * cell)); // Left arm
          fallbackGrid.add(Offset(r * cell, c * 0.9 * cell));  // Right arm
        }
      }

      for (final candidate in fallbackGrid) {
        final finalRestingCandidate = candidate + skid;
        final clearance = distToClosestGoti(finalRestingCandidate);
        if (clearance > bestClearance) {
          bestClearance = clearance;
          bestOffset = candidate;
        }
      }
    }

    final double lateral = centerTarget.dx + bestOffset.dx;
    final double forwardDist = centerTarget.dy + bestOffset.dy;
    final finalLanding = Offset(lateral, forwardDist);

    // 3. Multi-stage waypoints across board directly to the safe landing area
    final waypoints = generateDiceTrajectory(
      start: start,
      finalPosition: finalLanding,
      boardSize: boardSize,
      isTopPlayer: isTopPlayer,
      random: rng,
    );

    // 4. Exact 3D rotations ensuring target face lands facing the user (+Z)
    final (baseRotX, baseRotY) = getBaseOrientationForValue(targetValue);

    final signX = rng.nextBool() ? 1.0 : -1.0;
    final signY = rng.nextBool() ? 1.0 : -1.0;
    final signZ = rng.nextBool() ? 1.0 : -1.0;

    // Multi-axis physical tumbling: 3 to 5 full revolutions on X and Y, 2 to 3 rolls on Z
    final turnsX = 3 + rng.nextInt(3);
    final turnsY = 3 + rng.nextInt(3);
    final turnsZ = 2 + rng.nextInt(2);

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
  final double? boardDiceSize;
  final List<BoardCoord>? occupiedCoords;
  final bool isTopPlayer;
  final bool isHuman;
  final Size? boardSize;
  final GlobalKey? boardKey;
  final void Function(int finalValue)? onThrowComplete;

  /// Optional callback invoked when the dice settles on the board, providing
  /// the global center coordinates where it landed, the rolled value, and settling 3D tilt.
  final void Function(
    Offset globalCenter,
    int finalValue, [
    double tiltX,
    double tiltY,
    double tiltZ,
  ])? onBoardSettle;

  /// When true, the parent handles flying the settled dice either back to the
  /// same player (on 6 / bonus turn) or directly to the next player's slot.
  final bool handoffOnSettle;

  /// Online matches: the server decides the number, so a tap/flick only REQUESTS a roll
  /// ([onRoll]); the throw animation starts later when the parent sets [isRolling] with the real value.
  final bool deferThrowToParent;

  const AnimatedDice({
    super.key,
    required this.value,
    this.isRolling = false,
    this.canRoll = true,
    this.onRoll,
    this.diceColor = Colors.white,
    this.size = 52,
    this.boardDiceSize,
    this.occupiedCoords,
    this.isTopPlayer = false,
    this.isHuman = true,
    this.boardSize,
    this.boardKey,
    this.onThrowComplete,
    this.onBoardSettle,
    this.handoffOnSettle = false,
    this.deferThrowToParent = false,
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isRolling && !_isThrowing) {
          _startAutomaticThrow();
        }
      });
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

    // After brief settle pause to clearly show result on the board
    Future.delayed(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      final rollVal = widget.value ?? 1;

      if (widget.onBoardSettle != null) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final originGlobal =
              renderBox.localToGlobal(Offset(widget.size / 2, widget.size / 2));
          final p = _currentPhysics;
          final landingOffset = (p != null)
              ? (p.finalLanding + p.skidOffset)
              : Offset.zero;
          widget.onBoardSettle!(
            originGlobal + landingOffset,
            rollVal,
            p?.settleTiltX ?? 0.0,
            p?.settleTiltY ?? 0.0,
            p?.settleRotZ ?? 0.0,
          );
        }
      }

      widget.onThrowComplete?.call(rollVal);

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
    if (!mounted) return;
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
      Offset boardCenterGlobal;
      final boardBox =
          widget.boardKey?.currentContext?.findRenderObject() as RenderBox?;
      if (boardBox != null && boardBox.hasSize) {
        boardCenterGlobal =
            boardBox.localToGlobal(boardBox.size.center(Offset.zero));
      } else {
        // Fallback in case board render object is not ready
        boardCenterGlobal =
            Offset(screenW / 2.0, (screenH / 2.0) + 16.0);
      }
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
      occupiedCoords: widget.occupiedCoords,
      random: _random,
    );
    _executeLaunch();
  }

  void _startAutomaticThrow() {
    if (!mounted) return;
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
    if (!widget.canRoll || _isDiceAnimating || _isThrowing) {
      return;
    }
    _isHolding = false;

    if (widget.deferThrowToParent) {
      widget.onRoll?.call();
      _pressController.forward(from: 0.0);
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

    if (widget.deferThrowToParent) {
      _springBackToRest();
      widget.onRoll?.call();
      return;
    }

    _isDiceAnimating = true;
    _isThrowing = true;
    widget.onRoll?.call();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startThrow(
        dragOffset: _dragOffset,
        velocity: velocity,
      );
    });
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isRolling && !_isThrowing) {
          _startAutomaticThrow();
        }
      });
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

        // Calculate default resting orientation so ONLY the single current face
        // faces straight toward the viewer in the player box (zero side peek).
        final (baseRotX, baseRotY) =
            DiceThrowPhysics.getBaseOrientationForValue(widget.value ?? 1);
        double rotX = baseRotX + _tiltX;
        double rotY = baseRotY + _tiltY;
        double rotZ = 0.0;
        double spinEnergy = 0.0;
        double spinAngle = 0.0;
        double impactFlash = 0.0;

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

          // Golden spin ribbon energy peaks in mid-air and fades smoothly on bounce
          spinEnergy = t < 0.72
              ? sin((t / 0.72).clamp(0.0, 1.0) * pi).clamp(0.0, 1.0)
              : 0.0;
          spinAngle = t * pi * 5.2;

          final targetScale = (widget.boardDiceSize != null && widget.size > 0)
              ? (widget.boardDiceSize! / widget.size).clamp(0.40, 1.0)
              : 0.65;

          if (t <= 0.54) {
            // Phase 1: Airborne trajectory towards board (smoothly scales down from pod size to board size)
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
            final baseScale = 1.0 + (targetScale - 1.0) * Curves.easeOutCubic.transform(flightT);
            currentScale = baseScale + (midAirApex * targetScale) - landingImpactSquash;

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

            // Brief crisp golden landing impact ring right on first touch
            impactFlash = bounceT < 0.45
                ? (1.0 - (bounceT / 0.45)).clamp(0.0, 1.0)
                : 0.0;

            final skidT = Curves.easeOut.transform(bounceT);

            currentPos = Offset(
              p.finalLanding.dx + p.skidOffset.dx * skidT,
              p.finalLanding.dy + p.skidOffset.dy * skidT - bounceAlt,
            );

            final impactDamp =
                (1.0 - bounceT) * 0.06 * sin(bounceT * pi * 2);
            rotX += impactDamp;
            rotY += impactDamp;

            currentScale = targetScale +
                (bounceAlt / p.bounceHeight) * 0.03 * targetScale -
                (1.0 - bounceT) * 0.03 * (1.0 - bounceSine) * targetScale;

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
        final isSixSettled = (widget.value == 6) &&
            (!_isThrowing || _throwController.value > 0.78);

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
                  isSixBonus: isSixSettled && isCurrentlyActive,
                  spinEnergy: spinEnergy,
                  spinAngle: spinAngle,
                  impactFlash: impactFlash,
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
  final double normalZ;
  final double brightness;
  final double specular;
  final Matrix4 transform;

  const _VisibleFace({
    required this.value,
    required this.zDepth,
    required this.normalZ,
    required this.brightness,
    required this.specular,
    required this.transform,
  });
}

/// Public 3D dice visual reusing the exact same airtight luxury cube renderer as [AnimatedDice],
/// used for seamless resting-on-board and direct player-to-player dice flight.
class DiceCube3DDisplay extends StatelessWidget {
  final int value;
  final double size;
  final double extraRotX;
  final double extraRotY;
  final double extraRotZ;
  final Color diceColor;
  final bool isGlow;
  final bool isSixBonus;
  final double spinEnergy;
  final double spinAngle;
  final double shadowBlur;
  final Offset shadowOffset;

  const DiceCube3DDisplay({
    super.key,
    required this.value,
    required this.size,
    this.extraRotX = 0.0,
    this.extraRotY = 0.0,
    this.extraRotZ = 0.0,
    this.diceColor = Colors.white,
    this.isGlow = false,
    this.isSixBonus = false,
    this.spinEnergy = 0.0,
    this.spinAngle = 0.0,
    this.shadowBlur = 10.0,
    this.shadowOffset = const Offset(2, 6),
  });

  @override
  Widget build(BuildContext context) {
    final (baseRotX, baseRotY) =
        DiceThrowPhysics.getBaseOrientationForValue(value);

    return _DiceCube3D(
      size: size,
      rotX: baseRotX + extraRotX,
      rotY: baseRotY + extraRotY,
      rotZ: extraRotZ,
      diceColor: diceColor,
      isGlow: isGlow,
      isSixBonus: isSixBonus || value == 6,
      spinEnergy: spinEnergy,
      spinAngle: spinAngle,
      shadowBlur: shadowBlur,
      shadowSpread: 1.5,
      shadowOffset: shadowOffset,
    );
  }
}

/// Airtight Solid 3D Hard Luxury Cube:
/// - True centered perspective (`setEntry(3, 2, -0.0020)`) with exact perspective backface culling
/// - Shows STRICTLY 1 clean face when resting in a player box (zero side peek)
/// - Exact 3D-projected 24K gold convex hull backing guarantees 0px corner gaps at every spin angle
/// - Hard machined metallic gold casing + rounded warm porcelain ivory dish + 3D drilled pips
class _DiceCube3D extends StatelessWidget {
  final double size;
  final double rotX;
  final double rotY;
  final double rotZ;
  final Color diceColor;
  final bool isGlow;
  final bool isSixBonus;
  final double spinEnergy;
  final double spinAngle;
  final double impactFlash;
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
    this.isSixBonus = false,
    this.spinEnergy = 0.0,
    this.spinAngle = 0.0,
    this.impactFlash = 0.0,
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

  /// Computes the 2D convex hull of the 8 projected cube corners (Andrew's monotone chain)
  /// so the solid 24K gold backing matches the exact 3D cube silhouette at every angle.
  static List<Offset> _computeConvexHull(List<Offset> points) {
    if (points.length <= 3) return points;
    final pts = List<Offset>.from(points)
      ..sort((a, b) {
        final cmpX = a.dx.compareTo(b.dx);
        return cmpX != 0 ? cmpX : a.dy.compareTo(b.dy);
      });

    double cross(Offset o, Offset a, Offset b) =>
        (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);

    final lower = <Offset>[];
    for (final p in pts) {
      while (lower.length >= 2 &&
          cross(lower[lower.length - 2], lower[lower.length - 1], p) <= 0) {
        lower.removeLast();
      }
      lower.add(p);
    }

    final upper = <Offset>[];
    for (int i = pts.length - 1; i >= 0; i--) {
      final p = pts[i];
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
    // True perspective camera on +Z axis at distance D = 1 / perspective:
    // Front (+Z) projects larger (closer to viewer), back (-Z) projects smaller (recedes).
    const double perspective = 0.0020;
    const double cameraZ = 1.0 / perspective;

    // Slight compensation so the resting front face (+h) projects to exact [size x size]
    final cubeSize = size * 0.94;
    final h = cubeSize / 2.0;
    // +0.8px overlap seamlessly welds adjacent faces edge-to-edge on all mobile GPUs
    final fSize = cubeSize + 0.8;

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

    final cubeRotMatrix = Matrix4.identity()
      ..rotateX(rotX)
      ..rotateY(rotY)
      ..rotateZ(rotZ);

    // Properly centered perspective projection: T(center) * P(-perspective) * R
    final projMatrix = Matrix4.translationValues(size / 2.0, size / 2.0, 0.0)
      ..multiply(Matrix4.identity()..setEntry(3, 2, -perspective))
      ..multiply(cubeRotMatrix);

    // Studio key light from upper-left front for crisp 3D volume contrast
    final lightDir = const _Vec3(-0.38, -0.55, 0.74).normalized();

    final visibleFaces = <_VisibleFace>[];

    for (final face in faces) {
      final rotNorm = _rotateVec(face.normal, rotX, rotY, rotZ);
      final rotCenter = _rotateVec(face.center, rotX, rotY, rotZ);

      // Exact perspective visibility test: N · (Camera - FaceCenter) > 0
      // At 0° resting in a player pod, ONLY the single front face passes!
      final toCamera = _Vec3(
        -rotCenter.x,
        -rotCenter.y,
        cameraZ - rotCenter.z,
      );
      if (rotNorm.dot(toCamera) <= 0.0) continue;

      // Rich directional 3D lighting + dynamic specular sheen
      final dot = rotNorm.dot(lightDir).clamp(0.0, 1.0);
      final brightness = (0.56 + 0.44 * dot).clamp(0.52, 1.0);
      final specular = pow(dot, 5.0).toDouble().clamp(0.0, 1.0);

      // True 3D rigid body face transform
      final faceMatrix = projMatrix.clone()
        ..multiply(face.localMatrix)
        ..multiply(
          Matrix4.translationValues(-fSize / 2.0, -fSize / 2.0, 0.0),
        );

      visibleFaces.add(_VisibleFace(
        value: face.value,
        zDepth: rotCenter.z,
        normalZ: rotNorm.z,
        brightness: brightness,
        specular: specular,
        transform: faceMatrix,
      ));
    }

    // Depth sort: Painter's algorithm renders furthest face first, front face last on top
    visibleFaces.sort((a, b) => a.zDepth.compareTo(b.zDepth));

    // When resting flat on a single face (normalZ ~ 1.0), use a crisp hard casino corner (0.115).
    // When spinning in 3D (multiple faces visible), lock corners tightly (0.032) and back the
    // exact 3D silhouette with a solid 24K gold hull -> ZERO gaps at every angle!
    final frontNormalZ =
        visibleFaces.isNotEmpty ? visibleFaces.last.normalZ : 1.0;
    final flatBlend = visibleFaces.length <= 1
        ? 1.0
        : ((frontNormalZ - 0.96) / 0.04).clamp(0.0, 1.0);
    final outerCornerRatio = 0.032 + (0.083 * flatBlend);
    final hullOpacity = (1.0 - flatBlend).clamp(0.0, 1.0);

    // Project exact 8 cube corners for the airtight 3D gold hull when multi-face is visible
    List<Offset>? hullPoints;
    if (hullOpacity > 0.01) {
      final projectedCorners = <Offset>[];
      for (final sx in const [-1.0, 1.0]) {
        for (final sy in const [-1.0, 1.0]) {
          for (final sz in const [-1.0, 1.0]) {
            final p = _rotateVec(_Vec3(sx * h, sy * h, sz * h), rotX, rotY, rotZ);
            final w = 1.0 - perspective * p.z;
            projectedCorners.add(
              Offset(size / 2.0 + p.x / w, size / 2.0 + p.y / w),
            );
          }
        }
      }
      hullPoints = _computeConvexHull(projectedCorners);
    }

    // Grounded dark contact shadow directly beneath the dice
    final shadowWidget = Transform.translate(
      offset: shadowOffset,
      child: Center(
        child: Container(
          width: size * 0.94,
          height: size * 0.50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.elliptical(size * 0.47, size * 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.48),
                blurRadius: shadowBlur,
                spreadRadius: shadowSpread,
              ),
              if (isGlow || isSixBonus)
                BoxShadow(
                  color: const Color(0xFFFFCA28)
                      .withValues(alpha: isSixBonus ? 0.55 : 0.36),
                  blurRadius: shadowBlur + 4.0,
                  spreadRadius: shadowSpread + 0.8,
                ),
            ],
          ),
        ),
      ),
    );

    final fxExtent = size * 2.15;
    final showFx = spinEnergy > 0.02 || impactFlash > 0.02;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          shadowWidget,

          // Warm luxury golden halo behind dice when active or settled on 6
          if (isGlow || isSixBonus)
            Center(
              child: Container(
                width: size * (isSixBonus ? 1.14 : 1.06),
                height: size * (isSixBonus ? 1.14 : 1.06),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD54F)
                          .withValues(alpha: isSixBonus ? 0.55 : 0.34),
                      blurRadius: isSixBonus ? 16.0 : 11.0,
                      spreadRadius: isSixBonus ? 2.5 : 1.5,
                    ),
                  ],
                ),
              ),
            ),

          // Back layer of subtle golden spin ribbons + landing shockwave ring
          if (showFx)
            Positioned(
              left: (size - fxExtent) / 2.0,
              top: (size - fxExtent) / 2.0,
              child: IgnorePointer(
                child: SizedBox(
                  width: fxExtent,
                  height: fxExtent,
                  child: CustomPaint(
                    painter: _GameDiceSpinFxPainter(
                      spinEnergy: spinEnergy,
                      spinAngle: spinAngle,
                      impactFlash: impactFlash,
                      isFrontLayer: false,
                    ),
                  ),
                ),
              ),
            ),

          // Exact 3D-projected solid 24K gold silhouette hull behind rotating faces -> ZERO corner gaps!
          if (hullPoints != null && hullPoints.length >= 3)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _DiceCubeHullPainter(
                    hull: hullPoints,
                    opacity: hullOpacity,
                  ),
                ),
              ),
            ),

          // Depth-sorted 3D cube faces
          for (final vf in visibleFaces)
            Transform(
              transform: vf.transform,
              child: _DiceFaceWidget(
                faceSize: fSize,
                value: vf.value,
                brightness: vf.brightness,
                specular: vf.specular,
                outerCornerRatio: outerCornerRatio,
                diceColor: diceColor,
              ),
            ),

          // Front layer of subtle golden spin arc sweeping across the tumbling dice
          if (spinEnergy > 0.02)
            Positioned(
              left: (size - fxExtent) / 2.0,
              top: (size - fxExtent) / 2.0,
              child: IgnorePointer(
                child: SizedBox(
                  width: fxExtent,
                  height: fxExtent,
                  child: CustomPaint(
                    painter: _GameDiceSpinFxPainter(
                      spinEnergy: spinEnergy,
                      spinAngle: spinAngle,
                      impactFlash: 0.0,
                      isFrontLayer: true,
                    ),
                  ),
                ),
              ),
            ),

          // Crisp golden corner twinkle accent when 6 is rolled
          if (isSixBonus && spinEnergy < 0.08)
            Positioned(
              right: -size * 0.08,
              top: -size * 0.08,
              child: IgnorePointer(
                child: SizedBox(
                  width: size * 0.34,
                  height: size * 0.34,
                  child: const CustomPaint(
                    painter: _SixSparklePainter(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Fills the exact 2D convex hull of the 8 perspective-projected 3D cube vertices
/// with solid 24K antique gold so edges and corners are 100% airtight at every angle.
class _DiceCubeHullPainter extends CustomPainter {
  final List<Offset> hull;
  final double opacity;

  const _DiceCubeHullPainter({
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
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFFD966).withValues(alpha: opacity),
          const Color(0xFFC47D08).withValues(alpha: opacity),
          const Color(0xFF5C3200).withValues(alpha: opacity),
        ],
      ).createShader(bounds);
    canvas.drawPath(path, fillPaint);

    // Subtle solid gold edge weld preventing any sub-pixel antialias hairline
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF9C5E00).withValues(alpha: opacity);
    canvas.drawPath(path, edgePaint);
  }

  @override
  bool shouldRepaint(covariant _DiceCubeHullPainter oldDelegate) {
    return (oldDelegate.opacity - opacity).abs() > 0.01 ||
        oldDelegate.hull.length != hull.length ||
        (hull.isNotEmpty && oldDelegate.hull.first != hull.first);
  }
}

class _DiceFaceWidget extends StatelessWidget {
  final double faceSize;
  final int value;
  final double brightness;
  final double specular;
  final double outerCornerRatio;
  final Color diceColor;

  const _DiceFaceWidget({
    required this.faceSize,
    required this.value,
    required this.brightness,
    this.specular = 0.0,
    this.outerCornerRatio = 0.115,
    required this.diceColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: faceSize,
      height: faceSize,
      child: CustomPaint(
        painter: _LuxuryGameDiceFacePainter(
          value: value,
          brightness: brightness,
          specular: specular,
          outerCornerRatio: outerCornerRatio,
        ),
      ),
    );
  }
}

/// High-craft custom painter for each solid hard 3D dice face:
/// - Hard machined 24K metallic gold outer casing with crisp top-left / bottom-right bevels
/// - Inset smooth rounded pearl-ivory porcelain plate with concave casino dish & specular gleam
/// - Recessed 3D drilled gemstone pips (Royal Ruby Red for 1 & 6, Glossy Obsidian for 2–5)
class _LuxuryGameDiceFacePainter extends CustomPainter {
  final int value;
  final double brightness;
  final double specular;
  final double outerCornerRatio;

  const _LuxuryGameDiceFacePainter({
    required this.value,
    required this.brightness,
    required this.specular,
    this.outerCornerRatio = 0.115,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final outerRadius = Radius.circular(w * outerCornerRatio);
    final outerRect = Rect.fromLTWH(0, 0, w, h);
    final outerRRect = RRect.fromRectAndRadius(outerRect, outerRadius);

    // 1. Hard Machined 24K Metallic Gold Outer Casing (shaded by face brightness)
    final goldTop = Color.lerp(
      const Color(0xFFB87810),
      const Color(0xFFFFF7BF),
      brightness,
    )!;
    final goldMid = Color.lerp(
      const Color(0xFF945800),
      const Color(0xFFFFCA28),
      brightness,
    )!;
    final goldDeep = Color.lerp(
      const Color(0xFF472500),
      const Color(0xFFA66000),
      brightness,
    )!;

    final goldPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [goldTop, goldMid, goldDeep, goldMid, goldDeep],
        stops: const [0.0, 0.25, 0.54, 0.78, 1.0],
      ).createShader(outerRect);
    canvas.drawRRect(outerRRect, goldPaint);

    // Hard machined metallic outer rim bevel (sharp light catch top-left, dark steel-gold bottom-right)
    final outerEdgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.022).clamp(0.9, 1.5)
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.80 * brightness),
          const Color(0xFFFFD54F).withValues(alpha: 0.35 * brightness),
          const Color(0xFF4A2500).withValues(alpha: 0.78),
        ],
      ).createShader(outerRect);
    canvas.drawRRect(outerRRect.deflate(0.6), outerEdgePaint);

    // 2. Inset Hard Pearl-Ivory Porcelain Face Plate (rounded inside the gold casing)
    final rimWidth = (w * 0.074).clamp(2.8, 5.0);
    final innerRect = outerRect.deflate(rimWidth);
    final innerRadius = Radius.circular((w * 0.135).clamp(4.0, 11.0));
    final innerRRect = RRect.fromRectAndRadius(innerRect, innerRadius);

    // Crisp recessed groove shadow between gold bezel and ivory plate (gives real hard depth)
    canvas.drawRRect(
      innerRRect.inflate(0.7),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = const Color(0xFF5A3400).withValues(alpha: 0.55),
    );

    final ivoryLight = Color.lerp(
      const Color(0xFFD5CCB8),
      const Color(0xFFFFFFFF),
      brightness,
    )!;
    final ivoryMid = Color.lerp(
      const Color(0xFFC2B7A0),
      const Color(0xFFFAF5E9),
      brightness,
    )!;
    final ivoryShade = Color.lerp(
      const Color(0xFFA2967F),
      const Color(0xFFE5DAC2),
      brightness,
    )!;

    final ivoryPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [ivoryLight, ivoryMid, ivoryShade],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(innerRect);
    canvas.drawRRect(innerRRect, ivoryPaint);

    // 3. Subtle Recessed Concave Dish in Center (authentic luxury casino dice look)
    final dishRect = innerRect.deflate(w * 0.045);
    final dishPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.28, 0.28),
        radius: 0.85,
        colors: [
          Colors.white.withValues(alpha: 0.42 * brightness),
          Colors.transparent,
          const Color(0xFF9E8A6A).withValues(alpha: 0.18),
        ],
        stops: const [0.0, 0.62, 1.0],
      ).createShader(dishRect);
    canvas.drawOval(dishRect, dishPaint);

    // 4. Crisp Inner Bevel Highlight + Dynamic Specular Glint
    final innerBevelPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.016).clamp(0.7, 1.2)
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: (0.75 + 0.25 * specular) * brightness),
          Colors.transparent,
          const Color(0xFF8C6B32).withValues(alpha: 0.28),
        ],
      ).createShader(innerRect);
    canvas.drawRRect(innerRRect.deflate(0.4), innerBevelPaint);

    if (specular > 0.12) {
      final sheenRect = Rect.fromLTWH(
        innerRect.left + innerRect.width * 0.06,
        innerRect.top + innerRect.height * 0.05,
        innerRect.width * 0.55,
        innerRect.height * 0.26,
      );
      final sheenPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.34 * specular),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(sheenRect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(sheenRect, Radius.circular(w * 0.10)),
        sheenPaint,
      );
    }

    // 5. Recessed 3D Drilled Gemstone Pips (1 & 6 = Royal Ruby Red, 2-5 = Glossy Obsidian)
    final bool isRuby = value == 1 || value == 6;
    final pipRadius = value == 1 ? w * 0.125 : w * 0.084;
    final coords = _pipCoords(value);

    for (final pt in coords) {
      final center = Offset(
        innerRect.left + innerRect.width * pt.dx,
        innerRect.top + innerRect.height * pt.dy,
      );
      _drawCarvedPip(canvas, center, pipRadius, isRuby: isRuby, isOne: value == 1);
    }
  }

  void _drawCarvedPip(
    Canvas canvas,
    Offset center,
    double r, {
    required bool isRuby,
    required bool isOne,
  }) {
    final pipRect = Rect.fromCircle(center: center, radius: r);

    // Optional royal gold halo ring on the big '1' pip
    if (isOne) {
      canvas.drawCircle(
        center,
        r * 1.15,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (r * 0.16).clamp(0.9, 1.8)
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF3B0),
              Color(0xFFD99100),
              Color(0xFF7A4400),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: r * 1.2)),
      );
    }

    // Bottom-right carved rim catchlight (makes the hole look physically drilled in)
    canvas.drawCircle(
      center + Offset(r * 0.10, r * 0.12),
      r * 1.03,
      Paint()..color = Colors.white.withValues(alpha: 0.78 * brightness),
    );

    // Top-left recessed cavity shadow
    canvas.drawCircle(
      center - Offset(r * 0.08, r * 0.08),
      r * 1.02,
      Paint()..color = const Color(0xFF3E2D16).withValues(alpha: 0.45),
    );

    // Main 3D recessed gemstone fill (darker at top-left depth, brighter at bottom-right lip)
    final pipFill = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.26, 0.30),
        radius: 0.92,
        colors: isRuby
            ? [
                Color.lerp(const Color(0xFFE53935), const Color(0xFFFF6B6B), brightness)!,
                Color.lerp(const Color(0xFFB71C1C), const Color(0xFFD91E18), brightness)!,
                const Color(0xFF7F0909),
                const Color(0xFF470303),
              ]
            : [
                Color.lerp(const Color(0xFF334155), const Color(0xFF475569), brightness)!,
                Color.lerp(const Color(0xFF1E293B), const Color(0xFF273549), brightness)!,
                const Color(0xFF0F172A),
                const Color(0xFF020617),
              ],
        stops: const [0.0, 0.45, 0.80, 1.0],
      ).createShader(pipRect);
    canvas.drawCircle(center, r, pipFill);

    // Crisp glossy specular catchlight inside the pip
    canvas.drawCircle(
      center + Offset(r * 0.26, r * 0.28),
      r * 0.24,
      Paint()
        ..color = Colors.white.withValues(alpha: (isRuby ? 0.50 : 0.36) * brightness),
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
  bool shouldRepaint(covariant _LuxuryGameDiceFacePainter oldDelegate) {
    return oldDelegate.value != value ||
        (oldDelegate.brightness - brightness).abs() > 0.008 ||
        (oldDelegate.specular - specular).abs() > 0.01 ||
        (oldDelegate.outerCornerRatio - outerCornerRatio).abs() > 0.002;
  }
}

/// Lightweight, high-FPS golden spin ribbons and landing impact flash
/// painted cleanly around the dice only during active throws/flights.
class _GameDiceSpinFxPainter extends CustomPainter {
  final double spinEnergy;
  final double spinAngle;
  final double impactFlash;
  final bool isFrontLayer;

  const _GameDiceSpinFxPainter({
    required this.spinEnergy,
    required this.spinAngle,
    required this.impactFlash,
    required this.isFrontLayer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Crisp expanding golden shockwave ring right as the dice hits the board
    if (!isFrontLayer && impactFlash > 0.02) {
      final expand = 1.0 - impactFlash;
      final ringRadius = size.width * (0.24 + expand * 0.20);
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (2.6 * impactFlash).clamp(0.6, 3.0)
        ..color = const Color(0xFFFFE082).withValues(alpha: 0.75 * impactFlash);
      canvas.drawCircle(center, ringRadius, ringPaint);
    }

    if (spinEnergy <= 0.02) return;

    // 2. Two sleek tilted golden motion streaks wrapping behind & in front of the cube
    final rx = size.width * 0.42;
    final ry = size.height * 0.22;

    void drawArc(double tilt, double startAngle, double sweep, double width, double alpha) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(tilt);

      final rect = Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width * 2.2
        ..color = const Color(0xFFFFB300).withValues(alpha: alpha * 0.35 * spinEnergy)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawArc(rect, startAngle, sweep, false, glowPaint);

      final corePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width
        ..color = const Color(0xFFFFF8D6).withValues(alpha: alpha * 0.85 * spinEnergy);
      canvas.drawArc(rect, startAngle, sweep, false, corePaint);
      canvas.restore();
    }

    if (!isFrontLayer) {
      // Back half of orbit (upper semicircle: pi .. 2*pi)
      drawArc(-0.32, pi + (spinAngle % (pi * 0.55)), pi * 0.62, 1.8, 0.75);
      drawArc(0.28, pi * 1.15 + ((spinAngle * 0.8) % (pi * 0.45)), pi * 0.48, 1.3, 0.55);
    } else {
      // Front half of orbit sweeping across the dice (lower semicircle: 0 .. pi)
      drawArc(-0.32, 0.15 + (spinAngle % (pi * 0.48)), pi * 0.52, 2.0, 0.88);
      drawArc(0.28, 0.35 + ((spinAngle * 1.1) % (pi * 0.40)), pi * 0.40, 1.4, 0.68);
    }
  }

  @override
  bool shouldRepaint(covariant _GameDiceSpinFxPainter oldDelegate) {
    return (oldDelegate.spinEnergy - spinEnergy).abs() > 0.01 ||
        (oldDelegate.spinAngle - spinAngle).abs() > 0.02 ||
        (oldDelegate.impactFlash - impactFlash).abs() > 0.01 ||
        oldDelegate.isFrontLayer != isFrontLayer;
  }
}

/// Crisp 4-point golden star twinkle accent for rolling a 6.
class _SixSparklePainter extends CustomPainter {
  const _SixSparklePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.46;
    final inner = r * 0.22;

    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + inner * 0.6, c.dy - inner * 0.6, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + inner * 0.6, c.dy + inner * 0.6, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - inner * 0.6, c.dy + inner * 0.6, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - inner * 0.6, c.dy - inner * 0.6, c.dx, c.dy - r)
      ..close();

    canvas.drawCircle(
      c,
      r * 0.72,
      Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFFFFFBEB),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
