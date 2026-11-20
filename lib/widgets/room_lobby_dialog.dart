import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/network/api_service.dart';
import '../models/game_state.dart';
import '../models/room_model.dart';
import '../screens/game_screen.dart';
import '../services/ludo_socket_service.dart';

/// Royal Ludo Supreme Room Lobby Dialog
/// Displays the 6-character live Room Code from `/api/rooms/create`
/// Allows one-tap copying, sharing, and viewing waiting slots.
///
/// Live: the server pushes `player_joined` / `match_started` / `room_cancelled` over Socket.IO, so
/// both phones move into the game at the same moment (no polling). When the match starts this
/// dialog replaces itself with the [GameScreen] - exactly ONE route change, so no black screen.
class RoomLobbyDialog extends StatefulWidget {
  final RoomModel room;
  final int entryFee;

  /// Not used any more (the lobby opens the match itself). Kept so existing call sites compile.
  final void Function(String? sessionId)? onStartGame;
  final bool isHost;

  const RoomLobbyDialog({
    super.key,
    required this.room,
    this.entryFee = 0,
    this.onStartGame,
    this.isHost = true,
  });

  @override
  State<RoomLobbyDialog> createState() => _RoomLobbyDialogState();
}

class _RoomLobbyDialogState extends State<RoomLobbyDialog>
    with SingleTickerProviderStateMixin {
  bool _isCopied = false;
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

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _listenToRoom();

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
    final seat = widget.isHost ? 0 : (widget.room.seatIndex ?? room.seatIndex ?? 1);

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
          isHost: widget.isHost,
          mySeatIndex: seat,
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
    _fallbackTimer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleLeaveRoom() async {
    if (_isLeaving) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1B38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
        ),
        title: Text(
          widget.isHost ? "Cancel Room?" : "Leave Room?",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          widget.isHost
              ? "Are you sure you want to cancel this room? All joined players will be removed and entry fees refunded."
              : "Are you sure you want to leave this room?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Stay", style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(widget.isHost ? "Cancel Room" : "Leave"),
          ),
        ],
      ),
    );

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
    Future.delayed(const Duration(seconds: 2), () {
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 440,
              maxHeight: MediaQuery.sizeOf(context).height * 0.90,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF060E22),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFFFD700), width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
                const BoxShadow(
                  color: Colors.black87,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Ribbon (Fixed at Top)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F265C), Color(0xFF091636)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      border: Border(
                        bottom: BorderSide(color: Color(0x4DFFD700), width: 1.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.meeting_room_rounded, color: Color(0xFFFFD700), size: 20),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  widget.isHost ? "GAME ROOM CREATED" : "ROOM JOINED",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                              padding: const EdgeInsets.all(4),
                              icon: _isRefreshing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.amber,
                                      ),
                                    )
                                  : const Icon(Icons.refresh_rounded, color: Colors.amber, size: 20),
                              tooltip: "Refresh Room Status",
                              onPressed: _isRefreshing ? null : () => _fetchRoomUpdate(manual: true),
                            ),
                            IconButton(
                              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                              padding: const EdgeInsets.all(4),
                              icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                              onPressed: _isLeaving ? null : _handleLeaveRoom,
                              splashRadius: 18,
                              tooltip: widget.isHost ? "Cancel Room" : "Leave Room",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Body Content
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Share this Room Code with your friends to join:",
                            style: TextStyle(color: Color(0xFFB0BEC5), fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),

                          // Big Golden Room Code Display
                          ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF14203D),
                              Color(0xFF0D1730),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFFFD700), width: 2.2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.room.roomCode,
                                style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 8.0,
                                  fontFamily: 'Roboto',
                                  shadows: [
                                    Shadow(
                                      color: Colors.black87,
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: _copyRoomCode,
                                tooltip: "Copy Code",
                                icon: Icon(
                                  _isCopied ? Icons.check_circle_rounded : Icons.copy_rounded,
                                  color: _isCopied ? Colors.greenAccent : const Color(0xFFFFD700),
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tap to copy button
                    TextButton.icon(
                      onPressed: _copyRoomCode,
                      icon: Icon(
                        _isCopied ? Icons.check_rounded : Icons.content_copy_rounded,
                        color: _isCopied ? Colors.greenAccent : const Color(0xFFFFD700),
                        size: 15,
                      ),
                      label: Text(
                        _isCopied ? "Code Copied!" : "Tap to Copy Code",
                        style: TextStyle(
                          color: _isCopied ? Colors.greenAccent : const Color(0xFFFFD700),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Room Meta Info (Mode & Entry Fee)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1A33),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetaChip(Icons.people_alt_rounded, "$maxP Players", const Color(0xFF60A5FA)),
                          _buildMetaChip(Icons.monetization_on_rounded, "Fee: ${_currentRoom.entryFee}", const Color(0xFFFFD700)),
                          _buildMetaChip(Icons.shield_rounded, "Waiting", const Color(0xFF4ADE80)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Players Slot Arena
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Lobby Players:",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
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

                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 2),
                            decoration: BoxDecoration(
                              color: hasJoined
                                  ? const Color(0xFF132A5C)
                                  : const Color(0xFF0B1428),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: hasJoined ? seatColor : Colors.white12,
                                width: hasJoined ? 1.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: hasJoined
                                          ? seatColor.withValues(alpha: 0.25)
                                          : const Color(0xFF1E2B4A),
                                      child: Icon(
                                        hasJoined
                                            ? Icons.person_rounded
                                            : Icons.person_outline_rounded,
                                        color: hasJoined
                                            ? seatColor
                                            : Colors.white38,
                                        size: 22,
                                      ),
                                    ),
                                    if (hasJoined)
                                      const CircleAvatar(
                                        radius: 7,
                                        backgroundColor: Colors.greenAccent,
                                        child: Icon(Icons.check,
                                            size: 10, color: Colors.black),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
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
                                    color: hasJoined
                                        ? Colors.white
                                        : Colors.white38,
                                    fontSize: 10.5,
                                    fontWeight: hasJoined
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: seatColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    seatName,
                                    style: TextStyle(
                                      color: seatColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    // Start Game / Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLeaving ? null : _handleLeaveRoom,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              foregroundColor: Colors.white70,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLeaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white70,
                                    ),
                                  )
                                : Text(widget.isHost
                                    ? "Cancel Room"
                                    : "Leave Room"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: canStart ? _handleStartGame : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canStart
                                  ? const Color(0xFFFFD700)
                                  : Colors.white24,
                              foregroundColor: const Color(0xFF060E22),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                            child: _isStartingMatch
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF060E22),
                                    ),
                                  )
                                : Text(
                                    _isStartingMatch
                                        ? "Starting..."
                                        : (isStarting
                                            ? "Play Match"
                                            : (canHostStartEarly
                                                ? "Start Now (${_currentRoom.players.length}/$maxP)"
                                                : (widget.isHost
                                                    ? "Waiting for Players..."
                                                    : "Waiting for Host..."))),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ),
                      ],
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
  ),
);
  }

  Widget _buildMetaChip(IconData icon, String label, Color color) {
    return Flexible(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
