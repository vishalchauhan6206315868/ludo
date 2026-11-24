import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/network/api_service.dart';
import '../models/online_game_mode.dart';
import '../models/room_model.dart';
import 'auth_service.dart';

/// Result from automatic 1-click matchmaking
class MatchmakingResult {
  final RoomModel room;
  final bool isHost;

  const MatchmakingResult({
    required this.room,
    required this.isHost,
  });
}

/// Seamless Automatic Matchmaking Service for Ludo Supreme.
///
/// Features:
/// - 1-Click auto-discovery (no room code sharing, copying, or typing needed)
/// - Queries active matchmaking queues per game mode (Classic, 1-Kill Win, Quick, Popular, Mask)
/// - Pairs incoming players into waiting rooms within 1-2 seconds
/// - Creates a waiting room as host if no active player is currently waiting
/// - Periodic heartbeat keeps host rooms active for immediate pairing
/// - Automatic collision resolution merges parallel hosts into one lobby
class MatchmakingService {
  MatchmakingService._();
  static final MatchmakingService instance = MatchmakingService._();

  static const String _relayBase = 'https://ntfy.sh';
  final Set<String> _claimedOrDeadRooms = <String>{};

  String topicForMode(String modeId) =>
      'ludo_supreme_queue_${modeId.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';

