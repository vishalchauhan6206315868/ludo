import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/sound_haptic_service.dart';

/// Attractive 3D Gaming Settings Dialog for Ludo Supreme.
/// Matches the Royal Blue & Gold 3D Gaming theme with custom glowing headers,
/// 3D capsule toggle switches, golden crown, and festive Ludo board footer.
class SettingsDialog extends StatefulWidget {
  final VoidCallback? onRestart;
  final VoidCallback? onExitToMenu;

  const SettingsDialog({
    super.key,
    this.onRestart,
    this.onExitToMenu,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  bool _sound = SoundHapticService.isSoundEnabled;
  bool _haptics = SoundHapticService.isHapticsEnabled;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final viewInsets = mediaQuery.viewInsets.bottom;
    final maxHeight = (screenHeight * 0.90) - viewInsets;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 390,
          maxHeight: maxHeight.clamp(320.0, 720.0),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Outer Main Dialog Container
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF00A3FF),
                  width: 3.0,
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF061848),
                    Color(0xFF030D26),
                    Color(0xFF010614),
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x990077FF),
                    blurRadius: 26,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black87,
                    blurRadius: 22,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Header Ribbon with Crown & Close Button
                      _buildHeaderRibbon(context),

                      const SizedBox(height: 18),

                      // Setting Option 1: Sound Effects
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _SettingCardTile(
                          iconData: Icons.volume_up_rounded,
                          title: "Sound Effects",
                          subtitle: "Audio feedback on rolls and moves",
                          value: _sound,
                          onChanged: (val) async {
                            await SoundHapticService.toggleSound();
                            if (mounted) {
                              setState(() {
                                _sound = SoundHapticService.isSoundEnabled;
                              });
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Setting Option 2: Haptic Feedback
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _SettingCardTile(
                          iconData: Icons.vibration_rounded,
                          title: "Haptic Feedback",
                          subtitle: "Vibrations on captures & turns",
                          value: _haptics,
                          onChanged: (val) async {
                            await SoundHapticService.toggleHaptics();
                            if (mounted) {
                              setState(() {
                                _haptics = SoundHapticService.isHapticsEnabled;
                              });
                            }
                          },
                        ),
                      ),

                      // Optional In-Match Action Buttons (if active match)
                      if (widget.onRestart != null || widget.onExitToMenu != null) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Column(
                            children: [
                              if (widget.onRestart != null) ...[
                                _ActionGameButton(
                                  label: "Restart Match",
                                  icon: Icons.refresh_rounded,
                                  isDestructive: false,
                                  onPressed: () {
                                    Navigator.pop(context);
                                    widget.onRestart?.call();
                                  },
                                ),
                                const SizedBox(height: 10),
                              ],
                              if (widget.onExitToMenu != null) ...[
                                _ActionGameButton(
                                  label: "Quit to Main Menu",
                                  icon: Icons.home_rounded,
                                  isDestructive: true,
                                  onPressed: () {
                                    Navigator.pop(context);
                                    widget.onExitToMenu?.call();
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Festive 3D Ludo Board + Pawns + Glowing Dice Footer
                      const _LudoBoardFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the top curved 3D ribbon banner with 3D text, golden crown, and close button.
  Widget _buildHeaderRibbon(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 10, bottom: 12, left: 10, right: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0080FF),
            Color(0xFF0052D4),
            Color(0xFF0036A5),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        border: Border.all(
          color: const Color(0xFF00D2FF),
          width: 2.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99002E8A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Crown on Left
          const Positioned(
            left: 2,
            top: -2,
            child: _GoldenCrownWidget(),
          ),

          // Central 3D Title: "Game Settings"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 42),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // "Game" in pure bold white with 3D drop-shadow
                  Text(
                    "Game ",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      shadows: [
                        const Shadow(
                          color: Color(0xFF001E5B),
                          offset: Offset(0, 3),
                          blurRadius: 2,
                        ),
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          offset: const Offset(0, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  // "Settings" in vibrant warm yellow/gold with 3D drop-shadow
                  Text(
                    "Settings",
                    style: TextStyle(
                      color: const Color(0xFFFFD400),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      shadows: [
                        const Shadow(
                          color: Color(0xFF944F00),
                          offset: Offset(0, 3),
                          blurRadius: 2,
                        ),
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          offset: const Offset(0, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Circular Close Button on Right
          Positioned(
            right: 2,
            child: _CircularCloseButton(
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular Gold-Rimmed Close Button
class _CircularCloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CircularCloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E88E5),
              Color(0xFF0D47A1),
            ],
          ),
          border: Border.all(
            color: const Color(0xFFFFD700),
            width: 2.4,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66FFD700),
              blurRadius: 8,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black54,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.close_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// 3D Golden Crown with Ruby Gemstone
class _GoldenCrownWidget extends StatelessWidget {
  const _GoldenCrownWidget();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.18, // slightly tilted crown
      child: CustomPaint(
        size: const Size(44, 38),
        painter: _CrownPainter(),
      ),
    );
  }
}

class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer shadow
    final shadowPaint = Paint()
      ..color = Colors.black45
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final crownPath = Path()
      ..moveTo(w * 0.12, h * 0.88)
      ..lineTo(w * 0.05, h * 0.28)
      ..lineTo(w * 0.32, h * 0.52)
      ..lineTo(w * 0.50, h * 0.12)
      ..lineTo(w * 0.68, h * 0.52)
      ..lineTo(w * 0.95, h * 0.28)
      ..lineTo(w * 0.88, h * 0.88)
      ..close();
    canvas.drawPath(crownPath.shift(const Offset(0, 2)), shadowPaint);

    // Crown Body Gradient (Golden yellow to deep amber)
    final goldShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFF275),
        Color(0xFFFFD000),
        Color(0xFFFFA000),
        Color(0xFFFF6F00),
      ],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final crownPaint = Paint()
      ..shader = goldShader
      ..style = PaintingStyle.fill;
    canvas.drawPath(crownPath, crownPaint);

    // Crown Base Rim
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.10, h * 0.72, w * 0.80, h * 0.18),
      const Radius.circular(4),
    );
    final rimShader = const LinearGradient(
      colors: [Color(0xFFFFECB3), Color(0xFFFFB300), Color(0xFFFF8F00)],
    ).createShader(baseRect.outerRect);
    canvas.drawRRect(baseRect, Paint()..shader = rimShader);
    canvas.drawRRect(
      baseRect,
      Paint()
        ..color = const Color(0xFFFFF9C4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Three golden pearls at the tips of the crown
    final pearlPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.white, Color(0xFFFFD54F), Color(0xFFFF8F00)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawCircle(Offset(w * 0.05, h * 0.28), 3.2, pearlPaint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.12), 4.2, pearlPaint);
    canvas.drawCircle(Offset(w * 0.95, h * 0.28), 3.2, pearlPaint);

    // Red Ruby Gemstone in the center of the base band
    final rubyCenter = Offset(w * 0.50, h * 0.81);
    final rubyPath = Path()
      ..moveTo(rubyCenter.dx, rubyCenter.dy - 4.5)
      ..lineTo(rubyCenter.dx + 4.5, rubyCenter.dy)
      ..lineTo(rubyCenter.dx, rubyCenter.dy + 4.5)
      ..lineTo(rubyCenter.dx - 4.5, rubyCenter.dy)
      ..close();

    final rubyShader = const RadialGradient(
      colors: [
        Color(0xFFFF8A80),
        Color(0xFFE53935),
        Color(0xFFB71C1C),
      ],
    ).createShader(Rect.fromCircle(center: rubyCenter, radius: 5));

    canvas.drawPath(rubyPath, Paint()..shader = rubyShader);
    canvas.drawPath(
      rubyPath,
      Paint()
        ..color = const Color(0xFFFFCDD2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Setting Card Tile with Circular Gold Badge and 3D Capsule Toggle Switch
class _SettingCardTile extends StatelessWidget {
  final IconData iconData;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingCardTile({
    required this.iconData,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B2462),
              Color(0xFF061845),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF1E5BB8),
            width: 1.8,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Circular Gold-Rimmed Icon Badge
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFF165CD2),
                    Color(0xFF0A2466),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFFFCC00),
                  width: 3.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55FFC72C),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  iconData,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Thin vertical separator line
            Container(
              width: 1.5,
              height: 38,
              color: const Color(0xFF1E52A4),
            ),

            const SizedBox(width: 12),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF8EBAE5),
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // 3D Capsule Toggle Switch
            _CapsuleToggleSwitch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom 3D Glossy Capsule Toggle Switch matching the reference image.
class _CapsuleToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CapsuleToggleSwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: 66,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: value
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFB800),
                    Color(0xFFFF7A00),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1E355C),
                    Color(0xFF101D33),
                  ],
                ),
          border: Border.all(
            color: value ? const Color(0xFFFFD54F) : const Color(0xFF2C4B79),
            width: 2.2,
          ),
          boxShadow: [
            if (value)
              const BoxShadow(
                color: Color(0x77FF8F00),
                blurRadius: 10,
                spreadRadius: 1,
              )
            else
              const BoxShadow(
                color: Colors.black45,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment(-0.25, -0.25),
                colors: [
                  Colors.white,
                  Color(0xFFF0F0F0),
                  Color(0xFFD6D6D6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom 3D Action Game Button for In-Match Restart & Exit
class _ActionGameButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDestructive;
  final VoidCallback onPressed;

  const _ActionGameButton({
    required this.label,
    required this.icon,
    required this.isDestructive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = isDestructive
        ? const [Color(0xFFE53935), Color(0xFFC62828), Color(0xFFB71C1C)]
        : const [Color(0xFFFFB300), Color(0xFFFF8F00), Color(0xFFE65100)];
    final borderColor = isDestructive ? const Color(0xFFFF8A80) : const Color(0xFFFFE082);

    return Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
        border: Border.all(color: borderColor, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: isDestructive ? const Color(0x66E53935) : const Color(0x66FF8F00),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Festive Footer Illustration featuring:
/// - 4 Glossy 3D Gotiyan (Red, Blue, Green, Yellow)
/// - Center Glowing 3D Isometric White Ludo Dice with sparkles & aura rays
/// - Curved Ludo Board track beneath the pawns
class _LudoBoardFooter extends StatelessWidget {
  const _LudoBoardFooter();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 140,
      child: CustomPaint(
        painter: _LudoFooterPainter(),
      ),
    );
  }
}

class _LudoFooterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw Radiating Golden Aura Rays behind the central dice
    _drawRadiatingRays(canvas, Offset(w * 0.50, h * 0.58), 65);

    // 2. Draw Curved Ludo Board Track at the bottom
    _drawCurvedLudoBoard(canvas, w, h);

    // 3. Draw 4 Glossy 3D Pawns (Red, Blue, Green, Yellow)
    // Red pawn on red track (far left)
    _drawGlossyPawn(
      canvas,
      position: Offset(w * 0.13, h * 0.72),
      baseColor: const Color(0xFFE53935),
      darkColor: const Color(0xFFB71C1C),
      highlightColor: const Color(0xFFFF8A80),
      scale: 0.95,
    );

    // Blue pawn on blue track (mid-left)
    _drawGlossyPawn(
      canvas,
      position: Offset(w * 0.28, h * 0.76),
      baseColor: const Color(0xFF1E88E5),
      darkColor: const Color(0xFF0D47A1),
      highlightColor: const Color(0xFF82B1FF),
      scale: 0.95,
    );

    // Green pawn on green track (mid-right)
    _drawGlossyPawn(
      canvas,
      position: Offset(w * 0.72, h * 0.76),
      baseColor: const Color(0xFF43A047),
      darkColor: const Color(0xFF1B5E20),
      highlightColor: const Color(0xFFB9F6CA),
      scale: 0.95,
    );

    // Yellow pawn on yellow track (far right)
    _drawGlossyPawn(
      canvas,
      position: Offset(w * 0.87, h * 0.72),
      baseColor: const Color(0xFFFFB300),
      darkColor: const Color(0xFFE65100),
      highlightColor: const Color(0xFFFFF9C4),
      scale: 0.95,
    );

    // 4. Draw Central Glowing 3D Isometric White Ludo Dice
    _drawGlowing3DDice(canvas, Offset(w * 0.50, h * 0.62), 26);
  }

  /// Draws golden light aura rays radiating behind the central dice
  void _drawRadiatingRays(Canvas canvas, Offset center, double radius) {
    final rayPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD54F).withValues(alpha: 0.45),
          const Color(0xFFFFA000).withValues(alpha: 0.20),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.3));

    canvas.drawCircle(center, radius * 1.2, rayPaint);

    // Dynamic sparks/rays
    final sparkPaint = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.85)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3.0) + 0.3;
      final startDist = radius * 0.55;
      final endDist = radius * 0.85;
      final p1 = Offset(center.dx + math.cos(angle) * startDist, center.dy + math.sin(angle) * startDist);
      final p2 = Offset(center.dx + math.cos(angle) * endDist, center.dy + math.sin(angle) * endDist);
      canvas.drawLine(p1, p2, sparkPaint);
    }
  }

  /// Draws the curved Ludo board track with Red, Blue, Green, Yellow sections
  void _drawCurvedLudoBoard(Canvas canvas, double w, double h) {
    // Board surface path (curved upward arc)
    final boardPath = Path()
      ..moveTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.5, h * 0.86, w, h * 0.72)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    // Base board gradient
    final boardShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF0D3278),
        Color(0xFF041235),
      ],
    ).createShader(Rect.fromLTWH(0, h * 0.70, w, h * 0.30));

    canvas.drawPath(boardPath, Paint()..shader = boardShader);

    // Colored track quadrants across the board width
    final sections = [
      {'color': const Color(0xFFD32F2F), 'start': 0.0, 'end': 0.25}, // Red
      {'color': const Color(0xFF1976D2), 'start': 0.25, 'end': 0.50}, // Blue
      {'color': const Color(0xFF388E3C), 'start': 0.50, 'end': 0.75}, // Green
      {'color': const Color(0xFFFBC02D), 'start': 0.75, 'end': 1.0}, // Yellow
    ];

    canvas.save();
    canvas.clipPath(boardPath);

    for (final sec in sections) {
      final color = sec['color'] as Color;
      final startX = (sec['start'] as double) * w;
      final endX = (sec['end'] as double) * w;

      final secRect = Rect.fromLTRB(startX, h * 0.70, endX, h);
      final secPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.95),
            color.withValues(alpha: 0.70),
          ],
        ).createShader(secRect);

      canvas.drawRect(secRect, secPaint);

      // Tile grid lines inside each section
      final gridPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      final tileWidth = (endX - startX) / 3.0;
      for (int i = 1; i < 3; i++) {
        final gx = startX + (i * tileWidth);
        canvas.drawLine(Offset(gx, h * 0.70), Offset(gx, h), gridPaint);
      }
      canvas.drawLine(Offset(startX, h * 0.85), Offset(endX, h * 0.85), gridPaint);
    }

    canvas.restore();

    // Top Glowing Board Border (Electric cyan & gold)
    final topBorderPath = Path()
      ..moveTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.5, h * 0.86, w, h * 0.72);

    final cyanGlowPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8;
    canvas.drawPath(topBorderPath, cyanGlowPaint);

    final goldAccentPaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(topBorderPath.shift(const Offset(0, 2)), goldAccentPaint);
  }

  /// Draws a glossy 3D pawn (goti) with spherical head, collar, bell body, and base rim.
  void _drawGlossyPawn(
    Canvas canvas, {
    required Offset position,
    required Color baseColor,
    required Color darkColor,
    required Color highlightColor,
    double scale = 1.0,
  }) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.scale(scale);

    // 1. Soft bottom shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 24), width: 28, height: 8),
      shadowPaint,
    );

    // 2. Base Ring / Foot
    final baseRect = Rect.fromCenter(center: const Offset(0, 20), width: 26, height: 9);
    final baseShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [highlightColor, baseColor, darkColor],
    ).createShader(baseRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, const Radius.circular(5)),
      Paint()..shader = baseShader,
    );

    // 3. Pawn Body (Bell / cone shape)
    final bodyPath = Path()
      ..moveTo(-4, 2)
      ..quadraticBezierTo(-6, 12, -11, 18)
      ..lineTo(11, 18)
      ..quadraticBezierTo(6, 12, 4, 2)
      ..close();

    final bodyRect = Rect.fromLTWH(-11, 2, 22, 16);
    final bodyShader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [darkColor, highlightColor, baseColor, darkColor],
      stops: const [0.0, 0.35, 0.70, 1.0],
    ).createShader(bodyRect);
    canvas.drawPath(bodyPath, Paint()..shader = bodyShader);

    // 4. Collar Ring (Between head and body)
    final collarRect = Rect.fromCenter(center: const Offset(0, 1), width: 14, height: 4.5);
    final collarShader = LinearGradient(
      colors: [highlightColor, baseColor, darkColor],
    ).createShader(collarRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(collarRect, const Radius.circular(2)),
      Paint()..shader = collarShader,
    );

    // 5. Spherical Head
    final headCenter = const Offset(0, -9);
    const headRadius = 8.5;
    final headShader = RadialGradient(
      center: const Alignment(-0.35, -0.40),
      radius: 0.9,
      colors: [
        Colors.white,
        highlightColor,
        baseColor,
        darkColor,
      ],
      stops: const [0.0, 0.25, 0.65, 1.0],
    ).createShader(Rect.fromCircle(center: headCenter, radius: headRadius));

    canvas.drawCircle(headCenter, headRadius, Paint()..shader = headShader);

    canvas.restore();
  }

  /// Draws a tilted, glowing 3D isometric white Ludo dice showing dots (pips).
  void _drawGlowing3DDice(Canvas canvas, Offset center, double size) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.12); // subtle tilt for dynamic game look

    final s = size;

    // Dice shadow
    final diceShadow = Paint()
      ..color = Colors.black45
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, s * 0.95), width: s * 1.8, height: s * 0.6),
      diceShadow,
    );

    // 3D Isometric Cube Faces:
    // Top Face (Rhombus)
    final topFace = Path()
      ..moveTo(0, -s * 0.90)
      ..lineTo(s * 0.85, -s * 0.45)
      ..lineTo(0, 0)
      ..lineTo(-s * 0.85, -s * 0.45)
      ..close();

    final topShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.white, Color(0xFFF5F7FA)],
    ).createShader(Rect.fromLTWH(-s, -s, s * 2, s));
    canvas.drawPath(topFace, Paint()..shader = topShader);

    // Left Face
    final leftFace = Path()
      ..moveTo(-s * 0.85, -s * 0.45)
      ..lineTo(0, 0)
      ..lineTo(0, s * 0.90)
      ..lineTo(-s * 0.85, s * 0.45)
      ..close();

    final leftShader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
    ).createShader(Rect.fromLTWH(-s, 0, s, s));
    canvas.drawPath(leftFace, Paint()..shader = leftShader);

    // Right Face
    final rightFace = Path()
      ..moveTo(0, 0)
      ..lineTo(s * 0.85, -s * 0.45)
      ..lineTo(s * 0.85, s * 0.45)
      ..lineTo(0, s * 0.90)
      ..close();

    final rightShader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
    ).createShader(Rect.fromLTWH(0, 0, s, s));
    canvas.drawPath(rightFace, Paint()..shader = rightShader);

    // Cube Edge Outlines
    final edgePaint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(topFace, edgePaint);
    canvas.drawPath(leftFace, edgePaint);
    canvas.drawPath(rightFace, edgePaint);

    // Pip / Dot Paint
    final pipPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    // Top Face: 5 Pips
    final topCenter = Offset(0, -s * 0.45);
    _drawPip(canvas, topCenter, 2.4, pipPaint);
    _drawPip(canvas, Offset(topCenter.dx - s * 0.35, topCenter.dy - s * 0.18), 2.2, pipPaint);
    _drawPip(canvas, Offset(topCenter.dx + s * 0.35, topCenter.dy - s * 0.18), 2.2, pipPaint);
    _drawPip(canvas, Offset(topCenter.dx - s * 0.35, topCenter.dy + s * 0.18), 2.2, pipPaint);
    _drawPip(canvas, Offset(topCenter.dx + s * 0.35, topCenter.dy + s * 0.18), 2.2, pipPaint);

    // Left Face: 3 Pips (Diagonal)
    _drawPip(canvas, Offset(-s * 0.45, s * 0.15), 2.5, pipPaint);
    _drawPip(canvas, Offset(-s * 0.22, s * 0.42), 2.5, pipPaint);
    _drawPip(canvas, Offset(-s * 0.65, -s * 0.10), 2.5, pipPaint);

    // Right Face: 4 Pips
    _drawPip(canvas, Offset(s * 0.30, s * 0.05), 2.4, pipPaint);
    _drawPip(canvas, Offset(s * 0.60, -s * 0.12), 2.4, pipPaint);
    _drawPip(canvas, Offset(s * 0.30, s * 0.50), 2.4, pipPaint);
    _drawPip(canvas, Offset(s * 0.60, s * 0.32), 2.4, pipPaint);

    canvas.restore();
  }

  void _drawPip(Canvas canvas, Offset offset, double radius, Paint paint) {
    canvas.drawCircle(offset, radius, paint);
    // Tiny white shine inside the pip
    final shinePaint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(offset.dx - radius * 0.3, offset.dy - radius * 0.3), radius * 0.35, shinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
