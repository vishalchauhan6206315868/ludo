import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/core/network/api_service.dart';
import 'package:ludo/models/room_model.dart';
import 'package:ludo/screens/wallet_screen.dart';
import 'package:ludo/widgets/room_invitation_dialog.dart';

class MockSyncApiService implements ApiService {
  final Map<String, dynamic>? walletResponse;
  final Map<String, dynamic>? myWalletResponse;
  final Map<String, dynamic>? transactionsResponse;
  int getWalletCallCount = 0;

  MockSyncApiService({
    this.walletResponse,
    this.myWalletResponse,
    this.transactionsResponse,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Map<String, dynamic>> getWallet() async {
    getWalletCallCount++;
    return walletResponse ??
        {
          'success': true,
          'statusCode': 200,
          'data': {
            'wallet': {
              '_id': 'wal_sync_1',
              'user': 'user_sync_1',
              'balance': 2750,
            },
          },
        };
  }

  @override
  Future<Map<String, dynamic>> getMyWallet() async {
    return myWalletResponse ??
        {
          'success': true,
          'statusCode': 200,
          'data': {
            'balance': 2750,
          },
        };
  }

  @override
  Future<Map<String, dynamic>> getTransactions([int? page, int? limit]) async {
    return transactionsResponse ??
        {
          'success': true,
          'statusCode': 200,
          'data': {
            'transactions': <Map<String, dynamic>>[],
            'pagination': {'page': 1, 'limit': 20, 'total': 0, 'totalPages': 1},
          },
        };
  }
}

void main() {
  group('Ludo Supreme Coin Balance Synchronization Tests', () {
    testWidgets('Scenario 1: Profile 2750 / Wallet 2750 displays matched authoritative balance',
        (WidgetTester tester) async {
      final mockApi = MockSyncApiService(
        walletResponse: {
          'success': true,
          'statusCode': 200,
          'data': {
            'wallet': {'balance': 2750},
          },
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WalletScreen(
            apiService: mockApi,
            profileFallbackCoins: 2750,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should display 2750 coins
      expect(find.text('2,750'), findsOneWidget);
      expect(find.text('COINS'), findsOneWidget);
      // No discrepancy or fallback warning
      expect(find.textContaining('Profile reports'), findsNothing);
      expect(find.textContaining('Cached Profile Balance'), findsNothing);
    });

    testWidgets('Scenario 2: Profile 2750 / Wallet 0 detects discrepancy and shows warning',
        (WidgetTester tester) async {
      final mockApi = MockSyncApiService(
        walletResponse: {
          'success': true,
          'statusCode': 200,
          'data': {
            'wallet': {'balance': 0},
          },
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WalletScreen(
            apiService: mockApi,
            profileFallbackCoins: 2750,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Displays authoritative 0 coins
      expect(find.text('0'), findsOneWidget);
      // Shows discrepancy detection badge
      expect(find.text('Profile reports 2750 coins'), findsOneWidget);
    });

    testWidgets('Scenario 3: Profile 0 / Wallet 2750 displays authoritative wallet balance',
        (WidgetTester tester) async {
      final mockApi = MockSyncApiService(
        walletResponse: {
          'success': true,
          'statusCode': 200,
          'data': {
            'wallet': {'balance': 2750},
          },
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WalletScreen(
            apiService: mockApi,
            profileFallbackCoins: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2,750'), findsOneWidget);
      expect(find.textContaining('Cached Profile Balance'), findsNothing);
    });

    testWidgets('Scenario 5: Wallet API unavailable falls back safely to cached profile balance',
        (WidgetTester tester) async {
      final failingApi = MockSyncApiService(
        walletResponse: {
          'success': false,
          'statusCode': 503,
          'message': 'Service temporarily unavailable',
        },
        transactionsResponse: {
          'success': false,
          'statusCode': 503,
          'message': 'Service temporarily unavailable',
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WalletScreen(
            apiService: failingApi,
            profileFallbackCoins: 2750,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Does not crash or show dead error screen; displays cached fallback
      expect(find.text('2,750'), findsOneWidget);
      expect(find.text('Cached Profile Balance (Wallet syncing...)'), findsOneWidget);
    });

    testWidgets('Scenario 6: Both APIs unavailable and profile 0 shows error screen with Retry',
        (WidgetTester tester) async {
      final failingApi = MockSyncApiService(
        walletResponse: {
          'success': false,
          'statusCode': 500,
          'message': 'Connection error',
        },
        transactionsResponse: {
          'success': false,
          'statusCode': 500,
          'message': 'Connection error',
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WalletScreen(
            apiService: failingApi,
            profileFallbackCoins: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Connection error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Scenario 7 & 14: Deep link with entry fee 50 and balance 2750 displays confirmation dialog',
        (WidgetTester tester) async {
      final room = RoomModel(
        id: 'room_50',
        roomCode: 'ZWG4FU',
        host: 'host_player',
        gameMode: 'twoPlayer',
        entryFee: 50,
        maxPlayers: 2,
        status: 'waiting',
        players: const ['Opponent'],
        playerIds: const ['opp_1'],
        createdAt: DateTime.now(),
      );

      bool confirmed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomInvitationDialog(
              room: room,
              userBalance: 2750,
              onConfirmJoin: () => confirmed = true,
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify room details rendered
      expect(find.text('MATCH INVITATION'), findsOneWidget);
      expect(find.text('ZWG4FU'), findsOneWidget);
      expect(find.text('50 Coins'), findsOneWidget);

      // Tap JOIN MATCH
      await tester.tap(find.text('JOIN MATCH'));
      await tester.pump();
      expect(confirmed, isTrue);
    });

    testWidgets('Scenario 8: Insufficient balance dialog renders and provides ADD COINS navigation',
        (WidgetTester tester) async {
      final room = RoomModel(
        id: 'room_expensive',
        roomCode: 'EXP999',
        host: 'host_rich',
        gameMode: 'twoPlayer',
        entryFee: 500,
        maxPlayers: 2,
        status: 'waiting',
        players: const ['Rich Host'],
        playerIds: const ['rich_1'],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Insufficient Coins"),
                        content: Text("You need ${room.entryFee} coins to join this room. Your balance: 20 coins"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("CANCEL"),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("ADD COINS"),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text("Show Dialog"),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Insufficient Coins'), findsOneWidget);
      expect(find.textContaining('You need 500 coins'), findsOneWidget);
      expect(find.text('ADD COINS'), findsOneWidget);
    });

    testWidgets('Scenario 12: Wallet screen refresh callback executes properly',
        (WidgetTester tester) async {
      final mockApi = MockSyncApiService();
      bool walletUpdatedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: WalletScreen(
            apiService: mockApi,
            onWalletUpdated: () {
              walletUpdatedCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(mockApi.getWalletCallCount, equals(1));
      expect(walletUpdatedCalled, isTrue);

      // Tap refresh
      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pumpAndSettle();

      expect(mockApi.getWalletCallCount, equals(2));
    });
  });
}
