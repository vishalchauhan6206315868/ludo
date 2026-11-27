import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/room_model.dart';

/// Royal 3D Gaming Social Share Dialog for Ludo Supreme
/// Features 3D Golden Crown with radiant rays, floating dice, standing tokens,
/// 3D curled golden ribbon, hex neon room code capsule with gold copy button,
/// primary red & gold action button, 8 circular 3D social badges with mini ribbons,
/// and bottom gaming art.
class SocialShareBottomSheet extends StatefulWidget {
  final RoomModel room;
  final bool autoCopied;

  const SocialShareBottomSheet({
    super.key,
    required this.room,
    this.autoCopied = false,
  });

  /// Static helper to display the social share showcase from any screen or dialog.
  static Future<void> show(
    BuildContext context, {
    required RoomModel room,
    bool autoCopied = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (ctx) => SocialShareBottomSheet(
        room: room,
        autoCopied: autoCopied,
      ),
    );
  }

  /// Generates a rich, dynamic invite message containing actual room metadata.
  static String generateInviteMessage(RoomModel room) {
    final modeLabel = _formatMode(room.gameMode);
    final feeLabel = room.entryFee > 0 ? '${room.entryFee} Coins' : 'Free Entry';
    final joinUrl = 'https://ludoapi-jupm.onrender.com/join/${room.roomCode}';

    return '''🎲 *Ludo Supreme Match Invitation!* 🏆

Join my Ludo match!

🔑 Room Code: ${room.roomCode}
🎮 Mode: $modeLabel
💰 Entry: $feeLabel

👉 Join directly:
$joinUrl

👑 Let's play and see who wins!''';
  }

  static String _formatMode(String mode) {
    final m = mode.toLowerCase();
    if (m.contains('two') || m == '2p') return '2 Players Match';
    if (m.contains('three') || m == '3p') return '3 Players Match';
    if (m.contains('four') || m == '4p') return '4 Players Match';
    return 'Classic Match';
  }

  @override
  State<SocialShareBottomSheet> createState() => _SocialShareBottomSheetState();
}

class _SocialShareBottomSheetState extends State<SocialShareBottomSheet> {
  bool _isCopied = false;
  Timer? _copyTimer;

  @override
  void initState() {
    super.initState();
    _isCopied = widget.autoCopied;
  }

