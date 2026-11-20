import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

/// Handles official Google Play In-App Updates on Android with a royal
/// Ludo Supreme themed "New Update Available!" confirmation popup.
class AppUpdateService {
  static bool _hasCheckedThisSession = false;

  /// Checks Google Play Store once per session for a newer release.
  /// Safe to call on all platforms and in tests — silently no-ops when
  /// not running from Google Play (e.g., debug builds, tests, iOS, web).
  static Future<void> checkForUpdate(BuildContext context) async {
    if (_hasCheckedThisSession) return;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _hasCheckedThisSession = true;

    try {
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();
      if (!context.mounted) return;

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        final bool shouldUpdate = await showUpdateDialog(context) ?? false;
        if (!shouldUpdate || !context.mounted) return;

        await _triggerPlayStoreUpdate(context, info);
      }
    } catch (e) {
      // Expected on sideloaded debug builds or headless widget tests
      debugPrint('AppUpdateService check skipped/unavailable: $e');
    }
  }

  static Future<void> _triggerPlayStoreUpdate(
    BuildContext context,
    AppUpdateInfo info,
  ) async {
    try {
      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      } else if (info.flexibleUpdateAllowed) {
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      debugPrint('AppUpdateService update flow error: $e');
    }
  }

  /// Displays the luxury Royal Blue & 24K Gold "New Update Available!" dialog.
  static Future<bool?> showUpdateDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 26),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 350),
          padding: const EdgeInsets.all(2.8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF8C2),
                Color(0xFFFFCA28),
                Color(0xFFB26A00),
                Color(0xFFFFE082),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFCA28).withValues(alpha: 0.42),
                blurRadius: 22,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.75),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(23),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF142B78),
                  Color(0xFF09174A),
                  Color(0xFF060E30),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing 24K Gold Update Badge
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFF59D),
                        Color(0xFFFFCA28),
                        Color(0xFFFF8F00),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFCA28).withValues(alpha: 0.55),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    color: Color(0xFF3E1800),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),

                // Gold Header Title
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFFBE6),
                      Color(0xFFFFD54F),
                      Color(0xFFFFA000),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'New Update Available!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                const Text(
                  'A newer version of Ludo Supreme is available on Google Play with new features, smoother gameplay, and improvements.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1.3,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Later',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFCA28),
                          foregroundColor: const Color(0xFF3E1800),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(
                              color: Color(0xFFFFF8C2),
                              width: 1.4,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Update Now',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
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

  @visibleForTesting
  static void resetForTesting() {
    _hasCheckedThisSession = false;
  }
}
