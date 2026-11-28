import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../core/network/api_service.dart';
import '../features/wallet/models/wallet_model.dart';
import '../features/wallet/models/wallet_transaction_model.dart';
import '../services/auth_service.dart';
import '../services/razorpay_payment_service.dart';
import 'login_screen.dart';
import 'rewards_screen.dart';

/// Screen displaying user's coin balance, wallet information,
/// and paginated transaction history with filter tabs and pull-to-refresh.
class WalletScreen extends StatefulWidget {
  final ApiService? apiService;
  final VoidCallback? onWalletUpdated;
  final int? profileFallbackCoins;

  const WalletScreen({
    super.key,
    this.apiService,
    this.onWalletUpdated,
    this.profileFallbackCoins,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late final ApiService _apiService;
  late final RazorpayPaymentService _paymentService;
  final ScrollController _scrollController = ScrollController();

  // State flags
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  bool _isUnauthorized = false;

  // Payment State flags
  bool _isProcessingPayment = false;
  String _paymentProcessingStatus = "";
  String? _currentPendingOrderId;
  num _currentPendingAmount = 0;

  // Data
  WalletModel _wallet = const WalletModel();
  List<WalletTransactionModel> _transactions = [];
  WalletPaginationModel _pagination = const WalletPaginationModel();

  // Profile Fallback & Discrepancy flags (Safe Display Only)
  bool _isUsingProfileFallback = false;
  bool _hasBalanceDiscrepancy = false;
  int _profileFallbackBalance = 0;

  int get _displayBalance {
    if (_isUsingProfileFallback && _wallet.balance == 0) {
      return _profileFallbackBalance;
    }
    return _wallet.balance;
  }

  // Filter: 0 = All, 1 = Credit, 2 = Debit
  int _selectedFilter = 0;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _paymentService = RazorpayPaymentService();
    _paymentService.initialize(
      onSuccess: _handlePaymentSuccess,
      onError: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
    _scrollController.addListener(_onScroll);
    if (widget.apiService == null) {
      _apiService.preWarmServer();
    }
    _fetchInitialData();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Trigger next page when within 150px of bottom
    if (currentScroll >= maxScroll - 150) {
      if (!_isLoading && !_isLoadingMore && _pagination.hasNextPage) {
        _loadNextPage();
      }
    }
  }

  /// Initial load: fetch wallet balance and page 1 of transactions
  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isUnauthorized = false;
    });

    int profileCoins = widget.profileFallbackCoins ?? 0;
    if (profileCoins == 0 && widget.apiService == null) {
      try {
        final cached = await AuthService.getCachedUserProfile();
        profileCoins = cached?.coins ?? await AuthService.getUserCoins();
      } catch (_) {}
    }

    try {
      final results = await Future.wait([
        _apiService.getWallet(),
        _apiService.getTransactions(1, 20),
      ]);

      if (!mounted) return;

      final walletRes = results[0];
      final txRes = results[1];

      // Check Unauthorized (401)
      if (walletRes['statusCode'] == 401 || txRes['statusCode'] == 401) {
        setState(() {
          _isLoading = false;
          _isUnauthorized = true;
          _errorMessage = "Authentication required. Please login again to access your wallet.";
        });
        return;
      }

      // Check Errors
      final walletFailed = walletRes['success'] != true;
      final txFailed = txRes['success'] != true;

      if (walletFailed && txFailed && profileCoins == 0) {
        setState(() {
          _isLoading = false;
          _errorMessage = walletRes['message']?.toString() ??
              txRes['message']?.toString() ??
              "Unable to load wallet information. Please check your connection.";
        });
        return;
      }

      // 1. Parse Wallet Model
      WalletModel parsedWallet = const WalletModel();
      bool usingFallback = false;
      bool discrepancy = false;

      if (!walletFailed && walletRes['data'] != null) {
        parsedWallet = WalletModel.fromApiResponse(walletRes);
      } else if (profileCoins > 0) {
        // Safe display fallback when wallet API fails or times out
        usingFallback = true;
      }

      // 2. Parse Transactions Response
      WalletTransactionsResponse parsedTx = const WalletTransactionsResponse();
      if (!txFailed) {
        parsedTx = WalletTransactionsResponse.fromApiResponse(txRes);
        // Fallback balance if wallet endpoint didn't provide it
        if (parsedWallet.balance == 0 && parsedTx.balance > 0) {
          parsedWallet = parsedWallet.copyWith(balance: parsedTx.balance);
        }
      }

      // Detect discrepancy between authoritative wallet balance and profile
      if (!usingFallback && parsedWallet.balance == 0 && profileCoins > 0) {
        discrepancy = true;
      }

      // If valid wallet balance received, sync local profile in background
      if (!walletFailed && parsedWallet.balance > 0 && widget.apiService == null) {
        AuthService.updateLocalCoins(parsedWallet.balance);
      }

      // Trigger background profile refresh to keep both endpoints aligned in production
      if (widget.apiService == null) {
        AuthService.fetchUserProfile().catchError((_) => null);
      }

      // Notify parent callback if wallet balance updated
      widget.onWalletUpdated?.call();

      setState(() {
        _wallet = parsedWallet;
        _transactions = parsedTx.transactions;
        _pagination = parsedTx.pagination;
        _isUsingProfileFallback = usingFallback;
        _hasBalanceDiscrepancy = discrepancy;
        _profileFallbackBalance = profileCoins;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (profileCoins > 0) {
        setState(() {
          _isLoading = false;
          _isUsingProfileFallback = true;
          _profileFallbackBalance = profileCoins;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "An unexpected error occurred: $e";
        });
      }
    }
  }

  /// Load next page of transactions (Pagination)
  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_pagination.hasNextPage) return;

