import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/game_state.dart';
import '../../models/online_game_mode.dart';
import '../game_screen.dart';

/// Placeholder Matchmaking screen opened when the user taps "NEXT".
///
/// Pre-structured with clean TODO integration points for:
/// - Socket.IO / WebSocket realtime lobby connections
/// - Live player search queue
/// - Matchmaking ticket polling
/// - Game room assignment & handoff to online game session
class OnlineMatchmakingScreen extends StatefulWidget {
  final OnlineGameMode selectedMode;
  final int entryFee;

  const OnlineMatchmakingScreen({
    super.key,
    required this.selectedMode,
    this.entryFee = 100,
  });

  @override
  State<OnlineMatchmakingScreen> createState() => _OnlineMatchmakingScreenState();
}

class _OnlineMatchmakingScreenState extends State<OnlineMatchmakingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _searchTimer;
  int _secondsElapsed = 0;
  String _statusText = "Connecting to global matchmaking server...";

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Simulated matchmaking heartbeat with status progression
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsElapsed >= 4) {
        timer.cancel();
        _showNoOpponentsFoundDialog();
        return;
      }

      setState(() {
        _secondsElapsed++;
        if (_secondsElapsed == 2) {
          _statusText = "Searching for opponents in ${widget.selectedMode.title}...";
        } else if (_secondsElapsed == 6) {
          _statusText = "Analyzing skill rating & ping quality...";
        } else if (_secondsElapsed == 10) {
          _statusText = "Waiting for room confirmation...";
        }
      });

      // TODO: Connect to backend matchmaking service:
      // final matchTicket = await MatchmakingService.joinQueue(mode: widget.selectedMode.id);
      // matchTicket.onMatchFound((roomData) {
      //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OnlineGameScreen(room: roomData)));
      // });
    });
  }

  void _showNoOpponentsFoundDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF10192D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x44FFD700)),
        ),
        title: const Row(
          children: [
            Icon(Icons.wifi_tethering_off_rounded, color: Color(0xFFFFD700)),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                "Matchmaking Notice",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "No live opponents found in your matchmaking pool right now.\n\nGlobal online multiplayer servers are launching in the upcoming v1.1 release! In the meantime, you can challenge our smart AI bot or enjoy Pass N Play.",
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("Back to Menu", style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const GameScreen(mode: GameMode.vsComputer),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: const Color(0xFF261200),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Play vs Computer", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _cancelMatchmaking() {
    // TODO: Send cancel queue event to backend (e.g. MatchmakingService.cancelQueue())
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

              // Matchmaking Core
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Selected Mode Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

                        const SizedBox(height: 36),

                        // Pulsing Matchmaking Radar / Ring
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      mode.accentColor.withValues(alpha: 0.28),
                                      Colors.transparent,
                                    ],
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFFFD700).withValues(alpha: 0.7),
                                    width: 2.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: mode.glowColor.withValues(alpha: 0.45),
                                      blurRadius: 28,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF0E224F),
                                      border: Border.all(
                                        color: const Color(0xFFFFD700),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      mode.icon,
                                      color: const Color(0xFFFFD700),
                                      size: 44,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 36),

                        // Title
                        const Text(
                          "SEARCHING FOR PLAYERS",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: Color(0x66FFD700),
                                offset: Offset(0, 2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Status subtitle
                        Text(
                          _statusText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF90A4AE),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

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

                        const SizedBox(height: 32),

                        // Notice card for backend implementation
                        Container(
                          constraints: const BoxConstraints(maxWidth: 400),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1630).withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: Color(0xFFFFD700), size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Matchmaking queue simulated for demo. Ready to connect live multiplayer backend (WebSockets / Socket.IO).",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11.5,
                                    height: 1.3,
                                  ),
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

              // Bottom Cancel Action
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
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
