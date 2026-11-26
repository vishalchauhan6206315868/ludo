import 'dart:convert';
import 'player_identity.dart';

/// Model representing a multiplayer Game Room (`/api/rooms/*` responses and socket `room_*` events).
class RoomModel {
  final String id;
  final String roomCode;
  final String host;
  final List<String> players; // display names, in seat order
  final List<String> playerIds;
  final int maxPlayers;
  final String gameMode;
  final String status;
  final int entryFee;

  /// Live match of this room. Set by the server as soon as the room is full / the host starts.
  final String? sessionId;

  /// This player's seat (0-3) as assigned by the server (from the join response). Host = 0.
  final int? seatIndex;

  /// Normalized assigned color ('RED', 'GREEN', etc.)
  final String? assignedColor;

  /// Authenticated player identity if returned by the backend
  final PlayerIdentity? identity;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RoomModel({
    required this.id,
    required this.roomCode,
    required this.host,
    this.players = const [],
    this.playerIds = const [],
    this.maxPlayers = 2,
    this.gameMode = 'twoPlayer',
    this.status = 'waiting',
    this.entryFee = 0,
    this.sessionId,
    this.seatIndex,
    this.assignedColor,
    this.identity,
    this.createdAt,
    this.updatedAt,
  });

  int get playerCount => players.length;
  bool get isFull => playerCount >= maxPlayers;
  bool get isWaiting => status.toLowerCase() == 'waiting';
  bool get hasMatch => sessionId != null && sessionId!.isNotEmpty;

  /// From a REST response. Accepts the whole body, `data`, or the room itself:
  /// `{data:{room:{...}, sessionId, seatIndex}}`, `{room:{...}}` or `{...room fields}`.
  factory RoomModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> outer = json;
    if (json['data'] is Map) {
      outer = Map<String, dynamic>.from(json['data'] as Map);
    }
    Map<String, dynamic> roomMap = outer;
    if (outer['room'] is Map) {
      roomMap = Map<String, dynamic>.from(outer['room'] as Map);
    }

    final names = <String>[];
    final ids = <String>[];
    final rawPlayers = roomMap['players'];
    if (rawPlayers is List) {
      for (final e in rawPlayers) {
        if (e is Map) {
          names.add((e['name'] ?? e['user'] ?? '').toString());
          ids.add(_idOf(e['user']) ?? '');
        } else {
          names.add(e.toString());
          ids.add(e.toString());
        }
      }
    }

    final sid = (outer['sessionId'] ?? json['sessionId'] ?? roomMap['sessionId'])?.toString();
    final parsedIdentity = PlayerIdentity.tryParse(json) ?? PlayerIdentity.tryParse(outer);
    final seat = parsedIdentity?.seatIndex ?? outer['seatIndex'] ?? json['seatIndex'] ?? roomMap['seatIndex'];
    final rawColor = parsedIdentity?.color ?? outer['assignedColor'] ?? json['assignedColor'] ?? outer['color'] ?? json['color'];
    final color = rawColor != null ? PlayerIdentity.normalizeColor(rawColor, seat is num ? seat.toInt() : 0) : null;

