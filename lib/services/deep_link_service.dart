import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/api_service.dart';
import '../models/room_model.dart';
import '../screens/login_screen.dart';
import '../screens/wallet_screen.dart';
import '../services/auth_service.dart';
import '../services/ludo_socket_service.dart';
import '../widgets/room_invitation_dialog.dart';
import '../widgets/room_lobby_dialog.dart';

/// Data model representing a pending room invitation from a deep link.
class PendingRoomInvitation {
  final String roomCode;
  final String? rawUrl;
  final DateTime timestamp;

  const PendingRoomInvitation({
    required this.roomCode,
    this.rawUrl,
    required this.timestamp,
  });

  bool get isExpired =>
      DateTime.now().difference(timestamp) > const Duration(minutes: 15);
}

/// Service to handle App Links (HTTPS) & Custom Schemes (`ludosupreme://join`).
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  BuildContext? get _context => navigatorKey.currentContext;

  static const String _prefKeyPendingCode = '_pending_deep_link_code';
  static const String _prefKeyPendingUrl = '_pending_deep_link_url';
  static const String _prefKeyPendingTime = '_pending_deep_link_time';

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  PendingRoomInvitation? _currentPending;
  bool _isAppReady = false;
  bool _isProcessing = false;
  String? _lastProcessedCode;
  DateTime? _lastProcessedTime;

  PendingRoomInvitation? get currentPendingInvitation => _currentPending;
  bool get hasPendingInvitation =>
      _currentPending != null && !_currentPending!.isExpired;

  /// Initializes deep link listeners for both Cold Start and Warm Start.
  Future<void> init() async {
    // 1. Warm Start listener (app already running or brought to foreground)
    _linkSub?.cancel();
    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('[DEEP_LINK] Warm start URI received: $uri');
        handleUri(uri);
      },
      onError: (err) {
        debugPrint('[DEEP_LINK] URI stream error: $err');
      },
    );

    // 2. Cold Start check (app opened from closed state via link)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('[DEEP_LINK] Cold start initial URI received: $initialUri');
        handleUri(initialUri, isColdStart: true);
      }
    } catch (e) {
      debugPrint('[DEEP_LINK] Error reading initial link: $e');
    }

    // 3. Restore persisted invitation if app died before completion
    if (_currentPending == null) {
      await _restorePersistedInvitation();
    }
  }

  /// Extracts and validates room code from an incoming URI.
  /// Supports:
  /// - `https://ludoapi-jupm.onrender.com/join/HYYKM3`
  /// - `https://ludoapi-jupm.onrender.com/join?code=HYYKM3`
  /// - `ludosupreme://join?code=HYYKM3`
  /// - `ludosupreme://join/HYYKM3`
  static String? extractRoomCode(Uri uri) {
    String? code;

    // Check query parameter ?code=...
    if (uri.queryParameters.containsKey('code')) {
      code = uri.queryParameters['code'];
    }

    // Check path segments /join/:roomCode
    if (code == null || code.isEmpty) {
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        final joinIndex =
            segments.indexWhere((s) => s.toLowerCase() == 'join');
        if (joinIndex != -1 && joinIndex + 1 < segments.length) {
          code = segments[joinIndex + 1];
        } else if (segments.length == 1 && joinIndex != -1) {
          // If path is just /join with no child, check query
          code = uri.queryParameters['code'];
        } else if (segments.isNotEmpty && joinIndex == -1) {
          code = segments.last;
        }
      }
    }

    if (code == null) return null;
    final normalized = code.trim().toUpperCase();

    // Validate alphanumeric code length between 4 and 10 characters
    final validFormat = RegExp(r'^[A-Z0-9]{4,10}$');
    if (!validFormat.hasMatch(normalized)) {
      debugPrint('[DEEP_LINK] Rejected malformed room code: $normalized');
      return null;
    }

    return normalized;
  }

  /// Processes an incoming URI from either cold or warm start.
  Future<void> handleUri(Uri uri, {bool isColdStart = false}) async {
    final code = extractRoomCode(uri);
    if (code == null) return;

    // Deduplication check: ignore duplicate events within 3 seconds
    if (_lastProcessedCode == code &&
        _lastProcessedTime != null &&
        DateTime.now().difference(_lastProcessedTime!) <
            const Duration(seconds: 3)) {
      debugPrint('[DEEP_LINK] Skipping duplicate link event for $code');
      return;
    }

    _lastProcessedCode = code;
    _lastProcessedTime = DateTime.now();

    await savePendingInvitation(code, rawUrl: uri.toString());

    // If app is fully ready and visible, process immediately
    if (_isAppReady) {
      processPendingInvitation();
    }
  }

  /// Saves pending invitation in memory and persistent storage.
  Future<void> savePendingInvitation(String code, {String? rawUrl}) async {
    _currentPending = PendingRoomInvitation(
      roomCode: code.toUpperCase(),
      rawUrl: rawUrl,
      timestamp: DateTime.now(),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyPendingCode, _currentPending!.roomCode);
      if (rawUrl != null) {
        await prefs.setString(_prefKeyPendingUrl, rawUrl);
      }
      await prefs.setString(
          _prefKeyPendingTime, _currentPending!.timestamp.toIso8601String());
    } catch (e) {
      debugPrint('[DEEP_LINK] Error persisting invitation: $e');
    }
  }

  /// Clears pending invitation from memory and storage.
  Future<void> clearPendingInvitation() async {
    _currentPending = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyPendingCode);
      await prefs.remove(_prefKeyPendingUrl);
      await prefs.remove(_prefKeyPendingTime);
    } catch (_) {}
  }

  Future<void> _restorePersistedInvitation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefKeyPendingCode);
      final rawUrl = prefs.getString(_prefKeyPendingUrl);
      final timeStr = prefs.getString(_prefKeyPendingTime);

      if (code != null && timeStr != null) {
        final time = DateTime.tryParse(timeStr) ?? DateTime.now();
        final invite = PendingRoomInvitation(
          roomCode: code,
          rawUrl: rawUrl,
          timestamp: time,
        );
        if (!invite.isExpired) {
          _currentPending = invite;
        } else {
          await clearPendingInvitation();
        }
      }
    } catch (_) {}
  }

  /// Marks the app as ready to present UI dialogs.
  void setAppReady(bool ready) {
    _isAppReady = ready;
    if (_isAppReady && hasPendingInvitation) {
      // Small delay to ensure current frame has rendered
      Future.delayed(const Duration(milliseconds: 350), () {
        processPendingInvitation();
      });
    }
  }

  /// Core smart auto-join orchestration.
  Future<void> processPendingInvitation({BuildContext? context}) async {
    final activeContext = context ?? _context;
    if (activeContext == null || !activeContext.mounted) {
      debugPrint('[DEEP_LINK] Navigator context not ready yet');
      return;
    }

    if (!hasPendingInvitation || _isProcessing) return;
    _isProcessing = true;

    final invite = _currentPending!;
    final roomCode = invite.roomCode;

    try {
      // 1. Auth Check: User must be logged in
      final isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        _isProcessing = false;
        debugPrint('[DEEP_LINK] User not logged in. Preserving invite $roomCode');
        final c = _context;
        if (c != null && c.mounted) {
          Navigator.of(c).push(
            MaterialPageRoute(
              builder: (_) => const LoginScreen(),
              settings: const RouteSettings(name: '/login'),
            ),
          );
        }
        return;
      }

      // 2. Validate Room with Backend
      final cBeforeFetch = _context;
      if (cBeforeFetch != null && cBeforeFetch.mounted) {
        _showLoadingDialog(cBeforeFetch, "Checking room availability...");
      }

      final roomResponse =
          await ApiService().getRoomDetails(roomCode: roomCode);

      final cAfterFetch = _context;
      if (cAfterFetch != null && cAfterFetch.mounted) {
        _hideLoadingDialog(cAfterFetch);
      }

      if (roomResponse['success'] != true || roomResponse['data'] == null) {
        await clearPendingInvitation();
        _isProcessing = false;
        final c = _context;
        if (c != null && c.mounted) {
          _showInfoDialog(
            c,
            title: "Room Not Found",
            message: roomResponse['message']?.toString() ??
                "This room code does not exist. Please check the invitation link.",
          );
        }
        return;
      }

      RoomModel room;
      try {
        room = RoomModel.fromJson(roomResponse['data']);
      } catch (e) {
        await clearPendingInvitation();
        _isProcessing = false;
        final c = _context;
        if (c != null && c.mounted) {
          _showInfoDialog(c,
              title: "Invalid Room Data",
              message: "Unable to parse room details from backend.");
        }
        return;
      }

      // Validate Room Status
      if (room.status != 'waiting') {
        await clearPendingInvitation();
        _isProcessing = false;
        final c = _context;
        if (c != null && c.mounted) {
          _showInfoDialog(
            c,
            title: "Match Already Started",
            message: "This match has already started or the room has expired.",
          );
        }
        return;
      }

      // Validate Room Capacity
      if (room.players.length >= room.maxPlayers) {
        await clearPendingInvitation();
        _isProcessing = false;
        final c = _context;
        if (c != null && c.mounted) {
          _showInfoDialog(
            c,
            title: "Room Full",
            message:
                "This room is already full (${room.players.length}/${room.maxPlayers} players).",
          );
        }
        return;
      }

      // 3. Authenticated Profile & Wallet Balance Check
      final cachedProfile = await AuthService.getCachedUserProfile();
      final profileCoins = cachedProfile?.coins ?? await AuthService.getUserCoins();
      int userBalance = profileCoins;
      int? liveWalletBalance;
      bool walletApiOk = false;

      if (room.entryFee > 0) {
        try {
          final walletRes = await ApiService().getMyWallet();
          if (walletRes['success'] == true && walletRes['data'] != null) {
            final wData = walletRes['data'];
            if (wData is Map) {
              final b = wData['balance'] ??
                  (wData['wallet'] is Map ? wData['wallet']['balance'] : null);
              if (b is num) {
                liveWalletBalance = b.toInt();
                walletApiOk = true;
              }
            }
          }
        } catch (e) {
          debugPrint('[DEEP_LINK] Wallet check error: $e');
        }

        if (walletApiOk && liveWalletBalance != null) {
          userBalance = liveWalletBalance;
          if (liveWalletBalance != profileCoins) {
            debugPrint(
                '[DEEP_LINK] Balance mismatch: Wallet=$liveWalletBalance, Profile=$profileCoins. Refreshing cache.');
            AuthService.updateLocalCoins(liveWalletBalance);
          }
        }

        // Only show pre-flight Insufficient Coins dialog if BOTH live wallet balance
        // (when available) and profile balance are insufficient. If profile has coins
        // (e.g. 2750), preserve invitation and allow backend to validate authoritatively.
        final isAuthoritativelyInsufficient = walletApiOk &&
            liveWalletBalance != null &&
            liveWalletBalance < room.entryFee &&
            profileCoins < room.entryFee;
        final isOfflineInsufficient = !walletApiOk && profileCoins < room.entryFee;

        if (isAuthoritativelyInsufficient || isOfflineInsufficient) {
          _isProcessing = false;
          final c = _context;
          if (c != null && c.mounted) {
            _showInsufficientCoinsDialog(c, room, userBalance);
          }
          return;
        }
      }

      // 4. Show Royal Room Invitation Confirmation Dialog
      _isProcessing = false;
      final cConfirm = _context;
      if (cConfirm != null && cConfirm.mounted) {
        await RoomInvitationDialog.show(
          cConfirm,
          room: room,
          userBalance: userBalance,
          onConfirmJoin: () async {
            await _executeJoin(room, preFlightBalance: userBalance);
          },
          onCancel: () async {
            await clearPendingInvitation();
          },
        );
      }
    } catch (e) {
      _isProcessing = false;
      debugPrint('[DEEP_LINK] Unexpected error processing invitation: $e');
    }
  }

  /// Executes actual join room API and opens lobby
  Future<void> _executeJoin(RoomModel room, {int preFlightBalance = 0}) async {
    final cLoad = _context;
    if (cLoad != null && cLoad.mounted) {
      _showLoadingDialog(cLoad, "Joining match...");
    }

    try {
      final res = await ApiService().joinRoom(roomCode: room.roomCode);
      final cHide = _context;
      if (cHide != null && cHide.mounted) {
        _hideLoadingDialog(cHide);
      }

      if (res['success'] == true && res['data'] != null) {
        RoomModel joinedRoom = room;
        try {
          joinedRoom = RoomModel.fromJson(res['data']);
        } catch (_) {}

        // Connect socket room
        LudoSocketService.instance.joinRoom(room.roomCode);

        // Clear invitation upon successful join
        await clearPendingInvitation();

        // Refresh user profile in background after paid entry fee deduction
        if (joinedRoom.entryFee > 0) {
          AuthService.fetchUserProfile();
        }

        // Open Room Lobby Dialog
        final cLobby = _context;
        if (cLobby != null && cLobby.mounted) {
          showDialog(
            context: cLobby,
            barrierDismissible: false,
            builder: (_) => RoomLobbyDialog(
              room: joinedRoom,
              entryFee: joinedRoom.entryFee,
              isHost: false,
            ),
          );
        }
      } else {
        final cFail = _context;
        if (cFail != null && cFail.mounted) {
          final errMsg = res['message']?.toString() ?? "Could not join room.";
          final lower = errMsg.toLowerCase();
          if (lower.contains("insufficient") || lower.contains("balance")) {
            _showInsufficientCoinsDialog(cFail, room, preFlightBalance);
          } else {
            _showInfoDialog(
              cFail,
              title: "Join Failed",
              message: errMsg,
            );
          }
        }
      }
    } catch (e) {
      final cErr = _context;
      if (cErr != null && cErr.mounted) {
        _hideLoadingDialog(cErr);
        _showInfoDialog(
          cErr,
          title: "Connection Error",
          message: "Failed to connect to room: $e",
        );
      }
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1E48),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Color(0xFFFFD700)),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _showInfoDialog(BuildContext context,
      {required String title, required String message}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F1E48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFFD700), width: 1.8),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFFFE082),
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              "OK",
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInsufficientCoinsDialog(
      BuildContext context, RoomModel room, int currentBalance) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F1E48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFFD700), width: 1.8),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text(
              "Insufficient Coins",
              style: TextStyle(
                color: Color(0xFFFFE082),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You need ${room.entryFee} coins to join this room.",
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              "Your balance: $currentBalance coins",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            const Text(
              "Add coins to your wallet to continue joining this match.",
              style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              clearPendingInvitation();
              Navigator.of(context).pop();
            },
            child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              final c = _context;
              if (c != null && c.mounted) {
                // Navigate to wallet screen keeping pending invite intact
                Navigator.of(c).push(
                  MaterialPageRoute(
                    builder: (_) => WalletScreen(
                      onWalletUpdated: () {
                        // When wallet is updated, resume auto-join
                        processPendingInvitation();
                      },
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              "ADD COINS",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