  /// Performs 1-click automatic matchmaking:
  /// 1. Searches for any recently waiting room in this mode.
  /// 2. If an open room is found, joins it directly via ApiService.joinRoom.
  /// 3. If no open room is found, creates a new room via ApiService.createRoom, announces it to the queue, and waits.
  Future<MatchmakingResult?> findOrHostMatch({
    required OnlineGameMode mode,
    required int entryFee,
  }) async {
    final modeId = mode.id;
    final topic = topicForMode(modeId);
    await AuthService.ensureBackendSession();
    final myUid = await AuthService.getUserUid() ?? (await AuthService.getUserEmail());

    // 1. Search recent announcements in the last 25 seconds
    try {
      final url = Uri.parse('$_relayBase/$topic/json?poll=1&since=25s');
      final resp = await http.get(url).timeout(const Duration(seconds: 4));

      if (resp.statusCode == 200 && resp.body.trim().isNotEmpty) {
        final lines = resp.body.trim().split('\n');
        for (final line in lines.reversed) {
          if (line.trim().isEmpty) continue;
          try {
            final parsed = jsonDecode(line);
            final rawMsg = parsed['message']?.toString() ?? '';
            if (rawMsg.isNotEmpty) {
              final payload = jsonDecode(rawMsg);
              final status = payload['status']?.toString();
              final roomCode = payload['roomCode']?.toString().toUpperCase();
              final hostId = payload['hostId']?.toString();

              if (status == 'claimed' || status == 'cancelled') {
                if (roomCode != null) _claimedOrDeadRooms.add(roomCode);
                continue;
              }

              // If valid room code, not self, not dead/claimed:
              if (roomCode != null &&
                  roomCode.length == 6 &&
                  hostId != myUid &&
                  !_claimedOrDeadRooms.contains(roomCode)) {
                // Try joining this waiting room
                final joinRes = await ApiService().joinRoom(roomCode: roomCode);
                final msg = joinRes['message']?.toString().toLowerCase() ?? '';
                if (joinRes['success'] == true &&
                    joinRes['data'] != null &&
                    !msg.contains('already in this room')) {
                  final room = RoomModel.fromJson(joinRes['data']);
                  // Validate that at least 2 players exist in the room or joined successfully
                  if (room.players.length >= 2 || room.status == 'in_progress' || room.status == 'waiting') {
                    _claimedOrDeadRooms.add(roomCode);
                    // Announce claimed so other clients skip it
                    unawaited(announceClaimed(mode: mode, roomCode: roomCode));
                    return MatchmakingResult(room: room, isHost: false);
                  }
                }
                // If it failed or was already-in-room or closed, mark dead and try next or host
                _claimedOrDeadRooms.add(roomCode);
              }
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint("Matchmaking queue search notice: $e");
    }

    // 2. Proactively clear any active/stale room for this player before hosting
    try {
      final activeRes = await ApiService().getMyActiveRoom();
      if (activeRes['success'] == true && activeRes['data'] is Map) {
        final activeMap = activeRes['data'] as Map;
        final activeRoom = activeMap['room'];
        final activeCode = activeRoom is Map ? activeRoom['roomCode']?.toString() : null;
        if (activeCode != null && activeCode.isNotEmpty) {
          await ApiService().leaveRoom(roomCode: activeCode);
        }
      }
    } catch (_) {}

    // 3. No open room found: Create room as Host
    try {
      var createRes = await ApiService().createRoom(
        maxPlayers: 2,
        gameMode: 'twoPlayer',
        entryFee: entryFee,
      );

      // Handle if already in an active room
      final rawError = createRes['message']?.toString().toLowerCase() ?? '';
      final oldCode = createRes['data'] is Map ? createRes['data']['roomCode']?.toString() : null;
      if ((oldCode != null && oldCode.isNotEmpty) || rawError.contains('already in an active room')) {
        if (oldCode != null && oldCode.isNotEmpty) {
          await ApiService().leaveRoom(roomCode: oldCode);
        }
        createRes = await ApiService().createRoom(
          maxPlayers: 2,
          gameMode: 'twoPlayer',
          entryFee: entryFee,
        );
      }

      if (createRes['success'] == true && createRes['data'] != null) {
        final room = RoomModel.fromJson(createRes['data']);
        final code = room.roomCode.toUpperCase();

        // Announce this room to the mode's matchmaking queue
        unawaited(announceHeartbeat(mode: mode, roomCode: code, hostId: myUid));
        return MatchmakingResult(room: room, isHost: true);
      }
    } catch (e) {
      debugPrint("Error creating room during matchmaking: $e");
    }

    return null;
  }

  /// Searches the queue for any active waiting room hosted by another player.
  /// Used for merging waiting hosts if they clicked around the same time.
  Future<String?> findWaitingRoomCode({
    required OnlineGameMode mode,
    required String? myUid,
  }) async {
    final modeId = mode.id;
    final topic = topicForMode(modeId);
    try {
      final url = Uri.parse('$_relayBase/$topic/json?poll=1&since=20s');
      final resp = await http.get(url).timeout(const Duration(seconds: 3));
      if (resp.statusCode == 200 && resp.body.trim().isNotEmpty) {
        final lines = resp.body.trim().split('\n');
        for (final line in lines.reversed) {
          if (line.trim().isEmpty) continue;
          try {
            final parsed = jsonDecode(line);
            final rawMsg = parsed['message']?.toString() ?? '';
            if (rawMsg.isNotEmpty) {
              final payload = jsonDecode(rawMsg);
              final status = payload['status']?.toString();
              final roomCode = payload['roomCode']?.toString().toUpperCase();
              final hostId = payload['hostId']?.toString();
              if (status == 'claimed' || status == 'cancelled') continue;
              if (roomCode != null &&
                  roomCode.length == 6 &&
                  hostId != myUid &&
                  !_claimedOrDeadRooms.contains(roomCode)) {
                return roomCode;
              }
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
    return null;
  }

  /// Announces a waiting room heartbeat to the queue
  Future<void> announceHeartbeat({
    required OnlineGameMode mode,
    required String roomCode,
    String? hostId,
  }) async {
    try {
      final topic = topicForMode(mode.id);
      final payload = jsonEncode({
        'roomCode': roomCode,
        'hostId': hostId ?? 'host',
        'status': 'waiting',
        'time': DateTime.now().millisecondsSinceEpoch,
      });
      await http.post(
        Uri.parse('$_relayBase/$topic'),
        body: payload,
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  /// Announces that a waiting room has been claimed by an opponent
  Future<void> announceClaimed({
    required OnlineGameMode mode,
    required String roomCode,
  }) async {
    try {
      final topic = topicForMode(mode.id);
      final payload = jsonEncode({
        'roomCode': roomCode,
        'status': 'claimed',
        'time': DateTime.now().millisecondsSinceEpoch,
      });
      await http.post(
        Uri.parse('$_relayBase/$topic'),
        body: payload,
      ).timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  /// Announces that a waiting room was cancelled
  Future<void> announceCancelled({
    required OnlineGameMode mode,
    required String roomCode,
  }) async {
    try {
      final topic = topicForMode(mode.id);
      final payload = jsonEncode({
        'roomCode': roomCode,
        'status': 'cancelled',
        'time': DateTime.now().millisecondsSinceEpoch,
      });
      await http.post(
        Uri.parse('$_relayBase/$topic'),
        body: payload,
      ).timeout(const Duration(seconds: 2));
    } catch (_) {}
  }
}
