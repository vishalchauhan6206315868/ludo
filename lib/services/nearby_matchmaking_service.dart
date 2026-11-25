import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../core/network/api_service.dart';
import 'auth_service.dart';
import 'ludo_socket_service.dart';

enum NearbyMatchmakingState {
  idle,
  checkingPermission,
  permissionDenied,
  permissionPermanentlyDenied,
  locationDisabled,
  gettingLocation,
  searching,
  matchFound,
  error,
}

class NearbyMatchData {
  final String roomId;
  final String roomCode;
  final String sessionId;
  final Map<String, dynamic> opponent;
  final Map<String, dynamic> you;
  final Map<String, dynamic>? gameState;
  final int entryFee;
  final int prizePool;
  final int radiusKm;

  const NearbyMatchData({
    required this.roomId,
    required this.roomCode,
    required this.sessionId,
    required this.opponent,
    required this.you,
    this.gameState,
    this.entryFee = 0,
    this.prizePool = 0,
    this.radiusKm = 5,
  });

  factory NearbyMatchData.fromMap(Map<String, dynamic> data, {int radiusKm = 5}) {
    final opponentMap = data['opponent'] is Map
        ? Map<String, dynamic>.from(data['opponent'] as Map)
        : <String, dynamic>{};
    final youMap = data['you'] is Map
        ? Map<String, dynamic>.from(data['you'] as Map)
        : <String, dynamic>{};
    final stateMap = data['state'] is Map
        ? Map<String, dynamic>.from(data['state'] as Map)
        : (data['gameState'] is Map ? Map<String, dynamic>.from(data['gameState'] as Map) : null);

    return NearbyMatchData(
      roomId: data['roomId']?.toString() ?? '',
      roomCode: data['roomCode']?.toString() ?? '',
      sessionId: data['sessionId']?.toString() ?? data['gameId']?.toString() ?? '',
      opponent: opponentMap,
      you: youMap,
      gameState: stateMap,
      entryFee: data['entryFee'] is num ? (data['entryFee'] as num).toInt() : 0,
      prizePool: data['prizePool'] is num ? (data['prizePool'] as num).toInt() : 0,
      radiusKm: radiusKm,
    );
  }
}

class NearbyMatchmakingService {
  NearbyMatchmakingService._();
  static final NearbyMatchmakingService instance = NearbyMatchmakingService._();

  final ValueNotifier<NearbyMatchmakingState> stateNotifier =
      ValueNotifier<NearbyMatchmakingState>(NearbyMatchmakingState.idle);

  final ValueNotifier<int> elapsedSecondsNotifier = ValueNotifier<int>(0);
  final ValueNotifier<String?> errorMessageNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<NearbyMatchData?> matchDataNotifier = ValueNotifier<NearbyMatchData?>(null);
  final ValueNotifier<int> selectedRadiusKmNotifier = ValueNotifier<int>(5);

  NearbyMatchmakingState get currentState => stateNotifier.value;
  int get elapsedSeconds => elapsedSecondsNotifier.value;
  String? get errorMessage => errorMessageNotifier.value;
  NearbyMatchData? get matchData => matchDataNotifier.value;
  int get selectedRadiusKm => selectedRadiusKmNotifier.value;

  Timer? _timer;
  Timer? _pollingTimer;
  StreamSubscription? _matchFoundSub;
  StreamSubscription? _nearbyMatchFoundSub;
  StreamSubscription? _matchStartedSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _cancelledSub;
  StreamSubscription? _expiredSub;
  StreamSubscription? _errorSub;

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  /// Check location permission status without prompting
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission with explanation handling
  Future<bool> requestPermission() async {
    stateNotifier.value = NearbyMatchmakingState.checkingPermission;
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        stateNotifier.value = NearbyMatchmakingState.locationDisabled;
        errorMessageNotifier.value = 'Location services (GPS) are disabled. Please turn on GPS.';
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        stateNotifier.value = NearbyMatchmakingState.permissionDenied;
        errorMessageNotifier.value = 'Location permission is required to find players near you.';
        return false;
      }

