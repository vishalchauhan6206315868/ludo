import 'package:flutter/material.dart';
import '../constants/ludo_colors.dart';
import '../models/game_state.dart';

class PlayerSelectionDialog extends StatefulWidget {
  final int initialCount;

  const PlayerSelectionDialog({
    super.key,
    this.initialCount = 2,
  });

  @override
  State<PlayerSelectionDialog> createState() => _PlayerSelectionDialogState();
}

class _PlayerSelectionDialogState extends State<PlayerSelectionDialog> {
  // Tabs: true for "Create", false for "Join"
  bool _isCreateTab = true;

  // Selected player mode: 0 -> 2P/3P/4P, 1 -> Team Up, 2 -> 5P, 3 -> 6P
  int _selectedModeType = 0;

  // Selected player count for 2P/3P/4P
  late int _selectedCount;

  // Voice chat toggle
  bool _voiceChatEnabled = true;

  // Entry fee options & current selection
  final List<int> _entryFeeOptions = [50, 100, 500, 1000, 2500, 5000];
  int _entryFeeIndex = 1; // default 100

  // Currencies
  final int _coins = 3600;
  final int _gems = 150;

  // Join room code controller
  final TextEditingController _roomCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCount = widget.initialCount.clamp(2, 4);
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

  void _showGameHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF071938),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.amber, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.history_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text(
              "Game History",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Recent Matches:",
                style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("• Match #1042: 4 Players (Won 1st Place)",
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            SizedBox(height: 4),
            Text("• Match #1039: 2 Players (Won 1st Place)",
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            SizedBox(height: 4),
            Text("• Match #1035: Vs Computer (Finished)",
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close", style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF071938),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.amber, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: Colors.amber),
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
              Text("1. Choose your player mode (2P, 3P, or 4P).",
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              SizedBox(height: 6),
              Text("2. Set your lobby entry fee coins.",
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              SizedBox(height: 6),
              Text("3. Create a room or share the Room Code with friends.",
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              SizedBox(height: 6),
              Text("4. Pass & Play or play together on this device!",
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Got it!", style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entryFee = _entryFeeOptions[_entryFeeIndex];

    return SafeArea(
      child: Dialog(
        backgroundColor: const Color(0xFF04122C),
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFFFB300), width: 2.2),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 840, maxHeight: 680),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF071E4A),
                Color(0xFF04112B),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.25),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ---------------- TOP APP BAR ----------------
                _buildTopBar(context),

                // ---------------- MAIN CONTENT BODY ----------------
                Flexible(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 560;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        child: isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left Panel: Lobby & Bet Setup
                                  Expanded(
                                    flex: 11,
                                    child: _buildLobbyPanel(entryFee),
                                  ),
                                  const SizedBox(width: 12),
                                  // Right Panel: Select Players
                                  Expanded(
                                    flex: 10,
                                    child: _buildSelectPlayersPanel(),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildSelectPlayersPanel(),
                                  const SizedBox(height: 12),
                                  _buildLobbyPanel(entryFee),
                                ],
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TOP BAR
  // ==========================================
  Widget _buildTopBar(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;
        final isUltraCompact = constraints.maxWidth < 360;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isUltraCompact ? 8 : 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF020D22).withValues(alpha: 0.75),
            border: const Border(
              bottom: BorderSide(color: Color(0xFFFFB300), width: 1.2),
            ),
          ),
          child: isCompact
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Back Button with tooltip for accessibility and tests
                        IconButton(
                          tooltip: "Back to Home",
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: Colors.amber, size: 20),
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF0A2968),
                            side: const BorderSide(
                                color: Color(0xFFFFB300), width: 1.8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.all(8),
                            minimumSize: const Size(36, 36),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Play with Friends",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildHistoryButton(context, isCompact: isUltraCompact),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildGemsBadge(),
                        const SizedBox(width: 8),
                        _buildCoinsBadge(),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Back Button with tooltip for accessibility and tests
                    IconButton(
                      tooltip: "Back to Home",
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.amber, size: 20),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF0A2968),
                        side: const BorderSide(
                            color: Color(0xFFFFB300), width: 1.8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Play with Friends",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildHistoryButton(context, isCompact: false),
                    const SizedBox(width: 8),
                    _buildGemsBadge(),
                    const SizedBox(width: 8),
                    _buildCoinsBadge(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildHistoryButton(BuildContext context, {required bool isCompact}) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _showGameHistory(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF0A2252),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFB300), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded, color: Colors.amber, size: 14),
            const SizedBox(width: 4),
            Text(
              isCompact ? "HISTORY" : "GAME HISTORY",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGemsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF021B3D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00E5FF), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.diamond_rounded, color: Color(0xFF00E5FF), size: 16),
          const SizedBox(width: 4),
          Text(
            "$_gems",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1402),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB300), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on_rounded,
              color: Colors.amber, size: 16),
          const SizedBox(width: 4),
          Text(
            "$_coins",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LEFT PANEL: LOBBY & BET SETUP
  // ==========================================
  Widget _buildLobbyPanel(int entryFee) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF071F4F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB300), width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tabs: Create / Join (using ClipRRect with uniform structure to prevent assertion errors)
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFFFB300),
                    width: 1.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isCreateTab = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        color: _isCreateTab
                            ? const Color(0xFFFFB300)
                            : const Color(0xFF05173A),
                        child: Center(
                          child: Text(
                            "Create",
                            style: TextStyle(
                              color: _isCreateTab ? Colors.black : Colors.amber,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1.5,
                    height: 42,
                    color: const Color(0xFFFFB300),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isCreateTab = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        color: !_isCreateTab
                            ? const Color(0xFFFFB300)
                            : const Color(0xFF05173A),
                        child: Center(
                          child: Text(
                            "Join",
                            style: TextStyle(
                              color: !_isCreateTab ? Colors.black : Colors.amber,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: _isCreateTab
                ? _buildCreateRoomContent(entryFee)
                : _buildJoinRoomContent(),
          ),
        ],
      ),
    );
  }

  // ---------------- CREATE ROOM CONTENT ----------------
  Widget _buildCreateRoomContent(int entryFee) {
    return Column(
      children: [
        // SELECT LOBBY Heading
        const Text(
          "SELECT LOBBY",
          style: TextStyle(
            color: Color(0xFFFFC107),
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
            shadows: [
              Shadow(
                color: Colors.black,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Voice Chat Toggle Badge
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            setState(() {
              _voiceChatEnabled = !_voiceChatEnabled;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _voiceChatEnabled
                    ? [const Color(0xFF00B0FF), const Color(0xFF0052D4)]
                    : [const Color(0xFF37474F), const Color(0xFF212121)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _voiceChatEnabled
                    ? const Color(0xFF00E5FF)
                    : Colors.white30,
                width: 1.8,
              ),
              boxShadow: [
                if (_voiceChatEnabled)
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _voiceChatEnabled
                      ? Icons.mic_rounded
                      : Icons.mic_off_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  "Voice Chat: ${_voiceChatEnabled ? "ON" : "OFF"}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Entry Fee Selector Row with [-], [ENTRY Box], [+]
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Minus Button
            _buildRoundActionButton(
              icon: Icons.remove_rounded,
              onTap: _decreaseEntryFee,
              enabled: _entryFeeIndex > 0,
            ),

            const SizedBox(width: 10),

            // ENTRY Box
            Flexible(
              child: Container(
                constraints: const BoxConstraints(minWidth: 90, maxWidth: 130),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFF176), Color(0xFFFFB300)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "ENTRY",
                      style: TextStyle(
                        color: Color(0xFF4A2800),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF03224C),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber, width: 1.2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on_rounded,
                              color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "$entryFee",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
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

            const SizedBox(width: 10),

            // Plus Button
            _buildRoundActionButton(
              icon: Icons.add_rounded,
              onTap: _increaseEntryFee,
              enabled: _entryFeeIndex < _entryFeeOptions.length - 1,
            ),
          ],
        ),

        const SizedBox(height: 22),

        // Prominent "Next" Action Button (with Start Game text for clarity & tests)
        InkWell(
          key: const Key('start_game_button'),
          borderRadius: BorderRadius.circular(28),
          onTap: _onConfirm,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 260),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFFFD700), width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00C6FF).withValues(alpha: 0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Next",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "Start $_selectedCount-Player Game",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Bottom Bar info: "How to Play" Ribbon
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showHowToPlay(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.help_outline_rounded, color: Colors.amber, size: 14),
                SizedBox(width: 4),
                Text(
                  "How to Play Rules",
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- JOIN ROOM CONTENT ----------------
  Widget _buildJoinRoomContent() {
    return Column(
      children: [
        const Text(
          "JOIN LOBBY",
          style: TextStyle(
            color: Color(0xFFFFC107),
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Enter your friend's 6-digit Private Room Code",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 18),

        // Room code text input
        Container(
          width: 220,
          decoration: BoxDecoration(
            color: const Color(0xFF031636),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.amber, width: 1.8),
          ),
          child: TextField(
            controller: _roomCodeController,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 6.0,
            ),
            decoration: const InputDecoration(
              counterText: "",
              hintText: "• • • • • •",
              hintStyle: TextStyle(color: Colors.white30, letterSpacing: 4.0),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Join Room Action Button
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            if (_roomCodeController.text.length < 4) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Please enter a valid Room Code!"),
                  backgroundColor: Colors.redAccent,
                ),
              );
              return;
            }
            _onConfirm();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Text(
              "Join Room",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Circular +/- Buttons
  Widget _buildRoundActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: enabled
                  ? [const Color(0xFF00C6FF), const Color(0xFF0072FF)]
                  : [Colors.grey.shade700, Colors.grey.shade800],
            ),
            border: Border.all(
              color: enabled ? const Color(0xFFFFB300) : Colors.white24,
              width: 2.0,
            ),
            boxShadow: [
              if (enabled)
                BoxShadow(
                  color: const Color(0xFF00C6FF).withValues(alpha: 0.4),
                  blurRadius: 10,
                ),
            ],
          ),
          child: Icon(
            icon,
            color: enabled ? Colors.white : Colors.white38,
            size: 24,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // RIGHT PANEL: SELECT PLAYERS
  // ==========================================
  Widget _buildSelectPlayersPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF071F4F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB300), width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Heading: SELECT PLAYERS
          const Center(
            child: Text(
              "SELECT PLAYERS",
              style: TextStyle(
                color: Color(0xFFFFC107),
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Subtitle
          const Center(
            child: Text(
              "How many friends want to play?",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Option 1: 2P/3P/4P (Classic Mode)
          _buildPlayerModeCard(
            modeIndex: 0,
            title: "2P/3P/4P",
            subtitle: "Classic 4-color board",
            icon: Icons.grid_view_rounded,
            isSelected: _selectedModeType == 0,
            onTap: () {
              setState(() {
                _selectedModeType = 0;
              });
            },
            badge: "POPULAR",
            customPreview: _buildClassicBoardMiniIcon(),
            child: _selectedModeType == 0 ? _buildFriendsCountSubSelector() : null,
          ),

          const SizedBox(height: 8),

          // Option 2: Team Up
          _buildPlayerModeCard(
            modeIndex: 1,
            title: "Team Up",
            subtitle: "2 vs 2 Partner Battle",
            icon: Icons.handshake_rounded,
            isSelected: _selectedModeType == 1,
            onTap: () {
              setState(() {
                _selectedModeType = 1;
                _selectedCount = 4; // Team up is 4 players
              });
            },
            badge: "2 VS 2",
            customPreview: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.shade900,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.purpleAccent, width: 1),
              ),
              child: const Text(
                "A vs B",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Option 3: 5P
          _buildPlayerModeCard(
            modeIndex: 2,
            title: "5P",
            subtitle: "5-Player Pentagonal Board",
            icon: Icons.pentagon_rounded,
            isSelected: _selectedModeType == 2,
            onTap: () {
              setState(() {
                _selectedModeType = 2;
              });
            },
            badge: "SPECIAL",
          ),

          const SizedBox(height: 8),

          // Option 4: 6P
          _buildPlayerModeCard(
            modeIndex: 3,
            title: "6P",
            subtitle: "6-Player Hexagonal Board",
            icon: Icons.hexagon_rounded,
            isSelected: _selectedModeType == 3,
            onTap: () {
              setState(() {
                _selectedModeType = 3;
              });
            },
            badge: "SOON",
          ),
        ],
      ),
    );
  }

  // Sub-selector for exact player count in 2P/3P/4P
  Widget _buildFriendsCountSubSelector() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF031638),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Friend Count:",
            style: TextStyle(
              color: Colors.amber,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildCountOptionPill(
                  count: 2,
                  label: "👥 2 Friends",
                  keyName: "option_2",
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildCountOptionPill(
                  count: 3,
                  label: "👥 3 Friends",
                  keyName: "option_3",
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildCountOptionPill(
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

  Widget _buildCountOptionPill({
    required int count,
    required String label,
    required String keyName,
  }) {
    final isSelected = _selectedCount == count;
    return InkWell(
      key: Key(keyName),
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setState(() {
          _selectedCount = count;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : const Color(0xFF082250),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerModeCard({
    required int modeIndex,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
    Widget? customPreview,
    Widget? child,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0B2D6E)
                : const Color(0xFF041738),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFFFFC107) : Colors.white12,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.25),
                  blurRadius: 10,
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // Active Checkmark Indicator
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isSelected ? Colors.amber : Colors.white24,
                    size: 20,
                  ),
                  const SizedBox(width: 8),

                  // Mini preview icon
                  customPreview ??
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade900,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(icon, color: Colors.cyanAccent, size: 18),
                      ),

                  const SizedBox(width: 8),

                  // Title and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 2,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: isSelected ? Colors.amber : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (badge != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: Colors.amber, width: 0.8),
                                ),
                                child: Text(
                                  badge,
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ?child,
            ],
          ),
        ),
      ),
    );
  }

  // Classic Square Board 4-quadrant preview graphic
  Widget _buildClassicBoardMiniIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white30, width: 0.8),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(color: LudoColors.red),
                ),
                Expanded(
                  child: Container(color: LudoColors.green),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(color: LudoColors.blue),
                ),
                Expanded(
                  child: Container(color: LudoColors.yellow),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
