import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/api_service.dart';
import '../../models/game_state.dart';
import '../../models/online_game_mode.dart';
import '../../models/player_identity.dart';
import '../../models/room_model.dart';
import '../../services/auth_service.dart';
import '../../services/ludo_socket_service.dart';
import '../../services/matchmaking_service.dart';
import '../game_screen.dart';
import 'nearby_matchmaking_screen.dart';

/// Realtime 1-Click Online Matchmaking & Duel Lobby Screen.
///
/// Features:
/// - 1-Click automatic pairing across devices (no room code sharing, copying, or typing needed)
/// - Auto-discovers waiting rooms or creates and hosts a room seamlessly
/// - Real-time Socket.IO synchronization (player_joined, match_started)
/// - 2 Player pods (You & Opponent) with live pulse radar animation
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
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _rotateController;
  Timer? _searchTimer;
  Timer? _heartbeatTimer;
  Timer? _pollTimer;
  Timer? _countdownTimer;

  int _secondsElapsed = 0;
  String _statusText = "Connecting to matchmaking server...";
  bool _navigatedToGame = false;

  // Real room state
  RoomModel? _currentRoom;
  PlayerIdentity? _localPlayerIdentity;
  String? _roomCode;
  String? _sessionId;
  bool _isStartingMatch = false;
  bool _isHost = true;
  int? _assignedSeatIndex;
  String? _opponentName;
  bool _opponentJoined = false;
  int _countdownSeconds = 3;

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

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _currentRoom = widget.initialRoom;
    _localPlayerIdentity = widget.initialRoom?.identity;
    if (_localPlayerIdentity != null) {
      _assignedSeatIndex = _localPlayerIdentity!.seatIndex;
      _isHost = _localPlayerIdentity!.isHost;
    } else {
      _assignedSeatIndex = widget.initialRoom?.seatIndex;
      if (_assignedSeatIndex != null) {
        _isHost = (_assignedSeatIndex == 0);
      } else {
        _isHost = widget.isHost;
      }
    }
    _sessionId = widget.initialRoom?.sessionId;
    if (widget.initialRoom != null) {
      _roomCode = widget.initialRoom!.roomCode.toUpperCase();
      if (widget.initialRoom!.players.length >= 2) {
        _opponentJoined = true;
        _opponentName = widget.isHost
            ? (widget.initialRoom!.players.length > 1
                ? widget.initialRoom!.players[1]
                : "Challenger")
            : (widget.initialRoom!.players.isNotEmpty
                ? widget.initialRoom!.players[0]
                : "Host");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _onOpponentJoined(_opponentName);
          }
        });
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
        if (_secondsElapsed <= 2) {
          _statusText = "Connecting to matchmaking server...";
        } else if (_secondsElapsed <= 6) {
          _statusText = "Searching for online opponent in ${widget.selectedMode.title}...";
        } else if (_secondsElapsed <= 12) {
          _statusText = "Scanning active lobbies & player queue...";
        } else if (_secondsElapsed < 15) {
          _statusText = "Finding best match for your rank...";
        } else {
          _statusText = "Still searching... Play vs Smart Bot or keep waiting";
        }
      });
    });
  }

  Future<void> _initializeOnlineLobby() async {
    try {
      // 1. Ensure active backend session
      await AuthService.ensureBackendSession();

      if (_currentRoom == null) {
        setState(() {
          _statusText = "Searching for live opponent in ${widget.selectedMode.title}...";
        });

        // 2. Automated 1-click matchmaking: find open room or create as host
        final result = await MatchmakingService.instance.findOrHostMatch(
          mode: widget.selectedMode,
          entryFee: widget.entryFee,
        );

        if (result != null) {
          _currentRoom = result.room;
          _roomCode = result.room.roomCode.toUpperCase();
          _localPlayerIdentity = result.identity ?? result.room.identity;
          if (_localPlayerIdentity != null) {
            _assignedSeatIndex = _localPlayerIdentity!.seatIndex;
            _isHost = _localPlayerIdentity!.isHost;
          } else {
            _isHost = result.isHost;
            _assignedSeatIndex = result.isHost ? 0 : (result.room.seatIndex ?? 1);
          }

          // If we joined an already waiting host, trigger opponent joined right away
          if (!_isHost && result.room.players.isNotEmpty) {
            final hostPlayer = result.room.players[0];
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _onOpponentJoined(hostPlayer);
            });
          } else if (_isHost) {
            // As host, keep heartbeat alive while waiting
            _startHostHeartbeat();
          }
        }
      }

      // 3. Connect to live Socket.IO channel
      await _setupSocketListeners();

      // 4. Fallback periodic polling every 2 seconds in case WebSocket drops
      _setupFallbackPolling();
    } catch (e) {
      debugPrint("Matchmaking initialization notice: $e");
    }
  }

  void _startHostHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || _opponentJoined || _navigatedToGame || _roomCode == null || !_isHost) {
        timer.cancel();
        return;
      }
      final myUid = await AuthService.getUserUid() ?? (await AuthService.getUserEmail());
      MatchmakingService.instance.announceHeartbeat(
        mode: widget.selectedMode,
        roomCode: _roomCode!,
        hostId: myUid,
      );

      // If waiting for more than 3 seconds without an opponent, check if another player is hosting
      // and merge into their room to eliminate any race condition between simultaneous clicks
      if (_secondsElapsed >= 3 && !_opponentJoined) {
        final otherRoom = await MatchmakingService.instance.findWaitingRoomCode(
          mode: widget.selectedMode,
          myUid: myUid,
        );
        if (otherRoom != null && otherRoom != _roomCode && mounted && !_opponentJoined) {
          final oldRoom = _roomCode;
          final joinRes = await ApiService().joinRoom(roomCode: otherRoom);
          final msg = joinRes['message']?.toString().toLowerCase() ?? '';
          if (joinRes['success'] == true &&
              joinRes['data'] != null &&
              !msg.contains('already in this room')) {
            final room = RoomModel.fromJson(joinRes['data']);
            if (oldRoom != null) {
              ApiService().leaveRoom(roomCode: oldRoom).catchError((_) => <String, dynamic>{});
              MatchmakingService.instance.announceCancelled(
                mode: widget.selectedMode,
                roomCode: oldRoom,
              );
            }
            _currentRoom = room;
            _roomCode = room.roomCode.toUpperCase();
            _localPlayerIdentity = room.identity ??
                PlayerIdentity.tryParse(joinRes['player'] ?? joinRes['me'] ?? joinRes['data']);
            if (_localPlayerIdentity != null) {
              _isHost = _localPlayerIdentity!.isHost;
              _assignedSeatIndex = _localPlayerIdentity!.seatIndex;
            } else {
              _isHost = false;
              _assignedSeatIndex = room.seatIndex ?? 1;
            }
            timer.cancel();
            _setupSocketListeners();
            final hostPlayer = room.players.isNotEmpty ? room.players[0] : "Host";
            _onOpponentJoined(hostPlayer);
            MatchmakingService.instance.announceClaimed(
              mode: widget.selectedMode,
              roomCode: _roomCode!,
            );
          }
        }
      }
    });
  }

  Future<void> _setupSocketListeners() async {
    if (_roomCode == null || _roomCode!.isEmpty) return;
    final svc = LudoSocketService.instance;
    final connected = await svc.ensureConnected();

    if (connected && mounted) {
      // Join room socket channel
      await svc.request('join_room', {'roomCode': _roomCode});

      bool forThisRoom(Map<String, dynamic> e) {
        final code = (e['roomCode'] ?? (e['room'] is Map ? e['room']['roomCode'] : null))
            ?.toString()
            .toUpperCase();
        return code == _roomCode;
      }

      // Listen to player_joined event
      _socketSubs.add(svc.on('player_joined').listen((e) {
        if (forThisRoom(e)) {
          final name = e['player']?['name']?.toString() ??
              e['playerName']?.toString() ??
              (e['player'] is String ? e['player'].toString() : null);
          _onOpponentJoined(name ?? "Challenger");
        }
      }));

      // Listen to room_state event
      _socketSubs.add(svc.on('room_state').listen((e) {
        if (forThisRoom(e)) {
          final roomData = e['room'];
          if (roomData is Map && (roomData['players'] as List?)?.length == 2) {
            final players = roomData['players'] as List;
            final mySeat = _isHost ? 0 : 1;
            final other = players.firstWhere(
              (p) => (p is Map) && p['seatIndex'] != mySeat,
              orElse: () => null,
            );
            if (other is Map) {
              _onOpponentJoined(other['name']?.toString() ?? "Challenger");
            }
          }
        }
      }));

      // Listen to match_started and game_started event
      void handleMatchStarted(Map<String, dynamic> e) {
        if (forThisRoom(e)) {
          final sid = e['sessionId']?.toString() ?? e['matchId']?.toString() ?? e['gameId']?.toString();
          if (sid != null && sid.isNotEmpty) {
            _sessionId = sid;
          }
          final me = e['me'] ?? e['you'] ?? e['state']?['me'] ?? e['session']?['me'];
          final myUid = AuthService.cachedBackendUserId;
          final parsed = PlayerIdentity.tryParse(e, expectedUserId: myUid) ??
              PlayerIdentity.tryParse(me, expectedUserId: myUid);
          if (parsed != null) {
            _localPlayerIdentity = parsed;
            _assignedSeatIndex = parsed.seatIndex;
            _isHost = parsed.isHost;
          } else {
            int? seat = (e['seatIndex'] as num?)?.toInt();
            if (seat == null && me is Map) {
              seat = (me['seatIndex'] as num?)?.toInt();
            }
            if (seat == null) {
              final players = e['state']?['players'] ?? e['session']?['players'];
              if (players is List && myUid != null && myUid.isNotEmpty) {
                for (final p in players) {
                  if (p is Map && (p['userId']?.toString() == myUid || p['id']?.toString() == myUid)) {
                    seat = (p['seatIndex'] as num?)?.toInt();
                    break;
                  }
                }
              }
            }
            if (seat != null) {
              _assignedSeatIndex = seat;
              _isHost = (seat == 0);
            }
          }
          _launchGameSession(_sessionId);
        }
      }
      _socketSubs.add(svc.on('match_started').listen(handleMatchStarted));
      _socketSubs.add(svc.on('game_started').listen(handleMatchStarted));

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
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted || _opponentJoined || _navigatedToGame || _roomCode == null) return;
      try {
        final res = await ApiService().getRoomDetails(roomCode: _roomCode!);
        if (res['success'] == true && res['data'] != null) {
          final room = RoomModel.fromJson(res['data']);
          if (room.players.length >= 2) {
            final opp = _isHost
                ? (room.players.length > 1 ? room.players[1] : "Challenger")
                : (room.players.isNotEmpty ? room.players[0] : "Host");
            _onOpponentJoined(opp);
          }
        }
      } catch (_) {}
    });
  }

  void _onOpponentJoined(String? name) {
    if (_opponentJoined || _navigatedToGame || !mounted) return;

    _heartbeatTimer?.cancel();
    if (_roomCode != null) {
      MatchmakingService.instance.announceClaimed(
        mode: widget.selectedMode,
        roomCode: _roomCode!,
      );
    }

    setState(() {
      _opponentJoined = true;
      _opponentName = name ?? (_isHost ? "Challenger" : "Host");
      _statusText = "Opponent Found! Match starting in $_countdownSeconds...";
    });

    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    // If host, immediately request backend to start the game session
    if (_isHost) {
      _triggerMatchStart();
    }

    // Start 3-second visual countdown to launch
    _countdownSeconds = 3;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _countdownSeconds--;
        if (_countdownSeconds > 0) {
          _statusText = "Opponent Found! Match starting in $_countdownSeconds...";
        } else {
          _statusText = "Match Launching...";
        }
      });
      if (_countdownSeconds <= 0) {
        t.cancel();
        if (_sessionId != null && _sessionId!.isNotEmpty) {
          _launchGameSession(_sessionId);
        } else {
          _fetchAndLaunchMatch();
        }
      }
    });
  }

  Future<void> _triggerMatchStart() async {
    if (_roomCode == null || _isStartingMatch || _navigatedToGame) return;
    _isStartingMatch = true;
    try {
      final svc = LudoSocketService.instance;
      String? sid;
      final myUid = AuthService.cachedBackendUserId;
      if (await svc.ensureConnected()) {
        final ack = await svc.startMatch(_roomCode!);
        if (ack.ok) {
          sid = ack.data['sessionId']?.toString();
          final identity = PlayerIdentity.tryParse(ack.data, expectedUserId: myUid) ??
              PlayerIdentity.tryParse(ack.data['me'], expectedUserId: myUid);
          if (identity != null) {
            _localPlayerIdentity = identity;
            _assignedSeatIndex = identity.seatIndex;
            _isHost = identity.isHost;
          } else {
            final me = ack.data['me'] ?? ack.data['you'];
            final seat = (ack.data['seatIndex'] ?? (me is Map ? me['seatIndex'] : null)) as num?;
            if (seat != null) {
              _assignedSeatIndex = seat.toInt();
              _isHost = (_assignedSeatIndex == 0);
            }
          }
        }
      }
      if (sid == null || sid.isEmpty) {
        final res = await ApiService().startGame(roomCode: _roomCode!);
        if (res['success'] == true && res['data'] is Map) {
          final data = res['data'] as Map;
          final session = data['session'];
          sid = data['sessionId']?.toString() ??
              (session is Map ? (session['_id'] ?? session['id'])?.toString() : null);
          final identity = PlayerIdentity.tryParse(data, expectedUserId: myUid) ??
              PlayerIdentity.tryParse(data['me'], expectedUserId: myUid) ??
              PlayerIdentity.tryParse(data['player'], expectedUserId: myUid);
          if (identity != null) {
            _localPlayerIdentity = identity;
            _assignedSeatIndex = identity.seatIndex;
            _isHost = identity.isHost;
          } else {
            final seat = (data['seatIndex'] as num?)?.toInt();
            if (seat != null) {
              _assignedSeatIndex = seat;
              _isHost = (seat == 0);
            }
          }
        }
      }
      if (sid != null && sid.isNotEmpty) {
        _sessionId = sid;
      }
    } catch (e) {
      debugPrint("Error starting match: $e");
    } finally {
      _isStartingMatch = false;
    }
  }

  Future<void> _fetchAndLaunchMatch() async {
    if (_navigatedToGame || !mounted || _roomCode == null) return;
    try {
      final res = await ApiService().startGame(roomCode: _roomCode!);
      if (res['success'] == true && res['data'] is Map) {
        final data = res['data'] as Map;
        final session = data['session'];
        _sessionId = data['sessionId']?.toString() ??
            (session is Map ? (session['_id'] ?? session['id'])?.toString() : null);
        final myUid = AuthService.cachedBackendUserId;
        final identity = PlayerIdentity.tryParse(data, expectedUserId: myUid) ??
            PlayerIdentity.tryParse(data['me'], expectedUserId: myUid) ??
            PlayerIdentity.tryParse(data['player'], expectedUserId: myUid);
        if (identity != null) {
          _localPlayerIdentity = identity;
          _assignedSeatIndex = identity.seatIndex;
          _isHost = identity.isHost;
        }
      }
      if (_sessionId == null || _sessionId!.isEmpty) {
        final roomRes = await ApiService().getRoomDetails(roomCode: _roomCode!);
        if (roomRes['success'] == true && roomRes['data'] is Map) {
          final r = RoomModel.fromJson(roomRes['data']);
          _sessionId = r.sessionId;
          if (r.identity != null) {
            _localPlayerIdentity = r.identity;
            _assignedSeatIndex = r.identity!.seatIndex;
            _isHost = r.identity!.isHost;
          }
        }
      }
    } catch (e) {
      debugPrint("Fetch match error: $e");
    }
    _launchGameSession(_sessionId);
  }

  Future<void> _launchGameSession(String? sessionId) async {
    if (_navigatedToGame || !mounted) return;

    // Preserve real Host (Seat 0 = Red) vs Challenger (Seat 1 = Green)
    if (_assignedSeatIndex != null) {
      _isHost = (_assignedSeatIndex == 0);
    }

    String? effectiveSessionId = _sessionId ?? sessionId ?? _currentRoom?.sessionId;

    // Safe session resolution: Ensure sessionId is valid before navigating
    if ((effectiveSessionId == null || effectiveSessionId.isEmpty) && _roomCode != null) {
      try {
        final startRes = await ApiService().startGame(roomCode: _roomCode!);
        if (startRes['success'] == true && startRes['data'] is Map) {
          final data = startRes['data'] as Map;
          final session = data['session'];
          effectiveSessionId = data['sessionId']?.toString() ??
              data['matchId']?.toString() ??
              data['gameId']?.toString() ??
              (session is Map ? (session['_id'] ?? session['id'])?.toString() : null);
        }
      } catch (_) {}

      if (effectiveSessionId == null || effectiveSessionId.isEmpty) {
        try {
          final roomRes = await ApiService().getRoomDetails(roomCode: _roomCode!);
          if (roomRes['success'] == true && roomRes['data'] is Map) {
            final r = RoomModel.fromJson(roomRes['data']);
            effectiveSessionId = r.sessionId;
            _currentRoom = r;
            if (r.seatIndex != null) _assignedSeatIndex ??= r.seatIndex;
          }
        } catch (e) {
          debugPrint("Session resolution before launch notice: $e");
        }
      }
    }

    if (_navigatedToGame || !mounted) return;
    _navigatedToGame = true;

    _searchTimer?.cancel();
    _heartbeatTimer?.cancel();
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    for (final s in _socketSubs) {
      s.cancel();
    }
    _socketSubs.clear();

    int finalSeat = _localPlayerIdentity?.seatIndex ?? _assignedSeatIndex ?? _currentRoom?.seatIndex ?? (_isHost ? 0 : 1);
    bool finalIsHost = _localPlayerIdentity?.isHost ?? (_assignedSeatIndex != null ? _assignedSeatIndex == 0 : _isHost);
    if (!finalIsHost && finalSeat == 0) {
      finalSeat = 1;
    }
    if (finalSeat == 1) {
      finalIsHost = false;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          mode: GameMode.twoPlayer,
          sessionId: effectiveSessionId,
          roomCode: _roomCode,
          isOnlineMatch: true,
          isHost: finalIsHost,
          mySeatIndex: finalSeat,
          playerIdentity: _localPlayerIdentity,
          onlineModeType: widget.selectedMode.modeType,
        ),
      ),
    );
  }

  void _playVsSmartBot() {
    if (_navigatedToGame || !mounted) return;
    _navigatedToGame = true;

    _searchTimer?.cancel();
    _heartbeatTimer?.cancel();
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    for (final s in _socketSubs) {
      s.cancel();
    }
    _socketSubs.clear();

    if (_roomCode != null) {
      MatchmakingService.instance.announceCancelled(
        mode: widget.selectedMode,
        roomCode: _roomCode!,
      );
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
        title: const Text("Room Cancelled",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          "The online session was cancelled or timed out.",
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
    _rotateController.dispose();
    _searchTimer?.cancel();
    _heartbeatTimer?.cancel();
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    for (final s in _socketSubs) {
      s.cancel();
    }
    super.dispose();
  }

  void _cancelMatchmaking() {
    if (_roomCode != null) {
      if (_isHost) {
        MatchmakingService.instance.announceCancelled(
          mode: widget.selectedMode,
          roomCode: _roomCode!,
        );
      }
      ApiService().leaveRoom(roomCode: _roomCode!).catchError((_) => <String, dynamic>{});
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.selectedMode;

    return Scaffold(
      backgroundColor: const Color(0xFF020718),
      body: Stack(
        children: [
          // Background with subtle perspective floor and floating ambient glow
          Positioned.fill(
            child: CustomPaint(
              painter: _MatchmakingBackgroundPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 1. Top Header (Back, ONLINE LOBBY, Home)
                _buildHeader(context),

                // 2. Scrollable Body
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 3D Ludo Supreme Branding Logo
                          _buildLudoSupremeLogo(),

                          const SizedBox(height: 10),

                          // Mode Selector Pill (< CLASSIC >)
                          _buildModeSelectorPill(mode),

                          const SizedBox(height: 18),

                          // Status Heading ("SEARCHING FOR PLAYERS") & Neon Divider
                          _buildStatusSection(),

                          const SizedBox(height: 22),

                          // The Duel Arena (Host Card vs Opponent Card with 3D Lightning VS)
                          _buildPlayerDuelArena(mode),

                          const SizedBox(height: 22),

                          // Match Info Capsule (Elapsed Time & Entry Fee) & Live Queue Count
                          _buildMatchInfoCapsule(mode),

                          // Smart Bot Fallback Option (Visible after 15s)
                          if (_secondsElapsed >= 15 && !_opponentJoined) ...[
                            const SizedBox(height: 14),
                            _buildSmartBotFallbackCard(),
                            const SizedBox(height: 8),
                            _buildNearbyFallbackCard(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Bottom Decorative Floor with 3D Pawns & Dice + Cancel Button
                _buildBottomSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Top Navigation Bar with gold borders and crown
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button with Gold Border
          InkWell(
            key: const Key('matchmaking_back_button'),
            borderRadius: BorderRadius.circular(12),
            onTap: _cancelMatchmaking,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF132A66), Color(0xFF091436)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFD700),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFFFFD700),
                  size: 20,
                ),
              ),
            ),
          ),

          // Title with Golden Crown & Shiny Gold Font
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFFFFD700),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFFFDE7), Color(0xFFFFD700), Color(0xFFFFA000)],
                      ).createShader(bounds),
                      child: const Text(
                        "ONLINE LOBBY",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                          shadows: [
                            Shadow(
                              color: Color(0xFF001040),
                              offset: Offset(0, 2),
                              blurRadius: 6,
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

          // Home Button with Matching Gold Border
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _cancelMatchmaking,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF132A66), Color(0xFF091436)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFD700),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.home_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3D Ludo Supreme Branding Logo with Crown and 3D Red Die
  Widget _buildLudoSupremeLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown above LUDO
        const Icon(
          Icons.emoji_events_rounded,
          color: Color(0xFFFFD700),
          size: 26,
        ),
        // LUDO + 3D Red Die
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFFFF), Color(0xFFE1F5FE), Color(0xFF81D4FA)],
              ).createShader(bounds),
              child: const Text(
                "LUDO",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  shadows: [
                    Shadow(
                      color: Color(0xFF0D47A1),
                      offset: Offset(0, 3),
                      blurRadius: 4,
                    ),
                    Shadow(
                      color: Color(0xFF002171),
                      offset: Offset(0, 5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
            // Floating 3D Red Die on top right
            Positioned(
              right: -24,
              top: -6,
              child: Transform.rotate(
                angle: 0.22,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5252), Color(0xFFD50000)],
                    ),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 4,
                        offset: Offset(1, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // SUPREME Ribbon Pill
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFEA00), Color(0xFFFFB300), Color(0xFFFF8F00)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8F00).withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            "SUPREME",
            style: TextStyle(
              color: Color(0xFF4E1600),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ],
    );
  }

  /// Mode Selector Pill (< CLASSIC >)
  Widget _buildModeSelectorPill(OnlineGameMode mode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1938),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFD700),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.25),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.chevron_left_rounded,
            color: Color(0xFFFFD700),
            size: 22,
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.casino_rounded,
            color: Color(0xFFFFD700),
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            mode.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFFFD700),
            size: 22,
          ),
        ],
      ),
    );
  }

  /// Status Section with Yellow-White Italic Gradient & Glowing Divider
  Widget _buildStatusSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFFFEB3B), Color(0xFFFFC107)],
            stops: [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: const Text(
            "SEARCHING FOR PLAYERS",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _statusText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _opponentJoined ? const Color(0xFF00E676) : const Color(0xFFB0BEC5),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        // Glowing Neon Horizontal Divider with center orb
        SizedBox(
          width: 240,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 1.4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0xFF00E5FF)],
                    ),
                  ),
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00E5FF),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  height: 1.4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00E5FF), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The Duel Arena (Host Card vs Opponent Card with 3D Lightning VS)
  Widget _buildPlayerDuelArena(OnlineGameMode mode) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Card: Host (You)
          _buildHostCard(),

          // Center VS with Electric Lightning
          _buildCenterVS(),

          // Right Card: Opponent (Searching / Found)
          _buildOpponentCard(),
        ],
      ),
    );
  }

  /// Host / Player 1 Card (Red Neon Glow)
  Widget _buildHostCard() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: 126,
          height: 152,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF38080E), Color(0xFF1C0306)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFFF1E46),
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF1E46).withValues(alpha: 0.55),
                blurRadius: 18,
                spreadRadius: 1,
              ),
              const BoxShadow(
                color: Colors.black45,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              // Circular avatar
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF5A0812),
                  border: Border.all(
                    color: const Color(0xFFFF5252),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF1E46).withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_rounded,
                    color: Color(0xFFFF7070),
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Player Name
              Text(
                _isHost ? "Host (You)" : (_opponentName ?? "Host (Opponent)"),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              // READY Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E676), Color(0xFF00A844)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676).withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 3),
                    Text(
                      "READY",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 9.5,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Mini Golden Crown on top of card
        Positioned(
          top: -12,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1C0306),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFFD700),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  /// 3D Center VS with Fiery Lightning Bolt Burst
  Widget _buildCenterVS() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: SizedBox(
        width: 68,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Fiery electric lightning bolt burst
            CustomPaint(
              size: const Size(68, 110),
              painter: _LightningBurstPainter(),
            ),
            // 3D Metallic Golden VS
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFDE7), Color(0xFFFFD700), Color(0xFFFF8F00)],
              ).createShader(bounds),
              child: const Text(
                "VS",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: Color(0xFF8B0000),
                      offset: Offset(2, 3),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opponent / Player 2 Card (Cyan Neon Glow / Green when ready)
  Widget _buildOpponentCard() {
    return Container(
      width: 126,
      height: 152,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF07214A), Color(0xFF031026)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: (!_isHost || _opponentJoined) ? const Color(0xFF00E676) : const Color(0xFF00B0FF),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: ((!_isHost || _opponentJoined) ? const Color(0xFF00E676) : const Color(0xFF00B0FF))
                .withValues(alpha: 0.55),
            blurRadius: 18,
            spreadRadius: 1,
          ),
          const BoxShadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          // Circular Avatar (Radar / Searching or Found Avatar)
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF051733),
              border: Border.all(
                color: (!_isHost || _opponentJoined)
                    ? const Color(0xFF00E676)
                    : const Color(0xFF00E5FF).withValues(alpha: 0.5),
                width: 2.0,
              ),
            ),
            child: Center(
              child: (!_isHost || _opponentJoined)
                  ? const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF00E676),
                      size: 38,
                    )
                  : RotationTransition(
                      turns: _rotateController,
                      child: CustomPaint(
                        size: const Size(44, 44),
                        painter: _SearchingRadarArcPainter(),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          // Player Name / Searching
          Text(
            _isHost
                ? (_opponentJoined ? (_opponentName ?? "Challenger") : "Searching...")
                : "You (Challenger)",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          // Badge: WAITING or READY
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: (!_isHost || _opponentJoined)
                    ? [const Color(0xFF00E676), const Color(0xFF00A844)]
                    : [const Color(0xFF0288D1), const Color(0xFF01579B)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: ((!_isHost || _opponentJoined)
                          ? const Color(0xFF00E676)
                          : const Color(0xFF0288D1))
                      .withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  (!_isHost || _opponentJoined)
                      ? Icons.check_rounded
                      : Icons.access_time_rounded,
                  color: Colors.white,
                  size: 11,
                ),
                const SizedBox(width: 3),
                Text(
                  (!_isHost || _opponentJoined) ? "READY" : "WAITING",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 9.5,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Match Info Capsule (Elapsed Time & Entry Fee) & Queue Count
  Widget _buildMatchInfoCapsule(OnlineGameMode mode) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            width: 320,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFF081938).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                // Elapsed Time
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: Color(0xFFFFD700),
                        size: 24,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Elapsed Time",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF90A4AE),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "${_secondsElapsed}s",
                              maxLines: 1,
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Vertical Divider
                Container(
                  width: 1.2,
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: Colors.white24,
                ),

                // Entry Fee
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(
                        Icons.monetization_on_rounded,
                        color: Color(0xFFFFD700),
                        size: 24,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Entry Fee",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF90A4AE),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "${widget.entryFee}",
                              maxLines: 1,
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
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

        const SizedBox(height: 10),

        // Queue Count
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people_rounded,
              color: Color(0xFF00E676),
              size: 17,
            ),
            const SizedBox(width: 6),
            Text(
              "${mode.formattedPlayerCount} in queue",
              style: const TextStyle(
                color: Color(0xFFCFD8DC),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Bottom Decorative Section with 3D Pawns & Dice + Candy Red Cancel Button
  Widget _buildBottomSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Decorative Row: Left (Red Pawn + Dice) and Right (Green Pawn + Dice)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Left: Red Pawn & White Die
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const _PawnFigure(color: Color(0xFFE53935), height: 42),
                  const SizedBox(width: 4),
                  Transform.rotate(
                    angle: -0.18,
                    child: const _Mini3DDie(
                      size: 26,
                      color: Colors.white,
                      dotColor: Colors.black87,
                      pips: 3,
                    ),
                  ),
                ],
              ),

              // Right: Green Pawn & White/Blue Die
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Transform.rotate(
                    angle: 0.18,
                    child: const _Mini3DDie(
                      size: 26,
                      color: Colors.white,
                      dotColor: Color(0xFF1E88E5),
                      pips: 4,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const _PawnFigure(color: Color(0xFF00E676), height: 42),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // CANCEL MATCHMAKING Button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: InkWell(
            key: const Key('cancel_matchmaking_button'),
            borderRadius: BorderRadius.circular(30),
            onTap: _cancelMatchmaking,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF2626), Color(0xFFCC0000), Color(0xFF8B0000)],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFFFFD700),
                  width: 2.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF1744).withValues(alpha: 0.5),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.close_rounded,
                      color: Color(0xFFCC0000),
                      size: 16,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    "CANCEL MATCHMAKING",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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

  Widget _buildNearbyFallbackCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D253F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.near_me_rounded, color: Color(0xFF00E5FF), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Looking for players near you? Try Nearby Matchmaking",
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
              onPressed: () {
                _cancelMatchmaking();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NearbyMatchmakingScreen(
                      entryFee: widget.entryFee,
                      gameMode: 'twoPlayer',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                "SEARCH NEARBY PLAYERS (GPS)",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 3D Pawn Figure Component
class _PawnFigure extends StatelessWidget {
  final Color color;
  final double height;
  const _PawnFigure({required this.color, required this.height});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(height * 0.6, height),
      painter: _PawnPainter(color: color),
    );
  }
}

class _PawnPainter extends CustomPainter {
  final Color color;
  _PawnPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 0.9,
        colors: [
          Colors.white.withValues(alpha: 0.85),
          color,
          Color.alphaBlend(Colors.black.withValues(alpha: 0.55), color),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Base
    final basePath = Path()
      ..moveTo(w * 0.1, h * 0.95)
      ..quadraticBezierTo(w * 0.5, h * 0.88, w * 0.9, h * 0.95)
      ..quadraticBezierTo(w * 0.95, h, w * 0.5, h)
      ..quadraticBezierTo(w * 0.05, h, w * 0.1, h * 0.95);
    canvas.drawPath(basePath, paint);

    // Body
    final bodyPath = Path()
      ..moveTo(w * 0.25, h * 0.9)
      ..quadraticBezierTo(w * 0.35, h * 0.5, w * 0.4, h * 0.42)
      ..lineTo(w * 0.6, h * 0.42)
      ..quadraticBezierTo(w * 0.65, h * 0.5, w * 0.75, h * 0.9)
      ..close();
    canvas.drawPath(bodyPath, paint);

    // Collar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.4), width: w * 0.45, height: h * 0.08),
        const Radius.circular(3),
      ),
      paint,
    );

    // Head sphere
    canvas.drawCircle(Offset(w * 0.5, h * 0.2), w * 0.28, paint);
  }

  @override
  bool shouldRepaint(covariant _PawnPainter oldDelegate) => oldDelegate.color != color;
}