      if (permission == LocationPermission.deniedForever) {
        stateNotifier.value = NearbyMatchmakingState.permissionPermanentlyDenied;
        errorMessageNotifier.value =
            'Location permission is permanently denied. Please enable it in App Settings.';
        return false;
      }

      stateNotifier.value = NearbyMatchmakingState.idle;
      return true;
    } catch (e) {
      stateNotifier.value = NearbyMatchmakingState.error;
      errorMessageNotifier.value = 'Failed to check location permissions: $e';
      return false;
    }
  }

  /// Open device app settings for permanently denied permission
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Open device location settings for disabled GPS
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Set the preferred search radius in km
  void setRadius(int radiusKm) {
    selectedRadiusKmNotifier.value = radiusKm;
  }

  /// Starts nearby matchmaking flow:
  /// 1. Verifies / requests permission
  /// 2. Obtains current GPS coordinates
  /// 3. Connects Socket.IO
  /// 4. Enters nearby queue on backend
  /// 5. Awaits match or listens for match events
  Future<void> startSearch({
    int? radiusKm,
    int entryFee = 0,
    String gameMode = 'twoPlayer',
  }) async {
    final effectiveRadius = radiusKm ?? selectedRadiusKm;
    selectedRadiusKmNotifier.value = effectiveRadius;
    errorMessageNotifier.value = null;
    matchDataNotifier.value = null;

    // 1. Permission Check
    final hasPermission = await requestPermission();
    if (!hasPermission) return;

    // 2. Get Location
    stateNotifier.value = NearbyMatchmakingState.gettingLocation;
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (e) {
      debugPrint('[NearbyMatchmaking] getCurrentPosition error: $e. Falling back to last known.');
      try {
        _currentPosition = await Geolocator.getLastKnownPosition();
      } catch (_) {}
    }

    if (_currentPosition == null) {
      stateNotifier.value = NearbyMatchmakingState.error;
      errorMessageNotifier.value =
          'Unable to acquire device location. Please ensure GPS is enabled with good signal.';
      return;
    }

    // 3. Connect Socket.IO
    stateNotifier.value = NearbyMatchmakingState.searching;
    elapsedSecondsNotifier.value = 0;
    _startTimer();

    await AuthService.ensureBackendSession();
    await LudoSocketService.instance.ensureConnected();
    _subscribeSocketEvents(effectiveRadius);

    // 4. Call REST joinNearbyMatchmaking
    try {
      final res = await ApiService().joinNearbyMatchmaking(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        accuracy: _currentPosition!.accuracy,
        radiusKm: effectiveRadius,
        entryFee: entryFee,
        gameMode: gameMode,
      );

      if (res['success'] == true && res['data'] is Map) {
        final data = Map<String, dynamic>.from(res['data'] as Map);
        if (data['matched'] == true || data['status'] == 'matched') {
          _onMatchFound(data, effectiveRadius);
          return;
        }
      } else {
        final errorMsg = res['message']?.toString();
        if (errorMsg != null && errorMsg.isNotEmpty && !errorMsg.toLowerCase().contains('waiting')) {
          stateNotifier.value = NearbyMatchmakingState.error;
          errorMessageNotifier.value = errorMsg;
          _stopTimer();
          return;
        }
      }
    } catch (e) {
      debugPrint('[NearbyMatchmaking] REST join error: $e');
    }

    // 5. Start Polling Fallback (every 5 seconds)
    _startPollingFallback(effectiveRadius);
  }

  void _subscribeSocketEvents(int radiusKm) {
    _cancelSubscriptions();

    _nearbyMatchFoundSub = LudoSocketService.instance.on('nearby_match_found').listen((data) {
      _onMatchFound(data, radiusKm);
    });

    _matchFoundSub = LudoSocketService.instance.on('match_found').listen((data) {
      if (data['isNearby'] == true || stateNotifier.value == NearbyMatchmakingState.searching) {
        _onMatchFound(data, radiusKm);
      }
    });

    _matchStartedSub = LudoSocketService.instance.on('match_started').listen((data) {
      if (data['isNearby'] == true || stateNotifier.value == NearbyMatchmakingState.searching) {
        _onMatchFound(data, radiusKm);
      }
    });

    _cancelledSub = LudoSocketService.instance.on('matchmaking_cancelled').listen((_) {
      if (stateNotifier.value == NearbyMatchmakingState.searching) {
        cancelSearch();
      }
    });

    _expiredSub = LudoSocketService.instance.on('matchmaking_expired').listen((data) {
      stateNotifier.value = NearbyMatchmakingState.error;
      errorMessageNotifier.value = data['message']?.toString() ?? 'Nearby search timed out. No players found in range.';
      _stopTimer();
    });

    _errorSub = LudoSocketService.instance.on('matchmaking_error').listen((data) {
      stateNotifier.value = NearbyMatchmakingState.error;
      errorMessageNotifier.value = data['message']?.toString() ?? 'A matchmaking error occurred.';
      _stopTimer();
    });
  }

  void _onMatchFound(Map<String, dynamic> data, int radiusKm) {
    _stopTimer();
    _cancelSubscriptions();
    final match = NearbyMatchData.fromMap(data, radiusKm: radiusKm);
    matchDataNotifier.value = match;
    stateNotifier.value = NearbyMatchmakingState.matchFound;
  }

  void _startPollingFallback(int radiusKm) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (stateNotifier.value != NearbyMatchmakingState.searching) {
        _pollingTimer?.cancel();
        return;
      }
      try {
        final statusRes = await ApiService().getNearbyMatchmakingStatus();
        if (statusRes['success'] == true && statusRes['data'] is Map) {
          final data = Map<String, dynamic>.from(statusRes['data'] as Map);
          if (data['status'] == 'matched') {
            _onMatchFound(data, radiusKm);
          } else if (data['status'] == 'expired') {
            stateNotifier.value = NearbyMatchmakingState.error;
            errorMessageNotifier.value = data['message']?.toString() ?? 'Nearby search timed out.';
            _stopTimer();
          }
        }
      } catch (_) {}
    });
  }

  /// Cancels active nearby search
  Future<void> cancelSearch() async {
    _stopTimer();
    _cancelSubscriptions();
    stateNotifier.value = NearbyMatchmakingState.idle;
    elapsedSecondsNotifier.value = 0;
    errorMessageNotifier.value = null;

    try {
      await ApiService().leaveNearbyMatchmaking();
    } catch (e) {
      debugPrint('[NearbyMatchmaking] leaveNearbyMatchmaking error: $e');
    }
  }

  void reset() {
    _stopTimer();
    _cancelSubscriptions();
    stateNotifier.value = NearbyMatchmakingState.idle;
    elapsedSecondsNotifier.value = 0;
    errorMessageNotifier.value = null;
    matchDataNotifier.value = null;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      elapsedSecondsNotifier.value = t.tick;
      if (t.tick >= 65 && stateNotifier.value == NearbyMatchmakingState.searching) {
        stateNotifier.value = NearbyMatchmakingState.error;
        errorMessageNotifier.value =
            'Search timed out after 60 seconds. No nearby players found. Try increasing the search radius!';
        _stopTimer();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _cancelSubscriptions() {
    _matchFoundSub?.cancel();
    _nearbyMatchFoundSub?.cancel();
    _matchStartedSub?.cancel();
    _statusSub?.cancel();
    _cancelledSub?.cancel();
    _expiredSub?.cancel();
    _errorSub?.cancel();
    _matchFoundSub = null;
    _nearbyMatchFoundSub = null;
    _matchStartedSub = null;
    _statusSub = null;
    _cancelledSub = null;
    _expiredSub = null;
    _errorSub = null;
  }
}
