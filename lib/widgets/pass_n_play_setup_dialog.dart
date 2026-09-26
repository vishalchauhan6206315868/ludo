import 'package:flutter/material.dart';
import '../constants/ludo_colors.dart';

class PassNPlayConfig {
  final int playerCount;
  final List<String> playerNames;

  const PassNPlayConfig({
    required this.playerCount,
    required this.playerNames,
  });
}

class PassNPlaySetupDialog extends StatefulWidget {
  final int initialCount;

  const PassNPlaySetupDialog({
    super.key,
    this.initialCount = 2,
  });

  @override
  State<PassNPlaySetupDialog> createState() => _PassNPlaySetupDialogState();
}

class _PassNPlaySetupDialogState extends State<PassNPlaySetupDialog> {
  late int _playerCount;
  late final List<TextEditingController> _nameControllers;

  @override
  void initState() {
    super.initState();
    _playerCount = widget.initialCount.clamp(2, 4);
    _nameControllers = List.generate(
      4,
      (index) => TextEditingController(text: "Player ${index + 1}"),
    );
  }

  @override
  void dispose() {
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Color _getColorForIndex(int index, int totalCount) {
    if (totalCount == 2) {
      return index == 0 ? LudoColors.red : LudoColors.yellow;
    } else if (totalCount == 3) {
      switch (index) {
        case 0:
          return LudoColors.red;
        case 1:
          return LudoColors.green;
        case 2:
          return LudoColors.yellow;
        default:
          return LudoColors.red;
      }
    } else {
      switch (index) {
        case 0:
          return LudoColors.red;
        case 1:
          return LudoColors.green;
        case 2:
          return LudoColors.yellow;
        case 3:
          return LudoColors.blue;
        default:
          return LudoColors.red;
      }
    }
  }

  String _getColorNameForIndex(int index, int totalCount) {
    if (totalCount == 2) {
      return index == 0 ? "Red" : "Yellow";
    } else if (totalCount == 3) {
      switch (index) {
        case 0:
          return "Red";
        case 1:
          return "Green";
        case 2:
          return "Yellow";
        default:
          return "Red";
      }
    } else {
      switch (index) {
        case 0:
          return "Red";
        case 1:
          return "Green";
        case 2:
          return "Yellow";
        case 3:
          return "Blue";
        default:
          return "Red";
      }
    }
  }

  void _onStart() {
    final names = <String>[];
    for (int i = 0; i < _playerCount; i++) {
      final text = _nameControllers[i].text.trim();
      names.add(text.isNotEmpty ? text : "Player ${i + 1}");
    }
    Navigator.pop(
      context,
      PassNPlayConfig(playerCount: _playerCount, playerNames: names),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F1A30),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.8),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                blurRadius: 28,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFF8F00).withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.phonelink_ring_rounded,
                        color: Color(0xFF10192D),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "PASS N PLAY SETUP",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Local multiplayer on this device",
                            style: TextStyle(
                              color: Color(0xFFB0BEC5),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: "Close",
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0x33FFD700), height: 1),

              // Scrollable Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step 1: Select Player Count
                      const Text(
                        "1. SELECT PLAYER COUNT",
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          _buildPlayerCountButton(2, "2 Players"),
                          const SizedBox(width: 8),
                          _buildPlayerCountButton(3, "3 Players"),
                          const SizedBox(width: 8),
                          _buildPlayerCountButton(4, "4 Players"),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Step 2: Configure Player Names
                      const Text(
                        "2. CONFIGURE PLAYER NAMES",
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),

                      ...List.generate(_playerCount, (idx) {
                        final color = _getColorForIndex(idx, _playerCount);
                        final colorName =
                            _getColorNameForIndex(idx, _playerCount);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14203D),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: color.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color,
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.6),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    "${idx + 1}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  key: Key('player_name_input_$idx'),
                                  controller: _nameControllers[idx],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            vertical: 8),
                                    border: InputBorder.none,
                                    hintText: "Player ${idx + 1}",
                                    hintStyle: const TextStyle(
                                        color: Colors.white38),
                                    suffixText: colorName,
                                    suffixStyle: TextStyle(
                                      color: color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 12),

                      // Info banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0x33FFB300),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0x66FFB300),
                            width: 1.0,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: Color(0xFFFFD54F), size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Turn rotates automatically. Pass the device when prompted!",
                                style: TextStyle(
                                  color: Color(0xFFFFECB3),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
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

              const Divider(color: Color(0x33FFD700), height: 1),

              // Bottom Action Button
              Padding(
                padding: const EdgeInsets.all(18),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFD54F),
                          Color(0xFFFFB300),
                          Color(0xFFFF8F00),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFFF8F00).withValues(alpha: 0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const Key('start_pass_n_play_button'),
                        borderRadius: BorderRadius.circular(16),
                        onTap: _onStart,
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded,
                                  color: Color(0xFF10192D), size: 26),
                              SizedBox(width: 6),
                              Text(
                                "START PASS N PLAY",
                                style: TextStyle(
                                  color: Color(0xFF10192D),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
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
    );
  }

  Widget _buildPlayerCountButton(int count, String label) {
    final isSelected = _playerCount == count;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('option_${count}p'),
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            setState(() {
              _playerCount = count;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFFB300)
                  : const Color(0xFF14203D),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFFD700)
                    : Colors.white.withValues(alpha: 0.15),
                width: isSelected ? 1.8 : 1.0,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.groups_rounded,
                  color: isSelected ? const Color(0xFF10192D) : Colors.white70,
                  size: 22,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color:
                        isSelected ? const Color(0xFF10192D) : Colors.white70,
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