    return RoomModel(
      id: roomMap['_id']?.toString() ?? roomMap['id']?.toString() ?? '',
      roomCode: roomMap['roomCode']?.toString() ?? '',
      host: _idOf(roomMap['host']) ?? '',
      players: names,
      playerIds: ids,
      maxPlayers: _parseInt(roomMap['maxPlayers'], defaultValue: 2),
      gameMode: roomMap['gameMode']?.toString() ?? 'twoPlayer',
      status: roomMap['status']?.toString() ?? 'waiting',
      entryFee: _parseInt(roomMap['entryFee'], defaultValue: 0),
      sessionId: (sid == null || sid.isEmpty || sid == 'null') ? null : sid,
      seatIndex: seat is num ? seat.toInt() : null,
      assignedColor: color,
      identity: parsedIdentity,
      createdAt: roomMap['createdAt'] != null ? DateTime.tryParse(roomMap['createdAt'].toString()) : null,
      updatedAt: roomMap['updatedAt'] != null ? DateTime.tryParse(roomMap['updatedAt'].toString()) : null,
    );
  }

  /// From a socket `room_state` / `player_joined` / `player_left` / `room_created` payload
  /// (`{roomId, roomCode, hostId, players:[{userId,name,seatIndex,...}], sessionId, ...}`).
  factory RoomModel.fromSocket(Map<String, dynamic> room, {RoomModel? previous}) {
    final names = <String>[];
    final ids = <String>[];
    final raw = room['players'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          names.add((e['name'] ?? '').toString());
          ids.add((e['userId'] ?? '').toString());
        }
      }
    }
    final sid = room['sessionId']?.toString();
    final parsedIdentity = PlayerIdentity.tryParse(room) ?? previous?.identity;
    final seat = parsedIdentity?.seatIndex ?? room['seatIndex'] ?? previous?.seatIndex;
    final rawColor = parsedIdentity?.color ?? room['assignedColor'] ?? room['color'] ?? previous?.assignedColor;
    final color = rawColor != null ? PlayerIdentity.normalizeColor(rawColor, seat is num ? seat.toInt() : 0) : null;

    return RoomModel(
      id: room['roomId']?.toString() ?? previous?.id ?? '',
      roomCode: room['roomCode']?.toString() ?? previous?.roomCode ?? '',
      host: room['hostId']?.toString() ?? previous?.host ?? '',
      players: names,
      playerIds: ids,
      maxPlayers: _parseInt(room['maxPlayers'], defaultValue: previous?.maxPlayers ?? 2),
      gameMode: room['gameMode']?.toString() ?? previous?.gameMode ?? 'twoPlayer',
      status: room['status']?.toString() ?? previous?.status ?? 'waiting',
      entryFee: _parseInt(room['entryFee'], defaultValue: previous?.entryFee ?? 0),
      sessionId: (sid == null || sid.isEmpty || sid == 'null') ? previous?.sessionId : sid,
      seatIndex: seat is num ? seat.toInt() : null,
      assignedColor: color,
      identity: parsedIdentity,
      createdAt: previous?.createdAt,
      updatedAt: previous?.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'roomCode': roomCode,
        'host': host,
        'players': players,
        'maxPlayers': maxPlayers,
        'gameMode': gameMode,
        'status': status,
        'entryFee': entryFee,
        'sessionId': sessionId,
        'seatIndex': seatIndex,
        'assignedColor': assignedColor,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  String toRawJson() => jsonEncode(toJson());

  factory RoomModel.fromRawJson(String str) => RoomModel.fromJson(jsonDecode(str) as Map<String, dynamic>);

  RoomModel copyWith({
    String? id,
    String? roomCode,
    String? host,
    List<String>? players,
    List<String>? playerIds,
    int? maxPlayers,
    String? gameMode,
    String? status,
    int? entryFee,
    String? sessionId,
    int? seatIndex,
    String? assignedColor,
    PlayerIdentity? identity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      roomCode: roomCode ?? this.roomCode,
      host: host ?? this.host,
      players: players ?? this.players,
      playerIds: playerIds ?? this.playerIds,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      gameMode: gameMode ?? this.gameMode,
      status: status ?? this.status,
      entryFee: entryFee ?? this.entryFee,
      sessionId: sessionId ?? this.sessionId,
      seatIndex: seatIndex ?? this.seatIndex,
      assignedColor: assignedColor ?? this.assignedColor,
      identity: identity ?? this.identity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String? _idOf(dynamic v) {
    if (v == null) return null;
    if (v is Map) return (v['_id'] ?? v['id'])?.toString();
    return v.toString();
  }

  static int _parseInt(dynamic value, {int defaultValue = 2}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}
