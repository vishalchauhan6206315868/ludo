import 'package:flutter/material.dart';
import '../models/ludo_player.dart';
import '../services/sound_haptic_service.dart';

class PassNPlayHandoffOverlay extends StatelessWidget {
  final LudoPlayer nextPlayer;
  final VoidCallback onReady;

  const PassNPlayHandoffOverlay({
    super.key,
    required this.nextPlayer,
    required this.onReady,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          // Absorb and consume all taps to block board / dice interaction
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: Container(
            color: const Color(0xEE060B19),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            alignment: Alignment.center,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1A30),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: nextPlayer.primaryColor.withValues(alpha: 0.30),
                        blurRadius: 36,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.75),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mode Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFFFF8F00).withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Text(
                          "PASS N PLAY",
                          style: TextStyle(
                            color: Color(0xFF10192D),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Animated Pulsing Device Handoff Icon
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF14203D),
                          border: Border.all(
                            color: nextPlayer.primaryColor,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: nextPlayer.primaryColor
                                  .withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.phonelink_ring_rounded,
                          color: nextPlayer.primaryColor,
                          size: 46,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Title: PASS THE DEVICE
                      const Text(
                        "PASS THE DEVICE",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Subtitle: Pass the device to
                      const Text(
                        "Pass the device to",
                        style: TextStyle(
                          color: Color(0xFF90A4AE),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Next Player Badge with Avatar & Color
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14203D),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: nextPlayer.primaryColor.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: nextPlayer.primaryColor,
                                border: Border.all(color: Colors.white, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: nextPlayer.primaryColor
                                        .withValues(alpha: 0.7),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                nextPlayer.name.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: nextPlayer.lightColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 26),

                      // "I'M READY" Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFD54F),
                                Color(0xFFFFB300),
                                Color(0xFFFF8F00),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8F00)
                                    .withValues(alpha: 0.5),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              key: const Key('pass_n_play_ready_button'),
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                SoundHapticService.playTokenStepSound();
                                onReady();
                              },
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.play_arrow_rounded,
                                      color: Color(0xFF10192D),
                                      size: 26,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "I'M READY",
                                      style: TextStyle(
                                        color: Color(0xFF10192D),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
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
            ),
          ),
        ),
      ),
    );
  }
}
