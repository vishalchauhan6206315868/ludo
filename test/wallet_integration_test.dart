import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/core/network/api_config.dart';
import 'package:ludo/core/network/api_service.dart';
import 'package:ludo/features/wallet/models/wallet_model.dart';
import 'package:ludo/features/wallet/models/wallet_transaction_model.dart';
import 'package:ludo/features/wallet/services/wallet_repository.dart';
import 'package:ludo/screens/wallet_screen.dart';

class FakeWalletApiService implements ApiService {
  final Map<String, dynamic>? walletResponse;
  final Map<String, dynamic>? myWalletResponse;
  final Map<String, dynamic>? transactionsResponse;
  final Map<String, dynamic>? Function(int? page, int? limit)? onGetTransactions;

  FakeWalletApiService({
    this.walletResponse,
    this.myWalletResponse,
    this.transactionsResponse,
    this.onGetTransactions,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Map<String, dynamic>> getWallet() async {
    return walletResponse ??
        {
          'success': true,
          'statusCode': 200,
          'message': 'Wallet fetched successfully',
          'data': {
            'wallet': {
              '_id': 'wal_1234567890ab',
              'user': 'user_test_999',
              'balance': 1500,
              'createdAt': '2026-10-06T10:00:00.000Z',
              'updatedAt': '2026-10-06T10:30:00.000Z',
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
          'message': 'Wallet balance fetched successfully',
          'data': {
            'balance': 1500,
          },
        };
  }

  @override
  Future<Map<String, dynamic>> getTransactions([int? page, int? limit]) async {
    if (onGetTransactions != null) {
      final custom = onGetTransactions!(page, limit);
      if (custom != null) return custom;
    }

    return transactionsResponse ??
        {
          'success': true,
          'statusCode': 200,
          'message': 'Wallet transactions fetched successfully',
          'data': {
            'wallet': {
              'balance': 1500,
            },
            'transactions': [
              {
                '_id': 'tx_01',
                'user': 'user_test_999',
                'wallet': 'wal_1234567890ab',
                'type': 'credit',
                'amount': 500,
                'balanceBefore': 1000,
                'balanceAfter': 1500,
                'source': 'bonus',
                'description': 'Welcome Bonus Coins',
                'status': 'completed',
                'createdAt': '2026-10-06T10:30:00.000Z',
              },
              {
                '_id': 'tx_02',
                'user': 'user_test_999',
                'wallet': 'wal_1234567890ab',
                'type': 'debit',
                'amount': 200,
                'balanceBefore': 1200,
                'balanceAfter': 1000,
                'source': 'game_entry',
                'description': 'Ludo Match Entry Fee',
                'status': 'completed',
                'createdAt': '2026-10-06T09:15:00.000Z',
              },
            ],
            'pagination': {
              'page': page ?? 1,
              'limit': limit ?? 20,
              'total': 2,
              'totalPages': 1,
            },
          },
        };
  }
}

void main() {
  group('Wallet API Config & Model Tests', () {
    test('ApiConfig has all wallet endpoints', () {
      expect(ApiConfig.wallet, '/wallet');
      expect(ApiConfig.walletMe, '/wallet/me');
      expect(ApiConfig.walletTransactions, '/wallet/transactions');
      expect(
        ApiConfig.walletTransactionsPaginated(page: 2, limit: 15),
        '/wallet/transactions?page=2&limit=15',
      );
    });

    test('WalletModel parses from backend JSON safely', () {
      final json = {
        '_id': 'wal_abc123',
        'user': 'usr_xyz456',
        'balance': 2500,
        'createdAt': '2026-10-06T08:00:00.000Z',
        'updatedAt': '2026-10-06T09:00:00.000Z',
      };

      final wallet = WalletModel.fromJson(json);
      expect(wallet.id, 'wal_abc123');
      expect(wallet.userId, 'usr_xyz456');
      expect(wallet.balance, 2500);
      expect(wallet.createdAt, isNotNull);
    });

    test('WalletModel parses nested response from GET /wallet and /wallet/me', () {
      final getWalletRes = {
        'success': true,
        'data': {
          'wallet': {
            '_id': 'wal_777',
            'user': 'usr_888',
            'balance': 300,
          },
        },
      };
      final fromWallet = WalletModel.fromApiResponse(getWalletRes);
      expect(fromWallet.id, 'wal_777');
      expect(fromWallet.balance, 300);

      final getMeRes = {
        'success': true,
        'data': {
          'balance': 450,
        },
      };
      final fromMe = WalletModel.fromApiResponse(getMeRes);
      expect(fromMe.balance, 450);
    });

    test('WalletTransactionModel and Response parse correctly', () {
      final response = {
        'success': true,
        'data': {
          'wallet': {'balance': 1200},
          'transactions': [
            {
              '_id': 'tx_99',
              'type': 'credit',
              'amount': 100,
              'balanceBefore': 1100,
              'balanceAfter': 1200,
              'source': 'game_reward',
              'description': 'Daily Win',
              'createdAt': '2026-10-06T10:00:00.000Z',
            },
          ],
          'pagination': {
            'page': 1,
            'limit': 20,
            'total': 1,
            'totalPages': 1,
          },
        },
      };

      final parsed = WalletTransactionsResponse.fromApiResponse(response);
      expect(parsed.balance, 1200);
      expect(parsed.transactions.length, 1);
      expect(parsed.transactions.first.isCredit, true);
      expect(parsed.transactions.first.isDebit, false);
      expect(parsed.transactions.first.amount, 100);
      expect(parsed.pagination.hasNextPage, false);
    });

    test('WalletRepository fetches wallet and transactions', () async {
      final fakeApi = FakeWalletApiService();
      final repo = WalletRepository(apiService: fakeApi);

      final wallet = await repo.getWallet();
      expect(wallet, isNotNull);
      expect(wallet!.balance, 1500);

      final myBal = await repo.getMyWallet();
      expect(myBal, 1500);

      final txRes = await repo.getTransactions(page: 1, limit: 20);
      expect(txRes.transactions.length, 2);
    });
  });

  group('WalletScreen Widget Tests', () {
    testWidgets('Renders WalletScreen with Balance, Info, and Transactions', (tester) async {
      final fakeApi = FakeWalletApiService();

      await tester.pumpWidget(
        MaterialApp(
          home: WalletScreen(apiService: fakeApi),
        ),
      );

      // Initially shows loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Screen title
      expect(find.text('MY WALLET'), findsOneWidget);

      // Balance Card
      expect(find.text('AVAILABLE BALANCE'), findsOneWidget);
      expect(find.text('1,500'), findsOneWidget);
      expect(find.text('COINS'), findsOneWidget);

      // Quick action buttons
      expect(find.text('Earn Free Coins'), findsOneWidget);
      expect(find.text('Sync'), findsOneWidget);

      // Transactions
      expect(find.text('Welcome Bonus Coins'), findsOneWidget);
      expect(find.text('+500'), findsOneWidget);
      expect(find.text('Ludo Match Entry Fee'), findsOneWidget);
      expect(find.text('-200'), findsOneWidget);
    });

    testWidgets('Filter tabs switch between Credit and Debit transactions', (tester) async {
      final fakeApi = FakeWalletApiService();

      await tester.pumpWidget(
        MaterialApp(
          home: WalletScreen(apiService: fakeApi),
        ),
      );
      await tester.pumpAndSettle();

      // Initially 'All' tab shows both transactions
      expect(find.text('Welcome Bonus Coins'), findsOneWidget);
      expect(find.text('Ludo Match Entry Fee'), findsOneWidget);

      // Tap Credit filter
      await tester.tap(find.textContaining('Credit'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome Bonus Coins'), findsOneWidget);
      expect(find.text('Ludo Match Entry Fee'), findsNothing);

      // Tap Debit filter
      await tester.tap(find.textContaining('Debit'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome Bonus Coins'), findsNothing);
      expect(find.text('Ludo Match Entry Fee'), findsOneWidget);
    });

    testWidgets('Handles Empty Transactions gracefully', (tester) async {
      final fakeApi = FakeWalletApiService(
        transactionsResponse: {
          'success': true,
          'statusCode': 200,
          'data': {
            'wallet': {'balance': 0},
            'transactions': [],
            'pagination': {'page': 1, 'limit': 20, 'total': 0, 'totalPages': 1},
          },
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WalletScreen(apiService: fakeApi),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Transactions Yet'), findsOneWidget);
      expect(find.text('Claim Free Rewards'), findsOneWidget);
    });

    testWidgets('Handles 401 Unauthorized state gracefully', (tester) async {
      final fakeApi = FakeWalletApiService(
        walletResponse: {
          'success': false,
          'statusCode': 401,
          'message': 'Authentication required. Please login.',
        },
        transactionsResponse: {
          'success': false,
          'statusCode': 401,
          'message': 'Authentication required. Please login.',
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WalletScreen(apiService: fakeApi),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Session Required'), findsOneWidget);
      expect(find.text('Go to Login'), findsOneWidget);
    });

    testWidgets('Handles Network/Server Error state with Retry', (tester) async {
      final failingApi = FakeWalletApiService(
        walletResponse: {
          'success': false,
          'statusCode': 500,
          'message': 'Server error: database timeout',
        },
        transactionsResponse: {
          'success': false,
          'statusCode': 500,
          'message': 'Server error: database timeout',
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WalletScreen(apiService: failingApi),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Server error: database timeout'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Small screen (320x568) renders WalletScreen without RenderFlex overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeApi = FakeWalletApiService();
      await tester.pumpWidget(
        MaterialApp(
          home: WalletScreen(apiService: fakeApi),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('MY WALLET'), findsOneWidget);
      expect(find.text('AVAILABLE BALANCE'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('COINS'), findsOneWidget);
    });
  });
}
