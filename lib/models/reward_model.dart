/// Model representing a single Reward item (from GET /rewards or claim)
class RewardItem {
  final String id;
  final String title;
  final String description;
  final String rewardType;
  final int rewardValue;
  final String icon;
  final bool isClaimed;
  final bool canClaim;

  const RewardItem({
    required this.id,
    required this.title,
    required this.description,
    this.rewardType = 'coins',
    required this.rewardValue,
    this.icon = 'daily_login',
    this.isClaimed = false,
    this.canClaim = true,
  });

  factory RewardItem.fromJson(Map<String, dynamic> json) {
    return RewardItem(
      id: json['_id']?.toString() ??
          json['id']?.toString() ??
          json['rewardId']?.toString() ??
          '',
      title: json['title']?.toString() ?? 'Reward',
      description: json['description']?.toString() ?? '',
      rewardType: json['rewardType']?.toString() ?? 'coins',
      rewardValue: _parseInt(json['rewardValue'] ?? json['amount'] ?? json['value']),
      icon: json['icon']?.toString() ?? 'daily_login',
      isClaimed: _parseBool(json['isClaimed']),
      canClaim: _parseBool(json['canClaim'] ?? (!(_parseBool(json['isClaimed'])))),
    );
  }

  RewardItem copyWith({
    String? id,
    String? title,
    String? description,
    String? rewardType,
    int? rewardValue,
    String? icon,
    bool? isClaimed,
    bool? canClaim,
  }) {
    return RewardItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      rewardType: rewardType ?? this.rewardType,
      rewardValue: rewardValue ?? this.rewardValue,
      icon: icon ?? this.icon,
      isClaimed: isClaimed ?? this.isClaimed,
      canClaim: canClaim ?? this.canClaim,
    );
  }
}

/// Model representing a user's claimed reward record (from GET /rewards/me)
class UserRewardClaim {
  final String rewardId;
  final String title;
  final String rewardType;
  final int rewardValue;
  final DateTime? claimedAt;

  const UserRewardClaim({
    required this.rewardId,
    required this.title,
    this.rewardType = 'coins',
    required this.rewardValue,
    this.claimedAt,
  });

  factory UserRewardClaim.fromJson(Map<String, dynamic> json) {
    return UserRewardClaim(
      rewardId: json['rewardId']?.toString() ??
          json['_id']?.toString() ??
          json['id']?.toString() ??
          '',
      title: json['title']?.toString() ?? 'Claimed Reward',
      rewardType: json['rewardType']?.toString() ?? 'coins',
      rewardValue: _parseInt(json['rewardValue'] ?? json['amount'] ?? json['value']),
      claimedAt: _parseDateTime(json['claimedAt'] ?? json['createdAt']),
    );
  }
}

/// Model representing user rewards summary (from GET /rewards/summary)
class RewardsSummary {
  final int totalRewards;
  final int claimedRewards;
  final int availableRewards;
  final int totalCoinsEarned;

  const RewardsSummary({
    this.totalRewards = 0,
    this.claimedRewards = 0,
    this.availableRewards = 0,
    this.totalCoinsEarned = 0,
  });

  factory RewardsSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RewardsSummary();
    return RewardsSummary(
      totalRewards: _parseInt(json['totalRewards']),
      claimedRewards: _parseInt(json['claimedRewards']),
      availableRewards: _parseInt(json['availableRewards']),
      totalCoinsEarned: _parseInt(json['totalCoinsEarned']),
    );
  }
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

bool _parseBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  if (value is num) return value != 0;
  return false;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
