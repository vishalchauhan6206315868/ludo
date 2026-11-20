import 'package:flutter/material.dart';
import '../constants/ludo_colors.dart';
import '../core/network/api_config.dart';
import '../core/network/api_service.dart';
import '../models/game_state.dart';
import '../models/room_model.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';
import 'room_lobby_dialog.dart';

/// Streamlined & High-Performance 3D Gaming Player Selection Dialog:
/// - Purely focused on Core Room Creation and Room Joining (Zero extra clutter)
/// - Removed unsupported 5P/6P, duplicate Team Up, dummy history & fake voice chat
/// - 100% API-compliant: strict payload integrity for maxPlayers, roomCode, and auth tokens
/// - Glowing 3D dice & crown hero centerpiece
/// - Tactile golden entry fee counter & glossy cyan-blue CTA button
/// - Fully responsive for all phone sizes and landscape viewports
class PlayerSelectionDialog extends StatefulWidget {
  final int initialCount;
  final bool initialIsCreateTab;

  const PlayerSelectionDialog({
    super.key,
    this.initialCount = 2,
    this.initialIsCreateTab = true,
  });

  @override
  State<PlayerSelectionDialog> createState() => _PlayerSelectionDialogState();
}

class _PlayerSelectionDialogState extends State<PlayerSelectionDialog> {
  // Theme Color Tokens
  static const Color _bgDarkNavy = Color(0xFF020A24);
  static const Color _panelBlue = Color(0xFF061848);
  static const Color _neonCyan = Color(0xFF00E5FF);
  static const Color _electricBlue = Color(0xFF087BFF);
  static const Color _goldLight = Color(0xFFFFEA75);
  static const Color _goldDark = Color(0xFFFFB300);
  static const Color _goldAccent = Color(0xFFFFD700);

  // Tabs: true for "Create", false for "Join"
  late bool _isCreateTab;

  // Selected player count for 2P/3P/4P
  late int _selectedCount;

  // Entry fee options & current selection
  final List<int> _entryFeeOptions = [50, 100, 500, 1000, 2500, 5000];
  int _entryFeeIndex = 1; // default 100

  // Currencies
  int _coins = 1000;
  int _gems = 150;

  // Join room code controller
  final TextEditingController _roomCodeController = TextEditingController();

  bool _isCreatingRoom = false;
  bool _isJoiningRoom = false;

  @override
  void initState() {
    super.initState();
    _isCreateTab = widget.initialIsCreateTab;
    _selectedCount = widget.initialCount.clamp(2, 4);
    _loadLiveCoins();
  }

  Future<void> _loadLiveCoins() async {
    try {
      final liveCoins = await AuthService.getUserCoins();
      final liveGems = await AuthService.getUserGems();
      if (mounted) {
        setState(() {
          _coins = liveCoins;
          _gems = liveGems;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  GameMode _modeForCount(int count) {
    switch (count) {
      case 2:
        return GameMode.twoPlayer;
      case 3:
        return GameMode.threePlayer;
      case 4:
        return GameMode.fourPlayer;
      default:
        return GameMode.twoPlayer;
    }
  }

  void _onConfirm() {
    Navigator.pop(context, _modeForCount(_selectedCount));
  }

  /// Ensure we have an active JWT auth token, or sync backend session
  Future<String?> _ensureToken() async {
    return await AuthService.ensureBackendSession();
  }

  /// Display an alert dialog handling both server unreachable (if logged in) or login needed (if not)
  void _showServerOrAuthDialog({
    required bool isAlreadyLoggedIn,
    required VoidCallback onPlayOffline,
    String? customMessage,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF071938),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _goldAccent, width: 1.8),
        ),
        title: Row(
          children: [
            Icon(
              isAlreadyLoggedIn ? Icons.cloud_off_rounded : Icons.lock_rounded,
              color: _goldAccent,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              isAlreadyLoggedIn ? "Server Unreachable" : "Login Required",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          isAlreadyLoggedIn
              ? (customMessage ??
                  "Aap logged in hain, lekin backend server (${ApiConfig.baseUrl}) se connect nahi ho pa raha hai.\n\nKya aap isi device par Offline Match shuru karna chahte hain?")
              : "Online Room create karne ke liye login zaroori hai.\n\nKya aap Login karna chahte hain ya isi device par Offline Match khelna chahte hain?",
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onPlayOffline();
            },
            child: const Text("Play Offline", style: TextStyle(color: Colors.amberAccent)),
          ),
          if (!isAlreadyLoggedIn)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _goldAccent,
                foregroundColor: const Color(0xFF04122C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text("Login Now"),
            ),
        ],
      ),
    );
  }

  Future<void> _handleCreateRoom() async {
    setState(() => _isCreatingRoom = true);

    // 1. Ensure token exists (auto-login with default credentials if needed)
    final token = await _ensureToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() => _isCreatingRoom = false);
      _onConfirm();
      return;
    }

