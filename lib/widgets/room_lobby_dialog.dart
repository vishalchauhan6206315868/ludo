import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/network/api_service.dart';
import '../models/game_state.dart';
import '../models/room_model.dart';
import '../screens/game_screen.dart';
import '../services/ludo_socket_service.dart';
import 'cancel_room_dialog.dart';

/// Royal 3D Ludo Supreme Room Lobby Dialog
/// Displays the 6-character live Room Code from `/api/rooms/create`
/// Featuring 3D Royal Crown with golden light rays, 3D floating dice,
/// glowing room code capsule, 3-in-1 meta metrics, and themed player slots.
class RoomLobbyDialog extends StatefulWidget {
  final RoomModel room;
  final int entryFee;

  /// Not used any more (the lobby opens the match itself). Kept so existing call sites compile.
  final void Function(String? sessionId)? onStartGame;
  final bool isHost;
  final bool enableSocket;

  const RoomLobbyDialog({
    super.key,
    required this.room,
    this.entryFee = 0,
    this.onStartGame,
    this.isHost = true,
    this.enableSocket = true,
  });

  @override
  State<RoomLobbyDialog> createState() => _RoomLobbyDialogState();
}

class _RoomLobbyDialogState extends State<RoomLobbyDialog>
    with SingleTickerProviderStateMixin {
  bool _isCopied = false;
  Timer? _copyTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late RoomModel _currentRoom;
  final List<StreamSubscription<dynamic>> _subs = [];
  Timer? _fallbackTimer;
  bool _isRefreshing = false;
  bool _isLeaving = false;
  bool _isStartingMatch = false;
  bool _navigated = false;

  String get _code => _currentRoom.roomCode.toUpperCase();

  @override
  void initState() {
    super.initState();
    _currentRoom = widget.room;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.enableSocket) {
      _listenToRoom();
    }

    // The room was already full when we joined: the server created the match for us.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentRoom.hasMatch) _openGame(_currentRoom.sessionId);
    });
  }

  // ---------------------------------------------------------------------------
  // Live events from the server
  // ---------------------------------------------------------------------------
  void _listenToRoom() {
    final svc = LudoSocketService.instance;

    bool forThisRoom(Map<String, dynamic> e) {
      final room = e['room'];
      final code = (e['roomCode'] ?? (room is Map ? room['roomCode'] : null))?.toString().toUpperCase();
      return code == _code;
    }

    for (final event in ['room_state', 'room_created', 'player_joined', 'player_left']) {
      _subs.add(svc.on(event).listen((e) {
        if (forThisRoom(e)) _applyRoomPayload(e['room']);
      }));
    }
    _subs.add(svc.on('match_started').listen((e) {
      if (forThisRoom(e)) _openGame(e['sessionId']?.toString());
    }));
    _subs.add(svc.on('room_cancelled').listen((e) {
      if (forThisRoom(e)) _onRoomCancelled();
    }));

    // connect (if needed), attach to the lobby channel and fetch the latest room
    svc.ensureConnected().then((ok) async {
      if (!ok || !mounted) return;
      final ack = await svc.request('join_room', {'roomCode': _code});
      if (ack.ok) _applyRoomPayload(ack.data['room']);
    });

    // Safety net ONLY while the socket is down (never polls while connected)
    _fallbackTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!svc.isConnected) _fetchRoomUpdate(manual: false);
    });
  }

  void _applyRoomPayload(dynamic raw) {
    if (raw is! Map || !mounted || _navigated) return;
    final updated = RoomModel.fromSocket(Map<String, dynamic>.from(raw), previous: _currentRoom);
    setState(() => _currentRoom = updated);
    if (updated.hasMatch && updated.status.toLowerCase() == 'playing') {
      _openGame(updated.sessionId);
    }
  }

  void _onRoomCancelled() {
    if (_navigated || _isLeaving || !mounted) return;
    _navigated = true;
    _fallbackTimer?.cancel();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text("The host has cancelled this room."),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Replaces this dialog with the game screen (one single route change).
  void _openGame(String? sessionId) {
    if (_navigated || !mounted || _isLeaving) return;
    if (sessionId == null || sessionId.isEmpty) return;
    _navigated = true;
    _fallbackTimer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();

    final room = _currentRoom;
    final mode = room.maxPlayers >= 4
        ? GameMode.fourPlayer
        : (room.maxPlayers == 3 || room.gameMode == 'threePlayer'
            ? GameMode.threePlayer
            : GameMode.twoPlayer);
    final identity = room.identity ?? widget.room.identity;
    final isHost = identity?.isHost ?? widget.isHost;
    final rawSeat = identity?.seatIndex ?? (isHost ? 0 : (widget.room.seatIndex ?? room.seatIndex ?? 1));
    final seat = (!isHost && rawSeat == 0) ? 1 : rawSeat;

    final navigator = Navigator.of(context);
    final route = ModalRoute.of(context);
    if (route != null) {
      navigator.popUntil((r) => r == route); // close anything that is open above the lobby
    }
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          mode: mode,
          sessionId: sessionId,
          roomCode: room.roomCode,
          isOnlineMatch: true,
          isHost: isHost,
          mySeatIndex: seat,
          playerIdentity: identity,
        ),
      ),
    );
  }

  /// Host starts the match before the room is full (only needed for 4-player rooms;
  /// a full room starts by itself).
  Future<void> _handleStartGame() async {
    if (_isStartingMatch) return;
    setState(() => _isStartingMatch = true);
    String? sessionId;
    String? error;

    try {
      final svc = LudoSocketService.instance;
      if (await svc.ensureConnected()) {
        final ack = await svc.startMatch(_code);
        if (ack.ok) {
          sessionId = ack.data['sessionId']?.toString();
        } else if (ack.code != 'NOT_CONNECTED' && ack.code != 'TIMEOUT') {
          error = ack.message;
        }
      }
      if (sessionId == null && error == null) {
        // socket unavailable: same thing over REST
        final res = await ApiService().startGame(roomCode: _code);
        if (res['success'] == true && res['data'] is Map) {
          final data = res['data'] as Map;
          final session = data['session'];
          sessionId = data['sessionId']?.toString() ??
              (session is Map ? (session['_id'] ?? session['id'])?.toString() : null);
        } else {
          error = res['message']?.toString();
        }
      }
    } catch (e) {
      debugPrint("Error starting match: $e");
      error = "Could not start the match. Please try again.";
    }

    if (!mounted) return;
    setState(() => _isStartingMatch = false);

    if (sessionId != null && sessionId.isNotEmpty) {
      _openGame(sessionId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? "Could not start the match. Please try again."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Manual refresh button + fallback while offline.
  Future<void> _fetchRoomUpdate({bool manual = false}) async {
    if (manual) {
      setState(() => _isRefreshing = true);
    }

    try {
      final updated = await ApiService().getRoomModel(roomCode: _currentRoom.roomCode);
      if (!mounted) return;

      if (updated != null) {
        if (updated.status.toLowerCase() == 'cancelled') {
          _onRoomCancelled();
          return;
        }
        setState(() {
          _currentRoom = updated.copyWith(seatIndex: _currentRoom.seatIndex);
          if (manual) _isRefreshing = false;
        });
        if (updated.hasMatch && updated.status.toLowerCase() == 'playing') {
          _openGame(updated.sessionId);
        }
      } else if (manual) {
        setState(() => _isRefreshing = false);
      }
    } catch (_) {
      if (mounted && manual) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  void dispose() {
    _copyTimer?.cancel();
    _fallbackTimer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleLeaveRoom() async {
    if (_isLeaving) return;

    final confirm = await CancelRoomDialog.show(context, isHost: widget.isHost);

    if (confirm != true || !mounted) return;

    setState(() => _isLeaving = true);
    _fallbackTimer?.cancel();

    try {
      final res = await ApiService().leaveRoom(roomCode: _currentRoom.roomCode);
      if (!mounted) return;

      final message = res['message']?.toString() ??
          (widget.isHost ? "Room cancelled successfully" : "Left room successfully");

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: res['success'] == true ? const Color(0xFF0F1B38) : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _copyRoomCode() {
    Clipboard.setData(ClipboardData(text: _currentRoom.roomCode));
    HapticFeedback.mediumImpact();
    setState(() => _isCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
            const SizedBox(width: 8),
            Text(
              "Room Code '${_currentRoom.roomCode}' copied to clipboard!",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F1B38),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    _copyTimer?.cancel();
    _copyTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  static const List<Color> _seatColors = [
    Color(0xFFE53935), // Seat 0: Red
    Color(0xFF43A047), // Seat 1: Green
    Color(0xFFFDD835), // Seat 2: Yellow
    Color(0xFF1E88E5), // Seat 3: Blue
  ];
  static const List<String> _seatColorNames = [
    "Red",
    "Green",
    "Yellow",
    "Blue",
  ];

  @override
  Widget build(BuildContext context) {
    final maxP = widget.room.maxPlayers;
    final isStarting = _currentRoom.status.toLowerCase() == 'starting' ||
        _currentRoom.players.length >= maxP;
    final canHostStartEarly = widget.isHost && _currentRoom.players.length >= 2;
    final canStart =
        (isStarting || canHostStartEarly) && !_isStartingMatch && !_isLeaving;

    return PopScope(
      canPop: !_isLeaving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_isLeaving) {
          _handleLeaveRoom();
        }
      },
      child: MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.85,
        maxScaleFactor: 1.15,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: MediaQuery.sizeOf(context).height * 0.94,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // 1. Top Crown with Sunburst Rays
                Positioned(
                  top: -38,
                  child: CustomPaint(
                    size: const Size(120, 56),
                    painter: _CrownHeaderPainter(),
                  ),
                ),

                // 2. Top-Left Floating 3D Dice
                Positioned(
                  top: -24,
                  left: 6,
                  child: CustomPaint(
                    size: const Size(40, 40),
                    painter: _FloatingDicePainter(rotationAngle: -0.25),
                  ),
                ),

                // 3. Top-Right Floating 3D Dice
                Positioned(
                  top: -24,
                  right: 6,
                  child: CustomPaint(
                    size: const Size(40, 40),
                    painter: _FloatingDicePainter(rotationAngle: 0.3),
                  ),
                ),

                // 4. Main Royal Navy Dialog Card
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0A1838),
                        Color(0xFF060F26),
                        Color(0xFF040A1C),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFF00E5FF), width: 2.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 1,
                      ),
                      const BoxShadow(
                        color: Colors.black87,
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header Ribbon (Fixed at Top)
                        _buildHeaderRibbon(),

                        // Scrollable Body Content
                        Flexible(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Share invitation hint
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.share_rounded,
                                      color: Color(0xFFFFD700),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "Share this Room Code with your friends to join:",
                                          style: const TextStyle(
                                            color: Color(0xFFB0D2FF),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Big Golden 3D Room Code Display Capsule
                                _buildBigGoldenCodeCapsule(),
                                const SizedBox(height: 8),

                                // Tap to copy hint
                                GestureDetector(
                                  onTap: _copyRoomCode,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "👉",
                                            style: TextStyle(
                                              color: _isCopied ? Colors.greenAccent : const Color(0xFFFFD700),
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            _isCopied ? Icons.check_circle_rounded : Icons.touch_app_rounded,
                                            color: _isCopied ? Colors.greenAccent : const Color(0xFFFFD700),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            _isCopied ? "Code Copied!" : "Tap to Copy Code",
                                            style: TextStyle(
                                              color: _isCopied ? Colors.greenAccent : const Color(0xFFFFE082),
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "👈",
                                            style: TextStyle(
                                              color: _isCopied ? Colors.greenAccent : const Color(0xFFFFD700),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // 3-in-1 Room Meta Metrics Bar
                                _buildRoomMetaMetricsBar(maxP),
                                const SizedBox(height: 16),

                                // Players Slot Arena Header
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.group_rounded,
                                      color: Color(0xFFFFD700),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    const Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "Lobby Players:",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "${_currentRoom.players.length}/$maxP Joined",
                                        style: const TextStyle(
                                          color: Color(0xFF00E5FF),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Dynamic Themed Player Slot Cards
                                _buildPlayerSlots(maxP),
                                const SizedBox(height: 18),

                                // Action Buttons (Cancel Room & Waiting/Start)
                                _buildActionButtons(canStart, isStarting, canHostStartEarly, maxP),
                              ],
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
        ),
      ),
    );
  }

  /// Header Ribbon with Yellow Door, 3D Typography, Refresh, and Close Buttons
  Widget _buildHeaderRibbon() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2C6B), Color(0xFF0B1F4A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFF00E5FF), width: 1.4),
        ),
      ),
      child: Row(
        children: [
          // Yellow 3D Door/Room Icon
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFEA79), Color(0xFFFFB300)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Icon(
              Icons.meeting_room_rounded,
              color: Color(0xFF0D1730),
              size: 18,
            ),
          ),
          const SizedBox(width: 8),

          // Title: GAME ROOM CREATED
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.isHost ? "GAME ROOM " : "ROOM ",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFFFFF9D2),
                        Color(0xFFFFDF00),
                        Color(0xFFFFB300),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds),
                    child: Text(
                      widget.isHost ? "CREATED" : "JOINED",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Action Buttons: Refresh & Close
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular Refresh Button
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF13254E),
                  border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFFD700),
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, color: Color(0xFFFFD700), size: 18),
                  tooltip: "Refresh Room Status",
                  onPressed: _isRefreshing ? null : () => _fetchRoomUpdate(manual: true),
                ),
              ),
              const SizedBox(width: 6),

              // Circular Close Button
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF13254E),
                  border: Border.all(color: Colors.white30, width: 1.2),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                  onPressed: _isLeaving ? null : _handleLeaveRoom,
                  tooltip: widget.isHost ? "Cancel Room" : "Leave Room",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Big 3D Golden Room Code Showcase with glowing border
  Widget _buildBigGoldenCodeCapsule() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: GestureDetector(
        onTap: _copyRoomCode,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0F1E44),
                Color(0xFF0B1634),
                Color(0xFF070E22),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD700), width: 2.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                blurRadius: 18,
                spreadRadius: 1,
              ),
              const BoxShadow(
                color: Colors.black87,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFFFFDE7),
                      Color(0xFFFFEA79),
                      Color(0xFFFFB300),
                      Color(0xFFFFA000),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: Text(
                    widget.room.roomCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 7.0,
                      shadows: [
                        Shadow(
                          color: Color(0xFF5E3900),
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // 3D Golden Copy Icon Button
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFEA79), Color(0xFFFFB300)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isCopied ? Icons.check_rounded : Icons.content_copy_rounded,
                    color: _isCopied ? const Color(0xFF007E33) : const Color(0xFF3E2700),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 3-in-1 Room Meta Metrics Bar (Players, Fee, Status)
  Widget _buildRoomMetaMetricsBar(int maxP) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1938),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Players
          _buildMetaPill(
            icon: Icons.people_alt_rounded,
            label: "$maxP Players",
            color: const Color(0xFF00E5FF),
          ),
          Container(width: 1, height: 18, color: Colors.white24),

          // Fee
          _buildMetaPill(
            icon: Icons.monetization_on_rounded,
            label: "Fee: ${_currentRoom.entryFee}",
            color: const Color(0xFFFFD700),
          ),
          Container(width: 1, height: 18, color: Colors.white24),

          // Status
          _buildMetaPill(
            icon: Icons.hourglass_top_rounded,
            label: "Waiting",
            color: const Color(0xFF00E676),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaPill({required IconData icon, required String label, required Color color}) {
    return Flexible(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dynamic Themed Player Slot Cards (Red Host, Green Opponent, etc.)
  Widget _buildPlayerSlots(int maxP) {
    return Row(
      children: List.generate(maxP, (idx) {
        final isHost = idx == 0;
        final hasJoined = isHost ||
            (!widget.isHost && idx == 1) ||
            (idx > 0 && idx < _currentRoom.players.length);

        final seatColor = idx < _seatColors.length
            ? _seatColors[idx]
            : const Color(0xFFFFD700);
        final seatName = idx < _seatColorNames.length
            ? _seatColorNames[idx]
            : "Seat ${idx + 1}";

        // Themed Background Gradient based on seat color
        LinearGradient cardGradient;
        Color borderColor;

        if (idx == 0) {
          // Seat 0: Red Host
          cardGradient = const LinearGradient(
            colors: [Color(0xFF8B0000), Color(0xFF4A0000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );
          borderColor = const Color(0xFFFF1744);
        } else if (idx == 1) {
          // Seat 1: Green Opponent
          cardGradient = const LinearGradient(
            colors: [Color(0xFF006400), Color(0xFF003300)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );
          borderColor = const Color(0xFF00E676);
        } else if (idx == 2) {
          // Seat 2: Yellow
          cardGradient = const LinearGradient(
            colors: [Color(0xFF7A5800), Color(0xFF402E00)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );
          borderColor = const Color(0xFFFFD700);
        } else {
          // Seat 3: Blue
          cardGradient = const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF062254)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );
          borderColor = const Color(0xFF00B0FF);
        }

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              gradient: hasJoined
                  ? cardGradient
                  : const LinearGradient(
                      colors: [Color(0xFF101C38), Color(0xFF0A1224)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasJoined ? borderColor : Colors.white12,
                width: hasJoined ? 1.8 : 1.0,
              ),
              boxShadow: hasJoined
                  ? [
                      BoxShadow(
                        color: borderColor.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar with Badge
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasJoined
                            ? seatColor.withValues(alpha: 0.35)
                            : const Color(0xFF1A2744),
                        border: Border.all(
                          color: hasJoined ? seatColor : Colors.white24,
                          width: 1.8,
                        ),
                      ),
                      child: Icon(
                        hasJoined ? Icons.person_rounded : Icons.person_outline_rounded,
                        color: hasJoined ? Colors.white : Colors.white38,
                        size: 26,
                      ),
                    ),
                    if (hasJoined)
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF00E676),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 11,
                          color: Colors.black,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                // Player Role / Name
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.isHost
                        ? (isHost
                            ? "Host (You)"
                            : (idx < _currentRoom.players.length
                                ? "Player ${idx + 1}"
                                : "Waiting..."))
                        : (idx == 0
                            ? "Host"
                            : (idx == 1
                                ? "You"
                                : (idx < _currentRoom.players.length
                                    ? "Player ${idx + 1}"
                                    : "Waiting..."))),
                    style: TextStyle(
                      color: hasJoined ? Colors.white : Colors.white54,
                      fontSize: 12,
                      fontWeight: hasJoined ? FontWeight.w900 : FontWeight.w500,
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 5),

                // Seat Color Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: seatColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: seatColor, width: 1.0),
                  ),
                  child: Text(
                    seatName,
                    style: TextStyle(
                      color: seatColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Action Buttons (Cancel Room & Waiting/Start)
  Widget _buildActionButtons(bool canStart, bool isStarting, bool canHostStartEarly, int maxP) {
    return Row(
      children: [
        // Cancel Room Button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLeaving ? null : _handleLeaveRoom,
            icon: _isLeaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                  )
                : const Icon(Icons.cancel_rounded, size: 18),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(widget.isHost ? "Cancel Room" : "Leave Room"),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF132247),
              foregroundColor: Colors.white,
              elevation: 4,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Waiting / Start Game Button
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: canStart
                  ? const LinearGradient(
                      colors: [Color(0xFFFFEA79), Color(0xFFFFB300), Color(0xFFFF8F00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF0088CC), Color(0xFF005588)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              boxShadow: [
                BoxShadow(
                  color: canStart
                      ? const Color(0xFFFFD700).withValues(alpha: 0.45)
                      : const Color(0xFF00B0FF).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: canStart ? _handleStartGame : null,
              icon: _isStartingMatch
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                    )
                  : Icon(
                      canStart ? Icons.play_arrow_rounded : Icons.hourglass_top_rounded,
                      size: 18,
                      color: canStart ? const Color(0xFF1A1200) : Colors.white,
                    ),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _isStartingMatch
                      ? "Starting..."
                      : (isStarting
                          ? "Play Match"
                          : (canHostStartEarly
                              ? "Start Now (${_currentRoom.players.length}/$maxP)"
                              : (widget.isHost
                                  ? "Waiting for Players..."
                                  : "Waiting for Host..."))),
                  style: TextStyle(
                    color: canStart ? const Color(0xFF1A1200) : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 3D Golden Crown with Sunburst Rays Header Painter
class _CrownHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.65);

    // 1. Sunburst Light Rays
    final rayPaint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 9; i++) {
      final angle = -math.pi * 0.85 + (i * (math.pi * 0.7 / 8));
      final rayStart = Offset(center.dx + math.cos(angle) * 16, center.dy + math.sin(angle) * 16);
      final rayEnd = Offset(center.dx + math.cos(angle) * 36, center.dy + math.sin(angle) * 36);

      rayPaint.shader = LinearGradient(
        colors: [
          const Color(0xFFFFD700).withValues(alpha: 0.6),
          Colors.transparent,
        ],
      ).createShader(Rect.fromPoints(rayStart, rayEnd));

      canvas.drawLine(rayStart, rayEnd, rayPaint);
    }

    // 2. Crown Ambient Glow
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFB300).withValues(alpha: 0.45),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 28));
    canvas.drawCircle(center, 28, glow);

    // 3. 3D Crown Body
    final crownPath = Path()
      ..moveTo(center.dx - 22, center.dy + 12)
      ..lineTo(center.dx + 22, center.dy + 12)
      ..lineTo(center.dx + 26, center.dy - 10)
      ..lineTo(center.dx + 13, center.dy)
      ..lineTo(center.dx, center.dy - 16)
      ..lineTo(center.dx - 13, center.dy)
      ..lineTo(center.dx - 26, center.dy - 10)
      ..close();

    final crownPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF9D2), Color(0xFFFFD700), Color(0xFFFF8F00), Color(0xFF8C5300)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: 24));
    canvas.drawPath(crownPath, crownPaint);

    // 4. Crown Jewels
    final rubyPaint = Paint()..color = const Color(0xFFFF1744);
    canvas.drawCircle(Offset(center.dx, center.dy - 16), 3.0, rubyPaint);
    canvas.drawCircle(Offset(center.dx - 26, center.dy - 10), 2.5, rubyPaint);
    canvas.drawCircle(Offset(center.dx + 26, center.dy - 10), 2.5, rubyPaint);
    canvas.drawCircle(Offset(center.dx - 13, center.dy), 2.0, Paint()..color = const Color(0xFF00E5FF));
    canvas.drawCircle(Offset(center.dx + 13, center.dy), 2.0, Paint()..color = const Color(0xFF00E5FF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Floating 3D Isometric Dice Painter
class _FloatingDicePainter extends CustomPainter {
  final double rotationAngle;

  _FloatingDicePainter({this.rotationAngle = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.5);
    canvas.rotate(rotationAngle);

    final s = size.width * 0.45;

    // Top Face
    final topFace = Path()
      ..moveTo(0, -s)
      ..lineTo(s, -s * 0.5)
      ..lineTo(0, 0)
      ..lineTo(-s, -s * 0.5)
      ..close();
    canvas.drawPath(topFace, Paint()..color = Colors.white);

    // Left Face
    final leftFace = Path()
      ..moveTo(-s, -s * 0.5)
      ..lineTo(0, 0)
      ..lineTo(0, s)
      ..lineTo(-s, s * 0.5)
      ..close();
    canvas.drawPath(leftFace, Paint()..color = const Color(0xFFD6DBDF));

    // Right Face
    final rightFace = Path()
      ..moveTo(0, 0)
      ..lineTo(s, -s * 0.5)
      ..lineTo(s, s * 0.5)
      ..lineTo(0, s)
      ..close();
    canvas.drawPath(rightFace, Paint()..color = const Color(0xFFAEB6BF));

    // Pips
    final pipPaint = Paint()..color = const Color(0xFF0A1224);
    canvas.drawCircle(Offset(0, -s * 0.5), 2.2, pipPaint);
    canvas.drawCircle(Offset(-s * 0.5, s * 0.1), 1.8, pipPaint);
    canvas.drawCircle(Offset(-s * 0.5, s * 0.35), 1.8, pipPaint);
    canvas.drawCircle(Offset(s * 0.5, s * 0.1), 1.8, pipPaint);
    canvas.drawCircle(Offset(s * 0.5, s * 0.35), 1.8, pipPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
