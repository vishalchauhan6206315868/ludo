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
            Icon(Icons.card_giftcard_rounded, color: Color(0xFFFFD700), size: 22),
            SizedBox(width: 8),
            Text(
              "REWARDS & BONUSES",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Refresh",
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFFD700), size: 22),
            onPressed: _isLoading ? null : _fetchRewardsData,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Summary Cards (Always visible if loaded)
            if (!_isLoading && _errorMessage == null) _buildSummaryHeader(),

            // Custom Tab Bar (Available Rewards vs My Rewards)
            if (!_isLoading && _errorMessage == null) _buildCustomTabBar(),

            // Body
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  // --- Summary Metric Cards ---
  Widget _buildSummaryHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141F36),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.redeem_rounded,
              iconColor: const Color(0xFFFFD700),
              label: "Available",
              value: "${_summary.availableRewards}",
            ),
          ),
          Container(width: 1, height: 36, color: Colors.white12),
          Expanded(
            child: _buildStatItem(
              icon: Icons.check_circle_rounded,
              iconColor: const Color(0xFF4ADE80),
              label: "Claimed",
              value: "${_summary.claimedRewards}",
            ),
          ),
          Container(width: 1, height: 36, color: Colors.white12),
          Expanded(
            child: _buildStatItem(
              icon: Icons.monetization_on_rounded,
              iconColor: const Color(0xFFFFB300),
              label: "Coins Earned",
              value: "${_summary.totalCoinsEarned}",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 5),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF90A4AE),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // --- Tab Bar ---
  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF101A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
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
          color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF091428) : const Color(0xFF90A4AE),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF091428) : const Color(0xFF90A4AE),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Main Content Body ---
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

  // --- 1. Available Rewards List ---
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141F36),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isClaimed
              ? Colors.white12
              : const Color(0xFFFFD700).withValues(alpha: 0.35),
          width: isClaimed ? 1.0 : 1.3,
        ),
        boxShadow: isClaimed
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isClaimed
                  ? const Color(0xFF1A2640)
                  : const Color(0xFFFFD700).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isClaimed
                    ? Colors.white12
                    : const Color(0xFFFFD700).withValues(alpha: 0.4),
              ),
            ),
            child: Icon(
              _getRewardIcon(reward.icon),
              color: isClaimed ? const Color(0xFF90A4AE) : const Color(0xFFFFD700),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Title & Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  style: TextStyle(
                    color: isClaimed ? const Color(0xFF90A4AE) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
                if (reward.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    reward.description,
                    style: const TextStyle(
                      color: Color(0xFF90A4AE),
                      fontSize: 11.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),

                // Amount Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2E4D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD700), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "+${reward.rewardValue} Coins",
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Action Button (CLAIM vs CLAIMED)
          if (isClaimed) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF16233B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF4ADE80).withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 14),
                  SizedBox(width: 4),
                  Text(
                    "CLAIMED",
                    style: TextStyle(
                      color: Color(0xFF4ADE80),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
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
                disabledBackgroundColor: const Color(0xFF26334D),
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 3,
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
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 2. My Rewards History List ---
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141F36),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF4ADE80).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF4ADE80).withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  claim.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  claim.claimedAt != null ? _formatDateTime(claim.claimedAt!) : "Claimed",
                  style: const TextStyle(
                    color: Color(0xFF90A4AE),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2E5C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "+${claim.rewardValue} Coins",
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
                fontSize: 12,
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

  IconData _getRewardIcon(String iconKey) {
    switch (iconKey.toLowerCase()) {
      case 'daily_login':
      case 'streak_2':
      case 'streak_3':
        return Icons.calendar_today_rounded;
      case 'welcome_bonus':
        return Icons.celebration_rounded;
      case 'first_win':
        return Icons.emoji_events_rounded;
      case 'lucky_spin':
        return Icons.casino_rounded;
      case 'weekend_rush':
        return Icons.bolt_rounded;
      case 'referral_bonus':
        return Icons.share_rounded;
      case 'master_player':
        return Icons.workspace_premium_rounded;
      case 'community':
        return Icons.groups_rounded;
      default:
        return Icons.card_giftcard_rounded;
    }
  }
}
