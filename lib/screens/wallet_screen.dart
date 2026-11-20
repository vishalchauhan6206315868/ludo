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

  const WalletScreen({
    super.key,
    this.apiService,
    this.onWalletUpdated,
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
      if (walletRes['success'] != true && txRes['success'] != true) {
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
      if (walletRes['success'] == true && walletRes['data'] != null) {
        parsedWallet = WalletModel.fromApiResponse(walletRes);
      }

      // 2. Parse Transactions Response
      WalletTransactionsResponse parsedTx = const WalletTransactionsResponse();
      if (txRes['success'] == true) {
        parsedTx = WalletTransactionsResponse.fromApiResponse(txRes);
        // Fallback balance if wallet endpoint didn't provide it
        if (parsedWallet.balance == 0 && parsedTx.balance > 0) {
          parsedWallet = parsedWallet.copyWith(balance: parsedTx.balance);
        }
      }

      // Notify parent callback if wallet balance updated
      widget.onWalletUpdated?.call();

      setState(() {
        _wallet = parsedWallet;
        _transactions = parsedTx.transactions;
        _pagination = parsedTx.pagination;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "An unexpected error occurred: $e";
      });
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
            Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFFFD700), size: 22),
            SizedBox(width: 8),
            Text(
              "MY WALLET",
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
            tooltip: "Refresh Wallet",
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFFD700), size: 22),
            onPressed: _isLoading ? null : _fetchInitialData,
          ),
        ],
      ),
      body: SafeArea(
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

        // Wallet Metadata Info Card
        if (_wallet.id.isNotEmpty || _wallet.createdAt != null)
          SliverToBoxAdapter(
            child: _buildWalletInfoCard(),
          ),

        // Filter Tabs
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
            Color(0xFF1B2A4A),
            Color(0xFF121D33),
            Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          const BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFFFFD700),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AVAILABLE BALANCE",
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        "Game Coins for Matches & Entry",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 12),
                    SizedBox(width: 4),
                    Text(
                      "ACTIVE",
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.monetization_on_rounded,
                color: Color(0xFFFFD700),
                size: 34,
              ),
              const SizedBox(width: 8),
              Text(
                _formatNumber(_wallet.balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "COINS",
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 14),
          // Action Buttons: Row 1 (Add Cash & Withdraw)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddCashBottomSheet,
                  icon: const Icon(Icons.add_circle_rounded, size: 18),
                  label: const Text(
                    "Add Cash",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showWithdrawBottomSheet,
                  icon: const Icon(Icons.account_balance_rounded, size: 18),
                  label: const Text(
                    "Withdraw",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: const Color(0xFFFFD700),
                    side: const BorderSide(color: Color(0xFFFFD700), width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Action Buttons: Row 2 (Earn Free Coins & Sync)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
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
                  icon: const Icon(Icons.card_giftcard_rounded, size: 16, color: Color(0xFFFFD700)),
                  label: const Text(
                    "Earn Free Coins",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _fetchInitialData,
                icon: const Icon(Icons.sync_rounded, size: 16, color: Colors.white70),
                label: const Text(
                  "Sync",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF101A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
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
        duration: const Duration(milliseconds: 180),
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
              size: 14,
              color: isSelected ? const Color(0xFF091428) : const Color(0xFF90A4AE),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF091428) : const Color(0xFF90A4AE),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 11,
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
                    Text(
                      tx.createdAt != null
                          ? _formatDateTime(tx.createdAt!)
                          : "Recently",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
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
                Row(
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
                    const SizedBox(width: 6),
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
                    if (tx.source.isNotEmpty && tx.source != 'other') ...[
                      const SizedBox(width: 6),
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
            "• End of Transaction History •",
            style: TextStyle(color: Colors.white24, fontSize: 11),
          ),
        ),
      );
    }

    return const SizedBox(height: 24);
  }

  // --- 6. Empty State View ---
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF141F36),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFFFFD700),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "No Transactions Yet",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Play matches or claim daily rewards to start building your coin history!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
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
              icon: const Icon(Icons.card_giftcard_rounded, size: 16),
              label: const Text("Claim Free Rewards"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF0D1424),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
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
                            "₹",
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
                            "+ ₹$amt",
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
                        "PROCEED TO PAY ₹$enteredAmount",
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
        name: "Ludo Supreme",
        description: "Deposit ₹$amount (Coins: $amount)",
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
                                "Available Balance: ₹$availableBalance",
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
                          labelText: "Withdrawal Amount (₹)",
                          labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              "₹",
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
                              label: const Text("₹100"),
                              backgroundColor: const Color(0xFF141F36),
                              labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                              side: const BorderSide(color: Colors.white12),
                              onPressed: () {
                                setModalState(() => amountController.text = "100");
                              },
                            ),
                          if (availableBalance >= 500)
                            ActionChip(
                              label: const Text("₹500"),
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
              "Your withdrawal request of ₹$amount has been submitted successfully.${requestNo != null ? '\nRequest No: $requestNo' : ''}\nStatus: Pending Admin Approval.",
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
                "₹$amount has been added to your wallet balance.",
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