    final nextPage = _pagination.page + 1;
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final res = await _apiService.getTransactions(nextPage, 20);
      if (!mounted) return;

      if (res['success'] == true) {
        final nextResponse = WalletTransactionsResponse.fromApiResponse(res);
        setState(() {
          // Avoid duplicate entries if any
          final existingIds = _transactions.map((t) => t.id).toSet();
          final newItems = nextResponse.transactions.where((t) => !existingIds.contains(t.id));
          _transactions.addAll(newItems);
          _pagination = nextResponse.pagination;
        });
      }
    } catch (_) {
      // Silently fail pagination error, user can scroll again
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  List<WalletTransactionModel> get _filteredTransactions {
    if (_selectedFilter == 1) {
      return _transactions.where((t) => t.isCredit).toList();
    } else if (_selectedFilter == 2) {
      return _transactions.where((t) => t.isDebit).toList();
    }
    return _transactions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B24),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Color(0xFF1E0E44),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "MY WALLET",
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(color: Color(0xFFFFD700), blurRadius: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Refresh Wallet",
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.7),
                  width: 1.5,
                ),
                color: const Color(0x22FFD700),
              ),
              child: const Icon(Icons.refresh_rounded, color: Color(0xFFFFD700), size: 18),
            ),
            onPressed: _isLoading ? null : _fetchInitialData,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF04081E),
              Color(0xFF09123E),
              Color(0xFF05081C),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              RefreshIndicator(
                color: const Color(0xFFFFD700),
                backgroundColor: const Color(0xFF141F36),
                onRefresh: _fetchInitialData,
                child: _buildBody(),
              ),
              if (_isProcessingPayment) _buildPaymentLoadingOverlay(),
            ],
          ),
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
              "Loading Wallet & Passbook...",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_isUnauthorized) {
      return _buildUnauthorizedView();
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Top Wallet Balance Card
        SliverToBoxAdapter(
          child: _buildBalanceCard(),
        ),

        // Filter Tabs (Placed directly below balance card as in reference design)
        SliverToBoxAdapter(
          child: _buildFilterTabBar(),
        ),

        // Transactions List or Empty State
        if (_filteredTransactions.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tx = _filteredTransactions[index];
                  return _buildTransactionCard(tx);
                },
                childCount: _filteredTransactions.length,
              ),
            ),
          ),

        // Pagination Loader / End Indicator
        SliverToBoxAdapter(
          child: _buildPaginationFooter(),
        ),

        // Optional Wallet Metadata Info at the very bottom
        if (_wallet.id.isNotEmpty || _wallet.createdAt != null)
          SliverToBoxAdapter(
            child: _buildWalletInfoCard(),
          ),
      ],
    );
  }

  // --- 1. Luxury Gold Wallet Balance Card ---
  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F1E4A),
            Color(0xFF0A1435),
            Color(0xFF060B22),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFD54F),
          width: 2.6,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withValues(alpha: 0.45),
            blurRadius: 22,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Crowned Wallet Emblem, Available Balance & ACTIVE pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Crown + Wallet Emblem + Titles (Wrapped in Expanded to prevent overflow)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Crown + Wallet Emblem
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFFD54F),
                              width: 1.8,
                            ),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1976D2), Color(0xFF0D47A1), Color(0xFF052060)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1976D2).withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Color(0xFFFFD700),
                            size: 22,
                          ),
                        ),
                        Positioned(
                          top: 0,
                          child: CustomPaint(
                            size: const Size(26, 16),
                            painter: _WalletCrownPainter(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            "AVAILABLE BALANCE",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFFFFD54F),
                              fontSize: 12.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Game Coins for Matches & Entry",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFFB0BEC5),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right: ACTIVE status pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C853).withValues(alpha: 0.45),
                      blurRadius: 6,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 3),
                    Text(
                      "ACTIVE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Center Row: Balance Display (Left) & 3D Treasure Chest (Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Coin Icon, Dynamic Balance, and COINS label
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildGlossyStarCoin(size: 38),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _formatNumber(_displayBalance),
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "COINS",
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Color(0xFFFFD54F),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              // Right: 3D Open Golden Treasure Chest
              const SizedBox(
                width: 86,
                height: 72,
                child: CustomPaint(
                  painter: _TreasureChestPainter(),
                ),
              ),
            ],
          ),
          if (_isUsingProfileFallback) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sync_rounded, color: Color(0xFFFFD54F), size: 14),
                  SizedBox(width: 6),
                  Text(
                    "Cached Profile Balance (Wallet syncing...)",
                    style: TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_hasBalanceDiscrepancy) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.cyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.cyan.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFF00E5FF), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    "Profile reports $_profileFallbackBalance coins",
                    style: const TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Action Buttons: Row 1 (+ Add Cash & Withdraw)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _showAddCashBottomSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFA7FFEB),
                        width: 1.2,
                      ),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E676), Color(0xFF00C853), Color(0xFF009624)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E676).withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_circle, color: Colors.white, size: 20),
                          SizedBox(width: 6),
                          Text(
                            "Add Cash",
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _showWithdrawBottomSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFD54F),
                        width: 1.8,
                      ),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E232F), Color(0xFF101520), Color(0xFF080C14)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.account_balance_rounded, color: Color(0xFFFFD54F), size: 19),
                          SizedBox(width: 6),
                          Text(
                            "Withdraw",
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              color: Color(0xFFFFD54F),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons: Row 2 (Earn Free Coins & Sync)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RewardsScreen(
                          onRewardClaimed: _fetchInitialData,
                        ),
                      ),
                    );
                    _fetchInitialData();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0x33101C38),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.card_giftcard_rounded, size: 16, color: Color(0xFFFFD700)),
                        SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            "Earn Free Coins",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _fetchInitialData,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                  decoration: BoxDecoration(
                    color: const Color(0x33101C38),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.sync_rounded, size: 16, color: Colors.white70),
                      SizedBox(width: 5),
                      Text(
                        "Sync",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 2. Wallet Metadata Information Card ---
  Widget _buildWalletInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141F36),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_wallet.id.isNotEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "WALLET ID",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _shortId(_wallet.id),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          if (_wallet.createdAt != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  "CREATED ON",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateOnly(_wallet.createdAt!),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // --- 3. Filter Tab Bar ---
  Widget _buildFilterTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1028),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x33FFD54F), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterTabItem(0, "All (${_transactions.length})", Icons.swap_horiz_rounded),
          ),
          Expanded(
            child: _buildFilterTabItem(
              1,
              "Credit (${_transactions.where((t) => t.isCredit).length})",
              Icons.arrow_downward_rounded,
            ),
          ),
          Expanded(
            child: _buildFilterTabItem(
              2,
              "Debit (${_transactions.where((t) => t.isDebit).length})",
              Icons.arrow_upward_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabItem(int index, String label, IconData icon) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFFFF9C4), Color(0xFFFFD54F), Color(0xFFFF9800)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? const Color(0xFF1B0F00) : Colors.white70,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: isSelected ? const Color(0xFF1B0F00) : Colors.white70,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  fontSize: 11.5,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. Single Transaction Card ---
  Widget _buildTransactionCard(WalletTransactionModel tx) {
    final isCredit = tx.isCredit;
    final primaryColor = isCredit ? const Color(0xFF4ADE80) : const Color(0xFFF87171);
    final sign = isCredit ? "+" : "-";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141F36),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Main info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _formatTitle(tx),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "$sign${_formatNumber(tx.amount)}",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Date & Time + Source
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        tx.createdAt != null
                            ? _formatDateTime(tx.createdAt!)
                            : "Recently",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Text(
                      "Bal: ${_formatNumber(tx.balance)}",
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Pills: Status + Source Tag
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tx.type.toUpperCase(),
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tx.status.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (tx.source.isNotEmpty && tx.source != 'other')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tx.source.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 9,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. Pagination Footer ---
  Widget _buildPaginationFooter() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                ),
              ),
              SizedBox(width: 10),
              Text(
                "Loading more transactions...",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (_transactions.isNotEmpty && !_pagination.hasNextPage) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            "â€¢ End of Transaction History â€¢",
            style: TextStyle(color: Colors.white24, fontSize: 11),
          ),
        ),
      );
    }

    return const SizedBox(height: 24);
  }

  Widget _buildGlossyStarCoin({double size = 36}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          radius: 0.8,
          colors: [
            Color(0xFFFFF9C4),
            Color(0xFFFFD54F),
            Color(0xFFFFB300),
            Color(0xFFC45A00),
          ],
        ),
        border: Border.all(color: const Color(0xFFFFFDE7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withValues(alpha: 0.5),
            blurRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.star_rounded,
          color: const Color(0xFF6B3300),
          size: size * 0.62,
        ),
      ),
    );
  }

  // --- 6. Empty State View ---
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 3D Illuminated Pedestal Stage with Passbook and Coins
            const SizedBox(
              width: 180,
              height: 140,
              child: CustomPaint(
                painter: _PedestalStagePainter(),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "No Transactions Yet",
              style: TextStyle(
                fontFamily: 'Roboto',
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Play matches or claim daily rewards to start building your coin history!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFB0BEC5),
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RewardsScreen(
                      onRewardClaimed: _fetchInitialData,
                    ),
                  ),
                );
                _fetchInitialData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white, width: 1.5),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF9C4), Color(0xFFFFD54F), Color(0xFFFF8F00)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8F00).withValues(alpha: 0.55),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.card_giftcard_rounded, color: Color(0xFF261200), size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Claim Free Rewards",
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Color(0xFF261200),
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 7. Error State View ---
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? "Unable to load wallet data",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _fetchInitialData,
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

  // --- 8. Unauthorized State View ---
  Widget _buildUnauthorizedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded, color: Color(0xFFFBBF24), size: 52),
            const SizedBox(height: 14),
            const Text(
              "Session Required",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Please login with your account to view your wallet balance and transactions.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text("Go to Login"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF0D1424),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Formatters ---
  String _formatTitle(WalletTransactionModel tx) {
    if (tx.description.isNotEmpty) {
      return tx.description;
    }
    if (tx.source.isNotEmpty) {
      return tx.source.replaceAll('_', ' ').toUpperCase();
    }
    return tx.isCredit ? "Coin Credit" : "Coin Debit";
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String _shortId(String id) {
    if (id.length <= 12) return id;
    return '${id.substring(0, 6)}...${id.substring(id.length - 4)}';
  }

  String _formatDateOnly(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute $period';
  }

  // ===========================================================================
  // PAYMENT & RAZORPAY INTEGRATION
  // ===========================================================================

  Widget _buildPaymentLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          decoration: BoxDecoration(
            color: const Color(0xFF141F36),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 48,
                width: 48,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                  strokeWidth: 3.5,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _paymentProcessingStatus.isNotEmpty
                    ? _paymentProcessingStatus
                    : "Processing Payment...",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please do not close or exit the app",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _hidePaymentProcessing() {
    if (mounted) {
      setState(() {
        _isProcessingPayment = false;
        _paymentProcessingStatus = "";
      });
    }
  }

  /// 1. Add Cash Bottom Sheet
  void _showAddCashBottomSheet() {
    if (widget.apiService == null) {
      _apiService.preWarmServer();
    }
    final amountController = TextEditingController(text: "100");
    final presetAmounts = [50, 100, 200, 500, 1000, 2000];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final enteredAmount = int.tryParse(amountController.text) ?? 0;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                decoration: const BoxDecoration(
                  color: Color(0xFF101A2E),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -4)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_card_rounded,
                            color: Color(0xFF10B981),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ADD CASH TO WALLET",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              "Instant coins credit for tournaments & matches",
                              style: TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Amount Text Field
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            "â‚¹",
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        suffixText: "COINS: $enteredAmount",
                        suffixStyle: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF141F36),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Preset Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presetAmounts.map((amt) {
                        final isSelected = enteredAmount == amt;
                        return ChoiceChip(
                          label: Text(
                            "+ â‚¹$amt",
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF091428) : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFFFFD700),
                          backgroundColor: const Color(0xFF141F36),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFFFFD700) : Colors.white12,
                          ),
                          onSelected: (_) {
                            setModalState(() {
                              amountController.text = amt.toString();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Trust Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_rounded, color: Color(0xFF10B981), size: 14),
                          SizedBox(width: 6),
                          Text(
                            "100% Safe & Secure via Razorpay (UPI, Cards, NetBanking)",
                            style: TextStyle(color: Colors.white60, fontSize: 8),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pay Button
                    ElevatedButton(
                      onPressed: enteredAmount > 0
                          ? () {
                              Navigator.pop(bottomSheetContext);
                              _startAddCashFlow(enteredAmount);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.white12,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "PROCEED TO PAY â‚¹$enteredAmount",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 2. Initiate Create Order & Launch Razorpay
  Future<void> _startAddCashFlow(num amount) async {
    if (amount <= 0) return;

    setState(() {
      _isProcessingPayment = true;
      _paymentProcessingStatus = "Creating Razorpay Order...\nPlease wait";
    });

    try {
      var res = await _apiService.createDepositOrder(amount);

      if (!mounted) return;

      // Auto-refresh backend JWT token once if 401 (e.g., stale token from previous server)
      if (res['statusCode'] == 401) {
        final refreshedToken = await AuthService.ensureBackendSession();
        if (refreshedToken != null && refreshedToken.isNotEmpty) {
          res = await _apiService.createDepositOrder(amount);
          if (!mounted) return;
        }
      }

      if (res['success'] != true) {
        _hidePaymentProcessing();
        _showAlertDialog(
          title: "Order Failed",
          message: res['message']?.toString() ??
              "Unable to create deposit order. Please check your internet or try again later.",
          isError: true,
        );
        return;
      }

      // Unpack nested backend response structure safely:
      // Backend returns: { success: true, data: { razorpayOrderId: ..., keyId: ... } }
      // ApiService wraps this as: { success: true, data: <decodedBody> }
      Map<String, dynamic> payload = {};
      final rawData = res['data'];
      if (rawData is Map<String, dynamic>) {
        if (rawData['data'] is Map<String, dynamic>) {
          payload = rawData['data'] as Map<String, dynamic>;
        } else {
          payload = rawData;
        }
      } else {
        payload = res;
      }

      // Priority: Razorpay Order ID (e.g., order_xxxx)
      String? orderId = payload['razorpayOrderId']?.toString() ??
          payload['razorpay_order_id']?.toString() ??
          payload['orderId']?.toString() ??
          payload['order_id']?.toString() ??
          payload['id']?.toString();

      if (orderId == null && payload['order'] is Map<String, dynamic>) {
        final orderMap = payload['order'] as Map<String, dynamic>;
        orderId = orderMap['razorpayOrderId']?.toString() ??
            orderMap['razorpay_order_id']?.toString() ??
            orderMap['id']?.toString() ??
            orderMap['orderId']?.toString();
      }

      // Fallback check on outer data if not found in payload
      if (orderId == null && res['data'] is Map<String, dynamic>) {
        final outer = res['data'] as Map<String, dynamic>;
        orderId = outer['razorpayOrderId']?.toString() ??
            outer['razorpay_order_id']?.toString() ??
            outer['orderId']?.toString() ??
            outer['order_id']?.toString() ??
            outer['id']?.toString();
      }

      String? razorpayKey = payload['keyId']?.toString() ??
          payload['key_id']?.toString() ??
          payload['key']?.toString() ??
          payload['razorpay_key']?.toString();

      if (razorpayKey == null && res['data'] is Map<String, dynamic>) {
        final outer = res['data'] as Map<String, dynamic>;
        razorpayKey = outer['keyId']?.toString() ??
            outer['key_id']?.toString() ??
            outer['key']?.toString() ??
            outer['razorpay_key']?.toString();
      }

      debugPrint('[Razorpay Deposit] Parsed orderId: $orderId, keyId: $razorpayKey');

      if (orderId == null || orderId.isEmpty) {
        _hidePaymentProcessing();
        _showAlertDialog(
          title: "Invalid Order Response",
          message: "Backend did not return an order ID. Please ensure backend deposit API is active.",
          isError: true,
        );
        return;
      }

      _currentPendingOrderId = orderId;
      _currentPendingAmount = amount;

      final userEmail = await AuthService.getUserEmail();
      final userName = await AuthService.getUserName();

      _hidePaymentProcessing();

      _paymentService.openCheckout(
        key: razorpayKey,
        orderId: orderId,
        amount: amount,
        name: "Ludo Supreme Pro",
        description: "Deposit â‚¹$amount (Coins: $amount)",
        prefillName: userName,
        prefillEmail: userEmail,
      );
    } catch (e) {
      _hidePaymentProcessing();
      _showAlertDialog(
        title: "Connection Error",
        message: "Failed to initiate payment: $e",
        isError: true,
      );
    }
  }

  /// 3. Razorpay Success Callback -> Verify Payment API
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() {
      _isProcessingPayment = true;
      _paymentProcessingStatus =
          "Verifying payment with backend...\nPlease do not close or exit the app.";
    });

    final orderId = response.orderId ?? _currentPendingOrderId ?? '';
    final paymentId = response.paymentId ?? '';
    final signature = response.signature ?? '';

    try {
      final verifyRes = await _apiService.verifyDepositPayment(
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
      );

      _hidePaymentProcessing();

      if (!mounted) return;

      if (verifyRes['success'] == true) {
        _showPaymentSuccessDialog(
          amount: _currentPendingAmount,
          paymentId: paymentId,
        );
        await _fetchInitialData();
        widget.onWalletUpdated?.call();
      } else {
        _showAlertDialog(
          title: "Verification Pending",
          message: verifyRes['message']?.toString() ??
              "Payment verification is in progress. If amount was deducted, your coins will be added automatically within 5 minutes.",
          isError: true,
        );
        _fetchInitialData();
      }
    } catch (e) {
      _hidePaymentProcessing();
      if (!mounted) return;
      _showAlertDialog(
        title: "Verification Notice",
        message:
            "Payment completed, but verification timed out: $e.\nIf money was debited, your coins will be credited via backend webhook.",
        isError: true,
      );
      _fetchInitialData();
    }
  }

  /// 4. Razorpay Error Callback
  void _handlePaymentError(PaymentFailureResponse response) {
    _hidePaymentProcessing();
    if (!mounted) return;

    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Payment was cancelled."),
          backgroundColor: Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      _showAlertDialog(
        title: "Payment Unsuccessful",
        message: response.message ?? "The transaction could not be processed.",
        isError: true,
      );
    }
  }

  /// 5. Razorpay External Wallet Callback
  void _handleExternalWallet(ExternalWalletResponse response) {
    _hidePaymentProcessing();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Redirecting to ${response.walletName ?? 'external wallet'}..."),
        backgroundColor: const Color(0xFF141F36),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 6. Withdrawal Bottom Sheet (UPI & Bank Transfer Support)
  void _showWithdrawBottomSheet() {
    final amountController = TextEditingController(text: "100");
    final upiController = TextEditingController();
    final accountNumberController = TextEditingController();
    final ifscController = TextEditingController();
    final accountHolderController = TextEditingController();
    final bankNameController = TextEditingController();
    
    // 0 = UPI, 1 = Bank Transfer
    int selectedPayoutMode = 0;
    final availableBalance = _wallet.balance;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final enteredAmount = int.tryParse(amountController.text) ?? 0;
            final isAmountValid = enteredAmount > 0 && enteredAmount <= availableBalance;

            bool isDetailsValid;
            if (selectedPayoutMode == 0) {
              isDetailsValid = upiController.text.trim().isNotEmpty && upiController.text.contains('@');
            } else {
              isDetailsValid = accountNumberController.text.trim().isNotEmpty &&
                  ifscController.text.trim().isNotEmpty &&
                  accountHolderController.text.trim().isNotEmpty;
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                decoration: const BoxDecoration(
                  color: Color(0xFF101A2E),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -4)),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle Bar
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.account_balance_rounded,
                              color: Color(0xFFFFD700),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "WITHDRAW WINNINGS",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                "Available Balance: â‚¹$availableBalance",
                                style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Mode Switcher (UPI vs Bank)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141F36),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setModalState(() => selectedPayoutMode = 0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selectedPayoutMode == 0 ? const Color(0xFFFFD700) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "UPI (Instant)",
                                    style: TextStyle(
                                      color: selectedPayoutMode == 0 ? const Color(0xFF091428) : Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setModalState(() => selectedPayoutMode = 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selectedPayoutMode == 1 ? const Color(0xFFFFD700) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "Bank Transfer",
                                    style: TextStyle(
                                      color: selectedPayoutMode == 1 ? const Color(0xFF091428) : Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Amount Text Field
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          labelText: "Withdrawal Amount (â‚¹)",
                          labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              "â‚¹",
                              style: TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                          filled: true,
                          fillColor: const Color(0xFF141F36),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Colors.white12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Quick Balance Chips
                      Wrap(
                        spacing: 8,
                        children: [
                          if (availableBalance >= 100)
                            ActionChip(
                              label: const Text("â‚¹100"),
                              backgroundColor: const Color(0xFF141F36),
                              labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                              side: const BorderSide(color: Colors.white12),
                              onPressed: () {
                                setModalState(() => amountController.text = "100");
                              },
                            ),
                          if (availableBalance >= 500)
                            ActionChip(
                              label: const Text("â‚¹500"),
                              backgroundColor: const Color(0xFF141F36),
                              labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                              side: const BorderSide(color: Colors.white12),
                              onPressed: () {
                                setModalState(() => amountController.text = "500");
                              },
                            ),
                          ActionChip(
                            label: const Text("Withdraw All"),
                            backgroundColor: const Color(0xFF141F36),
                            labelStyle: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold),
                            side: const BorderSide(color: Color(0xFFFFD700)),
                            onPressed: () {
                              setModalState(() => amountController.text = availableBalance.toString());
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Payout Mode Inputs
                      if (selectedPayoutMode == 0) ...[
                        // UPI Mode Input
                        TextField(
                          controller: upiController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          onChanged: (_) => setModalState(() {}),
                          decoration: InputDecoration(
                            labelText: "UPI ID / VPA",
                            labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                            hintText: "e.g. player@okhdfcbank or 9876543210@paytm",
                            hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                            prefixIcon: const Icon(Icons.payment_rounded, color: Color(0xFFFFD700), size: 20),
                            filled: true,
                            fillColor: const Color(0xFF141F36),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Colors.white12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Bank Mode Inputs
                        TextField(
                          controller: accountHolderController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          onChanged: (_) => setModalState(() {}),
                          decoration: InputDecoration(
                            labelText: "Account Holder Name",
                            labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                            prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFFFFD700), size: 20),
                            filled: true,
                            fillColor: const Color(0xFF141F36),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: accountNumberController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          onChanged: (_) => setModalState(() {}),
                          decoration: InputDecoration(
                            labelText: "Account Number",
                            labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                            prefixIcon: const Icon(Icons.numbers_rounded, color: Color(0xFFFFD700), size: 20),
                            filled: true,
                            fillColor: const Color(0xFF141F36),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: ifscController,
                                textCapitalization: TextCapitalization.characters,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                onChanged: (_) => setModalState(() {}),
                                decoration: InputDecoration(
                                  labelText: "IFSC Code",
                                  labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                                  prefixIcon: const Icon(Icons.pin_rounded, color: Color(0xFFFFD700), size: 18),
                                  filled: true,
                                  fillColor: const Color(0xFF141F36),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: bankNameController,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: "Bank Name",
                                  labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                                  filled: true,
                                  fillColor: const Color(0xFF141F36),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Submit Button
                      ElevatedButton(
                        onPressed: (isAmountValid && isDetailsValid)
                            ? () {
                                Navigator.pop(bottomSheetContext);
                                if (selectedPayoutMode == 0) {
                                  _submitWithdrawalRequest(
                                    amount: enteredAmount,
                                    payoutMode: 'upi',
                                    payoutDetails: {
                                      'upiId': upiController.text.trim(),
                                    },
                                  );
                                } else {
                                  _submitWithdrawalRequest(
                                    amount: enteredAmount,
                                    payoutMode: 'bank_transfer',
                                    payoutDetails: {
                                      'accountNumber': accountNumberController.text.trim(),
                                      'ifscCode': ifscController.text.trim().toUpperCase(),
                                      'accountHolderName': accountHolderController.text.trim(),
                                      if (bankNameController.text.trim().isNotEmpty)
                                        'bankName': bankNameController.text.trim(),
                                    },
                                  );
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: const Color(0xFF091428),
                          disabledBackgroundColor: Colors.white12,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "SUBMIT WITHDRAWAL REQUEST",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 7. Submit Withdrawal API Call
  Future<void> _submitWithdrawalRequest({
    required num amount,
    required String payoutMode,
    required Map<String, dynamic> payoutDetails,
  }) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final res = await _apiService.requestWithdrawal(
        amount: amount,
        payoutMode: payoutMode,
        payoutDetails: payoutDetails,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        final dynamic data = res['data'];
        String? requestNo;
        if (data is Map<String, dynamic>) {
          if (data['withdrawal'] is Map<String, dynamic>) {
            requestNo = data['withdrawal']['requestNo']?.toString();
          }
          requestNo ??= data['requestNo']?.toString();
        }

        _showAlertDialog(
          title: "Withdrawal Requested",
          message:
              "Your withdrawal request of â‚¹$amount has been submitted successfully.${requestNo != null ? '\nRequest No: $requestNo' : ''}\nStatus: Pending Admin Approval.",
        );
      } else {
        _showAlertDialog(
          title: "Withdrawal Failed",
          message: res['message']?.toString() ?? "Could not submit withdrawal request.",
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showAlertDialog(
        title: "Network Error",
        message: "Failed to submit withdrawal: $e",
        isError: true,
      );
    } finally {
      _fetchInitialData();
    }
  }

  /// 8. Payment Success Dialog
  void _showPaymentSuccessDialog({
    required num amount,
    required String paymentId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141F36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Payment Successful!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "â‚¹$amount has been added to your wallet balance.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (paymentId.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "ID: $paymentId",
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("GREAT!"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 9. Generic Alert Dialog
  void _showAlertDialog({
    required String title,
    required String message,
    bool isError = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141F36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: isError ? Colors.redAccent.withValues(alpha: 0.5) : const Color(0xFFFFD700).withValues(alpha: 0.5),
            ),
          ),
          title: Row(
            children: [
              Icon(
                isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
                color: isError ? Colors.redAccent : const Color(0xFFFFD700),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                "OK",
                style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// 3D ROYAL GAMING WALLET CUSTOM PAINTERS & GRAPHICS
// ============================================================================

/// 1. Mini Jeweled Golden Crown perched atop the wallet emblem
class _WalletCrownPainter extends CustomPainter {
  const _WalletCrownPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Crown Path (5-peaks)
    final path = Path()
      ..moveTo(width * 0.12, height * 0.90)
      ..lineTo(width * 0.05, height * 0.30)
      ..lineTo(width * 0.28, height * 0.58)
      ..lineTo(width * 0.50, height * 0.08)
      ..lineTo(width * 0.72, height * 0.58)
      ..lineTo(width * 0.95, height * 0.30)
      ..lineTo(width * 0.88, height * 0.90)
      ..close();

    // Crown Gold Gradient
    final crownPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFFC45A00)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    canvas.drawPath(path, crownPaint);

    // Crown Outline
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF5D2E00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Center Ruby
    final rubyPaint = Paint()..color = const Color(0xFFD50000);
    canvas.save();
    canvas.translate(width * 0.50, height * 0.65);
    canvas.rotate(math.pi / 4);
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 4.5, height: 4.5), rubyPaint);
    canvas.restore();

    // Peak Jewels (white pearls)
    final jewelPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(width * 0.05, height * 0.30), 1.8, jewelPaint);
    canvas.drawCircle(Offset(width * 0.50, height * 0.08), 2.4, jewelPaint);
    canvas.drawCircle(Offset(width * 0.95, height * 0.30), 1.8, jewelPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. 3D Open Golden Treasure Chest with overflowing coins & sparkles
class _TreasureChestPainter extends CustomPainter {
  const _TreasureChestPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.55;
    final scale = (size.width / 90.0).clamp(0.65, 1.35);

    // 1. Radiant Aura Behind Chest
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0x77FFD700),
          Color(0x33FF9100),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx + 4 * scale, cy), radius: 36 * scale));
    canvas.drawCircle(Offset(cx + 4 * scale, cy), 36 * scale, auraPaint);

    // 2. Chest Lower Body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 10 * scale), width: 56 * scale, height: 32 * scale),
      Radius.circular(6 * scale),
    );
    // Body Drop Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 13 * scale), width: 56 * scale, height: 32 * scale),
        Radius.circular(6 * scale),
      ),
      Paint()..color = const Color(0x66000000),
    );

    // Wood / Gold body gradient
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8D4B00), Color(0xFF5D2E00), Color(0xFF381A00)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bodyRect.outerRect);
    canvas.drawRRect(bodyRect, bodyPaint);

    // Golden Vertical Ribs & Corner Brackets on Body
    final goldBandPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF9C4), Color(0xFFFFD54F), Color(0xFFC45A00)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bodyRect.outerRect);

    // Left band
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 18 * scale, cy + 10 * scale), width: 6 * scale, height: 32 * scale),
        Radius.circular(2 * scale),
      ),
      goldBandPaint,
    );
    // Right band
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 18 * scale, cy + 10 * scale), width: 6 * scale, height: 32 * scale),
        Radius.circular(2 * scale),
      ),
      goldBandPaint,
    );
    // Rim trim
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 * scale,
    );

    // 3. Open Lid (Angled backwards)
    final lidPath = Path()
      ..moveTo(cx - 30 * scale, cy - 4 * scale)
      ..lineTo(cx + 30 * scale, cy - 4 * scale)
      ..lineTo(cx + 26 * scale, cy - 24 * scale)
      ..quadraticBezierTo(cx, cy - 30 * scale, cx - 26 * scale, cy - 24 * scale)
      ..close();

    final lidPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3E1F80), Color(0xFF1E0E44), Color(0xFF0F0525)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCenter(center: Offset(cx, cy - 16 * scale), width: 60 * scale, height: 26 * scale));
    canvas.drawPath(lidPath, lidPaint);

    // Lid Golden Rim
    canvas.drawPath(
      lidPath,
      Paint()
        ..shader = goldBandPaint.shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * scale,
    );

    // 4. Glowing Golden Coins Overflowing
    final coinPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF9C4), Color(0xFFFFD54F), Color(0xFFFF8F00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: 40 * scale, height: 20 * scale));

    final coinPositions = [
      Offset(cx - 16 * scale, cy - 2 * scale),
      Offset(cx - 8 * scale, cy - 6 * scale),
      Offset(cx, cy - 4 * scale),
      Offset(cx + 8 * scale, cy - 7 * scale),
      Offset(cx + 16 * scale, cy - 3 * scale),
      Offset(cx - 12 * scale, cy + 2 * scale),
      Offset(cx - 4 * scale, cy + 1 * scale),
      Offset(cx + 5 * scale, cy + 2 * scale),
      Offset(cx + 13 * scale, cy + 3 * scale),
      Offset(cx - 20 * scale, cy + 18 * scale),
      Offset(cx + 22 * scale, cy + 17 * scale),
    ];

    for (final pos in coinPositions) {
      canvas.drawOval(
        Rect.fromCenter(center: pos, width: 8.5 * scale, height: 6.0 * scale),
        coinPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: pos, width: 8.5 * scale, height: 6.0 * scale),
        Paint()
          ..color = const Color(0xFF7A3600)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8 * scale,
      );
    }

    // 5. Golden Center Latch / Lock Plate
    final lockRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 3 * scale), width: 9 * scale, height: 11 * scale),
      Radius.circular(2.5 * scale),
    );
    canvas.drawRRect(lockRect, goldBandPaint);
    canvas.drawCircle(Offset(cx, cy + 4.5 * scale), 1.6 * scale, Paint()..color = const Color(0xFF381A00));

    // 6. Floating Coins in Air
    final floatingCoins = [
      Offset(cx - 26 * scale, cy - 14 * scale),
      Offset(cx + 28 * scale, cy - 12 * scale),
      Offset(cx + 34 * scale, cy + 4 * scale),
    ];
    for (final pos in floatingCoins) {
      canvas.drawOval(
        Rect.fromCenter(center: pos, width: 7.5 * scale, height: 5.5 * scale),
        coinPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: pos, width: 7.5 * scale, height: 5.5 * scale),
        Paint()
          ..color = const Color(0xFF7A3600)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7 * scale,
      );
    }

    // 7. Twinkling Sparkles
    _drawSparkle(canvas, Offset(cx - 20 * scale, cy - 20 * scale), 4.5 * scale);
    _drawSparkle(canvas, Offset(cx + 24 * scale, cy - 22 * scale), 5.0 * scale);
    _drawSparkle(canvas, Offset(cx + 2 * scale, cy - 12 * scale), 4.0 * scale);
    _drawSparkle(canvas, Offset(cx + 36 * scale, cy - 4 * scale), 3.5 * scale);
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const RadialGradient(
          colors: [Colors.white, Color(0xFFFFD54F), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. 3D Illuminated Circular Pedestal Stage Empty State
class _PedestalStagePainter extends CustomPainter {
  const _PedestalStagePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.65;
    final scale = (size.width / 200.0).clamp(0.65, 1.35);

    // 1. Purple / Blue Ambient Glow behind stage
    final glowRadius = 55.0 * scale;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0x667C4DFF),
          Color(0x3300E5FF),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy - 15 * scale), radius: glowRadius));
    canvas.drawCircle(Offset(cx, cy - 15 * scale), glowRadius, glowPaint);

    // 2. Lower Pedestal Tier (Elliptical podium)
    final lowerRect = Rect.fromCenter(center: Offset(cx, cy + 12 * scale), width: 140 * scale, height: 42 * scale);
    final lowerPath = Path()..addOval(lowerRect);
    canvas.drawPath(
      lowerPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF2A166A), Color(0xFF130938)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(lowerRect),
    );
    canvas.drawOval(
      lowerRect,
      Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * scale,
    );

    // 3. Upper Pedestal Tier
    final upperRect = Rect.fromCenter(center: Offset(cx, cy), width: 116 * scale, height: 34 * scale);
    canvas.drawOval(
      upperRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF651FFF), Color(0xFF311B92)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(upperRect),
    );
    canvas.drawOval(
      upperRect,
      Paint()
        ..color = const Color(0xFF80D8FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 * scale,
    );

    // 4. Stacks of 3D Gold Coins on Left & Right
    _drawCoinStack(canvas, Offset(cx - 36 * scale, cy - 4 * scale), scale);
    _drawCoinStack(canvas, Offset(cx + 36 * scale, cy - 4 * scale), scale);

    // 5. Center 3D Passbook Document Card with Wallet Emblem
    _drawPassbookCard(canvas, Offset(cx, cy - 24 * scale), scale);

    // 6. Floating Sparkles and Radiant Beams
    _drawSparkle(canvas, Offset(cx - 32 * scale, cy - 42 * scale), 4.5 * scale);
    _drawSparkle(canvas, Offset(cx + 32 * scale, cy - 42 * scale), 4.5 * scale);
    _drawSparkle(canvas, Offset(cx, cy - 54 * scale), 5.5 * scale);
    _drawSparkle(canvas, Offset(cx - 48 * scale, cy + 8 * scale), 4.0 * scale);
    _drawSparkle(canvas, Offset(cx + 48 * scale, cy + 8 * scale), 4.0 * scale);
  }

  void _drawCoinStack(Canvas canvas, Offset baseCenter, double scale) {
    final coinPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF9C4), Color(0xFFFFD54F), Color(0xFFFF8F00)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCenter(center: baseCenter, width: 22 * scale, height: 26 * scale));

    final strokePaint = Paint()
      ..color = const Color(0xFF7A3600)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9 * scale;

    // 3 Coins stacked vertically
    for (int i = 0; i < 3; i++) {
      final y = baseCenter.dy - (i * 5.0 * scale);
      final r = Rect.fromCenter(center: Offset(baseCenter.dx, y), width: 18 * scale, height: 7 * scale);
      canvas.drawOval(r, coinPaint);
      canvas.drawOval(r, strokePaint);
    }
  }

  void _drawPassbookCard(Canvas canvas, Offset center, double scale) {
    final width = 36.0 * scale;
    final height = 46.0 * scale;
    final rect = Rect.fromCenter(center: center, width: width, height: height);

    // Card shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy + 3 * scale), width: width, height: height),
        Radius.circular(6 * scale),
      ),
      Paint()..color = const Color(0x66000000),
    );

    // White / Silver Document Body
    final bodyRRect = RRect.fromRectAndRadius(rect, Radius.circular(6 * scale));
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFECEFF1), Color(0xFFCFD8DC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect),
    );
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..color = const Color(0xFFB0BEC5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * scale,
    );

    // Center Gold Wallet Emblem on Passbook
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 20 * scale, height: 20 * scale),
      Radius.circular(4 * scale),
    );
    canvas.drawRRect(
      badgeRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF0F1E4A), Color(0xFF060B22)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(badgeRect.outerRect),
    );
    canvas.drawRRect(
      badgeRect,
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * scale,
    );

    // Mini Golden Wallet inside badge
    final walletPaint = Paint()..color = const Color(0xFFFFD54F);
    final walletRect = Rect.fromCenter(center: center, width: 11 * scale, height: 8 * scale);
    canvas.drawRRect(RRect.fromRectAndRadius(walletRect, Radius.circular(1.5 * scale)), walletPaint);
    canvas.drawCircle(Offset(center.dx + 2.5 * scale, center.dy), 1.2 * scale, Paint()..color = const Color(0xFF0F1E4A));
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const RadialGradient(
          colors: [Colors.white, Color(0xFFFFD54F), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
