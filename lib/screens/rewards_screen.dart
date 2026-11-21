import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/network/api_service.dart';
import '../models/reward_model.dart';

class RewardsScreen extends StatefulWidget {
  final ApiService? apiService;
  final VoidCallback? onRewardClaimed;

  const RewardsScreen({
    super.key,
    this.apiService,
    this.onRewardClaimed,
  });

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  late final ApiService _apiService;

  bool _isLoading = true;
  String? _errorMessage;
  String? _claimingRewardId;

  List<RewardItem> _availableRewards = [];
  List<UserRewardClaim> _myRewards = [];
  RewardsSummary _summary = const RewardsSummary();

  int _selectedTabIndex = 0; // 0: Available Rewards, 1: My Rewards

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _fetchRewardsData();
  }

  /// Concurrently fetch Available Rewards, My Claimed Rewards, and Summary
  Future<void> _fetchRewardsData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getRewards(),
        _apiService.getMyRewards(),
        _apiService.getRewardsSummary(),
      ]);

      if (!mounted) return;

      final rewardsRes = results[0];
      final myRewardsRes = results[1];
      final summaryRes = results[2];

      if (rewardsRes['success'] == true) {
        // 1. Parse Available / All Rewards
        List<RewardItem> rewardsList = [];
        final rData = rewardsRes['data'];
        if (rData is Map<String, dynamic> && rData['rewards'] is List) {
          rewardsList = (rData['rewards'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => RewardItem.fromJson(e))
              .toList();
        } else if (rData is Map<String, dynamic> &&
            rData['data'] is Map<String, dynamic> &&
            rData['data']['rewards'] is List) {
          rewardsList = (rData['data']['rewards'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => RewardItem.fromJson(e))
              .toList();
        } else if (rData is List) {
          rewardsList = rData
              .whereType<Map<String, dynamic>>()
              .map((e) => RewardItem.fromJson(e))
              .toList();
        }

        // 2. Parse My Rewards (Claim History)
        List<UserRewardClaim> myClaimList = [];
        if (myRewardsRes['success'] == true && myRewardsRes['data'] != null) {
          final mData = myRewardsRes['data'];
          if (mData is Map<String, dynamic> && mData['rewards'] is List) {
            myClaimList = (mData['rewards'] as List)
                .whereType<Map<String, dynamic>>()
                .map((e) => UserRewardClaim.fromJson(e))
                .toList();
          } else if (mData is Map<String, dynamic> &&
              mData['data'] is Map<String, dynamic> &&
              mData['data']['rewards'] is List) {
            myClaimList = (mData['data']['rewards'] as List)
                .whereType<Map<String, dynamic>>()
                .map((e) => UserRewardClaim.fromJson(e))
                .toList();
          } else if (mData is List) {
            myClaimList = mData
                .whereType<Map<String, dynamic>>()
                .map((e) => UserRewardClaim.fromJson(e))
                .toList();
          }
        }

        // 3. Parse Rewards Summary
        RewardsSummary summaryObj = const RewardsSummary();
        if (summaryRes['success'] == true && summaryRes['data'] != null) {
          final sData = summaryRes['data'];
          if (sData is Map<String, dynamic> && sData['data'] is Map<String, dynamic>) {
            summaryObj = RewardsSummary.fromJson(sData['data'] as Map<String, dynamic>);
          } else if (sData is Map<String, dynamic>) {
            summaryObj = RewardsSummary.fromJson(sData);
          }
        }

        setState(() {
          _availableRewards = rewardsList;
          _myRewards = myClaimList;
          _summary = summaryObj;
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        final statusCode = rewardsRes['statusCode'];
        String msg = rewardsRes['message']?.toString() ?? 'Failed to load rewards';
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

  /// Claim a specific reward
  Future<void> _claimReward(RewardItem reward) async {
    if (_claimingRewardId != null) return; // Prevent concurrent claims

    setState(() {
      _claimingRewardId = reward.id;
    });

    try {
      final res = await _apiService.claimReward(reward.id);

      if (!mounted) return;

      if (res['success'] == true) {
        try {
          HapticFeedback.mediumImpact();
        } catch (_) {}

        // 1. Success feedback snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Claimed ${reward.title}! +${reward.rewardValue} Coins added to wallet.",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E3A8A),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFFFD700), width: 1.2),
            ),
          ),
        );

        // 2. Optimistically update local reward status
        setState(() {
          final idx = _availableRewards.indexWhere((r) => r.id == reward.id);
          if (idx != -1) {
            _availableRewards[idx] = reward.copyWith(
              isClaimed: true,
              canClaim: false,
            );
          }
        });

        // 3. Notify parent callback to update home coin balance
        widget.onRewardClaimed?.call();

        // 4. Refresh full rewards data in background (summary, my rewards list)
        _fetchRewardsData();
      } else {
        final errorMsg = res['message']?.toString() ?? 'Failed to claim reward';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFF87171), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    errorMsg,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF7F1D1D),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: const Color(0xFF7F1D1D),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _claimingRewardId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03091E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1938),
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0C2456),
              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.6), width: 1.2),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFFFEE58), Color(0xFFFFB300), Color(0xFFFF8F00)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFF221500), size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              "REWARDS & BONUSES",
              style: TextStyle(
                fontFamily: 'Roboto',
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.w900,
                fontSize: 16.5,
                letterSpacing: 1.1,
                fontStyle: FontStyle.italic,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0C2456),
                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.6), width: 1.2),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: "Refresh",
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFFD700), size: 20),
                onPressed: _isLoading ? null : _fetchRewardsData,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Layer 1: 3D Cosmic Background (3D Dice, Floating Coins, Pedestal, Gift Box)
          const Positioned.fill(
            child: CustomPaint(
              painter: _RewardsCosmicBackgroundPainter(),
            ),
          ),

          // Layer 2: Main Content Area
          SafeArea(
            child: Column(
              children: [
                // Top Summary Metric Capsule Bar
                if (!_isLoading && _errorMessage == null) _buildSummaryHeader(),

                // Dual 3D Tab Switcher: Available Rewards vs My History
                if (!_isLoading && _errorMessage == null) _buildCustomTabBar(),

                // Body List View
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. Summary Metric Capsule Bar ---
  Widget _buildSummaryHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0C2456), // Electric royal blue
            Color(0xFF071738), // Dark navy
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00B0FF).withValues(alpha: 0.75),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B0FF).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _buildStatItem(
                icon: Icons.calendar_today_rounded,
                badgeColor: const Color(0xFFFFD54F),
                label: "Available",
                value: "${_summary.availableRewards}",
              ),
            ),
          ),
          Container(width: 1.2, height: 32, color: Colors.white24),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _buildStatItem(
                icon: Icons.check_circle_rounded,
                badgeColor: const Color(0xFF00E676),
                label: "Claimed",
                value: "${_summary.claimedRewards}",
              ),
            ),
          ),
          Container(width: 1.2, height: 32, color: Colors.white24),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _buildStatItem(
                icon: Icons.monetization_on_rounded,
                badgeColor: const Color(0xFFFFD700),
                label: "Coins Earned",
                value: "${_summary.totalCoinsEarned}",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color badgeColor,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: badgeColor, width: 1.0),
              ),
              child: Icon(icon, color: badgeColor, size: 14),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF90A4AE),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // --- 2. Dual 3D Tab Switcher: Available Rewards vs My History ---
  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF071434).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00B0FF).withValues(alpha: 0.4), width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              index: 0,
              label: "Available Rewards (${_availableRewards.length})",
              icon: Icons.card_giftcard_rounded,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTabButton(
              index: 1,
              label: "My History (${_myRewards.length})",
              icon: Icons.history_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(0xFFFFEE58),
                    Color(0xFFFFB300),
                    Color(0xFFFF8F00),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: const Color(0xFFFFF9C4), width: 1.1) : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? const Color(0xFF091428) : const Color(0xFF90A4AE),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF091428) : Colors.white70,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 3. Main Content Body ---
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
              "Loading Rewards...",
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
                onPressed: _fetchRewardsData,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: const Color(0xFF0D1424),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedTabIndex == 0) {
      return _buildAvailableRewardsList();
    } else {
      return _buildMyRewardsHistoryList();
    }
  }

  // --- 4. Available Rewards List ---
  Widget _buildAvailableRewardsList() {
    if (_availableRewards.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchRewardsData,
        color: const Color(0xFFFFD700),
        backgroundColor: const Color(0xFF141F36),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: const [
            SizedBox(height: 100),
            Center(
              child: Column(
                children: [
                  Icon(Icons.card_giftcard_rounded, color: Colors.white24, size: 64),
                  SizedBox(height: 14),
                  Text(
                    "No rewards available right now.",
                    style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Check back soon for new bonus events!",
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRewardsData,
      color: const Color(0xFFFFD700),
      backgroundColor: const Color(0xFF141F36),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _availableRewards.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final reward = _availableRewards[index];
          return _buildRewardCard(reward);
        },
      ),
    );
  }

  Widget _buildRewardCard(RewardItem reward) {
    final isClaimingThis = _claimingRewardId == reward.id;
    final isClaimed = reward.isClaimed;
    final canClaim = reward.canClaim && !isClaimed;

    // Glowing Golden Card for ready-to-claim reward (matching Master Player reference)
    final isSpecialHighlight = canClaim;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: isSpecialHighlight
            ? const LinearGradient(
                colors: [
                  Color(0xFF2E1C00), // Rich amber gold
                  Color(0xFF181002),
                  Color(0xFF0C2456),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [
                  Color(0xFF0C2456), // Electric royal blue
                  Color(0xFF071738), // Dark navy
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSpecialHighlight
              ? const Color(0xFFFFD700)
              : const Color(0xFF00B0FF).withValues(alpha: 0.65),
          width: isSpecialHighlight ? 1.8 : 1.2,
        ),
        boxShadow: [
          if (isSpecialHighlight)
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.40),
              blurRadius: 14,
              spreadRadius: 0.5,
              offset: const Offset(0, 3),
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Themed Icon Container (Crowned for Master, Calendar for Login/Streak, People for Community, etc.)
          _buildThemedRewardIcon(reward, isSpecialHighlight, isClaimed),
          const SizedBox(width: 12),

          // Title & Description & Coin Pill
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    reward.title,
                    style: TextStyle(
                      color: isClaimed ? const Color(0xFFECEFF1) : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (reward.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    reward.description,
                    style: TextStyle(
                      color: isSpecialHighlight ? const Color(0xFFFFE082) : const Color(0xFF90A4AE),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 5),

                // Golden Coin Amount Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0x33FFB300), Color(0x1AFF8F00)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD700), size: 13),
                      const SizedBox(width: 4),
                      Text(
                        "+${reward.rewardValue} Coins",
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Action Button: 3D Glossy "CLAIM" vs "CLAIMED" Badge
          if (isClaimed) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF00E676),
                    Color(0xFF00C853),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFB9F6CA), width: 1.1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E676).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    "CLAIMED",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: (canClaim && !isClaimingThis) ? () => _claimReward(reward) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF091428),
                disabledBackgroundColor: const Color(0xFF1E2D4A),
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: canClaim ? const Color(0xFFFFF9C4) : Colors.white12,
                    width: 1.2,
                  ),
                ),
                elevation: canClaim ? 4 : 0,
                shadowColor: const Color(0xFFFFB300).withValues(alpha: 0.6),
              ),
              child: isClaimingThis
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF091428)),
                      ),
                    )
                  : const Text(
                      "CLAIM",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, letterSpacing: 0.4),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThemedRewardIcon(RewardItem reward, bool isSpecial, bool isClaimed) {
    final iconKey = reward.icon.toLowerCase();
    final isMaster = isSpecial || iconKey == 'master_player' || reward.id.contains('master');

    if (isMaster) {
      // 3D Crown on Red Velvet Cushion for Master Player
      return Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFF880E4F), Color(0xFF310018)],
          ),
          border: Border.all(color: const Color(0xFFFFD700), width: 1.6),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.5),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 26),
        ),
      );
    }

    if (iconKey.contains('login') || iconKey.contains('streak')) {
      // Calendar with Star
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
          ),
          border: Border.all(color: const Color(0xFFFFCDD2), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE53935).withValues(alpha: 0.35),
              blurRadius: 6,
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.calendar_month_rounded, color: Colors.white, size: 22),
        ),
      );
    }

    if (iconKey.contains('community')) {
      // Community colorful avatars
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFF0091EA)],
          ),
          border: Border.all(color: const Color(0xFFE0F7FA), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
              blurRadius: 6,
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.groups_rounded, color: Colors.white, size: 22),
        ),
      );
    }

    if (iconKey.contains('referral') || iconKey.contains('share')) {
      // Share icon
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF00B0FF), Color(0xFF0277BD)],
          ),
          border: Border.all(color: const Color(0xFF80D8FF), width: 1.2),
        ),
        child: const Center(
          child: Icon(Icons.share_rounded, color: Colors.white, size: 20),
        ),
      );
    }

    if (iconKey.contains('weekend') || iconKey.contains('rush')) {
      // Lightning bolt in purple
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFAB47BC), Color(0xFF6A1B9A)],
          ),
          border: Border.all(color: const Color(0xFFE1BEE7), width: 1.2),
        ),
        child: const Center(
          child: Icon(Icons.bolt_rounded, color: Color(0xFFFFEE58), size: 24),
        ),
      );
    }

    // Default gift medallion
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFD700).withValues(alpha: 0.15),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.6), width: 1.2),
      ),
      child: const Center(
        child: Icon(Icons.card_giftcard_rounded, color: Color(0xFFFFD700), size: 22),
      ),
    );
  }

  // --- 5. My Rewards History List ---
  Widget _buildMyRewardsHistoryList() {
    if (_myRewards.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchRewardsData,
        color: const Color(0xFFFFD700),
        backgroundColor: const Color(0xFF141F36),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: const [
            SizedBox(height: 100),
            Center(
              child: Column(
                children: [
                  Icon(Icons.history_rounded, color: Colors.white24, size: 64),
                  SizedBox(height: 14),
                  Text(
                    "No rewards claimed yet.",
                    style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Switch to Available Rewards to claim your first bonus!",
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRewardsData,
      color: const Color(0xFFFFD700),
      backgroundColor: const Color(0xFF141F36),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _myRewards.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final claim = _myRewards[index];
          return _buildHistoryCard(claim);
        },
      ),
    );
  }

  Widget _buildHistoryCard(UserRewardClaim claim) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0C2456),
            Color(0xFF071738),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF00B0FF).withValues(alpha: 0.6), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00E676).withValues(alpha: 0.15),
              border: Border.all(color: const Color(0xFF00E676), width: 1.3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E676).withValues(alpha: 0.3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  claim.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  claim.claimedAt != null ? _formatDateTime(claim.claimedAt!) : "Claimed",
                  style: const TextStyle(
                    color: Color(0xFF8FA8CE),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0x33FFB300), Color(0x1AFF8F00)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.8), width: 1.1),
            ),
            child: Text(
              "+${claim.rewardValue} Coins",
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.w900,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    final m = months[local.month - 1];
    final d = local.day;
    final y = local.year;
    final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final ampm = local.hour >= 12 ? "PM" : "AM";
    final min = local.minute.toString().padLeft(2, '0');
    return "$m $d, $y • $hour:$min $ampm";
  }
}

