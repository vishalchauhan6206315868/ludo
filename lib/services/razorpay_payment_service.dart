import 'dart:developer' as developer;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../core/network/api_config.dart';

/// Handler for Razorpay Payment Gateway integration
class RazorpayPaymentService {
  late final Razorpay _razorpay;

  Function(PaymentSuccessResponse)? _onSuccess;
  Function(PaymentFailureResponse)? _onError;
  Function(ExternalWalletResponse)? _onExternalWallet;

  bool _isInitialized = false;

  RazorpayPaymentService() {
    _razorpay = Razorpay();
  }

  /// Initialize listeners for Razorpay callbacks
  void initialize({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onError,
    Function(ExternalWalletResponse)? onExternalWallet,
  }) {
    _onSuccess = onSuccess;
    _onError = onError;
    _onExternalWallet = onExternalWallet;

    if (!_isInitialized) {
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      _isInitialized = true;
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    developer.log(
      'Razorpay Payment Success: paymentId=${response.paymentId}, orderId=${response.orderId}',
      name: 'RazorpayPaymentService',
    );
    _onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    developer.log(
      'Razorpay Payment Error: code=${response.code}, message=${response.message}',
      name: 'RazorpayPaymentService',
    );
    _onError?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    developer.log(
      'Razorpay External Wallet: walletName=${response.walletName}',
      name: 'RazorpayPaymentService',
    );
    _onExternalWallet?.call(response);
  }

  /// Launch Razorpay Checkout sheet
  void openCheckout({
    String? key,
    required String orderId,
    required num amount,
    String? name,
    String? description,
    String? prefillName,
    String? prefillContact,
    String? prefillEmail,
  }) {
    final effectiveKey = (key != null && key.trim().isNotEmpty)
        ? key.trim()
        : ApiConfig.razorpayKeyId.trim();

    if (effectiveKey.isEmpty) {
      throw StateError('Razorpay Key ID is missing from server order response.');
    }

    // Razorpay expects amount in paise (₹1 = 100 paise)
    final int amountInPaise = (amount * 100).round();

    // Check if contact is a valid numeric phone number
    final cleanContact = prefillContact?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final validContact = cleanContact.length >= 10 ? cleanContact : null;

    final options = {
      'key': effectiveKey,
      'amount': amountInPaise,
      'name': name ?? 'Ludo Supreme Pro',
      'description': description ?? 'Deposit Coins to Wallet',
      'order_id': orderId,
      'timeout': 300, // 5 minutes timeout
      'prefill': {
        if (prefillName != null && prefillName.trim().isNotEmpty)
          'name': prefillName.trim(),
        'contact': ?validContact,
        if (prefillEmail != null && prefillEmail.trim().isNotEmpty && prefillEmail.contains('@'))
          'email': prefillEmail.trim(),
      },
      'theme': {
        'color': '#FFD700', // Ludo Supreme Gold theme
      },
      'external': {
        'wallets': ['paytm', 'mobikwik']
      }
    };

    developer.log('Opening Razorpay Checkout with Order ID: $orderId, Amount: ₹$amount', name: 'RazorpayPaymentService');
    _razorpay.open(options);
  }

  /// Clean up Razorpay instance and listeners
  void dispose() {
    if (_isInitialized) {
      _razorpay.clear();
      _isInitialized = false;
    }
  }
}

