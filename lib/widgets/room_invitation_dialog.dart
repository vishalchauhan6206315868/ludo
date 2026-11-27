import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/room_model.dart';

/// Royal Navy & Gold Confirmation Dialog for 1-Click Room Joining
class RoomInvitationDialog extends StatelessWidget {
  final RoomModel room;
  final int userBalance;
  final VoidCallback onConfirmJoin;
  final VoidCallback? onCancel;

  const RoomInvitationDialog({
    super.key,
    required this.room,
    required this.userBalance,
    required this.onConfirmJoin,
    this.onCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required RoomModel room,
    required int userBalance,
    required VoidCallback onConfirmJoin,
    VoidCallback? onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (ctx) => RoomInvitationDialog(
        room: room,
        userBalance: userBalance,
        onConfirmJoin: onConfirmJoin,
        onCancel: onCancel,
      ),
    );
  }

  String _formatMode(String mode, int maxP) {
    final m = mode.toLowerCase();
    if (m.contains('two') || maxP == 2) return '2 Players Match';
    if (m.contains('three') || maxP == 3) return '3 Players Match';
    if (m.contains('four') || maxP == 4) return '4 Players Match';
    return 'Classic Match';
  }

  @override
  Widget build(BuildContext context) {
    final modeLabel = _formatMode(room.gameMode, room.maxPlayers);
    final feeLabel = room.entryFee > 0 ? '${room.entryFee} Coins' : 'Free Entry';
    final slotsLabel = '${room.players.length}/${room.maxPlayers} Joined';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0F1E48),
                  Color(0xFF081334),
                  Color(0xFF030718),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFFFFD700),
                width: 2.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
                const BoxShadow(
                  color: Colors.black87,
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Crown / Dice Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA000), Color(0xFF7B4D00)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.45),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.sports_esports_rounded,
                    color: Color(0xFF1B0F00),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),

                // Title Banner
                const Text(
                  "MATCH INVITATION",
                  style: TextStyle(
                    color: Color(0xFFFFE082),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "You've been invited to join an online Ludo match!",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),

                // Big Golden Room Code Capsule
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF070E22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFFD700),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "ROOM CODE",
                        style: TextStyle(
                          color: Color(0xFFE5C07B),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        room.roomCode,
                        style: const TextStyle(
                          color: Color(0xFFFFE082),
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                          shadows: [
                            Shadow(color: Color(0xFFFFB300), blurRadius: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Match Metadata Info Chips (Mode, Entry, Players)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF091434),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildInfoColumn(Icons.videogame_asset_rounded, modeLabel, const Color(0xFF00E5FF)),
                      Container(width: 1, height: 26, color: Colors.white24),
                      _buildInfoColumn(Icons.monetization_on_rounded, feeLabel, const Color(0xFFFFD700)),
                      Container(width: 1, height: 26, color: Colors.white24),
                      _buildInfoColumn(Icons.group_rounded, slotsLabel, const Color(0xFF00E676)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Host info if available
                if (room.players.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      "Host: ${room.players.first}",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                // Action Buttons: [ JOIN MATCH ] & [ CANCEL ]
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop(false);
                          if (onCancel != null) onCancel!();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "CANCEL",
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Join Match Button
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E676), Color(0xFF00C853), Color(0xFF009624)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E676).withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.of(context).pop(true);
                            onConfirmJoin();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
                                SizedBox(width: 4),
                                Text(
                                  "JOIN MATCH",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String label, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
