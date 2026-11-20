/// Model representing a single Wallet Transaction
class WalletTransactionModel {
  final String id;
  final String userId;
  final String walletId;
  final String type; // 'credit' or 'debit'
  final int amount;
  final String status; // 'completed', 'success', 'pending', etc.
  final String source; // 'game_reward', 'game_entry', 'bonus', 'admin', 'refund', 'other'
  final String description;
  final int balanceBefore;
  final int balanceAfter;
  final int balance; // Represents final balance after transaction
  final String? referenceId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WalletTransactionModel({
    this.id = '',
    this.userId = '',
    this.walletId = '',
    this.type = 'credit',
    this.amount = 0,
    this.status = 'completed',
    this.source = 'other',
    this.description = '',
    this.balanceBefore = 0,
    this.balanceAfter = 0,
    this.balance = 0,
    this.referenceId,
    this.createdAt,
    this.updatedAt,
  });

  bool get isCredit => type.toLowerCase() == 'credit';
  bool get isDebit => type.toLowerCase() == 'debit';

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    final balBefore = _parseInt(json['balanceBefore']);
    final balAfter = _parseInt(json['balanceAfter'] ?? json['balance']);
    final balanceVal = json.containsKey('balance') ? _parseInt(json['balance']) : balAfter;
    final typeVal = json['type']?.toString().toLowerCase() ?? 'credit';

    return WalletTransactionModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['user']?.toString() ?? json['userId']?.toString() ?? '',
      walletId: json['wallet']?.toString() ?? json['walletId']?.toString() ?? '',
      type: typeVal,
      amount: _parseInt(json['amount']),
      status: json['status']?.toString() ?? 'completed',
      source: json['source']?.toString() ?? 'other',
      description: json['description']?.toString() ??
          json['reason']?.toString() ??
          json['source']?.toString() ??
          '',
      balanceBefore: balBefore,
      balanceAfter: balAfter,
      balance: balanceVal,
      referenceId: json['referenceId']?.toString(),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': userId,
      'wallet': walletId,
      'type': type,
      'amount': amount,
      'status': status,
      'source': source,
      'description': description,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'balance': balance,
      'referenceId': referenceId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

/// Model representing Pagination metadata from GET /wallet/transactions
class WalletPaginationModel {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const WalletPaginationModel({
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 1,
  });

  bool get hasNextPage => page < totalPages;

  factory WalletPaginationModel.fromJson(dynamic json) {
    if (json == null || json is! Map<String, dynamic>) {
      return const WalletPaginationModel();
    }
    return WalletPaginationModel(
      page: _parseInt(json['page'], defaultValue: 1),
      limit: _parseInt(json['limit'], defaultValue: 20),
      total: _parseInt(json['total'], defaultValue: 0),
      totalPages: _parseInt(json['totalPages'], defaultValue: 1),
    );
  }

  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}

/// Container model for full response from GET /wallet/transactions
class WalletTransactionsResponse {
  final int balance;
  final List<WalletTransactionModel> transactions;
  final WalletPaginationModel pagination;

  const WalletTransactionsResponse({
    this.balance = 0,
    this.transactions = const [],
    this.pagination = const WalletPaginationModel(),
  });

  factory WalletTransactionsResponse.fromApiResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      return const WalletTransactionsResponse();
    }

    // Extract balance
    int balanceVal = 0;
    if (data['wallet'] is Map<String, dynamic>) {
      balanceVal = _parseInt(data['wallet']['balance']);
    } else if (data.containsKey('balance')) {
      balanceVal = _parseInt(data['balance']);
    }

    // Extract transactions
    List<WalletTransactionModel> txList = [];
    if (data['transactions'] is List) {
      txList = (data['transactions'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => WalletTransactionModel.fromJson(item))
          .toList();
    }

    // Extract pagination
    WalletPaginationModel pagination = const WalletPaginationModel();
    if (data['pagination'] is Map<String, dynamic>) {
      pagination = WalletPaginationModel.fromJson(data['pagination'] as Map<String, dynamic>);
    }

    return WalletTransactionsResponse(
      balance: balanceVal,
      transactions: txList,
      pagination: pagination,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
