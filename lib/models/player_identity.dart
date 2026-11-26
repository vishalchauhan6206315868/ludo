import '../constants/ludo_path.dart';

/// Represents an authoritative player identity returned by the backend.
///
/// Contains:
/// - [userId]: Unique authenticated MongoDB ID of the player
/// - [seatIndex]: Seat index (0 = Host/Red, 1 = Challenger/Green, etc.)
/// - [color]: Normalized color string ('RED', 'GREEN', 'YELLOW', 'BLUE')
/// - [isHost]: Whether this player is the room/match host
class PlayerIdentity {
  final String userId;
  final int seatIndex;
  final String color;
  final bool isHost;

  const PlayerIdentity({
    required this.userId,
    required this.seatIndex,
    required this.color,
    required this.isHost,
  });

  /// Normalized PlayerColor enum for UI & board mechanics
  PlayerColor get playerColor {
    switch (color.toUpperCase()) {
      case 'RED':
        return PlayerColor.red;
      case 'GREEN':
        return PlayerColor.green;
      case 'YELLOW':
        return PlayerColor.yellow;
      case 'BLUE':
        return PlayerColor.blue;
      default:
        return seatIndex == 1 ? PlayerColor.green : PlayerColor.red;
    }
  }

  /// Normalizes any color input to uppercase 'RED', 'GREEN', 'YELLOW', 'BLUE'
  static String normalizeColor(dynamic rawColor, int fallbackSeat) {
    if (rawColor != null) {
      final s = rawColor.toString().trim().toUpperCase();
      if (s == 'RED' || s == 'GREEN' || s == 'YELLOW' || s == 'BLUE') {
        return s;
      }
    }
    switch (fallbackSeat) {
      case 0:
        return 'RED';
      case 1:
        return 'GREEN';
      case 2:
        return 'YELLOW';
      case 3:
        return 'BLUE';
      default:
        return 'RED';
    }
  }

  factory PlayerIdentity.fromJson(Map<String, dynamic> json) {
    final rawSeat = json['seatIndex'] ?? json['seat'];
    final seat = rawSeat is num ? rawSeat.toInt() : 0;
    final rawColor = json['color'] ?? json['assignedColor'];
    final normalized = normalizeColor(rawColor, seat);

    final rawUid = json['userId'] ?? json['playerId'] ?? json['id'] ?? json['_id'];
    final uid = rawUid?.toString() ?? '';

    final rawHost = json['isHost'] ?? (seat == 0);
    final host = rawHost is bool ? rawHost : (rawHost.toString().toLowerCase() == 'true');

    return PlayerIdentity(
      userId: uid,
      seatIndex: seat,
      color: normalized,
      isHost: host,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'seatIndex': seatIndex,
        'color': color,
        'isHost': isHost,
      };

  /// Safely extracts and parses PlayerIdentity from any REST or Socket response payload.
  ///
  /// Inspects in order:
  /// 1. `data['player']` or `json['player']`
  /// 2. `data['me']` or `json['me']` or `json['you']`
  /// 3. In a players list matching [expectedUserId]
  /// 4. Direct mapping if keys exist
  static PlayerIdentity? tryParse(dynamic raw, {String? expectedUserId}) {
    if (raw == null) return null;
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);

    // 1. Direct 'player' block
    final playerBlock = map['player'] ?? (map['data'] is Map ? (map['data'] as Map)['player'] : null);
    if (playerBlock is Map) {
      final parsed = PlayerIdentity.fromJson(Map<String, dynamic>.from(playerBlock));
      if (expectedUserId == null || expectedUserId.isEmpty || parsed.userId == expectedUserId) {
        return parsed;
      }
    }

    // 2. Direct 'me' or 'you' block (Socket.IO / viewer view)
    final meBlock = map['me'] ??
        map['you'] ??
        (map['data'] is Map ? (map['data'] as Map)['me'] : null) ??
        (map['state'] is Map ? (map['state'] as Map)['me'] : null);
    if (meBlock is Map) {
      final parsed = PlayerIdentity.fromJson(Map<String, dynamic>.from(meBlock));
      if (expectedUserId == null || expectedUserId.isEmpty || parsed.userId == expectedUserId) {
        return parsed;
      }
    }

    // 3. Search in players array if expectedUserId provided
    if (expectedUserId != null && expectedUserId.isNotEmpty) {
      final players = map['players'] ??
          (map['data'] is Map ? (map['data'] as Map)['players'] : null) ??
          (map['state'] is Map ? (map['state'] as Map)['players'] : null) ??
          (map['session'] is Map ? (map['session'] as Map)['players'] : null);
      if (players is List) {
        for (final p in players) {
          if (p is Map) {
            final uid = (p['userId'] ?? p['playerId'] ?? p['id'] ?? p['_id'] ?? (p['user'] is Map ? p['user']['_id'] : p['user']))?.toString();
            if (uid == expectedUserId) {
              return PlayerIdentity.fromJson(Map<String, dynamic>.from(p));
            }
          }
        }
      }
    }

    // 4. Direct fields in top-level map
    if ((map.containsKey('seatIndex') || map.containsKey('seat')) && (map.containsKey('userId') || map.containsKey('playerId'))) {
      return PlayerIdentity.fromJson(map);
    }

    return null;
  }

  PlayerIdentity copyWith({
    String? userId,
    int? seatIndex,
    String? color,
    bool? isHost,
  }) {
    return PlayerIdentity(
      userId: userId ?? this.userId,
      seatIndex: seatIndex ?? this.seatIndex,
      color: color ?? this.color,
      isHost: isHost ?? this.isHost,
    );
  }

  @override
  String toString() => 'PlayerIdentity(userId: $userId, seatIndex: $seatIndex, color: $color, isHost: $isHost)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerIdentity &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          seatIndex == other.seatIndex &&
          color == other.color &&
          isHost == other.isHost;

  @override
  int get hashCode => userId.hashCode ^ seatIndex.hashCode ^ color.hashCode ^ isHost.hashCode;
}