// ============================================================================
// 3D CUSTOM PAINTER FOR REWARDS & BONUSES BACKGROUND
// ============================================================================

/// 3D Cosmic Background Painter: 3D Dice, Floating Coins, Pedestal, Gift Box
class _RewardsCosmicBackgroundPainter extends CustomPainter {
  const _RewardsCosmicBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── 1. Cosmic Deep Space Gradient ─────────────────────────────────
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.3),
        radius: 1.25,
        colors: const [
          Color(0xFF0E2868), // Radiant royal blue
          Color(0xFF081844),
          Color(0xFF040D26), // Midnight abyss
          Color(0xFF020614),
        ],
        stops: const [0.0, 0.40, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Diagonal Radiant Cyan Light Streaks
    final streakPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x0000E5FF),
          Color(0x2200E5FF),
          Color(0x4400E5FF),
          Color(0x0000E5FF),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, h * 0.3), Offset(w, h * 0.6), streakPaint);
    canvas.drawLine(Offset(0, h * 0.5), Offset(w, h * 0.8), streakPaint);

    // ── 2. Top Left: 3D White Ludo Dice with Blue Pips & Floating Coins
    final dice1X = w * 0.12;
    final dice1Y = h * 0.09;
    final diceSize = 32.0;

    void draw3dDice(double x, double y, double size, {required bool bluePips}) {
      final half = size / 2;

      // Shadow
      final shadowPath = Path()
        ..moveTo(x - half * 1.1, y + half * 1.2)
        ..lineTo(x + half * 1.2, y + half * 1.2)
        ..lineTo(x + half * 1.5, y + half * 0.5)
        ..lineTo(x - half * 0.8, y + half * 0.5)
        ..close();
      canvas.drawPath(
        shadowPath,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // Top Face
      final topPath = Path()
        ..moveTo(x, y - half * 0.85)
        ..lineTo(x + half * 0.9, y - half * 0.3)
        ..lineTo(x, y + half * 0.25)
        ..lineTo(x - half * 0.9, y - half * 0.3)
        ..close();
      canvas.drawPath(
        topPath,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFECEFF1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(x - half, y - half, size, size)),
      );

      // Left Face
      final leftPath = Path()
        ..moveTo(x - half * 0.9, y - half * 0.3)
        ..lineTo(x, y + half * 0.25)
        ..lineTo(x, y + half * 1.05)
        ..lineTo(x - half * 0.9, y + half * 0.5)
        ..close();
      canvas.drawPath(
        leftPath,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFCFD8DC), Color(0xFF90A4AE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(x - half, y, half, half)),
      );

      // Right Face
      final rightPath = Path()
        ..moveTo(x, y + half * 0.25)
        ..lineTo(x + half * 0.9, y - half * 0.3)
        ..lineTo(x + half * 0.9, y + half * 0.5)
        ..lineTo(x, y + half * 1.05)
        ..close();
      canvas.drawPath(
        rightPath,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFB0BEC5), Color(0xFF78909C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(x, y, half, half)),
      );

      // Edges Stroke
      final edgePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.7)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(topPath, edgePaint);
      canvas.drawPath(leftPath, edgePaint);
      canvas.drawPath(rightPath, edgePaint);

      // Pips Color
      final pipPaint = Paint()..color = bluePips ? const Color(0xFF0D47A1) : const Color(0xFF1E293B);
      // Top face pip (center)
      canvas.drawCircle(Offset(x, y - half * 0.3), 2.2, pipPaint);
      // Left face pips (2 pips)
      canvas.drawCircle(Offset(x - half * 0.5, y + half * 0.05), 1.8, pipPaint);
      canvas.drawCircle(Offset(x - half * 0.35, y + half * 0.65), 1.8, pipPaint);
      // Right face pips (3 pips)
      canvas.drawCircle(Offset(x + half * 0.35, y + half * 0.05), 1.8, pipPaint);
      canvas.drawCircle(Offset(x + half * 0.45, y + half * 0.38), 1.8, pipPaint);
      canvas.drawCircle(Offset(x + half * 0.55, y + half * 0.70), 1.8, pipPaint);
    }

    draw3dDice(dice1X, dice1Y, diceSize, bluePips: true);

    void drawCoin(double x, double y, double r, [double tilt = 0.65]) {
      final coinRect = Rect.fromCenter(center: Offset(x, y), width: r * 2, height: r * 2 * tilt);
      final coinGrad = const LinearGradient(
        colors: [Color(0xFFFFF9C4), Color(0xFFFFD54F), Color(0xFFFF8F00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(coinRect);
      canvas.drawOval(coinRect, Paint()..shader = coinGrad);
      canvas.drawOval(
        coinRect,
        Paint()
          ..color = const Color(0xFFFFFDE7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    drawCoin(dice1X + 22, dice1Y + 20, 8.5, 0.6);
    drawCoin(dice1X - 14, dice1Y + 28, 7.5, 0.55);

    // ── 3. Top Right: 3D Golden Gift Box with Red Ribbon ──────────────
    final giftX = w * 0.88;
    final giftY = h * 0.12;

    void draw3dGift(double x, double y) {
      // Box body
      final boxRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y + 6), width: 34, height: 26),
        const Radius.circular(5),
      );
      final boxPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFEE58), Color(0xFFFFB300), Color(0xFFFF8F00)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(boxRect.outerRect);
      canvas.drawRRect(boxRect, boxPaint);

      // Red vertical ribbon
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y + 6), width: 6, height: 26),
        Paint()..color = const Color(0xFFD50000),
      );
      // Red horizontal ribbon
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y + 6), width: 34, height: 6),
        Paint()..color = const Color(0xFFD50000),
      );

      // Ribbon Bow on top
      final bowPaint = Paint()..color = const Color(0xFFFF1744);
      canvas.drawOval(Rect.fromCenter(center: Offset(x - 6, y - 8), width: 12, height: 8), bowPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(x + 6, y - 8), width: 12, height: 8), bowPaint);
      canvas.drawCircle(Offset(x, y - 8), 3.5, Paint()..color = const Color(0xFFD50000));
    }

    draw3dGift(giftX, giftY);
    drawCoin(giftX - 22, giftY + 22, 9.0, 0.7);
    drawCoin(giftX + 10, giftY + 28, 8.0, 0.6);

    // ── 4. Bottom Center: 3D Dice on Glowing Neon Platform (Pedestal) ─
    final platX = w * 0.5;
    final platY = h * 0.94;

    // Outer Neon Glow Rings
    final platGlow = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(Rect.fromCenter(center: Offset(platX, platY + 12), width: 140, height: 42), platGlow);

    final magentaGlow = Paint()
      ..color = const Color(0xFFE040FB).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(Rect.fromCenter(center: Offset(platX, platY + 12), width: 110, height: 32), magentaGlow);

    // Concentric Neon Rings
    canvas.drawOval(
      Rect.fromCenter(center: Offset(platX, platY + 12), width: 120, height: 36),
      Paint()
        ..color = const Color(0xFF00E5FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(platX, platY + 12), width: 90, height: 26),
      Paint()
        ..color = const Color(0xFFE040FB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 3D White Dice on the Platform
    draw3dDice(platX, platY - 4, 38.0, bluePips: false);

    // ── 5. Bottom Left & Right: Tall Stacks of 3D Gold Coins ──────────
    void drawCoinStack(double x, double baseY, int count) {
      for (int i = 0; i < count; i++) {
        drawCoin(x, baseY - (i * 5.0), 12.0, 0.60);
      }
    }

    // Left Stacks
    drawCoinStack(w * 0.08, h * 0.96, 5);
    drawCoinStack(w * 0.18, h * 0.97, 4);

    // Right Stacks
    drawCoinStack(w * 0.92, h * 0.96, 5);
    drawCoinStack(w * 0.82, h * 0.97, 4);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
