import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/room_model.dart';
import '../../models/user_profile_model.dart';
import 'api_config.dart';

/// Centralized API Service for Backend Communication
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const Duration timeoutDuration = Duration(seconds: 60);
  static const String tokenKey = 'backend_auth_token';

  String? _token;

  /// Get current auth token (from memory or SharedPreferences)
  Future<String?> getToken() async {
    if (_token != null && _token!.isNotEmpty) {
      return _token;
    }
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(tokenKey);
    return _token;
  }

  /// Save auth token locally
  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null && token.isNotEmpty) {
      await prefs.setString(tokenKey, token);
    } else {
      await prefs.remove(tokenKey);
    }
  }

  /// Clear token on logout
  Future<void> clearSession() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  /// Build standard headers with optional authorization token
  Future<Map<String, String>> _buildHeaders({
    Map<String, String>? extraHeaders,
    bool withAuth = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  /// Format backend response into unified map
  Map<String, dynamic> _handleResponse(http.Response response) {
    dynamic decodedBody;
    try {
      if (response.body.isNotEmpty) {
        decodedBody = jsonDecode(response.body);
      }
    } catch (_) {
      decodedBody = response.body;
    }

    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;

    String? message;
    if (decodedBody is Map<String, dynamic>) {
      message = decodedBody['message']?.toString() ??
          decodedBody['msg']?.toString() ??
          decodedBody['error']?.toString();
    }

    if (message == null || message.trim().isEmpty) {
      if (isSuccess) {
        message = 'Success';
      } else if (response.statusCode == 401) {
        clearSession().catchError((_) {});
        message = 'Authentication required. Please login.';
      } else if (response.statusCode == 403) {
        message = 'Access forbidden (403).';
      } else if (response.statusCode == 404) {
        message = 'Requested resource not found on server (404).';
      } else if (response.statusCode >= 500) {
        message = 'Server encountered an error (${response.statusCode}). Please try again shortly.';
      } else {
        message = 'Request failed with status ${response.statusCode}';
      }
    }

    return {
      'success': isSuccess,
      'statusCode': response.statusCode,
      'message': message,
      'data': decodedBody,
    };
  }

  /// Handle Network & System Exceptions cleanly
  Map<String, dynamic> _handleError(dynamic error) {
    debugPrint('ApiService Error: $error');

    if (error is SocketException) {
      return {
        'success': false,
        'statusCode': 0,
        'message': 'Cannot reach backend server. Please check if your server is running and Wi-Fi / IP is correct.',
        'data': null,
      };
    } else if (error is TimeoutException) {
      return {
        'success': false,
        'statusCode': 408,
        'message': 'Server connection timed out (60s). Server might be waking up—please try again.',
        'data': null,
      };
    } else if (error is FormatException) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Invalid response format received from server.',
        'data': null,
      };
    } else if (error.toString().contains('ClientException') ||
        error.toString().contains('Failed host lookup') ||
        error.toString().contains('Connection refused')) {
      return {
        'success': false,
        'statusCode': 0,
        'message': 'Network connection error. Server is unreachable or offline.',
        'data': null,
      };
    }

    return {
      'success': false,
      'statusCode': -1,
      'message': error.toString(),
      'data': null,
    };
  }

  // ===========================================================================
  // CORE HTTP METHODS (WITH AUTOMATIC CANDIDATE URL FAILOVER)
  // ===========================================================================

  /// Executes request across candidate base URLs until a live backend is found
  Future<Map<String, dynamic>> _executeWithCandidates(
    Future<http.Response> Function(String baseUrl) requestFn,
  ) async {
    final candidates = ApiConfig.candidateBaseUrls;
    Map<String, dynamic> lastError = {};

    for (final base in candidates) {
      try {
        final timeout = candidates.length > 1 ? const Duration(seconds: 15) : timeoutDuration;
        final response = await requestFn(base).timeout(timeout);
        ApiConfig.setActiveBaseUrl(base);
        return _handleResponse(response);
      } catch (e) {
        lastError = _handleError(e);
        // On connection failure, attempt next candidate URL
        continue;
      }
    }

    return lastError;
  }

  /// Generic GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    bool withAuth = true,
  }) async {
    return _executeWithCandidates((baseUrl) async {
      final url = Uri.parse('$baseUrl$endpoint');
      final reqHeaders = await _buildHeaders(extraHeaders: headers, withAuth: withAuth);
      return http.get(url, headers: reqHeaders);
    });
  }

  /// Generic POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    bool withAuth = true,
  }) async {
    return _executeWithCandidates((baseUrl) async {
      final url = Uri.parse('$baseUrl$endpoint');
      final reqHeaders = await _buildHeaders(extraHeaders: headers, withAuth: withAuth);
      final jsonBody = body != null ? jsonEncode(body) : null;
      return http.post(url, headers: reqHeaders, body: jsonBody);
    });
  }

  /// Generic PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    bool withAuth = true,
  }) async {
    return _executeWithCandidates((baseUrl) async {
      final url = Uri.parse('$baseUrl$endpoint');
      final reqHeaders = await _buildHeaders(extraHeaders: headers, withAuth: withAuth);
      final jsonBody = body != null ? jsonEncode(body) : null;
      return http.put(url, headers: reqHeaders, body: jsonBody);
    });
  }

  /// Generic DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
    bool withAuth = true,
  }) async {
    return _executeWithCandidates((baseUrl) async {
      final url = Uri.parse('$baseUrl$endpoint');
      final reqHeaders = await _buildHeaders(extraHeaders: headers, withAuth: withAuth);
      return http.delete(url, headers: reqHeaders);
    });
  }

  // ===========================================================================
  // AUTHENTICATION & APP SPECIFIC APIS
  // ===========================================================================

  /// Test backend health / connectivity
  Future<Map<String, dynamic>> getHealth() async {
    final res = await get(ApiConfig.health, withAuth: false);
    if (res['success'] == true) {
      return res;
    }

    // Try root / URL across candidates as fallback
    for (final base in ApiConfig.candidateBaseUrls) {
      try {
        final rootUri = Uri.parse(base.replaceAll(RegExp(r'/api/?$'), ''));
        final fallbackResponse = await http.get(rootUri).timeout(const Duration(seconds: 10));
        if (fallbackResponse.statusCode >= 200 && fallbackResponse.statusCode < 400) {
          ApiConfig.setActiveBaseUrl(base);
          return {
            'success': true,
            'statusCode': fallbackResponse.statusCode,
            'message': 'Backend Server is Online & Reachable!',
            'data': fallbackResponse.body,
          };
        }
      } catch (_) {}
    }

    return res;
  }

  /// Fire-and-forget health ping to wake up cold Render instances before payment
  void preWarmServer() {
    getHealth().catchError((_) => <String, dynamic>{'success': false});
  }

  /// Login with Email and Password
  /// API: http://localhost:5000/api/auth/login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await post(
      ApiConfig.login,
      body: {
        'email': email.trim(),
        'password': password,
      },
      withAuth: false,
    );

    if (response['success'] == true && response['data'] != null) {
      final token = _extractToken(response['data']);
      if (token != null && token.isNotEmpty) {
        await setToken(token);
      }
    }

    return response;
  }

  /// Register new user
  /// API: http://localhost:5000/api/auth/register
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await post(
      ApiConfig.register,
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      },
      withAuth: false,
    );

    if (response['success'] == true && response['data'] != null) {
      final token = _extractToken(response['data']);
      if (token != null && token.isNotEmpty) {
        await setToken(token);
      }
    }

    return response;
  }

  /// Helper to reliably extract auth token from various backend formats
  String? _extractToken(dynamic body) {
    if (body == null || body is! Map) return null;

    if (body['token'] != null) return body['token'].toString();
    if (body['accessToken'] != null) return body['accessToken'].toString();
    if (body['jwt'] != null) return body['jwt'].toString();

    final data = body['data'];
    if (data is Map) {
      if (data['token'] != null) return data['token'].toString();
      if (data['accessToken'] != null) return data['accessToken'].toString();
      if (data['jwt'] != null) return data['jwt'].toString();
    }
    return null;
  }

  /// Fetch user profile raw response
  /// API: http://localhost:5000/api/users/me
  Future<Map<String, dynamic>> getProfile() async {
    return await get(ApiConfig.profile, withAuth: true);
  }

  /// Fetch typed UserProfileModel from /api/users/me
  Future<UserProfileModel?> getUserProfile() async {
    final response = await getProfile();
    if (response['success'] == true && response['data'] != null) {
      try {
        final data = response['data'];
        if (data is Map<String, dynamic>) {
          return UserProfileModel.fromJson(data);
        }
      } catch (e) {
        debugPrint('Error parsing UserProfileModel: $e');
      }
    }
    return null;
  }

  /// Create Game Room
  /// API: http://localhost:5000/api/rooms/create
  Future<Map<String, dynamic>> createRoom({
    int maxPlayers = 2,
    String gameMode = 'twoPlayer',
    int? entryFee,
  }) async {
    return await post(
      ApiConfig.createRoom,
      body: {
        'maxPlayers': maxPlayers,
        'gameMode': gameMode,
        'entryFee': ?entryFee,
      },
      withAuth: true,
    );
  }

  /// Helper to create room and return strongly typed RoomModel
  Future<RoomModel?> createRoomModel({
    int maxPlayers = 2,
    String gameMode = 'twoPlayer',
    int? entryFee,
  }) async {
    final response = await createRoom(
      maxPlayers: maxPlayers,
      gameMode: gameMode,
      entryFee: entryFee,
    );
    if (response['success'] == true && response['data'] != null) {
      try {
        final data = response['data'];
        if (data is Map<String, dynamic>) {
          return RoomModel.fromJson(data);
        }
      } catch (e) {
        debugPrint('Error parsing RoomModel: $e');
      }
    }
    return null;
  }

  /// Join Game Room
  /// API: http://localhost:4000/api/rooms/join
  Future<Map<String, dynamic>> joinRoom({
    required String roomCode,
  }) async {
    return await post(
      ApiConfig.joinRoom,
      body: {
        'roomCode': roomCode.trim(),
      },
      withAuth: true,
    );
  }

  /// Helper to join room and return strongly typed RoomModel
  Future<RoomModel?> joinRoomModel({
    required String roomCode,
  }) async {
    final response = await joinRoom(roomCode: roomCode);
    if (response['success'] == true && response['data'] != null) {
      try {
        final data = response['data'];
        if (data is Map<String, dynamic>) {
          return RoomModel.fromJson(data);
        }
      } catch (e) {
        debugPrint('Error parsing RoomModel from joinRoom: $e');
      }
    }
    return null;
  }

  /// Get Game Room Details by Room Code
  /// API: http://localhost:5000/api/rooms/:roomCode
  Future<Map<String, dynamic>> getRoomDetails({
    required String roomCode,
  }) async {
    return await get(
      ApiConfig.getRoom(roomCode),
      withAuth: true,
    );
  }

  /// Helper to fetch room details and return strongly typed RoomModel
  Future<RoomModel?> getRoomModel({
    required String roomCode,
  }) async {
    final response = await getRoomDetails(roomCode: roomCode);
    if (response['success'] == true && response['data'] != null) {
      try {
        final data = response['data'];
        if (data is Map<String, dynamic>) {
          return RoomModel.fromJson(data);
        }
      } catch (e) {
        debugPrint('Error parsing RoomModel from getRoomDetails: $e');
      }
    }
    return null;
  }

  /// The room / live match this player is currently in (used to resume after an app restart).
  /// API: GET /api/rooms/me/active  ->  { room, sessionId }  (both null when nothing is active)
  Future<Map<String, dynamic>> getMyActiveRoom() async {
    return await get(
      ApiConfig.myActiveRoom,
      withAuth: true,
    );
  }

  /// Leave / Cancel Game Room
  /// API: POST /api/rooms/leave
  /// Host leaves -> cancels room for all players.
  /// Player leaves -> removes player from room.
  Future<Map<String, dynamic>> leaveRoom({
    required String roomCode,
  }) async {
    return await post(
      ApiConfig.leaveRoom,
      body: {
        'roomCode': roomCode.trim(),
      },
      withAuth: true,
    );
  }

  // ===========================================================================
  // GAME SESSION APIS
  // ===========================================================================

  /// Start / Initialize Game Session from Room Code
  /// API: POST /api/games/start
  Future<Map<String, dynamic>> startGame({
    required String roomCode,
  }) async {
    return await post(
      ApiConfig.startGame,
      body: {
        'roomCode': roomCode.trim().toUpperCase(),
      },
      withAuth: true,
    );
  }

  /// Get Live Game Session State
  /// API: GET /api/games/session/:sessionId
  Future<Map<String, dynamic>> getGameSession({
    required String sessionId,
  }) async {
    return await get(
      ApiConfig.getSession(sessionId),
      withAuth: true,
    );
  }

  /// Roll Dice in Active Session
  /// API: POST /api/games/session/:sessionId/roll-dice
  Future<Map<String, dynamic>> rollDice({
    required String sessionId,
  }) async {
    return await post(
      ApiConfig.rollDice(sessionId),
      body: {},
      withAuth: true,
    );
  }

  /// Move Token & Update Score in Active Session
  /// API: POST /api/games/session/:sessionId/move-token
  Future<Map<String, dynamic>> moveToken({
    required String sessionId,
    required int tokenId,
  }) async {
    return await post(
      ApiConfig.moveToken(sessionId),
      body: {
        'tokenId': tokenId,
      },
      withAuth: true,
    );
  }

  /// Handle Turn Timeout in Active Session
  /// API: POST /api/games/session/:sessionId/timeout
  Future<Map<String, dynamic>> timeoutGame({
    required String sessionId,
  }) async {
    return await post(
      ApiConfig.timeoutGame(sessionId),
      body: {},
      withAuth: true,
    );
  }

  /// Surrender / Forfeit Active Match
  /// API: POST /api/games/session/:sessionId/surrender
  Future<Map<String, dynamic>> surrenderGame({
    required String sessionId,
  }) async {
    return await post(
      ApiConfig.surrenderGame(sessionId),
      body: {},
      withAuth: true,
    );
  }

  /// Complete & Settle Match
  /// API: POST /api/games/session/:sessionId/complete
  Future<Map<String, dynamic>> completeGame({
    required String sessionId,
  }) async {
    return await post(
      ApiConfig.completeGame(sessionId),
      body: {},
      withAuth: true,
    );
  }

  /// Get Player Match History
  /// API: GET /api/games/history/my-games?page=1&limit=10
  Future<Map<String, dynamic>> getMyGameHistory({
    int page = 1,
    int limit = 10,
  }) async {
    return await get(
      ApiConfig.myGameHistory(page: page, limit: limit),
      withAuth: true,
    );
  }

  // ===========================================================================
  // LEADERBOARD APIS
  // ===========================================================================

  /// Get Top Ranked Leaderboard Players
  /// API: GET /api/leaderboard?limit=:limit
  Future<Map<String, dynamic>> getLeaderboard({int limit = 50}) async {
    return await get(
      '${ApiConfig.leaderboard}?limit=$limit',
      withAuth: true,
    );
  }

  /// Get Logged-in User Ranking
  /// API: GET /api/leaderboard/me
  Future<Map<String, dynamic>> getMyLeaderboard() async {
    return await get(
      ApiConfig.leaderboardMe,
      withAuth: true,
    );
  }

  /// Update Game Match Result (Win / Loss)
  /// API: POST /api/leaderboard/update-result
  Future<Map<String, dynamic>> updateLeaderboardResult({
    required String result,
  }) async {
    return await post(
      ApiConfig.leaderboardUpdateResult,
      body: {
        'result': result,
      },
      withAuth: true,
    );
  }

  // ===========================================================================
  // REWARDS APIS
  // ===========================================================================

  /// Get Available Rewards List
  /// API: GET /api/rewards
  Future<Map<String, dynamic>> getRewards() async {
    return await get(
      ApiConfig.rewards,
      withAuth: true,
    );
  }

  /// Get Current User's Claimed Rewards History
  /// API: GET /api/rewards/me
  Future<Map<String, dynamic>> getMyRewards() async {
    return await get(
      ApiConfig.rewardsMe,
      withAuth: true,
    );
  }

  /// Get Rewards Summary Stats
  /// API: GET /api/rewards/summary
  Future<Map<String, dynamic>> getRewardsSummary() async {
    return await get(
      ApiConfig.rewardsSummary,
      withAuth: true,
    );
  }

  /// Claim a Specific Available Reward
  /// API: POST /api/rewards/:rewardId/claim
  Future<Map<String, dynamic>> claimReward(String rewardId) async {
    return await post(
      ApiConfig.claimReward(rewardId),
      body: {},
      withAuth: true,
    );
  }

  // ===========================================================================
  // WALLET APIS
  // ===========================================================================

  /// Get Wallet Details (Wallet info & balance)
  /// API: GET /api/wallet
  Future<Map<String, dynamic>> getWallet() async {
    return await get(
      ApiConfig.wallet,
      withAuth: true,
    );
  }

  /// Get Current Logged-in User's Wallet Balance
  /// API: GET /api/wallet/me
  Future<Map<String, dynamic>> getMyWallet() async {
    return await get(
      ApiConfig.walletMe,
      withAuth: true,
    );
  }

  /// Get Wallet Transaction History (Supports optional page and limit)
  /// API: GET /api/wallet/transactions OR /api/wallet/transactions?page=1&limit=20
  Future<Map<String, dynamic>> getTransactions([int? page, int? limit]) async {
    final endpoint = (page != null || limit != null)
        ? ApiConfig.walletTransactionsPaginated(
            page: page ?? 1,
            limit: limit ?? 20,
          )
        : ApiConfig.walletTransactions;
    return await get(
      endpoint,
      withAuth: true,
    );
  }

  /// Create Razorpay Deposit Order
  /// API: POST /api/wallet/deposit/create-order
  Future<Map<String, dynamic>> createDepositOrder(num amount) async {
    return await post(
      ApiConfig.walletDepositCreateOrder,
      body: {
        'amount': amount,
      },
      withAuth: true,
    );
  }

  /// Verify Razorpay Payment Signature and Credit Wallet
  /// API: POST /api/wallet/deposit/verify
  Future<Map<String, dynamic>> verifyDepositPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    return await post(
      ApiConfig.walletDepositVerify,
      body: {
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
        // Fallback backward-compatible snake_case keys
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      },
      withAuth: true,
    );
  }

  /// Get Deposit History (Paginated)
  /// API: GET /api/wallet/deposit/history?page=1&limit=20
  Future<Map<String, dynamic>> getDepositHistory({
    int page = 1,
    int limit = 20,
  }) async {
    return await get(
      ApiConfig.walletDepositHistory(page: page, limit: limit),
      withAuth: true,
    );
  }

  /// Request Wallet Withdrawal
  /// API: POST /api/wallet/withdraw/request
  Future<Map<String, dynamic>> requestWithdrawal({
    required num amount,
    String payoutMode = 'upi',
    Map<String, dynamic>? payoutDetails,
    String? paymentMethod,
  }) async {
    final effectivePayoutMode = (paymentMethod != null && paymentMethod.isNotEmpty)
        ? paymentMethod.toLowerCase()
        : payoutMode.toLowerCase();

    final details = payoutDetails ?? {};

    final Map<String, dynamic> body = {
      'amount': amount,
      'payoutMode': effectivePayoutMode,
      'payoutDetails': details,
      // Backward compatibility keys
      'paymentMethod': effectivePayoutMode,
      ...details,
    };

    return await post(
      ApiConfig.walletWithdrawRequest,
      body: body,
      withAuth: true,
    );
  }

  /// Get Withdrawal History (Paginated)
  /// API: GET /api/wallet/withdraw/history?page=1&limit=20
  Future<Map<String, dynamic>> getWithdrawalHistory({
    int page = 1,
    int limit = 20,
  }) async {
    return await get(
      ApiConfig.walletWithdrawHistory(page: page, limit: limit),
      withAuth: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Nearby Matchmaking Endpoints
  // ---------------------------------------------------------------------------

  /// Get Nearby Matchmaking Options
  /// API: GET /api/matchmaking/nearby/options
  Future<Map<String, dynamic>> getNearbyMatchmakingOptions() async {
    return await get(
      ApiConfig.nearbyMatchmakingOptions,
      withAuth: true,
    );
  }

  /// Join Nearby Matchmaking Queue
  /// API: POST /api/matchmaking/nearby/join
  Future<Map<String, dynamic>> joinNearbyMatchmaking({
    required double latitude,
    required double longitude,
    double? accuracy,
    int radiusKm = 5,
    int entryFee = 0,
    String gameMode = 'twoPlayer',
  }) async {
    final body = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'radiusKm': radiusKm,
      'entryFee': entryFee,
      'gameMode': gameMode,
    };
    if (accuracy != null) body['accuracy'] = accuracy;
    return await post(
      ApiConfig.nearbyMatchmakingJoin,
      body: body,
      withAuth: true,
    );
  }

  /// Update Nearby Location in Matchmaking Queue
  /// API: POST /api/matchmaking/nearby/location
  Future<Map<String, dynamic>> updateNearbyLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    int? radiusKm,
  }) async {
    final body = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
    };
    if (accuracy != null) body['accuracy'] = accuracy;
    if (radiusKm != null) body['radiusKm'] = radiusKm;
    return await post(
      ApiConfig.nearbyMatchmakingLocation,
      body: body,
      withAuth: true,
    );
  }

  /// Get Nearby Matchmaking Status
  /// API: GET /api/matchmaking/nearby/status
  Future<Map<String, dynamic>> getNearbyMatchmakingStatus() async {
    return await get(
      ApiConfig.nearbyMatchmakingStatus,
      withAuth: true,
    );
  }

  /// Leave/Cancel Nearby Matchmaking Queue
  /// API: POST /api/matchmaking/nearby/leave
  Future<Map<String, dynamic>> leaveNearbyMatchmaking() async {
    return await post(
      ApiConfig.nearbyMatchmakingLeave,
      body: {},
      withAuth: true,
    );
  }
}