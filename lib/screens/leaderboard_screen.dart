import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../models/leaderboard_model.dart';

class LeaderboardScreen extends StatefulWidget {
  final ApiService? apiService;

  const LeaderboardScreen({
    super.key,
    this.apiService,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late final ApiService _apiService;

  bool _isLoading = true;
  String? _errorMessage;
  List<LeaderboardEntry> _leaderboard = [];
  UserRanking? _myRanking;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch Global Leaderboard
      final lbRes = await _apiService.getLeaderboard();

      // 2. Fetch Logged-in User Ranking
      final meRes = await _apiService.getMyLeaderboard();

      if (!mounted) return;

      if (lbRes['success'] == true) {
        final data = lbRes['data'];
        List<LeaderboardEntry> entries = [];
        if (data is Map<String, dynamic> && data['data'] != null && data['data'] is Map<String, dynamic>) {
          final innerData = data['data'] as Map<String, dynamic>;
          if (innerData['leaderboard'] is List) {
            entries = (innerData['leaderboard'] as List)
                .whereType<Map<String, dynamic>>()
                .map((e) => LeaderboardEntry.fromJson(e))
                .toList();
          }
          if (innerData['currentUser'] is Map<String, dynamic> && _myRanking == null) {
            _myRanking = UserRanking.fromJson(innerData['currentUser'] as Map<String, dynamic>);
          }
        } else if (data is Map<String, dynamic> && data['leaderboard'] is List) {
          entries = (data['leaderboard'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => LeaderboardEntry.fromJson(e))
              .toList();
          if (data['currentUser'] is Map<String, dynamic> && _myRanking == null) {
            _myRanking = UserRanking.fromJson(data['currentUser'] as Map<String, dynamic>);
          }
        }

        // Parse explicit /leaderboard/me response if available
        if (meRes['success'] == true && meRes['data'] != null) {
          final meData = meRes['data'];
          if (meData is Map<String, dynamic> && meData['data'] is Map<String, dynamic>) {
            _myRanking = UserRanking.fromJson(meData['data'] as Map<String, dynamic>);
          } else if (meData is Map<String, dynamic>) {
            _myRanking = UserRanking.fromJson(meData);
          }
        }

        setState(() {
          _leaderboard = entries;
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        final statusCode = lbRes['statusCode'];
        String msg = lbRes['message']?.toString() ?? 'Failed to load leaderboard';
        if (statusCode == 401) {
          msg = 'Session expired or unauthorized. Please log in again.';
        } else if (statusCode == 0) {
          msg = 'Unable to reach backend server. Please verify your connection.';
        }

        setState(() {
          _isLoading = false;
          _errorMessage = msg;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1424),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141F36),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 22),
            SizedBox(width: 8),
            Text(
              "LEADERBOARD",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Refresh",
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFFD700), size: 22),
            onPressed: _isLoading ? null : _fetchLeaderboard,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Main content area
            Expanded(
              child: _buildBody(),
            ),

            // Sticky Current User Ranking Banner at bottom
            if (!_isLoading && _myRanking != null) _buildMyRankingBanner(_myRanking!),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              "Loading Leaderboard...",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _fetchLeaderboard,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: const Color(0xFF0D1424),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_leaderboard.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchLeaderboard,
        color: const Color(0xFFFFD700),
        backgroundColor: const Color(0xFF141F36),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: const [
            SizedBox(height: 120),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.leaderboard_rounded, color: Colors.white24, size: 64),
                  SizedBox(height: 12),
                  Text(
                    "No leaderboard rankings yet.",
                    style: TextStyle(color: Colors.white60, fontSize: 15),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Play matches to climb the global leaderboard!",
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchLeaderboard,
      color: const Color(0xFFFFD700),
      backgroundColor: const Color(0xFF141F36),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        itemCount: _leaderboard.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = _leaderboard[index];
          return _buildLeaderboardTile(item);
        },
      ),
    );
  }

  Widget _buildLeaderboardTile(LeaderboardEntry item) {
    Color rankColor;
    Color? badgeColor;

    if (item.rank == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
      badgeColor = const Color(0xFFFFD700).withValues(alpha: 0.15);
    } else if (item.rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
      badgeColor = const Color(0xFFC0C0C0).withValues(alpha: 0.15);
    } else if (item.rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
      badgeColor = const Color(0xFFCD7F32).withValues(alpha: 0.15);
    } else {
      rankColor = const Color(0xFF90A4AE);
      badgeColor = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: badgeColor ?? const Color(0xFF141F36),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.rank <= 3 ? rankColor.withValues(alpha: 0.5) : Colors.white10,
          width: item.rank <= 3 ? 1.4 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Rank Badge
          SizedBox(
            width: 38,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.rank <= 3)
                  Icon(Icons.military_tech_rounded, color: rankColor, size: 20)
                else
                  Text(
                    "#${item.rank}",
                    style: TextStyle(
                      color: rankColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // User Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E293B),
              border: Border.all(color: rankColor.withValues(alpha: 0.5), width: 1.5),
            ),
            child: (item.user.avatar.isNotEmpty)
                ? ClipOval(
                    child: Image.network(
                      item.user.avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.person,
                        color: rankColor,
                        size: 22,
                      ),
                    ),
                  )
                : Icon(
                    Icons.person,
                    color: rankColor,
                    size: 22,
                  ),
          ),
          const SizedBox(width: 12),

          // Player Name & Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "Wins: ${item.wins} • Matches: ${item.gamesPlayed}",
                  style: const TextStyle(
                    color: Color(0xFF90A4AE),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Score Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 16),
                const SizedBox(width: 4),
                Text(
                  "${item.score} pts",
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRankingBanner(UserRanking myRank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16233B),
        border: const Border(
          top: BorderSide(color: Color(0xFFFFD700), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // My Rank Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "Rank #${myRank.rank}",
              style: const TextStyle(
                color: Color(0xFF0D1424),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // My Statistics
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "MY POSITION",
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Wins: ${myRank.wins} • Losses: ${myRank.losses} • Matches: ${myRank.gamesPlayed}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${myRank.score}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text(
                "SCORE",
                style: TextStyle(
                  color: Color(0xFF90A4AE),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
