/// Model representing user wallet information
class WalletModel {
  final String id;
  final String userId;
  final int balance;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WalletModel({
    this.id = '',
    this.userId = '',
    this.balance = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory from individual wallet object JSON
  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['user']?.toString() ?? json['userId']?.toString() ?? '',
      balance: _parseInt(json['balance']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  /// Factory capable of safely unpacking nested response structures:
  /// e.g. { data: { wallet: { ... } } } or { data: { balance: 100 } } or { wallet: { ... } }
  factory WalletModel.fromApiResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      if (data['wallet'] is Map<String, dynamic>) {
        return WalletModel.fromJson(data['wallet'] as Map<String, dynamic>);
      }
      if (data.containsKey('balance')) {
        return WalletModel(
          balance: _parseInt(data['balance']),
          id: data['_id']?.toString() ?? data['id']?.toString() ?? '',
          userId: data['user']?.toString() ?? data['userId']?.toString() ?? '',
          createdAt: _parseDateTime(data['createdAt']),
          updatedAt: _parseDateTime(data['updatedAt']),
        );
      }
    } else if (response['wallet'] is Map<String, dynamic>) {
      return WalletModel.fromJson(response['wallet'] as Map<String, dynamic>);
    }
    return WalletModel.fromJson(response);
  }

  WalletModel copyWith({
    String? id,
    String? userId,
    int? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': userId,
      'balance': balance,
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