  @override
  void dispose() {
    _copyTimer?.cancel();
    super.dispose();
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.room.roomCode));
    HapticFeedback.mediumImpact();
    setState(() => _isCopied = true);
    _copyTimer?.cancel();
    _copyTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  Future<void> _shareToWhatsApp() async {
    final msg = SocialShareBottomSheet.generateInviteMessage(widget.room);
    final encoded = Uri.encodeComponent(msg);
    await _safeLaunch(
      'whatsapp://send?text=$encoded',
      fallbackText: msg,
      webFallback: 'https://api.whatsapp.com/send?text=$encoded',
    );
  }

  Future<void> _shareToWhatsAppStatus() async {
    final msg = SocialShareBottomSheet.generateInviteMessage(widget.room);
    final encoded = Uri.encodeComponent(msg);
    await _safeLaunch(
      'whatsapp://send?text=$encoded',
      fallbackText: msg,
      webFallback: 'https://api.whatsapp.com/send?text=$encoded',
    );
  }

  Future<void> _shareToInstagram() async {
    final msg = SocialShareBottomSheet.generateInviteMessage(widget.room);
    Clipboard.setData(ClipboardData(text: widget.room.roomCode));
    await _safeLaunch(
      'instagram://story-camera',
      fallbackText: msg,
      webFallback: 'https://www.instagram.com',
    );
  }

  Future<void> _shareToFacebook() async {
    final msg = SocialShareBottomSheet.generateInviteMessage(widget.room);
    final encoded = Uri.encodeComponent(msg);
    await _safeLaunch(
      'fb://facewebmodal/f?href=https://www.facebook.com',
      fallbackText: msg,
      webFallback: 'https://www.facebook.com/sharer/sharer.php?quote=$encoded',
    );
  }

  Future<void> _shareToTwitter() async {
    final msg = SocialShareBottomSheet.generateInviteMessage(widget.room);
    final encoded = Uri.encodeComponent(msg);
    await _safeLaunch(
      'https://twitter.com/intent/tweet?text=$encoded',
      fallbackText: msg,
    );
  }

  Future<void> _shareToSnapchat() async {
    final msg = SocialShareBottomSheet.generateInviteMessage(widget.room);
    Clipboard.setData(ClipboardData(text: widget.room.roomCode));
    await _safeLaunch(
      'snapchat://',
      fallbackText: msg,
    );
  }

  Future<void> _shareToTelegram() async {
    final msg = SocialShareBottomSheet.generateInviteMessage(widget.room);
    final encoded = Uri.encodeComponent(msg);
    await _safeLaunch(
      'tg://msg?text=$encoded',
      fallbackText: msg,
      webFallback: 'https://t.me/share/url?url=&text=$encoded',
    );
  }

  Future<void> _shareToSystemShare() async {
    final msg = SocialShareBottomSheet.generateInviteMessage(widget.room);
    HapticFeedback.lightImpact();
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: msg,
          subject: 'Ludo Supreme Match Invitation',
        ),
      );
    } catch (e) {
      debugPrint('[SHARE] Native share error: $e');
    }
  }

  Future<void> _safeLaunch(
    String uriString, {
    required String fallbackText,
    String? webFallback,
  }) async {
    HapticFeedback.lightImpact();
    try {
      final uri = Uri.parse(uriString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
      if (webFallback != null && webFallback.isNotEmpty) {
        final webUri = Uri.parse(webFallback);
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
          return;
        }
      }
    } catch (e) {
      debugPrint('[SHARE] Direct launch failed: $e');
    }

    // Graceful fallback to Native System Share
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: fallbackText,
          subject: 'Ludo Supreme Match Invitation',
        ),
      );
    } catch (e) {
      debugPrint('[SHARE] Fallback share error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomCode = widget.room.roomCode;
    final screenH = MediaQuery.of(context).size.height;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 395,
          maxHeight: screenH * 0.94,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF071438),
                Color(0xFF040C24),
                Color(0xFF020614),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFFFFD700),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                blurRadius: 26,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              const BoxShadow(
                color: Colors.black87,
                blurRadius: 36,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27.5),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Stack(
                children: [
                  // Subtle Golden Particle Sparks in Background
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BackgroundSparksPainter(),
                    ),
                  ),

                  // Main Content Column
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. TOP HEADER WITH 3D ASSETS & CLOSE BUTTON
                        _buildTopGamingHeader(),
                        const SizedBox(height: 6),

                        // 2. 3D GOLDEN CURLED RIBBON: "Room Code Copied!"
                        _build3DGoldTitleRibbon(),
                        const SizedBox(height: 12),

                        // 3. HEX NEON ROOM CODE CAPSULE + GOLD COPY BUTTON
                        _buildHexRoomCodeCapsule(roomCode),
                        const SizedBox(height: 10),

                        // 4. SUBTITLE PROMPT: "Invite your friends to join your match."
                        _buildSubtitlePrompt(),
                        const SizedBox(height: 12),

                        // 5. PRIMARY RED & GOLD MEGA ACTION BUTTON
                        _buildPrimaryShareButton(),
                        const SizedBox(height: 16),

                        // 6. 2x4 SOCIAL MEDIA BADGES GRID (WITH MINI GOLD RIBBONS)
                        _buildSocialGrid(),
                        const SizedBox(height: 16),

                        // 7. BOTTOM NAVIGATION: "Back to Lobby"
                        _buildBackToLobbyButton(),
                        const SizedBox(height: 12),

                        // 8. BOTTOM DECORATIVE GAMING ART
                        _buildBottomGamingFooter(),
                      ],
                    ),
                  ),

                  // Top-Right Sleek Circular Close Button (X)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1224),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFFD700),
                              width: 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
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
    );
  }

  // ---------------------------------------------------------------------------
  // 1. TOP GAMING HEADER: 3D DICE, CROWN & RAYS, CHECKMARK, 4 TOKENS
  // ---------------------------------------------------------------------------
  Widget _buildTopGamingHeader() {
    return SizedBox(
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center: 3D Crown with Sunburst Light Rays
          Positioned(
            top: 2,
            child: CustomPaint(
              size: const Size(110, 68),
              painter: _RoyalCrownWithSunburstPainter(),
            ),
          ),

          // Center Crown Base: Glossy Green Circle with White Checkmark
          Positioned(
            top: 30,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF00E676),
                    Color(0xFF00B0FF),
                    Color(0xFF00C853),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: const Color(0xFFFFD700),
                  width: 2.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E676).withValues(alpha: 0.6),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 24,
                  shadows: [
                    Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
              ),
            ),
          ),

          // Left: Two 3D Floating White Dice
          Positioned(
            left: 12,
            top: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(
                  size: const Size(32, 32),
                  painter: _IsometricDicePainter(rotation: -0.25, isBig: true),
                ),
                const SizedBox(width: 4),
                CustomPaint(
                  size: const Size(22, 22),
                  painter: _IsometricDicePainter(rotation: 0.35, isBig: false),
                ),
              ],
            ),
          ),

          // Right: 4 Colored Ludo Pawns (Yellow, Red, Green, Blue)
          Positioned(
            right: 44,
            top: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                CustomPaint(
                  size: Size(18, 30),
                  painter: _StandingTokenPainter(color: Color(0xFFFFD600)),
                ),
                SizedBox(width: 2),
                CustomPaint(
                  size: Size(18, 32),
                  painter: _StandingTokenPainter(color: Color(0xFFFF1744)),
                ),
                SizedBox(width: 2),
                CustomPaint(
                  size: Size(18, 31),
                  painter: _StandingTokenPainter(color: Color(0xFF00E676)),
                ),
                SizedBox(width: 2),
                CustomPaint(
                  size: Size(18, 29),
                  painter: _StandingTokenPainter(color: Color(0xFF2979FF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. 3D GOLDEN CURLED RIBBON: "Room Code Copied!"
  // ---------------------------------------------------------------------------
  Widget _build3DGoldTitleRibbon() {
    return CustomPaint(
      painter: _CurledGoldRibbonPainter(),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "Room Code Copied!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
              color: const Color(0xFF1B0F00),
              shadows: [
                Shadow(
                  color: Colors.white.withValues(alpha: 0.7),
                  offset: const Offset(0, 1),
                  blurRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. HEX NEON ROOM CODE CAPSULE + GOLD "COPY" BUTTON
  // ---------------------------------------------------------------------------
  Widget _buildHexRoomCodeCapsule(String roomCode) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F1E48),
            Color(0xFF091434),
            Color(0xFF060D24),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Electric Blue inner edge glow
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                  width: 1.0,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Left decorative shield pointer
                const Icon(
                  Icons.vpn_key_rounded,
                  color: Color(0xFFFFD700),
                  size: 20,
                ),
                const SizedBox(width: 10),

                // Center: ROOM CODE label + Big Dynamic Code
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "ROOM CODE",
                        style: TextStyle(
                          color: Color(0xFFE5C07B),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(height: 1),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          roomCode,
                          style: const TextStyle(
                            color: Color(0xFFFFE082),
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4.0,
                            shadows: [
                              Shadow(
                                color: Color(0xFFFFB300),
                                blurRadius: 12,
                              ),
                              Shadow(
                                color: Colors.black,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: 3D Glossy Gold "Copy" Action Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _copyToClipboard,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isCopied
                              ? [const Color(0xFF00E676), const Color(0xFF00B0FF)]
                              : [const Color(0xFFFFF176), const Color(0xFFFFB300), const Color(0xFFFF8F00)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isCopied ? const Color(0xFF00E676) : const Color(0xFFFFB300))
                                .withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isCopied ? Icons.check_circle_rounded : Icons.copy_rounded,
                            color: const Color(0xFF1B0F00),
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _isCopied ? "Copied" : "Copy",
                            style: const TextStyle(
                              color: Color(0xFF1B0F00),
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
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

  // ---------------------------------------------------------------------------
  // 4. SUBTITLE PROMPT: "Invite your friends to join your match."
  // ---------------------------------------------------------------------------
  Widget _buildSubtitlePrompt() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 16),
          const SizedBox(width: 6),
          Text(
            "Invite your friends to join your match.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 16),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. PRIMARY RED & GOLD MEGA ACTION BUTTON: "Share / Invite Friends >>"
  // ---------------------------------------------------------------------------
  Widget _buildPrimaryShareButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF1744),
            Color(0xFFD50000),
            Color(0xFF8A0000),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFFFFD700),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF1744).withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.35),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _shareToSystemShare,
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Color(0xFF8A0000),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Share / Invite Friends",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    ">>",
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
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

  // ---------------------------------------------------------------------------
  // 6. 2x4 SOCIAL MEDIA BADGES GRID (WITH MINI GOLD RIBBONS)
  // ---------------------------------------------------------------------------
  Widget _buildSocialGrid() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: WhatsApp, WhatsApp Status, Instagram, Facebook
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialBadgeItem(
                assetPath: 'assets/images/social/whatsapp.png',
                fallbackIcon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 24),
                label: "WhatsApp",
                gradientColors: const [Color(0xFF25D366), Color(0xFF128C7E)],
                onTap: _shareToWhatsApp,
              ),
              _buildSocialBadgeItem(
                assetPath: 'assets/images/social/whatsapp_status.png',
                fallbackIcon: const Icon(Icons.donut_large_rounded, color: Colors.white, size: 24),
                label: "WhatsApp Status",
                gradientColors: const [Color(0xFF00BFA5), Color(0xFF00796B)],
                onTap: _shareToWhatsAppStatus,
              ),
              _buildSocialBadgeItem(
                assetPath: 'assets/images/social/instagram.png',
                fallbackIcon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
                label: "Instagram",
                gradientColors: const [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCAF45)],
                onTap: _shareToInstagram,
              ),
              _buildSocialBadgeItem(
                assetPath: 'assets/images/social/facebook.png',
                fallbackIcon: const Text(
                  "f",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'sans-serif',
                  ),
                ),
                label: "Facebook",
                gradientColors: const [Color(0xFF1877F2), Color(0xFF0D47A1)],
                onTap: _shareToFacebook,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Row 2: X / Twitter, Snapchat, Telegram, More Apps
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialBadgeItem(
                assetPath: 'assets/images/social/twitter.png',
                fallbackIcon: const Text(
                  "𝕏",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                label: "X / Twitter",
                gradientColors: const [Color(0xFF1DA1F2), Color(0xFF0C85D0)],
                onTap: _shareToTwitter,
              ),
              _buildSocialBadgeItem(
                assetPath: 'assets/images/social/snapchat.png',
                fallbackIcon: const Icon(Icons.sentiment_very_satisfied_rounded, color: Colors.white, size: 26),
                label: "Snapchat",
                gradientColors: const [Color(0xFFFFFC00), Color(0xFFFFB300)],
                onTap: _shareToSnapchat,
              ),
              _buildSocialBadgeItem(
                assetPath: 'assets/images/social/telegram.png',
                fallbackIcon: Transform.rotate(
                  angle: -0.25,
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 23),
                ),
                label: "Telegram",
                gradientColors: const [Color(0xFF29B6F6), Color(0xFF0288D1)],
                onTap: _shareToTelegram,
              ),
              _buildSocialBadgeItem(
                assetPath: 'assets/images/social/more_apps.png',
                fallbackIcon: const Icon(Icons.share_rounded, color: Colors.white, size: 23),
                label: "More Apps",
                gradientColors: const [Color(0xFF2196F3), Color(0xFF1976D2)],
                onTap: _shareToSystemShare,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Single 3D Circular Badge with Golden Ring & Mini Curved Gold Ribbon below
  Widget _buildSocialBadgeItem({
    required String assetPath,
    required Widget fallbackIcon,
    required String label,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 3D Circular Shield Badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: const Color(0xFFFFD700),
                  width: 2.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withValues(alpha: 0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                  const BoxShadow(
                    color: Colors.black54,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // App Icon Asset Image
                  ClipOval(
                    child: Image.asset(
                      assetPath,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) => Center(child: fallbackIcon),
                    ),
                  ),

                  // Upper Glossy Glass Highlight
                  Positioned(
                    top: 2,
                    left: 5,
                    right: 5,
                    child: IgnorePointer(
                      child: Container(
                        height: 18,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.4),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),

            // Mini Golden Ribbon Banner
            CustomPaint(
              painter: _MiniGoldRibbonPainter(),
              child: Container(
                height: 19,
                constraints: const BoxConstraints(maxWidth: 72, minWidth: 50),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF1B0F00),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. BOTTOM NAVIGATION: "Back to Lobby"
  // ---------------------------------------------------------------------------
  Widget _buildBackToLobbyButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F1E48),
            Color(0xFF091434),
            Color(0xFF060D24),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.8),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.15),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 16),
                SizedBox(width: 8),
                Text(
                  "Back to Lobby",
                  style: TextStyle(
                    color: Color(0xFFFFE082),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 8. BOTTOM DECORATIVE GAMING ART: MINI LUDO BOARD CORNERS + TOKENS
  // ---------------------------------------------------------------------------
  Widget _buildBottomGamingFooter() {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left: Mini Ludo Board Corner with 3D Red Pawn
          Positioned(
            left: 0,
            bottom: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                CustomPaint(
                  size: Size(22, 38),
                  painter: _StandingTokenPainter(color: Color(0xFFFF1744)),
                ),
                SizedBox(width: 4),
                CustomPaint(
                  size: Size(48, 26),
                  painter: _MiniBoardQuadrantPainter(baseColor: Color(0xFFD50000)),
                ),
              ],
            ),
          ),

          // Center: Mini Golden Crown Sparkle
          Positioned(
            bottom: 4,
            child: CustomPaint(
              size: const Size(40, 24),
              painter: _MiniCrownSparklePainter(),
            ),
          ),

          // Right: Mini Ludo Board Corner with 3D Green Pawn
          Positioned(
            right: 0,
            bottom: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                CustomPaint(
                  size: Size(48, 26),
                  painter: _MiniBoardQuadrantPainter(baseColor: Color(0xFF00C853)),
                ),
                SizedBox(width: 4),
                CustomPaint(
                  size: Size(22, 38),
                  painter: _StandingTokenPainter(color: Color(0xFF00E676)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTERS: 3D GAMING ASSETS & SHADERS
// =============================================================================

/// Background subtle golden sparks/particles painter
class _BackgroundSparksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sparkPaint = Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.15);
    final random = math.Random(42);

    for (int i = 0; i < 28; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = 0.8 + random.nextDouble() * 1.6;
      canvas.drawCircle(Offset(x, y), r, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Curled Metallic Golden Ribbon Banner ("Room Code Copied!")
class _CurledGoldRibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Folded Back Shadow Triangles (Left and Right)
    final shadowPaint = Paint()..color = const Color(0xFF6B4500);
    final leftShadow = Path()
      ..moveTo(16, h * 0.25)
      ..lineTo(22, h * 0.75)
      ..lineTo(16, h * 0.75)
      ..close();
    canvas.drawPath(leftShadow, shadowPaint);

    final rightShadow = Path()
      ..moveTo(w - 16, h * 0.25)
      ..lineTo(w - 22, h * 0.75)
      ..lineTo(w - 16, h * 0.75)
      ..close();
    canvas.drawPath(rightShadow, shadowPaint);

    // 2. Left & Right Ribbon Folded Tails
    final tailPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFB300), Color(0xFFB26A00)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final leftTail = Path()
      ..moveTo(22, h * 0.2)
      ..lineTo(2, h * 0.45)
      ..lineTo(12, h * 0.65)
      ..lineTo(2, h * 0.85)
      ..lineTo(22, h * 0.75)
      ..close();
    canvas.drawPath(leftTail, tailPaint);

    final rightTail = Path()
      ..moveTo(w - 22, h * 0.2)
      ..lineTo(w - 2, h * 0.45)
      ..lineTo(w - 12, h * 0.65)
      ..lineTo(w - 2, h * 0.85)
      ..lineTo(w - 22, h * 0.75)
      ..close();
    canvas.drawPath(rightTail, tailPaint);

    // 3. Main Center Ribbon Body
    final ribbonRect = Rect.fromLTWH(16, 2, w - 32, h - 4);
    final mainRibbon = Path()
      ..moveTo(16, 8)
      ..quadraticBezierTo(w * 0.5, 0, w - 16, 8)
      ..lineTo(w - 18, h - 6)
      ..quadraticBezierTo(w * 0.5, h - 2, 18, h - 6)
      ..close();

    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFF9C4),
          Color(0xFFFFE082),
          Color(0xFFFFB300),
          Color(0xFFFFA000),
          Color(0xFFE65100),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(ribbonRect);
    canvas.drawPath(mainRibbon, bodyPaint);

    // Gold Stroke outline
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = const Color(0xFFFFD700);
    canvas.drawPath(mainRibbon, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Mini Golden Ribbon Banner beneath each social icon
class _MiniGoldRibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final ribbonPath = Path()
      ..moveTo(0, h * 0.2)
      ..lineTo(w, h * 0.2)
      ..lineTo(w - 4, h * 0.85)
      ..lineTo(0 + 4, h * 0.85)
      ..close();

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFF9C4),
          Color(0xFFFFE082),
          Color(0xFFFFB300),
          Color(0xFFFFA000),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(ribbonPath, paint);

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = const Color(0xFFB26A00);
    canvas.drawPath(ribbonPath, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Golden Crown with Sunburst Light Rays
class _RoyalCrownWithSunburstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.7);

    // 1. Sunburst Radiant Light Beams
    final rayPaint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 11; i++) {
      final angle = -math.pi * 0.9 + (i * (math.pi * 0.8 / 10));
      final rayStart = Offset(center.dx + math.cos(angle) * 20, center.dy + math.sin(angle) * 20);
      final rayEnd = Offset(center.dx + math.cos(angle) * 52, center.dy + math.sin(angle) * 52);

      rayPaint.shader = LinearGradient(
        colors: [
          const Color(0xFFFFD700).withValues(alpha: 0.75),
          Colors.transparent,
        ],
      ).createShader(Rect.fromPoints(rayStart, rayEnd));

      canvas.drawLine(rayStart, rayEnd, rayPaint);
    }

    // 2. Crown Body
    final crownPath = Path()
      ..moveTo(center.dx - 36, center.dy + 8)
      ..lineTo(center.dx + 36, center.dy + 8)
      ..lineTo(center.dx + 42, center.dy - 18)
      ..lineTo(center.dx + 21, center.dy - 4)
      ..lineTo(center.dx, center.dy - 28)
      ..lineTo(center.dx - 21, center.dy - 4)
      ..lineTo(center.dx - 42, center.dy - 18)
      ..close();

    final crownPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFFDE7),
          Color(0xFFFFEA79),
          Color(0xFFFFB300),
          Color(0xFFFFA000),
          Color(0xFF8C5300),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: 40));
    canvas.drawPath(crownPath, crownPaint);

    // 3. Crown Jewels on Peaks
    final rubyPaint = Paint()..color = const Color(0xFFFF1744);
    canvas.drawCircle(Offset(center.dx, center.dy - 28), 4.0, rubyPaint);
    canvas.drawCircle(Offset(center.dx - 42, center.dy - 18), 3.2, rubyPaint);
    canvas.drawCircle(Offset(center.dx + 42, center.dy - 18), 3.2, rubyPaint);
    canvas.drawCircle(Offset(center.dx - 21, center.dy - 4), 2.5, Paint()..color = const Color(0xFF00E5FF));
    canvas.drawCircle(Offset(center.dx + 21, center.dy - 4), 2.5, Paint()..color = const Color(0xFF00E5FF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Mini Golden Crown Sparkle for Bottom Footer
class _MiniCrownSparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.6);

    final crownPath = Path()
      ..moveTo(center.dx - 16, center.dy + 5)
      ..lineTo(center.dx + 16, center.dy + 5)
      ..lineTo(center.dx + 18, center.dy - 8)
      ..lineTo(center.dx + 9, center.dy - 2)
      ..lineTo(center.dx, center.dy - 12)
      ..lineTo(center.dx - 9, center.dy - 2)
      ..lineTo(center.dx - 18, center.dy - 8)
      ..close();

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF9C4), Color(0xFFFFD700), Color(0xFFFF8F00)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: 18));
    canvas.drawPath(crownPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Isometric Floating Dice Painter with Pips
class _IsometricDicePainter extends CustomPainter {
  final double rotation;
  final bool isBig;

  _IsometricDicePainter({this.rotation = 0.0, this.isBig = true});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.5);
    canvas.rotate(rotation);

    final s = size.width * 0.44;

    // Top Face
    final topFace = Path()
      ..moveTo(0, -s)
      ..lineTo(s, -s * 0.5)
      ..lineTo(0, 0)
      ..lineTo(-s, -s * 0.5)
      ..close();
    canvas.drawPath(topFace, Paint()..color = Colors.white);

    // Left Face
    final leftFace = Path()
      ..moveTo(-s, -s * 0.5)
      ..lineTo(0, 0)
      ..lineTo(0, s)
      ..lineTo(-s, s * 0.5)
      ..close();
    canvas.drawPath(leftFace, Paint()..color = const Color(0xFFD6DBDF));

    // Right Face
    final rightFace = Path()
      ..moveTo(0, 0)
      ..lineTo(s, -s * 0.5)
      ..lineTo(s, s * 0.5)
      ..lineTo(0, s)
      ..close();
    canvas.drawPath(rightFace, Paint()..color = const Color(0xFFAEB6BF));

    // Pips
    final pipPaint = Paint()..color = const Color(0xFF0F1E36);
    final dotR = isBig ? 1.9 : 1.3;

    canvas.drawCircle(Offset(0, -s * 0.5), dotR, pipPaint);
    canvas.drawCircle(Offset(-s * 0.45, s * 0.15), dotR, pipPaint);
    canvas.drawCircle(Offset(-s * 0.45, s * 0.4), dotR, pipPaint);
    canvas.drawCircle(Offset(s * 0.45, s * 0.15), dotR, pipPaint);
    canvas.drawCircle(Offset(s * 0.45, s * 0.4), dotR, pipPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Glossy Standing Ludo Pawn / Token Painter
class _StandingTokenPainter extends CustomPainter {
  final Color color;

  const _StandingTokenPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Base Pedestal
    final baseRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.90),
      width: w * 0.88,
      height: h * 0.18,
    );
    final basePaint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withValues(alpha: 0.7), Colors.black87],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(baseRect);
    canvas.drawOval(baseRect, basePaint);

    // Conical Body
    final bodyPath = Path()
      ..moveTo(w * 0.38, h * 0.46)
      ..lineTo(w * 0.62, h * 0.46)
      ..lineTo(w * 0.80, h * 0.84)
      ..lineTo(w * 0.20, h * 0.84)
      ..close();
    canvas.drawPath(bodyPath, basePaint);

    // Collar Ring
    final collarRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.46),
      width: w * 0.46,
      height: h * 0.10,
    );
    canvas.drawOval(collarRect, Paint()..color = const Color(0xFFFFD700));

    // Spherical Head
    final headCenter = Offset(w * 0.5, h * 0.24);
    final headRadius = w * 0.32;
    final headPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        colors: [Colors.white, color, color.withValues(alpha: 0.8), Colors.black87],
      ).createShader(Rect.fromCircle(center: headCenter, radius: headRadius));
    canvas.drawCircle(headCenter, headRadius, headPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Mini 3D Perspective Ludo Board Quadrant for Footer
class _MiniBoardQuadrantPainter extends CustomPainter {
  final Color baseColor;

  const _MiniBoardQuadrantPainter({required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final boardRect = Rect.fromLTWH(0, 0, w, h);
    final rrect = RRect.fromRectAndRadius(boardRect, const Radius.circular(6));

    // Background
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: [baseColor, baseColor.withValues(alpha: 0.6), const Color(0xFF0A1224)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(boardRect);
    canvas.drawRRect(rrect, bgPaint);

    // Border
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFFFD700);
    canvas.drawRRect(rrect, border);

    // Mini checkered squares
    final cellPaint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    final stepW = w / 4;
    final stepH = h / 2;

    for (int i = 0; i < 4; i++) {
      canvas.drawRect(Rect.fromLTWH(i * stepW, 0, stepW * 0.7, stepH * 0.7), cellPaint);
      canvas.drawRect(Rect.fromLTWH(i * stepW, stepH, stepW * 0.7, stepH * 0.7), cellPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
