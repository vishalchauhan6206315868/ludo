import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/core/network/api_service.dart';
import 'package:ludo/widgets/tournament_payment_dialog.dart';

class FakePaymentApiService implements ApiService {
  final Map<String, dynamic>? walletResponse;
  final Map<String, dynamic>? createOrderResponse;
  final Map<String, dynamic>? verifyResponse;

  FakePaymentApiService({
    this.walletResponse,
    this.createOrderResponse,
    this.verifyResponse,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Map<String, dynamic>> getWallet() async {
    return walletResponse ??
        {
          'success': true,
          'statusCode': 200,
          'data': {
            'wallet': {
              'balance': 1500,
            },
          },
        };
  }

  @override
  Future<Map<String, dynamic>> createDepositOrder(num amount) async {
    return createOrderResponse ??
        {
          'success': true,
          'statusCode': 200,
          'data': {
            'razorpayOrderId': 'order_fake_123',
            'keyId': 'rzp_test_key_fake',
          },
        };
  }

  @override
  Future<Map<String, dynamic>> verifyDepositPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    return verifyResponse ??
        {
          'success': true,
          'statusCode': 200,
          'data': {
            'verified': true,
          },
        };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TournamentPaymentDialog Widget Tests', () {
    testWidgets(
        'Renders title, tournament summary, wallet balance and action buttons',
        (WidgetTester tester) async {
      final fakeApi = FakePaymentApiService(
        walletResponse: {
          'success': true,
          'data': {
            'wallet': {'balance': 2000},
          },
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TournamentPaymentDialog(
              tournamentName: "Grand Championship",
              prizePool: 50000,
              entryFee: 1000,
              initialBalance: 2000,
              apiService: fakeApi,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title & Tournament Info
      expect(find.text('TOURNAMENT ENTRY & PAYMENT'), findsOneWidget);
      expect(find.text('GRAND CHAMPIONSHIP'), findsOneWidget);
      expect(find.text('Prize: 50000 Coins'), findsOneWidget);
      expect(find.text('₹1000 / 1000 Coins'), findsOneWidget);

      // Wallet Balance & Sufficient status
      expect(find.text('🪙 2000 Coins'), findsOneWidget);
      expect(find.textContaining('Sufficient Balance'), findsOneWidget);

      // Buttons
      expect(find.byKey(const Key('pay_with_wallet_button')), findsOneWidget);
      expect(find.byKey(const Key('pay_with_razorpay_button')), findsOneWidget);
      expect(find.byKey(const Key('tournament_payment_close_button')),
          findsOneWidget);
    });

    testWidgets(
        'Paying with wallet balance triggers confirmation and success callback',
        (WidgetTester tester) async {
      int? paidAmountResult;
      String? paymentMethodResult;

      final fakeApi = FakePaymentApiService(
        walletResponse: {
          'success': true,
          'data': {
            'wallet': {'balance': 2000},
          },
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TournamentPaymentDialog(
              tournamentName: "Grand Championship",
              prizePool: 50000,
              entryFee: 1000,
              initialBalance: 2000,
              apiService: fakeApi,
              onPaymentSuccess: (paidAmount, paymentMethod) async {
                paidAmountResult = paidAmount;
                paymentMethodResult = paymentMethod;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Pay with Wallet
      await tester.tap(find.byKey(const Key('pay_with_wallet_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(paidAmountResult, 1000);
      expect(paymentMethodResult, 'Wallet Balance');
      expect(find.byKey(const Key('tournament_entry_success_view')),
          findsOneWidget);
      expect(find.text('REGISTRATION CONFIRMED! 🏆'), findsOneWidget);
    });

    testWidgets('Displays low balance warning when wallet balance is lower than entry fee',
        (WidgetTester tester) async {
      final fakeApi = FakePaymentApiService(
        walletResponse: {
          'success': true,
          'data': {
            'wallet': {'balance': 200},
          },
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TournamentPaymentDialog(
              tournamentName: "Weekend Blitz",
              prizePool: 25000,
              entryFee: 500,
              initialBalance: 200,
              apiService: fakeApi,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('🪙 200 Coins'), findsOneWidget);
      expect(find.textContaining('Low Balance: You need ₹300 more'), findsOneWidget);
      expect(find.text('ADD ₹300 & ENTER VIA RAZORPAY'), findsOneWidget);
    });

    testWidgets('Close button pops dialog cleanly',
        (WidgetTester tester) async {
      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (_) => TournamentPaymentDialog(
                    tournamentName: "Daily Knockout",
                    prizePool: 10000,
                    entryFee: 250,
                    initialBalance: 500,
                    apiService: FakePaymentApiService(),
                  ),
                );
                closed = true;
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('DAILY KNOCKOUT'), findsOneWidget);

      await tester.tap(find.byKey(const Key('tournament_payment_close_button')));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(find.text('DAILY KNOCKOUT'), findsNothing);
    });

    testWidgets('Renders on small 320x568 phone without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      FlutterErrorDetails? caughtDetails;
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        caughtDetails = details;
        oldOnError?.call(details);
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TournamentPaymentDialog(
              tournamentName: "Grand Championship",
              prizePool: 50000,
              entryFee: 1000,
              initialBalance: 500,
              apiService: FakePaymentApiService(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      FlutterError.onError = oldOnError;
      if (caughtDetails != null) {
        debugPrint('EXACT OVERFLOW DETAILS:\n${caughtDetails!.toString()}');
      }

      final exception = tester.takeException();
      expect(exception, isNull);
      expect(find.text('TOURNAMENT ENTRY & PAYMENT'), findsOneWidget);
      expect(find.text('GRAND CHAMPIONSHIP'), findsOneWidget);
    });
  });
}