    try {
      final entryFee = _entryFeeOptions[_entryFeeIndex];
      final modeStr = _selectedCount == 4
          ? 'fourPlayer'
          : (_selectedCount == 3 ? 'threePlayer' : 'twoPlayer');

      // Call backend API /api/rooms/create
      var response = await ApiService().createRoom(
        maxPlayers: _selectedCount,
        gameMode: modeStr,
        entryFee: entryFee,
      );

      // If user is already in an active room from a previous session, auto-leave and re-create
      final rawError = response['message']?.toString().toLowerCase() ?? '';
      final oldRoomCode = response['data'] is Map ? response['data']['roomCode']?.toString() : null;
      if ((oldRoomCode != null && oldRoomCode.isNotEmpty) || rawError.contains('already in an active room')) {
        if (oldRoomCode != null && oldRoomCode.isNotEmpty) {
          await ApiService().leaveRoom(roomCode: oldRoomCode);
        }
        response = await ApiService().createRoom(
          maxPlayers: _selectedCount,
          gameMode: modeStr,
          entryFee: entryFee,
        );
      }

      if (!mounted) return;
      setState(() => _isCreatingRoom = false);

      if (response['success'] == true && response['data'] != null) {
        RoomModel? room;
        try {
          final data = response['data'];
          if (data is Map<String, dynamic>) {
            room = RoomModel.fromJson(data);
          }
        } catch (e) {
          debugPrint('Error parsing RoomModel from create response: $e');
        }

        if (room != null && room.roomCode.isNotEmpty) {
          // Close selection dialog and open RoomLobbyDialog
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (ctx) => RoomLobbyDialog(
              room: room!,
              entryFee: entryFee,
              isHost: true,
              onStartGame: (sessionId) {
                Navigator.pop(ctx, {
                  'mode': _modeForCount(_selectedCount),
                  'sessionId': sessionId,
                  'roomCode': room!.roomCode,
                  'isOnlineMatch': true,
                  'isHost': true,
                  'mySeatIndex': 0,
                });
              },
            ),
          );
          return;
        }
      }

      // Handle backend specific error responses
      final statusCode = response['statusCode'] as int? ?? -1;
      final errorMessage = response['message']?.toString() ?? 'Failed to create room';