/// 3D Mini Die Component
class _Mini3DDie extends StatelessWidget {
  final double size;
  final Color color;
  final Color dotColor;
  final int pips;

  const _Mini3DDie({
    required this.size,
    required this.color,
    required this.dotColor,
    required this.pips,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.2),
        border: Border.all(color: Colors.white70, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 4,
            offset: Offset(1, 2),
          ),
        ],
      ),
      child: Center(
        child: _buildPips(),
      ),
    );
  }

  Widget _buildPips() {
    final dotSize = size * 0.16;
    Widget dot() => Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        );

    if (pips == 3) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Align(alignment: const Alignment(-0.5, 0), child: dot()),
          dot(),
          Align(alignment: const Alignment(0.5, 0), child: dot()),
        ],
      );
    }
    if (pips == 4) {
      return Padding(
        padding: EdgeInsets.all(size * 0.12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [dot(), dot()]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [dot(), dot()]),
          ],
        ),
      );
    }
    return dot();
  }
}

/// Fiery Lightning Bolt Burst Painter behind VS Emblem
class _LightningBurstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Fiery circular aura glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF9100).withValues(alpha: 0.7),
          const Color(0xFFFF3D00).withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 45));
    canvas.drawCircle(Offset(cx, cy), 45, glowPaint);

    // Lightning zigzag bolt
    final boltPaint = Paint()
      ..color = const Color(0xFFFFEA00)
      ..style = PaintingStyle.fill;

    final bolt = Path()
      ..moveTo(cx + 8, cy - 40)
      ..lineTo(cx - 14, cy - 2)
      ..lineTo(cx + 2, cy - 2)
      ..lineTo(cx - 8, cy + 40)
      ..lineTo(cx + 14, cy + 4)
      ..lineTo(cx - 2, cy + 4)
      ..close();

    canvas.drawPath(bolt, boltPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Searching Circular Radar Sweep Arc Painter
class _SearchingRadarArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [
          Colors.transparent,
          Color(0xFF00E5FF),
          Color(0xFFFFEA00),
        ],
        stops: [0.0, 0.7, 1.0],
      ).createShader(rect);

    canvas.drawArc(rect, 0, 4.8, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Background with Deep Cosmic Gradient & Perspective Floor
class _MatchmakingBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Deep cosmic gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF020718),
          Color(0xFF071438),
          Color(0xFF020A20),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Ambient top-center light aura
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1565C0).withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.5, size.height * 0.15), radius: size.width * 0.65));
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.15), size.width * 0.65, auraPaint);

    // Perspective grid floor lines on bottom 15%
    final floorTop = size.height * 0.84;
    final linePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    // Horizontal depth lines
    for (int i = 0; i <= 4; i++) {
      final y = floorTop + (size.height - floorTop) * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Perspective rays diverging to bottom
    final vanishX = size.width * 0.5;
    final vanishY = floorTop - 20;
    for (int i = -3; i <= 3; i++) {
      final targetX = vanishX + (i * (size.width / 5));
      canvas.drawLine(Offset(vanishX, vanishY), Offset(targetX, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
