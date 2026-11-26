import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/game_state.dart';
import '../../models/online_game_mode.dart';
import '../../models/player_identity.dart';
import '../../services/auth_service.dart';
import '../../services/nearby_matchmaking_service.dart';
import '../game_screen.dart';

/// Screen for location-based nearby player matchmaking in Ludo Supreme.
class NearbyMatchmakingScreen extends StatefulWidget {
  final int entryFee;
  final String gameMode;

  const NearbyMatchmakingScreen({
    super.key,
    this.entryFee = 0,
    this.gameMode = 'twoPlayer',
  });

  @override
  State<NearbyMatchmakingScreen> createState() => _NearbyMatchmakingScreenState();
}

class _NearbyMatchmakingScreenState extends State<NearbyMatchmakingScreen>
    with TickerProviderStateMixin {
  final NearbyMatchmakingService _service = NearbyMatchmakingService.instance;

  late AnimationController _radarController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Timer? _countdownTimer;
  int _countdownSeconds = 3;
  bool _navigated = false;

  String? _myPlayerName;
  String? _myPlayerAvatar;

  static const List<int> _radiusOptions = [1, 5, 10, 25];

  @override
  void initState() {
    super.initState();

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadMyProfile();

    _service.stateNotifier.addListener(_onStateChanged);

    // Auto-request location and start search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startNearbySearch();
      }
    });
  }

  Future<void> _loadMyProfile() async {
    final name = await AuthService.getUserName();
    final avatar = await AuthService.getUserPhotoUrl();
    if (mounted) {
      setState(() {
        _myPlayerName = name;
        _myPlayerAvatar = avatar;
      });
    }
  }

  void _onStateChanged() {
    if (!mounted) return;
    final state = _service.currentState;
    if (state == NearbyMatchmakingState.matchFound && !_navigated) {
      _startCountdownToGame();
    }
  }

  void _startNearbySearch() {
    _service.startSearch(
      radiusKm: _service.selectedRadiusKm,
      entryFee: widget.entryFee,
      gameMode: widget.gameMode,
    );
  }

  void _startCountdownToGame() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}

    _countdownSeconds = 3;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _countdownSeconds--;
      });
      if (_countdownSeconds <= 0) {
        t.cancel();
        _navigateToGameScreen();
      }
    });
  }

  void _navigateToGameScreen() {
    if (_navigated || !mounted) return;
    _navigated = true;

    final match = _service.matchData;
    if (match == null) return;

    final myUid = AuthService.cachedBackendUserId;
    final identity = PlayerIdentity.tryParse(match.you, expectedUserId: myUid);
    final mySeatIndex = identity?.seatIndex ??
        (match.you['seatIndex'] is int ? match.you['seatIndex'] as int : 1);
    final isHost = identity?.isHost ?? (mySeatIndex == 0);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          mode: GameMode.twoPlayer,
          sessionId: match.sessionId.isNotEmpty ? match.sessionId : null,
          roomCode: match.roomCode.isNotEmpty ? match.roomCode : null,
          isOnlineMatch: true,
          isHost: isHost,
          mySeatIndex: mySeatIndex,
          playerIdentity: identity,
          onlineModeType: OnlineModeType.classic,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _service.stateNotifier.removeListener(_onStateChanged);
    _countdownTimer?.cancel();
    _radarController.dispose();
    _pulseController.dispose();
    if (!_navigated) {
      _service.cancelSearch();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B19),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1838),
              Color(0xFF060E22),
              Color(0xFF030712),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ValueListenableBuilder<NearbyMatchmakingState>(
                  valueListenable: _service.stateNotifier,
                  builder: (context, state, _) {
                    switch (state) {
                      case NearbyMatchmakingState.matchFound:
                        return _buildMatchFoundView();
                      case NearbyMatchmakingState.locationDisabled:
                        return _buildLocationDisabledView();
                      case NearbyMatchmakingState.permissionDenied:
                      case NearbyMatchmakingState.permissionPermanentlyDenied:
                        return _buildPermissionDeniedView(
                          permanentlyDenied: state == NearbyMatchmakingState.permissionPermanentlyDenied,
                        );
                      case NearbyMatchmakingState.error:
                        return _buildErrorView();
                      case NearbyMatchmakingState.checkingPermission:
                      case NearbyMatchmakingState.gettingLocation:
                      case NearbyMatchmakingState.searching:
                      case NearbyMatchmakingState.idle:
                        return _buildRadarSearchView();
                    }
                  },
                ),
              ),
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Header
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFFFB300), size: 20),
            onPressed: () {
              _service.cancelSearch();
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.near_me_rounded, color: Colors.black87, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NEARBY PLAYERS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  widget.entryFee > 0
                      ? 'Entry: ₹${widget.entryFee} • Prize: ₹${widget.entryFee * 2}'
                      : 'Free Friendly Match',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Privacy badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_rounded, color: Color(0xFF00E676), size: 14),
                SizedBox(width: 4),
                Text(
                  'Private GPS',
                  style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Radar Search View
  // ---------------------------------------------------------------------------
  Widget _buildRadarSearchView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          // Radius selector
          _buildRadiusSelector(),
          const SizedBox(height: 24),

          // Radar Circle with Rotating Beam
          SizedBox(
            width: 260,
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Radar background grid and sweep
                AnimatedBuilder(
                  animation: _radarController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: const Size(260, 260),
                      painter: _RadarPainter(
                        sweepAngle: _radarController.value * 2 * math.pi,
                        radiusKm: _service.selectedRadiusKm,
                      ),
                    );
                  },
                ),

                // Center glowing user avatar
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF0091EA)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                          blurRadius: 18,
                          spreadRadius: 3,
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: Center(
                      child: ClipOval(
                        child: _myPlayerAvatar != null && _myPlayerAvatar!.isNotEmpty
                            ? Image.network(
                                _myPlayerAvatar!,
                                width: 68,
                                height: 68,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 38,
                                ),
                              )
                            : const Icon(Icons.person, color: Colors.white, size: 38),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Status & Elapsed Time
          ValueListenableBuilder<int>(
            valueListenable: _service.elapsedSecondsNotifier,
            builder: (context, seconds, _) {
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00E676),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Searching nearby (${seconds}s)...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Scanning players within ${_service.selectedRadiusKm} km of your area',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Privacy explanation note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.cyan.shade300, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your exact GPS coordinates are kept private and never shown to opponents.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      height: 1.3,
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

  // ---------------------------------------------------------------------------
  // Radius Selector Pills
  // ---------------------------------------------------------------------------
  Widget _buildRadiusSelector() {
    return ValueListenableBuilder<int>(
      valueListenable: _service.selectedRadiusKmNotifier,
      builder: (context, currentRadius, _) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _radiusOptions.map((r) {
              final isSelected = r == currentRadius;
              return GestureDetector(
                onTap: () {
                  if (_service.currentState == NearbyMatchmakingState.searching) {
                    _service.setRadius(r);
                    _service.startSearch(radiusKm: r, entryFee: widget.entryFee, gameMode: widget.gameMode);
                  } else {
                    _service.setRadius(r);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF0091EA)],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    '$r km',
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Match Found View (VS Screen)
  // ---------------------------------------------------------------------------
  Widget _buildMatchFoundView() {
    final match = _service.matchData;
    final opponent = match?.opponent ?? {};
    final oppName = opponent['name']?.toString() ?? 'Nearby Challenger';
    final oppAvatar = opponent['avatar']?.toString();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00E676)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'NEARBY MATCH FOUND!',
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Two Player Battle Pods
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // You
                _buildPlayerPod(
                  name: _myPlayerName ?? 'YOU',
                  avatarUrl: _myPlayerAvatar,
                  isMe: true,
                  color: const Color(0xFFE53935),
                  tag: 'YOU',
                ),

                // VS Badge
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),

                // Opponent
                _buildPlayerPod(
                  name: oppName,
                  avatarUrl: oppAvatar,
                  isMe: false,
                  color: const Color(0xFF43A047),
                  tag: 'NEARBY',
                ),
              ],
            ),

            const SizedBox(height: 36),

            // Countdown to launch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF0D1B2A)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Text(
                    'Starting Game in $_countdownSeconds...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Setting up Ludo board & colors',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerPod({
    required String name,
    required String? avatarUrl,
    required bool isMe,
    required Color color,
    required String tag,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [color.withValues(alpha: 0.4), color],
                ),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: ClipOval(
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 40,
                          ),
                        )
                      : const Icon(Icons.person, color: Colors.white, size: 40),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 90,
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Location Disabled View
  // ---------------------------------------------------------------------------
  Widget _buildLocationDisabledView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_off_rounded, color: Colors.amber, size: 56),
            ),
            const SizedBox(height: 20),
            const Text(
              'Location Services Disabled',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'To find players near you, please turn on GPS in your device settings.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await _service.openLocationSettings();
              },
              icon: const Icon(Icons.settings, color: Colors.black87),
              label: const Text('Open Location Settings', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _startNearbySearch,
              child: const Text('Retry Search', style: TextStyle(color: Color(0xFF00E5FF))),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Permission Denied View
  // ---------------------------------------------------------------------------
  Widget _buildPermissionDeniedView({required bool permanentlyDenied}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_disabled_rounded, color: Colors.redAccent, size: 56),
            ),
            const SizedBox(height: 20),
            Text(
              permanentlyDenied ? 'Location Permission Denied' : 'Location Required',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              permanentlyDenied
                  ? 'Location permission is permanently denied. Please allow location in your device app settings to find nearby players.'
                  : 'Nearby matchmaking needs device location to discover other players in your radius.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                if (permanentlyDenied) {
                  await _service.openAppSettings();
                } else {
                  _startNearbySearch();
                }
              },
              icon: Icon(permanentlyDenied ? Icons.settings : Icons.lock_open, color: Colors.black87),
              label: Text(
                permanentlyDenied ? 'Open App Settings' : 'Allow Location',
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error View
  // ---------------------------------------------------------------------------
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.radar_rounded, color: Colors.orangeAccent, size: 56),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Nearby Players Found',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _service.errorMessage ?? 'No opponents were discovered within your search radius.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _service.setRadius(25); // Expand radius
                _startNearbySearch();
              },
              icon: const Icon(Icons.zoom_out_map, color: Colors.black87),
              label: const Text('Search Wider (25 km)', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _startNearbySearch,
              child: const Text('Try Again', style: TextStyle(color: Color(0xFF00E5FF))),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Controls
  // ---------------------------------------------------------------------------
  Widget _buildBottomControls() {
    return ValueListenableBuilder<NearbyMatchmakingState>(
      valueListenable: _service.stateNotifier,
      builder: (context, state, _) {
        if (state == NearbyMatchmakingState.matchFound) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _service.cancelSearch();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF5350)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Cancel Search',
                    style: TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for animated radar rings and sweep beam
class _RadarPainter extends CustomPainter {
  final double sweepAngle;
  final int radiusKm;

  _RadarPainter({required this.sweepAngle, required this.radiusKm});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = const Color(0xFF0D1B2A).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius, bgPaint);

    // Concentric grid circles
    final ringPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, (maxRadius / 3) * i, ringPaint);
    }

    // Cross lines
    final linePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), linePaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), linePaint);

    // Rotating Sweep Gradient
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: math.pi / 2,
        colors: [
          const Color(0xFF00E5FF).withValues(alpha: 0.4),
          const Color(0xFF00E5FF).withValues(alpha: 0.0),
        ],
        transform: GradientRotation(sweepAngle),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, maxRadius, sweepPaint);

    // Outer border
    final borderPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, maxRadius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle || oldDelegate.radiusKm != radiusKm;
  }
}
