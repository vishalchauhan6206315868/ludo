import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../models/leaderboard_model.dart';
import 'rewards_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  final ApiService? apiService;

  const LeaderboardScreen({
    super.key,
    this.apiService,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
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
      backgroundColor: const Color(0xFF060B1E),
      body: Stack(
        children: [
          // 1. Cosmic 3D Gaming Canvas Background
          Positioned.fill(
            child: CustomPaint(
              painter: _LeaderboardCosmicBackgroundPainter(),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: Column(
              children: [
                // Custom 3D Royal AppBar & Header
                _buildHeader(),

                // Main Leaderboard Content (or Loading / Error / Empty states)
                Expanded(
                  child: _buildBody(),
                ),

                // Sticky Bottom "MY POSITION" Floating Royal Capsule
                if (!_isLoading && _myRanking != null)
                  _buildMyRankingBanner(_myRanking!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Royal 3D Header matching reference design
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 3D Glass Circular Back Button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF0F1E4A)],
                  center: Alignment(-0.3, -0.3),
                ),
                border: Border.all(color: const Color(0xFF00E5FF), width: 1.8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Center Crown + Laurel Wreath + 3D Gold Typography Title
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Crown with Laurel Wreath
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Left Laurel Sprig
                      CustomPaint(
                        size: const Size(18, 14),
                        painter: _LaurelWreathPainter(isLeft: true),
                      ),
                      const SizedBox(width: 4),
                      // Royal 3D Crown Icon
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: Color(0xFFFFD700),
                        size: 22,
                        shadows: [
                          Shadow(color: Color(0xFFFF9900), blurRadius: 12),
                          Shadow(color: Color(0xFFFFEA79), blurRadius: 4),
                        ],
                      ),
                      const SizedBox(width: 4),
                      // Right Laurel Sprig
                      CustomPaint(
                        size: const Size(18, 14),
                        painter: _LaurelWreathPainter(isLeft: false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),

                  // 3D Gold Embossed "LEADERBOARD" Title
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFFFFF9D2),
                        Color(0xFFFFDF00),
                        Color(0xFFFFB300),
                        Color(0xFFFFA000),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds),
                    child: const Text(
                      "LEADERBOARD",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8,
                        fontStyle: FontStyle.italic,
                        shadows: [
                          Shadow(
                            color: Color(0xFF5E3900),
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),

                  // Subtitle: ⭐ Top Players • Win Big • Be the Legend ⭐
                  const Text(
                    "⭐ Top Players • Win Big • Be the Legend ⭐",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFFE082),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Right Action Pills: Rewards Pill + Circular Refresh Button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rewards Pill Button
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RewardsScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C853), Color(0xFF007E33)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF69F0AE), width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E676).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 3),
                      Text(
                        "Rewards",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Refresh Button
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF141F36),
                  border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.6), width: 1.2),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: "Refresh",
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFFD700), size: 18),
                  onPressed: _isLoading ? null : _fetchLeaderboard,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF0F1E4A)],
                ),
                border: Border.all(color: const Color(0xFFFFD700), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                  strokeWidth: 3.5,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Loading Leaderboard...",
              style: TextStyle(
                color: Color(0xFFFFE082),
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A101C), Color(0xFF180812)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFF5252), width: 1.6),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF1744).withValues(alpha: 0.25),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFFF5252), size: 48),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _fetchLeaderboard,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text("Retry"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: const Color(0xFF0D1424),
                    elevation: 6,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
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
            SizedBox(height: 100),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.leaderboard_rounded, color: Colors.white24, size: 68),
                  SizedBox(height: 14),
                  Text(
                    "No leaderboard rankings yet.",
                    style: TextStyle(
                      color: Color(0xFFFFE082),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Play matches to climb the global leaderboard!",
                    style: TextStyle(color: Colors.white60, fontSize: 13),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        itemCount: _leaderboard.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = _leaderboard[index];
          if (item.rank == 1) {
            return _buildRank1Card(item);
          } else if (item.rank == 2) {
            return _buildRank2Card(item);
          } else if (item.rank == 3) {
            return _buildRank3Card(item);
          } else {
            return _buildStandardRankTile(item);
          }
        },
      ),
    );
  }

  /// 🥇 Rank #1 Gold Champion Card
  Widget _buildRank1Card(LeaderboardEntry item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8C5300),
            Color(0xFF5A3500),
            Color(0xFF381F00),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 3D Gold Laurel Shield with #1
          _buildPodiumBadge(rank: 1),
          const SizedBox(width: 8),

          // User Avatar with 24K Gold Ring
          _buildAvatar(item, borderColor: const Color(0xFFFFD700), glowColor: const Color(0xFFFFEA79)),
          const SizedBox(width: 8),

          // Player Name & Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 4),
                      ],
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Wins: ${item.wins} • Matches: ${item.gamesPlayed}",
                    style: const TextStyle(
                      color: Color(0xFFFFF176),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Score Badge: Radiant Gold Star Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A2F00), Color(0xFF281700)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD700), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 16),
                const SizedBox(width: 3),
                Text(
                  "${item.score} pts",
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🥈 Rank #2 Silver Champion Card
  Widget _buildRank2Card(LeaderboardEntry item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D47A1),
            Color(0xFF0A2E6B),
            Color(0xFF061A3D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00E5FF), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B0FF).withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 3D Silver Laurel Shield with #2
          _buildPodiumBadge(rank: 2),
          const SizedBox(width: 8),

          // User Avatar with Cyan / Silver Ring
          _buildAvatar(item, borderColor: const Color(0xFF00E5FF), glowColor: const Color(0xFF80D8FF)),
          const SizedBox(width: 8),

          // Player Name & Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 4),
                      ],
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Wins: ${item.wins} • Matches: ${item.gamesPlayed}",
                    style: const TextStyle(
                      color: Color(0xFF80D8FF),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Score Badge: Electric Blue Star Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF002244), Color(0xFF001224)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD700), width: 1.3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 16),
                const SizedBox(width: 3),
                Text(
                  "${item.score} pts",
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🥉 Rank #3 Bronze Champion Card
  Widget _buildRank3Card(LeaderboardEntry item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7A3500),
            Color(0xFF4E2000),
            Color(0xFF2C1000),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF9100), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6D00).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 3D Bronze Laurel Shield with #3
          _buildPodiumBadge(rank: 3),
          const SizedBox(width: 8),

          // User Avatar with Bronze / Copper Ring
          _buildAvatar(item, borderColor: const Color(0xFFFFAB40), glowColor: const Color(0xFFFFD180)),
          const SizedBox(width: 8),

          // Player Name & Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 4),
                      ],
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Wins: ${item.wins} • Matches: ${item.gamesPlayed}",
                    style: const TextStyle(
                      color: Color(0xFFFFCC80),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Score Badge: Warm Bronze Star Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF381600), Color(0xFF1E0A00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD700), width: 1.3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 16),
                const SizedBox(width: 3),
                Text(
                  "${item.score} pts",
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📜 Standard Leaderboard Row (Rank #4+)
  Widget _buildStandardRankTile(LeaderboardEntry item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1A38).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1E3A8A).withValues(alpha: 0.65),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Rank Badge (#4, #5, #6...)
          SizedBox(
            width: 34,
            child: Text(
              "#${item.rank}",
              style: const TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // User Avatar
          _buildAvatar(item, borderColor: const Color(0xFF00B0FF).withValues(alpha: 0.5)),
          const SizedBox(width: 8),

          // Player Name & Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Wins: ${item.wins} • Matches: ${item.gamesPlayed}",
                    style: const TextStyle(
                      color: Color(0xFF8FA8D0),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Score Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF080F24),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 15),
                const SizedBox(width: 3),
                Text(
                  "${item.score} pts",
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3D Laurel Shield with Rank (1, 2, 3)
  Widget _buildPodiumBadge({required int rank}) {
    Color primaryColor;
    Color secondaryColor;
    Color textColor;

    if (rank == 1) {
      primaryColor = const Color(0xFFFFD700);
      secondaryColor = const Color(0xFFFF8F00);
      textColor = const Color(0xFF3E2700);
    } else if (rank == 2) {
      primaryColor = const Color(0xFFE0E0E0);
      secondaryColor = const Color(0xFF90A4AE);
      textColor = const Color(0xFF0A1931);
    } else {
      primaryColor = const Color(0xFFFFAB40);
      secondaryColor = const Color(0xFFD84315);
      textColor = const Color(0xFF260E04);
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [primaryColor, secondaryColor],
          center: const Alignment(-0.3, -0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Laurel wreath ring
          CustomPaint(
            size: const Size(36, 36),
            painter: _BadgeWreathPainter(color: primaryColor),
          ),
          // Rank text
          Text(
            "$rank",
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              shadows: const [
                Shadow(color: Colors.white70, offset: Offset(0, 1), blurRadius: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Circular Player Avatar with border and glow
  Widget _buildAvatar(LeaderboardEntry item, {required Color borderColor, Color? glowColor}) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF131D38),
        border: Border.all(color: borderColor, width: 1.8),
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: (item.user.avatar.isNotEmpty)
            ? Image.network(
                item.user.avatar,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.person_rounded,
                  color: borderColor,
                  size: 22,
                ),
              )
            : Icon(
                Icons.person_rounded,
                color: borderColor,
                size: 22,
              ),
      ),
    );
  }

  /// Sticky Bottom "MY POSITION" Floating Royal Capsule
  Widget _buildMyRankingBanner(UserRanking myRank) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F1E42), Color(0xFF080F24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD700), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, -2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // My Rank Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFEA79), Color(0xFFFFB300)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Text(
              "Rank #${myRank.rank}",
              style: const TextStyle(
                color: Color(0xFF0A0F1D),
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 8),

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
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Wins: ${myRank.wins} • Losses: ${myRank.losses} • Matches: ${myRank.gamesPlayed}",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${myRank.score}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
              const Text(
                "SCORE",
                style: TextStyle(
                  color: Color(0xFF8FA8D0),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom Painter for 3D Cosmic Championship Gaming Background
class _LeaderboardCosmicBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Deep Space Cosmic Background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF030614),
          Color(0xFF071131),
          Color(0xFF0B1B48),
          Color(0xFF050A20),
        ],
        stops: [0.0, 0.35, 0.7, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // 2. Cosmic Ambient Radial Glows
    final centerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1E3A8A).withValues(alpha: 0.45),
          Colors.transparent,
        ],
        radius: 0.7,
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.5, size.height * 0.15), radius: size.width * 0.6));
    canvas.drawRect(rect, centerGlow);

    // 3. Diagonal Neon Laser Glow Streaks
    final streakPaint = Paint()
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    streakPaint.shader = LinearGradient(
      colors: [
        Colors.transparent,
        const Color(0xFF00E5FF).withValues(alpha: 0.35),
        const Color(0xFF8B5CF6).withValues(alpha: 0.25),
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 0.7, 1.0],
    ).createShader(rect);

    canvas.drawLine(
      Offset(-20, size.height * 0.25),
      Offset(size.width + 50, size.height * 0.55),
      streakPaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.7),
      Offset(size.width * 0.9, size.height * 0.95),
      streakPaint,
    );

    // 4. Draw Ambient Sparkling Stars
    _drawSparkles(canvas, size);

    // 5. Draw Left Side: 3D Golden Trophy
    _drawChampionTrophy(canvas, Offset(24, size.height * 0.22));

    // 6. Draw Left Side: 3D White Dice
    _draw3DDice(canvas, Offset(20, size.height * 0.72), 34);

    // 7. Draw Right Side: 3D Golden Crown
    _draw3DCrown(canvas, Offset(size.width - 24, size.height * 0.65));

    // 8. Draw Floating Gold Coins on Left and Right
    _drawGoldCoin(canvas, Offset(30, size.height * 0.48), 16);
    _drawGoldCoin(canvas, Offset(size.width - 26, size.height * 0.28), 18);
    _drawGoldCoin(canvas, Offset(size.width - 22, size.height * 0.54), 14);
    _drawGoldCoin(canvas, Offset(26, size.height * 0.88), 15);
  }

  void _drawSparkles(Canvas canvas, Size size) {
    final sparklePaint = Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.65);
    final offsets = [
      Offset(size.width * 0.15, size.height * 0.08),
      Offset(size.width * 0.85, size.height * 0.1),
      Offset(size.width * 0.08, size.height * 0.38),
      Offset(size.width * 0.92, size.height * 0.42),
      Offset(size.width * 0.12, size.height * 0.62),
      Offset(size.width * 0.88, size.height * 0.78),
      Offset(size.width * 0.5, size.height * 0.96),
    ];

    for (final pos in offsets) {
      canvas.drawCircle(pos, 2.0, sparklePaint);
      final ray = Paint()
        ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.45)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(pos.dx - 5, pos.dy), Offset(pos.dx + 5, pos.dy), ray);
      canvas.drawLine(Offset(pos.dx, pos.dy - 5), Offset(pos.dx, pos.dy + 5), ray);
    }
  }

  /// 3D Golden Trophy on Left Canvas
  void _drawChampionTrophy(Canvas canvas, Offset center) {
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700).withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 45));
    canvas.drawCircle(center, 45, glow);

    // Cup Body
    final cupPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFEA79), Color(0xFFFFB300), Color(0xFF8C5300)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(center.dx - 18, center.dy - 22, 36, 32));

    final cupPath = Path()
      ..moveTo(center.dx - 18, center.dy - 22)
      ..lineTo(center.dx + 18, center.dy - 22)
      ..lineTo(center.dx + 12, center.dy + 6)
      ..quadraticBezierTo(center.dx, center.dy + 14, center.dx - 12, center.dy + 6)
      ..close();
    canvas.drawPath(cupPath, cupPaint);

    // Trophy Handles
    final handlePaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(center.dx - 17, center.dy - 10), radius: 10),
      math.pi * 0.5,
      math.pi,
      false,
      handlePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(center.dx + 17, center.dy - 10), radius: 10),
      -math.pi * 0.5,
      math.pi,
      false,
      handlePaint,
    );

    // Stem and Base
    final basePaint = Paint()..color = const Color(0xFFFFA000);
    canvas.drawRect(Rect.fromCenter(center: Offset(center.dx, center.dy + 14), width: 8, height: 10), basePaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy + 22), width: 28, height: 8),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFFFD700),
    );
  }

  /// 3D Isometric White Dice
  void _draw3DDice(Canvas canvas, Offset pos, double size) {
    final topFace = Path()
      ..moveTo(pos.dx, pos.dy - size * 0.5)
      ..lineTo(pos.dx + size * 0.5, pos.dy - size * 0.25)
      ..lineTo(pos.dx, pos.dy)
      ..lineTo(pos.dx - size * 0.5, pos.dy - size * 0.25)
      ..close();
    canvas.drawPath(topFace, Paint()..color = const Color(0xFFFFFFFF));

    final leftFace = Path()
      ..moveTo(pos.dx - size * 0.5, pos.dy - size * 0.25)
      ..lineTo(pos.dx, pos.dy)
      ..lineTo(pos.dx, pos.dy + size * 0.5)
      ..lineTo(pos.dx - size * 0.5, pos.dy + size * 0.25)
      ..close();
    canvas.drawPath(leftFace, Paint()..color = const Color(0xFFD6DBDF));

    final rightFace = Path()
      ..moveTo(pos.dx, pos.dy)
      ..lineTo(pos.dx + size * 0.5, pos.dy - size * 0.25)
      ..lineTo(pos.dx + size * 0.5, pos.dy + size * 0.25)
      ..lineTo(pos.dx, pos.dy + size * 0.5)
      ..close();
    canvas.drawPath(rightFace, Paint()..color = const Color(0xFFAEB6BF));

    // Pip on top
    canvas.drawCircle(Offset(pos.dx, pos.dy - size * 0.25), 2.5, Paint()..color = const Color(0xFF1A237E));
    // Pips on left
    canvas.drawCircle(Offset(pos.dx - size * 0.25, pos.dy + size * 0.05), 2.2, Paint()..color = const Color(0xFF1A237E));
    canvas.drawCircle(Offset(pos.dx - size * 0.25, pos.dy + size * 0.25), 2.2, Paint()..color = const Color(0xFF1A237E));
  }

  /// 3D Golden Crown on Right Canvas
  void _draw3DCrown(Canvas canvas, Offset center) {
    final crownGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFB300).withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 35));
    canvas.drawCircle(center, 35, crownGlow);

    final crownPath = Path()
      ..moveTo(center.dx - 18, center.dy + 12)
      ..lineTo(center.dx + 18, center.dy + 12)
      ..lineTo(center.dx + 20, center.dy - 10)
      ..lineTo(center.dx + 10, center.dy)
      ..lineTo(center.dx, center.dy - 16)
      ..lineTo(center.dx - 10, center.dy)
      ..lineTo(center.dx - 20, center.dy - 10)
      ..close();

    final crownPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFEA79), Color(0xFFFFB300), Color(0xFFFF8F00)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: 20));
    canvas.drawPath(crownPath, crownPaint);

    // Crown jewels
    final jewelPaint = Paint()..color = const Color(0xFFFF1744);
    canvas.drawCircle(Offset(center.dx, center.dy - 16), 2.5, jewelPaint);
    canvas.drawCircle(Offset(center.dx - 20, center.dy - 10), 2.0, jewelPaint);
    canvas.drawCircle(Offset(center.dx + 20, center.dy - 10), 2.0, jewelPaint);
  }

  /// 3D Shiny Gold Coin
  void _drawGoldCoin(Canvas canvas, Offset center, double radius) {
    // Outer Coin Rim
    final rimPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFEA79), Color(0xFFFFB300), Color(0xFF8C5300)],
        center: Alignment(-0.3, -0.3),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, rimPaint);

    // Inner Coin Plate
    final innerPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFDF00), Color(0xFFFF8F00)],
        center: Alignment(0.2, 0.2),
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.75));
    canvas.drawCircle(center, radius * 0.75, innerPaint);

    // Specular Highlight
    final star = Paint()..color = const Color(0xFFFFF9C4).withValues(alpha: 0.8);
    canvas.drawCircle(Offset(center.dx - radius * 0.3, center.dy - radius * 0.3), radius * 0.2, star);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Header Laurel Wreath Painter
class _LaurelWreathPainter extends CustomPainter {
  final bool isLeft;

  _LaurelWreathPainter({required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFEA79), Color(0xFFFFB300), Color(0xFFFF8F00)],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    canvas.save();
    if (!isLeft) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    // Draw 3 Laurel Leaves
    final leaf1 = Path()
      ..moveTo(2, 14)
      ..quadraticBezierTo(8, 6, 18, 4)
      ..quadraticBezierTo(12, 12, 2, 14);
    canvas.drawPath(leaf1, paint);

    final leaf2 = Path()
      ..moveTo(4, 16)
      ..quadraticBezierTo(12, 12, 20, 11)
      ..quadraticBezierTo(12, 17, 4, 16);
    canvas.drawPath(leaf2, paint);

    final leaf3 = Path()
      ..moveTo(6, 17)
      ..quadraticBezierTo(14, 16, 21, 17)
      ..quadraticBezierTo(13, 19, 6, 17);
    canvas.drawPath(leaf3, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Circular Badge Laurel Wreath Painter
class _BadgeWreathPainter extends CustomPainter {
  final Color color;

  _BadgeWreathPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2 - 3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
