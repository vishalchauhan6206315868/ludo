import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/api_service.dart';
import '../../models/game_state.dart';
import '../../models/online_game_mode.dart';
import '../../models/room_model.dart';
import '../../services/auth_service.dart';
import '../../services/ludo_socket_service.dart';
import '../game_screen.dart';

/// Realtime Online Matchmaking & Room Lobby Screen.
///
/// Features:
/// - Real backend room creation (/api/rooms/create)
/// - Live 6-character room code with Copy & Share
/// - Real-time Socket.IO synchronization (player_joined, match_started)
/// - 2 Player pods (Host & Opponent) with live connection status
/// - 15-second Smart Bot Fallback so players are never left waiting
/// - Seamless handoff to GameScreen with selected OnlineModeType
class OnlineMatchmakingScreen extends StatefulWidget {
  final OnlineGameMode selectedMode;
  final int entryFee;
  final RoomModel? initialRoom;
  final bool isHost;

  const OnlineMatchmakingScreen({
    super.key,
    required this.selectedMode,
    this.entryFee = 100,
    this.initialRoom,
    this.isHost = true,
  });

  @override
  State<OnlineMatchmakingScreen> createState() => _OnlineMatchmakingScreenState();
}

class _OnlineMatchmakingScreenState extends State<OnlineMatchmakingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _searchTimer;
  Timer? _pollTimer;
  int _secondsElapsed = 0;
  String _statusText = "Connecting to matchmaking server...";
  bool _navigatedToGame = false;
  bool _isCopied = false;

  // Real room state
  RoomModel? _currentRoom;
  String? _roomCode;
  String? _opponentName;
  bool _opponentJoined = false;
  int _countdownSeconds = 3;
  Timer? _countdownTimer;

  final List<StreamSubscription<dynamic>> _socketSubs = [];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _currentRoom = widget.initialRoom;
    if (widget.initialRoom != null) {
      _roomCode = widget.initialRoom!.roomCode.toUpperCase();
      if (widget.initialRoom!.players.length >= 2) {
        _opponentJoined = true;
        _opponentName = widget.initialRoom!.players.length > 1
            ? widget.initialRoom!.players[1]
            : "Challenger";
      }
    }

    _startSearchTimer();
    _initializeOnlineLobby();
  }

  void _startSearchTimer() {
    _searchTimer?.cancel();
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_opponentJoined) return;

      setState(() {
        _secondsElapsed++;
        if (_secondsElapsed == 2) {
          _statusText = "Searching for opponents in ${widget.selectedMode.title}...";
        } else if (_secondsElapsed == 6) {
          _statusText = "Room active! Waiting for opponent to join...";
        } else if (_secondsElapsed == 12) {
          _statusText = "Analyzing skill pool & live lobbies...";
        } else if (_secondsElapsed >= 18) {
          _statusText = "Still searching... Share room code or play vs Smart Bot!";
        }
      });
    });
  }

  Future<void> _initializeOnlineLobby() async {
    try {
      // 1. Ensure active backend session
      await AuthService.ensureBackendSession();

      if (widget.isHost && _currentRoom == null) {
        // 2. Call backend /api/rooms/create
        final modeKey = widget.selectedMode.id;
        var response = await ApiService().createRoom(
          maxPlayers: 2,
          gameMode: modeKey,
          entryFee: widget.entryFee,
        );

        // Auto-leave if previously in an active room
        final rawError = response['message']?.toString().toLowerCase() ?? '';
        final oldRoomCode = response['data'] is Map ? response['data']['roomCode']?.toString() : null;
        if ((oldRoomCode != null && oldRoomCode.isNotEmpty) || rawError.contains('already in an active room')) {
          if (oldRoomCode != null && oldRoomCode.isNotEmpty) {
            await ApiService().leaveRoom(roomCode: oldRoomCode);
          }
          response = await ApiService().createRoom(
            maxPlayers: 2,
            gameMode: modeKey,
            entryFee: widget.entryFee,
          );
        }

        if (response['success'] == true && response['data'] != null) {
          final data = response['data'];
          if (data is Map<String, dynamic>) {
            _currentRoom = RoomModel.fromJson(data);
            _roomCode = _currentRoom?.roomCode.toUpperCase();
          }
        }
      }

      // 3. Connect to live Socket.IO channel
      await _setupSocketListeners();

      // 4. Fallback periodic polling every 4 seconds in case WebSocket drops
      _setupFallbackPolling();
    } catch (e) {
      debugPrint("Matchmaking initialization notice: $e");
    } finally {
      if (mounted) {
        setState(() {
          if (_roomCode != null) {
            _statusText = "Room Code: $_roomCode - Waiting for opponent...";
          }
        });
      }
    }
  }

  Future<void> _setupSocketListeners() async {
    if (_roomCode == null || _roomCode!.isEmpty) return;
    final svc = LudoSocketService.instance;
    final connected = await svc.ensureConnected();

    if (connected && mounted) {
      // Join room socket room channel
      await svc.request('join_room', {'roomCode': _roomCode});

      bool forThisRoom(Map<String, dynamic> e) {
        final code = (e['roomCode'] ?? (e['room'] is Map ? e['room']['roomCode'] : null))?.toString().toUpperCase();
        return code == _roomCode;
      }

      // Listen to player_joined event
      _socketSubs.add(svc.on('player_joined').listen((e) {
        if (forThisRoom(e)) {
          _onOpponentJoined(e['player']?['name']?.toString() ?? e['playerName']?.toString());
        }
      }));

      // Listen to room_state event
      _socketSubs.add(svc.on('room_state').listen((e) {
        if (forThisRoom(e)) {
          final roomData = e['room'];
          if (roomData is Map && (roomData['players'] as List?)?.length == 2) {
            final players = roomData['players'] as List;
            final other = players.firstWhere(
              (p) => (p is Map) && p['seatIndex'] != 0,
              orElse: () => null,
            );
            if (other is Map) {
              _onOpponentJoined(other['name']?.toString());
            }
          }
        }
      }));

      // Listen to match_started event
      _socketSubs.add(svc.on('match_started').listen((e) {
        if (forThisRoom(e)) {
          _launchGameSession(e['sessionId']?.toString());
        }
      }));

      // Listen to room_cancelled event
      _socketSubs.add(svc.on('room_cancelled').listen((e) {
        if (forThisRoom(e) && mounted && !_navigatedToGame) {
          _showRoomCancelledAlert();
        }
      }));
    }
  }

  void _setupFallbackPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!mounted || _opponentJoined || _navigatedToGame || _roomCode == null) return;
      try {
        final res = await ApiService().getRoomDetails(roomCode: _roomCode!);
        if (res['success'] == true && res['data'] != null) {
          final room = RoomModel.fromJson(res['data']);
          if (room.players.length >= 2) {
            final opp = room.players.length > 1 ? room.players[1] : "Challenger";
            _onOpponentJoined(opp);
          }
        }
      } catch (_) {}
    });
  }

  void _onOpponentJoined(String? name) {
    if (_opponentJoined || _navigatedToGame || !mounted) return;
    setState(() {
      _opponentJoined = true;
      _opponentName = name ?? "Player 2";
      _statusText = "Opponent Connected! Match starting...";
    });

    HapticFeedback.mediumImpact();

    // Start 3-second visual countdown to launch
    _countdownSeconds = 3;
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
        _launchGameSession(_currentRoom?.sessionId);
      }
    });
  }

  void _launchGameSession(String? sessionId) {
    if (_navigatedToGame || !mounted) return;
    _navigatedToGame = true;

    _searchTimer?.cancel();
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    for (final s in _socketSubs) {
      s.cancel();
    }
    _socketSubs.clear();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          mode: GameMode.twoPlayer,
          sessionId: sessionId,
          roomCode: _roomCode,
          isOnlineMatch: true,
          isHost: widget.isHost,
          mySeatIndex: widget.isHost ? 0 : 1,
          onlineModeType: widget.selectedMode.modeType,
        ),
      ),
    );
  }

  void _playVsSmartBot() {
    if (_navigatedToGame || !mounted) return;
    _navigatedToGame = true;

    _searchTimer?.cancel();
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    for (final s in _socketSubs) {
      s.cancel();
    }
    _socketSubs.clear();

    if (_roomCode != null) {
      ApiService().leaveRoom(roomCode: _roomCode!).catchError((_) => <String, dynamic>{});
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          mode: GameMode.twoPlayer,
          onlineModeType: widget.selectedMode.modeType,
        ),
      ),
    );
  }

  void _copyRoomCode() {
    if (_roomCode == null) return;
    Clipboard.setData(ClipboardData(text: _roomCode!));
    setState(() => _isCopied = true);
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Room code $_roomCode copied! Share with your friend."),
        backgroundColor: const Color(0xFF00C853),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  void _showRoomCancelledAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF10192D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFF5252)),
        ),
        title: const Text("Room Cancelled", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          "The room was cancelled by the host or session timed out.",
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB300)),
            child: const Text("Return to Menu", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchTimer?.cancel();
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    for (final s in _socketSubs) {
      s.cancel();
    }
    super.dispose();
  }

  void _cancelMatchmaking() {
    if (_roomCode != null) {
      ApiService().leaveRoom(roomCode: _roomCode!).catchError((_) => <String, dynamic>{});
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.selectedMode;

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
              // Top Header
              _buildHeader(context),

              // Matchmaking Core Content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Selected Mode Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: LinearGradient(
                              colors: mode.gradientColors,
                            ),
                            border: Border.all(
                              color: const Color(0xFFFFD700),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(mode.icon, color: const Color(0xFFFFD700), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                mode.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Title
                        const Text(
                          "SEARCHING FOR PLAYERS",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                            shadows: [
                              Shadow(
                                color: Color(0x66FFD700),
                                offset: Offset(0, 2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Status Subtitle
                        Text(
                          _statusText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _opponentJoined ? const Color(0xFF00E676) : const Color(0xFF90A4AE),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 22),

                        // 2 Player Pods (Host VS Opponent)
                        _buildPlayerDuelArena(mode),

                        const SizedBox(height: 22),

                        // Live Room Code Capsule (Shareable with friend)
                        if (_roomCode != null) _buildRoomCodeCapsule(),

                        const SizedBox(height: 18),

                        // Search timer & online player stats
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1E3D),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 14,
                            runSpacing: 6,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    color: Color(0xFFFFD700),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Elapsed: ${_secondsElapsed}s",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.monetization_on_rounded,
                                    color: Color(0xFFFFD700),
                                    size: 15,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Entry: ${widget.entryFee}",
                                    style: const TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00E676),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${mode.formattedPlayerCount} in queue",
                                    style: const TextStyle(
                                      color: Color(0xFFB0BEC5),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Smart Bot Fallback Option (Visible after 15s)
                        if (_secondsElapsed >= 15 && !_opponentJoined)
                          _buildSmartBotFallbackCard(),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Cancel Action
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    key: const Key('cancel_matchmaking_button'),
                    onPressed: _cancelMatchmaking,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF8A80),
                      side: BorderSide(
                        color: Colors.redAccent.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "CANCEL MATCHMAKING",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Two Player Pods Arena with VS Emblem
  Widget _buildPlayerDuelArena(OnlineGameMode mode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Player 1 (You)
        _buildPlayerPod(
          name: widget.isHost ? "Host (You)" : "You",
          isReady: true,
          color: const Color(0xFFE53935),
          isPulse: false,
        ),

        const SizedBox(width: 14),

        // Glowing VS Emblem
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFFFFD700), Color(0xFFE65100)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                blurRadius: 12,
              ),
            ],
          ),
          child: const Text(
            "VS",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),

        const SizedBox(width: 14),

        // Player 2 (Opponent or Waiting)
        _buildPlayerPod(
          name: _opponentJoined ? (_opponentName ?? "Opponent") : "Searching...",
          isReady: _opponentJoined,
          color: const Color(0xFF1E88E5),
          isPulse: !_opponentJoined,
        ),
      ],
    );
  }

  Widget _buildPlayerPod({
    required String name,
    required bool isReady,
    required Color color,
    required bool isPulse,
  }) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = isPulse ? _pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0A1838),
                  border: Border.all(
                    color: isReady ? const Color(0xFFFFD700) : Colors.white24,
                    width: 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isReady
                          ? const Color(0xFFFFD700).withValues(alpha: 0.45)
                          : Colors.transparent,
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Center(
                  child: isReady
                      ? Icon(Icons.person_rounded, color: color, size: 40)
                      : const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isReady ? const Color(0xFF00C853) : const Color(0xFF37474F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isReady ? "READY" : "WAITING",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Live Room Code Card with Copy & Share
  Widget _buildRoomCodeCapsule() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1C3C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.65),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.vpn_key_rounded, color: Color(0xFFFFD700), size: 18),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ROOM CODE",
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    _roomCode ?? "...",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _copyRoomCode,
            icon: Icon(_isCopied ? Icons.check_rounded : Icons.copy_rounded, size: 14),
            label: Text(_isCopied ? "COPIED" : "COPY"),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCopied ? const Color(0xFF00C853) : const Color(0xFFFFB300),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  /// Smart Bot Fallback Card when waiting takes longer than 15s
  Widget _buildSmartBotFallbackCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF142448),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFB300),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.smart_toy_rounded, color: Color(0xFFFFD700), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "No live opponent found yet. Play vs Smart Bot?",
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: _playVsSmartBot,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                "PLAY VS SMART BOT (${widget.selectedMode.title})",
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF091530).withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFFFD700).withValues(alpha: 0.2),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('matchmaking_back_button'),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: _cancelMatchmaking,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "ONLINE LOBBY",
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
