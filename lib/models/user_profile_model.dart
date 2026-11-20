import 'dart:convert';

/// Statistics for user game matches
class UserStatistics {
  final int totalGames;
  final int wins;
  final int losses;
  final int draws;

  const UserStatistics({
    this.totalGames = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
  });

  double get winRate {
    if (totalGames == 0) return 0.0;
    return (wins / totalGames) * 100;
  }

  factory UserStatistics.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserStatistics();
    return UserStatistics(
      totalGames: _parseInt(json['totalGames']),
      wins: _parseInt(json['wins']),
      losses: _parseInt(json['losses']),
      draws: _parseInt(json['draws']),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalGames': totalGames,
        'wins': wins,
        'losses': losses,
        'draws': draws,
      };

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

/// User Profile Model corresponding to `/api/users/me`
class UserProfileModel {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final String role;
  final bool isVerified;
  final int coins;
  final int gems;
  final int experience;
  final int level;
  final UserStatistics statistics;
  final DateTime? createdAt;

  const UserProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar = '',
    this.role = 'user',
    this.isVerified = false,
    this.coins = 0,
    this.gems = 0,
    this.experience = 0,
    this.level = 1,
    this.statistics = const UserStatistics(),
    this.createdAt,
  });

  /// Factory constructor to parse directly from the backend JSON response
  /// Handles both direct user object and { "data": { "user": { ... } } } structures
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> userMap = json;

    // If wrapped in "data" or "user"
    if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      final inner = json['data'] as Map<String, dynamic>;
      if (inner.containsKey('user') && inner['user'] is Map<String, dynamic>) {
        userMap = inner['user'] as Map<String, dynamic>;
      } else {
        userMap = inner;
      }
    } else if (json.containsKey('user') && json['user'] is Map<String, dynamic>) {
      userMap = json['user'] as Map<String, dynamic>;
    }

    return UserProfileModel(
      id: userMap['id']?.toString() ?? userMap['_id']?.toString() ?? '',
      name: userMap['name']?.toString() ?? userMap['username']?.toString() ?? 'Player',
      email: userMap['email']?.toString() ?? '',
      avatar: userMap['avatar']?.toString() ?? '',
      role: userMap['role']?.toString() ?? 'user',
      isVerified: userMap['isVerified'] == true,
      coins: _parseInt(userMap['coins']),
      gems: _parseInt(userMap['gems']),
      experience: _parseInt(userMap['experience']),
      level: _parseInt(userMap['level'], defaultValue: 1),
      statistics: UserStatistics.fromJson(userMap['statistics'] as Map<String, dynamic>?),
      createdAt: userMap['createdAt'] != null
          ? DateTime.tryParse(userMap['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatar': avatar,
        'role': role,
        'isVerified': isVerified,
        'coins': coins,
        'gems': gems,
        'experience': experience,
        'level': level,
        'statistics': statistics.toJson(),
        'createdAt': createdAt?.toIso8601String(),
      };

  String toRawJson() => jsonEncode(toJson());

  factory UserProfileModel.fromRawJson(String str) =>
      UserProfileModel.fromJson(jsonDecode(str) as Map<String, dynamic>);

  UserProfileModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    String? role,
    bool? isVerified,
    int? coins,
    int? gems,
    int? experience,
    int? level,
    UserStatistics? statistics,
    DateTime? createdAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      experience: experience ?? this.experience,
      level: level ?? this.level,
      statistics: statistics ?? this.statistics,
      createdAt: createdAt ?? this.createdAt,
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
