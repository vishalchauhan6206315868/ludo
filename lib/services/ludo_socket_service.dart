// Realtime connection to the Ludo server (Socket.IO).
//
// One shared connection for the whole app: authenticated connect, automatic reconnect,
// connection status stream, per-event streams, and request/ack calls with a timeout.
// Protocol reference: docs/realtime-protocol.md in the backend project.
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../core/network/api_config.dart';
import '../core/network/api_service.dart';
import 'auth_service.dart';

enum LudoConnectionStatus { idle, connecting, connected, reconnecting, unauthorized }

class LudoAck {
  final bool ok;
  final String? code; // BAD_REQUEST, FORBIDDEN, NOT_FOUND, CONFLICT, RATE_LIMITED, TIMEOUT, NOT_CONNECTED
  final String? message;
  final Map<String, dynamic> data;
  const LudoAck(this.ok, {this.code, this.message, this.data = const {}});
  factory LudoAck.err(String code, [String? message]) => LudoAck(false, code: code, message: message);
  factory LudoAck.success([Map<String, dynamic> data = const {}]) => LudoAck(true, data: data);
}

class LudoSocketService {
  LudoSocketService._();
  static final LudoSocketService instance = LudoSocketService._();

  /// Every event the server can push.
  static const serverEvents = <String>[
    'room_created', 'player_joined', 'player_left', 'room_left', 'room_cancelled', 'room_state',
    'match_started', 'game_started', 'match_found', 'game_state', 'active_game',
    'dice_rolled', 'dice_roll_result', 'token_moved', 'turn_changed', 'turn_timeout',
    'player_surrendered', 'player_disconnected', 'player_reconnected',
    'match_finished', 'game_over', 'invalid_move', 'game_error',
    'nearby_match_found', 'matchmaking_status', 'matchmaking_waiting',
    'matchmaking_cancelled', 'matchmaking_expired', 'matchmaking_error',
  ];

  io.Socket? _socket;
  bool _manualClose = false;
  bool _connecting = false;
  LudoConnectionStatus _status = LudoConnectionStatus.idle;

  final _statusCtrl = StreamController<LudoConnectionStatus>.broadcast();
  final Map<String, StreamController<Map<String, dynamic>>> _eventCtrls = {};
  final Set<String> _boundEvents = {};

  LudoConnectionStatus get status => _status;
  Stream<LudoConnectionStatus> get statusStream => _statusCtrl.stream;
  bool get isConnected => _status == LudoConnectionStatus.connected;

  Stream<Map<String, dynamic>> on(String event) {
    if (_socket != null && !_boundEvents.contains(event)) {
      _boundEvents.add(event);
      _socket!.on(event, (data) {
        final ctrl = _eventCtrls[event];
        if (ctrl != null && !ctrl.isClosed) ctrl.add(_asMap(data));
      });
    }
    return _eventCtrls.putIfAbsent(event, () => StreamController<Map<String, dynamic>>.broadcast()).stream;
  }

  void _setStatus(LudoConnectionStatus s) {
    if (_status == s) return;
    _status = s;
    if (!_statusCtrl.isClosed) _statusCtrl.add(s);
  }

  /// Connects (once) using the logged-in player's JWT. Safe to call from every screen.
  /// Returns true when the socket is connected.
  Future<bool> ensureConnected({Duration timeout = const Duration(seconds: 12)}) async {
    if (isConnected) return true;

    if (_socket == null || _status == LudoConnectionStatus.idle || _status == LudoConnectionStatus.unauthorized) {
      if (_connecting) {
        // another caller is already connecting: just wait below
      } else {
        _connecting = true;
        try {
          var token = await ApiService().getToken();
          if (token == null || token.isEmpty) {
            token = await AuthService.ensureBackendSession();
          }
          if (token == null || token.isEmpty) return false;
          _open(ApiConfig.socketUrl, token);
        } finally {
          _connecting = false;
        }
      }
    }

    final end = DateTime.now().add(timeout);
    while (!isConnected && DateTime.now().isBefore(end)) {
      if (_status == LudoConnectionStatus.unauthorized) return false;
      await Future.delayed(const Duration(milliseconds: 200));
    }
    return isConnected;
  }

