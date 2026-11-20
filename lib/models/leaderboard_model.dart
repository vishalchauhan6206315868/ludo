/// Player information attached to leaderboard ranking
class LeaderboardUser {
  final String id;
  final String name;
  final String avatar;

  const LeaderboardUser({
    required this.id,
    required this.name,
    this.avatar = '',
  });

  factory LeaderboardUser.fromJson(dynamic json) {
    if (json == null || json is! Map) {
      return const LeaderboardUser(id: '', name: 'Player');
    }
    return LeaderboardUser(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Player',
      avatar: json['avatar']?.toString() ?? '',
    );
  }
}

/// Single ranked player in the global leaderboard
class LeaderboardEntry {
  final int rank;
  final LeaderboardUser user;
  final int score;
  final int wins;
  final int gamesPlayed;

  const LeaderboardEntry({
    required this.rank,
    required this.user,
    required this.score,
    required this.wins,
    required this.gamesPlayed,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: _parseInt(json['rank']),
      user: LeaderboardUser.fromJson(json['user']),
      score: _parseInt(json['score']),
      wins: _parseInt(json['wins']),
      gamesPlayed: _parseInt(json['gamesPlayed']),
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

/// Current authenticated user's ranking details
class UserRanking {
  final int rank;
  final int score;
  final int wins;
  final int losses;
  final int gamesPlayed;

  const UserRanking({
    required this.rank,
    required this.score,
    required this.wins,
    this.losses = 0,
    required this.gamesPlayed,
  });

  factory UserRanking.fromJson(Map<String, dynamic> json) {
    return UserRanking(
      rank: _parseInt(json['rank']),
      score: _parseInt(json['score']),
      wins: _parseInt(json['wins']),
      losses: _parseInt(json['losses']),
      gamesPlayed: _parseInt(json['gamesPlayed']),
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
