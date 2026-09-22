import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/ludo_path.dart';
import '../models/game_state.dart';
import '../models/ludo_player.dart';
import '../models/token.dart';

class GameStorageService {
  static const String _keySavedMatch = 'saved_active_match';

  /// Checks if there is a valid ongoing game saved in preferences
  static Future<bool> hasSavedGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_keySavedMatch) &&
          prefs.getString(_keySavedMatch) != null;
    } catch (_) {
      return false;
    }
  }

  /// Clears any saved match
  static Future<void> clearSavedGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySavedMatch);
    } catch (_) {}
  }

  /// Saves current match state
  static Future<void> saveGame(GameState state) async {
    if (state.isGameOver) {
      await clearSavedGame();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'mode': state.mode.name,
        'currentPlayerIndex': state.currentPlayerIndex,
        'consecutiveSixes': state.consecutiveSixes,
        'statusMessage': state.statusMessage,
        'players': state.players.map((p) {
          return {
            'name': p.name,
            'color': p.color.name,
            'isBot': p.isBot,
            'rank': p.rank,
            'tokens':
                p.tokens.map((t) => {'id': t.id, 'step': t.step}).toList(),
          };
        }).toList(),
      };

      await prefs.setString(_keySavedMatch, jsonEncode(data));
    } catch (_) {}
  }

  /// Loads saved match state and reconstructs GameState
  static Future<GameState?> loadSavedGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keySavedMatch);
      if (raw == null) return null;

      final Map<String, dynamic> data = jsonDecode(raw);
      final mode = GameMode.values.firstWhere(
        (m) => m.name == data['mode'],
        orElse: () => GameMode.twoPlayer,
      );

      final List<dynamic> playersData = data['players'];
      final List<LudoPlayer> players = [];

      for (final pMap in playersData) {
        final color = PlayerColor.values.firstWhere(
          (c) => c.name == pMap['color'],
          orElse: () => PlayerColor.red,
        );

        final List<dynamic> tokensData = pMap['tokens'];
        final List<Token> tokens = tokensData.map((tMap) {
          return Token(
            id: tMap['id'] as int,
            color: color,
            step: tMap['step'] as int,
          );
        }).toList();

        players.add(
          LudoPlayer(
            name: pMap['name'] as String,
            color: color,
            isBot: pMap['isBot'] as bool,
            rank: pMap['rank'] as int?,
            tokens: tokens,
          ),
        );
      }

      return GameState(
        players: players,
        mode: mode,
        currentPlayerIndex: data['currentPlayerIndex'] as int,
        consecutiveSixes: data['consecutiveSixes'] as int,
        statusMessage: data['statusMessage'] as String? ?? "Resumed Match",
        phase: TurnPhase.waitingForRoll,
      );
    } catch (_) {
      await clearSavedGame();
      return null;
    }
  }
}