      if (statusCode == 401) {
        final isAlreadyLoggedIn = await AuthService.isLoggedIn();
        _showServerOrAuthDialog(
          isAlreadyLoggedIn: isAlreadyLoggedIn,
          onPlayOffline: _onConfirm,
          customMessage: "Server session expired. Please re-login or play offline on this device.",
        );
      } else if (statusCode == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Backend server unreachable on port ${ApiConfig.baseUrl}. Starting offline mode..."),
            backgroundColor: const Color(0xFFD97706),
            duration: const Duration(seconds: 3),
          ),
        );
        _onConfirm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.redAccent.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreatingRoom = false);
        _onConfirm();
      }
    }
  }

  Future<void> _handleJoinRoom() async {
    final code = _roomCodeController.text.trim();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid 4-6 digit Room Code!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isJoiningRoom = true);

    // Verify user is logged in or auto-login
    final token = await _ensureToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() => _isJoiningRoom = false);
      final isAlreadyLoggedIn = await AuthService.isLoggedIn();
      _showServerOrAuthDialog(
        isAlreadyLoggedIn: isAlreadyLoggedIn,
        onPlayOffline: _onConfirm,
      );
      return;
    }

    try {
      final response = await ApiService().joinRoom(roomCode: code);

      if (!mounted) return;
      setState(() => _isJoiningRoom = false);

      if (response['success'] == true && response['data'] != null) {
        RoomModel? room;
        try {
          final data = response['data'];
          if (data is Map<String, dynamic>) {
            room = RoomModel.fromJson(data);
          }
        } catch (e) {
          debugPrint('Error parsing RoomModel from join response: $e');
        }

        if (room != null) {
          final targetMode = room.maxPlayers == 4
              ? GameMode.fourPlayer
              : (room.maxPlayers == 3 ? GameMode.threePlayer : GameMode.twoPlayer);

          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (ctx) => RoomLobbyDialog(
              room: room!,
              entryFee: _entryFeeOptions[_entryFeeIndex],
              isHost: false,
              onStartGame: (sessionId) {
                Navigator.pop(ctx, {
                  'mode': targetMode,
                  'sessionId': sessionId,
                  'roomCode': room!.roomCode,
                  'isOnlineMatch': true,
                  'isHost': false,
                  'mySeatIndex': 1,
                });
              },
            ),
          );
          return;
        }
      }

      final statusCode = response['statusCode'] as int? ?? -1;
      final errorMessage = response['message']?.toString() ?? 'Unable to join room. Please check the code.';

      if (statusCode == 401) {
        final isAlreadyLoggedIn = await AuthService.isLoggedIn();
        _showServerOrAuthDialog(
          isAlreadyLoggedIn: isAlreadyLoggedIn,
          onPlayOffline: _onConfirm,
          customMessage: "Server session expired. Please re-login or play offline on this device.",
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.redAccent.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isJoiningRoom = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error joining room: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _decreaseEntryFee() {
    if (_entryFeeIndex > 0) {
      setState(() {
        _entryFeeIndex--;
      });
    }
  }

  void _increaseEntryFee() {
    if (_entryFeeIndex < _entryFeeOptions.length - 1) {
      setState(() {
        _entryFeeIndex++;
      });
    }
  }

  void _showHowToPlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF071938),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _goldAccent, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: _goldAccent),
            SizedBox(width: 8),
            Text("How to Play",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("1. Choose player count (2 or 4 Players online).",
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              SizedBox(height: 6),
              Text("2. Set your lobby entry fee coins.",
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              SizedBox(height: 6),
              Text("3. Create a room and share the 6-digit code with friends.",
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              SizedBox(height: 6),
              Text("4. Play together and win the prize pool!",
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Got it!", style: TextStyle(color: _goldAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entryFee = _entryFeeOptions[_entryFeeIndex];
    final screenSize = MediaQuery.sizeOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final availableHeight = screenSize.height - viewInsets.bottom;
    final responsiveMaxHeight = (availableHeight * 0.94).clamp(260.0, 720.0);

    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.15,
      child: SafeArea(
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Container(
            constraints: BoxConstraints(maxWidth: 700, maxHeight: responsiveMaxHeight),
            decoration: BoxDecoration(
              color: _bgDarkNavy,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _neonCyan, width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: _neonCyan.withValues(alpha: 0.35),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.3,
                    colors: [
                      Color(0xFF0C2C75),
                      Color(0xFF061848),
                      Color(0xFF020922),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Bar (Back button, Title, Currencies, Tabs)
                    _buildHeaderBar(context),

                    // Main Body
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 540;

                            if (_isCreateTab) {
                              if (isWide) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildSelectPlayersPanel()),
                                    const SizedBox(width: 10),
                                    Expanded(child: _buildLobbyPanel(entryFee)),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    _buildSelectPlayersPanel(),
                                    const SizedBox(height: 10),
                                    _buildLobbyPanel(entryFee),
                                  ],
                                );
                              }
                            } else {
                              return _buildJoinLobbyPanel();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // STREAMLINED HEADER BAR
  // ==========================================
  Widget _buildHeaderBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF030E2E).withValues(alpha: 0.9),
        border: const Border(
          bottom: BorderSide(color: _neonCyan, width: 1.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: "Back to Home",
                icon: const Icon(Icons.arrow_back_rounded, color: _goldAccent, size: 20),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: _panelBlue,
                  side: const BorderSide(color: _neonCyan, width: 1.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(34, 34),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Play with Friends",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildCurrencyBadge(Icons.diamond_rounded, "$_gems", _neonCyan),
              const SizedBox(width: 6),
              _buildCurrencyBadge(Icons.monetization_on_rounded, "$_coins", _goldAccent),
            ],
          ),
          const SizedBox(height: 8),
          // Create / Join Tabs
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              color: const Color(0xFF031438),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _neonCyan.withValues(alpha: 0.6), width: 1.2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isCreateTab = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        gradient: _isCreateTab
                            ? const LinearGradient(colors: [_goldLight, _goldDark])
                            : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          "Create",
                          style: TextStyle(
                            color: _isCreateTab ? const Color(0xFF020A24) : Colors.white70,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isCreateTab = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        gradient: !_isCreateTab
                            ? const LinearGradient(colors: [_goldLight, _goldDark])
                            : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          "Join",
                          style: TextStyle(
                            color: !_isCreateTab ? const Color(0xFF020A24) : Colors.white70,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
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

  Widget _buildCurrencyBadge(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFF061536),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PANEL 1: SELECT PLAYERS (Clean 3D Card)
  // ==========================================
  Widget _buildSelectPlayersPanel() {
    return _buildGlowingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with 3D Dice + Title
          Row(
            children: [
              _buildHero3DDice(),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SELECT PLAYERS",
                      style: TextStyle(
                        color: _goldAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "How many friends want to play?",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sub-selector Pill
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
              decoration: BoxDecoration(
                color: _goldAccent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _goldAccent.withValues(alpha: 0.35),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Text(
                "✓  Select Friend Count:",
                style: TextStyle(
                  color: Color(0xFF020A24),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 3 Buttons: 2 Friends, 3 Friends, 4 Friends
          Row(
            children: [
              Expanded(
                child: _buildFriendCountButton(
                  count: 2,
                  label: "👥 2 Friends",
                  keyName: "option_2",
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildFriendCountButton(
                  count: 3,
                  label: "👥 3 Friends",
                  keyName: "option_3",
                  disabled: false,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildFriendCountButton(
                  count: 4,
                  label: "👥 4 Friends",
                  keyName: "option_4",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Hero 3D Dice Graphic with Crown & 4-Color Pawns
  Widget _buildHero3DDice() {
    return Container(
      width: 70,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF0A4FC2),
            Color(0xFF041854),
          ],
        ),
        border: Border.all(color: _neonCyan, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: _neonCyan.withValues(alpha: 0.45),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Crown on top
          const Positioned(
            top: 2,
            child: Icon(Icons.military_tech_rounded, color: _goldAccent, size: 20),
          ),
          // Center 3D Dice
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color(0xFFE2E8F0),
                  Color(0xFFCBD5E1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(1, 2),
                ),
              ],
            ),
            child: const Icon(Icons.casino_rounded, color: Color(0xFF081C4E), size: 30),
          ),
          // Bottom 4-color pawn dots
          Positioned(
            bottom: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildColorOrb(LudoColors.red),
                const SizedBox(width: 2.5),
                _buildColorOrb(LudoColors.green),
                const SizedBox(width: 2.5),
                _buildColorOrb(_goldAccent),
                const SizedBox(width: 2.5),
                _buildColorOrb(_neonCyan),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOrb(Color color) {
    return Container(
      width: 7.5,
      height: 7.5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.7),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCountButton({
    required int count,
    required String label,
    required String keyName,
    bool disabled = false,
  }) {
    final isSelected = !disabled && _selectedCount == count;

    return InkWell(
      key: Key(keyName),
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        if (disabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("This mode is currently unavailable."),
              backgroundColor: Colors.orangeAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        setState(() {
          _selectedCount = count;
        });
      },
      child: Opacity(
        opacity: disabled ? 0.45 : 1.0,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [_goldLight, _goldDark],
                )
              : null,
          color: isSelected ? null : const Color(0xFF04153B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _goldAccent : _electricBlue.withValues(alpha: 0.8),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _goldAccent.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              Icons.people_alt_rounded,
              color: isSelected ? const Color(0xFF020A24) : Colors.white,
              size: 17,
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF020A24) : Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  // ==========================================
  // PANEL 2: SELECT LOBBY (Create Tab)
  // ==========================================
  Widget _buildLobbyPanel(int entryFee) {
    return _buildGlowingCard(
      child: Column(
        children: [
          // Header with Crown & Lines
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 1.5,
                  color: _goldAccent.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.military_tech_rounded, color: _goldAccent, size: 20),
                const SizedBox(width: 5),
                const Text(
                  "SELECT LOBBY",
                  style: TextStyle(
                    color: _goldAccent,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 20,
                  height: 1.5,
                  color: _goldAccent.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Entry Fee Capsule Selector
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFF031438),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _goldAccent, width: 1.6),
              boxShadow: [
                BoxShadow(
                  color: _goldAccent.withValues(alpha: 0.2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                _buildRoundStepButton(
                  icon: Icons.remove_rounded,
                  onTap: _decreaseEntryFee,
                  enabled: _entryFeeIndex > 0,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_goldLight, _goldDark],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "ENTRY",
                          style: TextStyle(
                            color: Color(0xFF020A24),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.monetization_on_rounded,
                              color: Color(0xFF8C5700),
                              size: 16,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              "$entryFee",
                              style: const TextStyle(
                                color: Color(0xFF020A24),
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _buildRoundStepButton(
                  icon: Icons.add_rounded,
                  onTap: _increaseEntryFee,
                  enabled: _entryFeeIndex < _entryFeeOptions.length - 1,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Main "Create Room" CTA Button
          InkWell(
            key: const Key('start_game_button'),
            borderRadius: BorderRadius.circular(32),
            onTap: _isCreatingRoom ? null : _handleCreateRoom,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF00DDF5),
                    Color(0xFF087BFF),
                    Color(0xFF2149FF),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: _neonCyan, width: 1.8),
                boxShadow: [
                  BoxShadow(
                    color: _electricBlue.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _isCreatingRoom
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Creating Room...",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.groups_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Create Room",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Start $_selectedCount-Player Game",
                                  style: const TextStyle(
                                    color: Color(0xFFC7F3FF),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),

          // Bottom Rules Ribbon
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showHowToPlay(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _goldAccent.withValues(alpha: 0.6), width: 1.1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.help_outline_rounded, color: _goldAccent, size: 13),
                  SizedBox(width: 4),
                  Text(
                    "How to Play Rules",
                    style: TextStyle(
                      color: _goldAccent,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PANEL 3: JOIN LOBBY (Join Tab)
  // ==========================================
  Widget _buildJoinLobbyPanel() {
    return _buildGlowingCard(
      child: Column(
        children: [
          // Header with Crown & Lines
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 1.5,
                  color: _goldAccent.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.military_tech_rounded, color: _goldAccent, size: 20),
                const SizedBox(width: 5),
                const Text(
                  "JOIN LOBBY",
                  style: TextStyle(
                    color: _goldAccent,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 20,
                  height: 1.5,
                  color: _goldAccent.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          const Text(
            "Enter your friend's 6-digit Private Room Code",
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 10),

          // Code Input Box
          Container(
            width: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF031438),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _neonCyan, width: 1.6),
            ),
            child: TextField(
              controller: _roomCodeController,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 5.0,
              ),
              decoration: const InputDecoration(
                counterText: "",
                hintText: "• • • • • •",
                hintStyle: TextStyle(color: Colors.white30, letterSpacing: 3.5),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Join Room Button
          InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: _isJoiningRoom ? null : _handleJoinRoom,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 220),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isJoiningRoom
                      ? [const Color(0xFF374151), const Color(0xFF1F2937)]
                      : [const Color(0xFF10B981), const Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white, width: 1.6),
                boxShadow: [
                  if (!_isJoiningRoom)
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                ],
              ),
              child: Center(
                child: _isJoiningRoom
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Join Room",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Bottom Rules Ribbon
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showHowToPlay(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _goldAccent.withValues(alpha: 0.6), width: 1.1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.help_outline_rounded, color: _goldAccent, size: 13),
                  SizedBox(width: 4),
                  Text(
                    "How to Play Rules",
                    style: TextStyle(
                      color: _goldAccent,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundStepButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: enabled
                ? const [Color(0xFF00C6FF), Color(0xFF0072FF)]
                : [Colors.grey.shade700, Colors.grey.shade800],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled ? _neonCyan : Colors.white24,
            width: 1.4,
          ),
          boxShadow: [
            if (enabled)
              BoxShadow(
                color: _neonCyan.withValues(alpha: 0.35),
                blurRadius: 6,
              ),
          ],
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.white38,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildGlowingCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _panelBlue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _neonCyan, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _neonCyan.withValues(alpha: 0.16),
            blurRadius: 12,
          ),
        ],
      ),
      child: child,
    );
  }
}
