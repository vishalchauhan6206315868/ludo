import 'package:ludo/core/network/api_service.dart';
import '../models/wallet_model.dart';
import '../models/wallet_transaction_model.dart';

/// Repository for handling Wallet and Transaction interactions
class WalletRepository {
  final ApiService _apiService;

  WalletRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Fetch full wallet details
  Future<WalletModel?> getWallet() async {
    final response = await _apiService.getWallet();
    if (response['success'] == true && response['data'] != null) {
      return WalletModel.fromApiResponse(response);
    }
    return null;
  }

  /// Fetch current balance only
  Future<int?> getMyWallet() async {
    final response = await _apiService.getMyWallet();
    if (response['success'] == true && response['data'] != null) {
      final data = response['data'];
      if (data is Map<String, dynamic> && data.containsKey('balance')) {
        final val = data['balance'];
        if (val is int) return val;
        if (val is double) return val.toInt();
        if (val is String) return int.tryParse(val);
      }
    }
    return null;
  }

  /// Fetch transactions with optional pagination
  Future<WalletTransactionsResponse> getTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiService.getTransactions(page, limit);
    if (response['success'] == true) {
      return WalletTransactionsResponse.fromApiResponse(response);
    }
    return const WalletTransactionsResponse();
  }

  /// Create Razorpay Deposit Order
  Future<Map<String, dynamic>> createDepositOrder(num amount) async {
    return await _apiService.createDepositOrder(amount);
  }

  /// Verify Payment with Backend
  Future<Map<String, dynamic>> verifyDepositPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    return await _apiService.verifyDepositPayment(
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
    );
  }

  /// Request Withdrawal
  Future<Map<String, dynamic>> requestWithdrawal({
    required num amount,
    String? paymentMethod,
    Map<String, dynamic>? payoutDetails,
  }) async {
    return await _apiService.requestWithdrawal(
      amount: amount,
      paymentMethod: paymentMethod,
      payoutDetails: payoutDetails,
    );
  }
}
