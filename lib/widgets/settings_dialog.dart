import 'package:flutter/material.dart';
import '../constants/ludo_colors.dart';
import '../services/sound_haptic_service.dart';

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
    return Dialog(
      backgroundColor: LudoColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.settings_rounded, color: Colors.amber, size: 24),
                      SizedBox(width: 10),
                      Text(
                        "Game Settings",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white60),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 24),

              // Sound Toggle
              SwitchListTile(
                value: _sound,
                activeThumbColor: Colors.amber,
                contentPadding: EdgeInsets.zero,
                title: const Text("Sound Effects",
                    style: TextStyle(color: Colors.white, fontSize: 15)),
                subtitle: const Text("Audio feedback on rolls and moves",
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                secondary: const Icon(Icons.volume_up_rounded, color: Colors.white70),
                onChanged: (val) async {
                  await SoundHapticService.toggleSound();
                  if (mounted) {
                    setState(() {
                      _sound = SoundHapticService.isSoundEnabled;
                    });
                  }
                },
              ),

              // Haptics Toggle
              SwitchListTile(
                value: _haptics,
                activeThumbColor: Colors.amber,
                contentPadding: EdgeInsets.zero,
                title: const Text("Haptic Feedback",
                    style: TextStyle(color: Colors.white, fontSize: 15)),
                subtitle: const Text("Vibrations on captures & turns",
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                secondary: const Icon(Icons.vibration_rounded, color: Colors.white70),
                onChanged: (val) async {
                  await SoundHapticService.toggleHaptics();
                  if (mounted) {
                    setState(() {
                      _haptics = SoundHapticService.isHapticsEnabled;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Action buttons if during match
              if (widget.onRestart != null) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onRestart?.call();
                  },
                  icon: const Icon(Icons.refresh_rounded, color: Colors.amber),
                  label: const Text("Restart Match",
                      style: TextStyle(color: Colors.amber)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                    side: const BorderSide(color: Colors.amber),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              if (widget.onExitToMenu != null) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onExitToMenu?.call();
                  },
                  icon: const Icon(Icons.home_rounded),
                  label: const Text("Quit to Main Menu"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }
}