  void _open(String baseUrl, String token) {
    _socket?.dispose();
    _manualClose = false;
    _setStatus(LudoConnectionStatus.connecting);

    final s = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token', 'token': token})
          .setQuery({'token': token})
          .enableForceNew()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .disableAutoConnect()
          .build(),
    );
    _socket = s;

    s.onConnect((_) => _setStatus(LudoConnectionStatus.connected));
    s.onDisconnect((_) {
      if (!_manualClose) _setStatus(LudoConnectionStatus.reconnecting);
    });
    s.onConnectError((err) {
      final text = '$err';
      debugPrint('[SOCKET] connect_error: $text');
      if (text.contains('UNAUTHORIZED') || text.contains('Authentication') || text.contains('Invalid or expired') || text.contains('User not found')) {
        // token is bad/expired: stop retrying; the next ensureConnected() fetches a fresh one
        _setStatus(LudoConnectionStatus.unauthorized);
        s.dispose();
        _socket = null;
      } else {
        _setStatus(LudoConnectionStatus.reconnecting);
      }
    });

    _boundEvents.clear();
    for (final event in serverEvents) {
      _boundEvents.add(event);
      s.on(event, (data) {
        final ctrl = _eventCtrls[event];
        if (ctrl != null && !ctrl.isClosed) ctrl.add(_asMap(data));
      });
    }
    for (final event in _eventCtrls.keys) {
      if (!_boundEvents.contains(event)) {
        _boundEvents.add(event);
        s.on(event, (data) {
          final ctrl = _eventCtrls[event];
          if (ctrl != null && !ctrl.isClosed) ctrl.add(_asMap(data));
        });
      }
    }
    s.connect();
  }

  void disconnect() {
    _manualClose = true;
    _socket?.dispose();
    _socket = null;
    _setStatus(LudoConnectionStatus.idle);
  }

  /// Request/response call. Never throws: failures come back as LudoAck(ok:false).
  Future<LudoAck> request(String event,
      [Map<String, dynamic> payload = const {}, Duration timeout = const Duration(seconds: 8)]) {
    final s = _socket;
    if (s == null || !isConnected) {
      return Future.value(const LudoAck(false, code: 'NOT_CONNECTED', message: 'No connection to the game server'));
    }
    final done = Completer<LudoAck>();
    final timer = Timer(timeout, () {
      if (!done.isCompleted) done.complete(const LudoAck(false, code: 'TIMEOUT', message: 'Server did not answer'));
    });
    s.emitWithAck(event, payload, ack: (dynamic res) {
      timer.cancel();
      if (done.isCompleted) return;
      final m = _asMap(res);
      done.complete(LudoAck(m['ok'] == true, code: m['code']?.toString(), message: m['message']?.toString(), data: m));
    });
    return done.future;
  }

  Future<LudoAck> joinSession(String sessionId) => request('join_session', {'sessionId': sessionId});
  Future<LudoAck> rollDice(String sessionId) async {
    final ack = await request('dice_roll_requested', {'sessionId': sessionId});
    if (!ack.ok && (ack.code == 'TIMEOUT' || ack.code == 'NO_HANDLER' || ack.code == 'NOT_CONNECTED')) {
      final ack2 = await request('roll_dice', {'sessionId': sessionId});
      if (ack2.ok) return ack2;
    }
    return ack;
  }

  Future<LudoAck> moveToken(String sessionId, int tokenId) async {
    final ack = await request('token_move_requested', {'sessionId': sessionId, 'tokenId': tokenId});
    if (!ack.ok && (ack.code == 'TIMEOUT' || ack.code == 'NO_HANDLER' || ack.code == 'NOT_CONNECTED')) {
      final ack2 = await request('move_token', {'sessionId': sessionId, 'tokenId': tokenId});
      if (ack2.ok) return ack2;
    }
    return ack;
  }

  Future<LudoAck> startMatch(String roomCode) => request('start_match', {'roomCode': roomCode});

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is List && v.isNotEmpty && v.first is Map) return Map<String, dynamic>.from(v.first as Map);
    return <String, dynamic>{};
  }
}
