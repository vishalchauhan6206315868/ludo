class ApiConfig {
  ApiConfig._();

  // Local backend configuration (Commented out for Production)
  // static const int port = 4000;
  // static const String localWifiIp = '192.168.1.17';

  // Production Api Url
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://ludoapi-3.onrender.com/api',
  );

  static String? customBaseUrl;
  static String? _activeBaseUrl;

  /// Socket.IO runs on the same host as the REST API, just without the `/api` path.
  static String get socketUrl {
    String pick() {
      if (_activeBaseUrl != null && _activeBaseUrl!.trim().isNotEmpty) return _activeBaseUrl!.trim();
      if (customBaseUrl != null && customBaseUrl!.trim().isNotEmpty) return customBaseUrl!.trim();
      return defaultBaseUrl;
    }

    var url = pick();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.endsWith('/api')) {
      url = url.substring(0, url.length - 4);
    }
    return url;
  }

  static void setActiveBaseUrl(String url) {
    _activeBaseUrl = url.trim();
  }

  static List<String> get candidateBaseUrls {
    final list = <String>[];

    if (customBaseUrl != null && customBaseUrl!.trim().isNotEmpty) {
      list.add(customBaseUrl!.trim());
    }

    if (_activeBaseUrl != null && _activeBaseUrl!.trim().isNotEmpty) {
      if (!list.contains(_activeBaseUrl!.trim())) {
        list.add(_activeBaseUrl!.trim());
      }
    }

    // Production URL as primary candidate
    if (!list.contains(defaultBaseUrl)) {
      list.add(defaultBaseUrl);
    }

    // Local candidates (commented out for production):
    // final standardCandidates = [
    //   'http://$localWifiIp:$port/api',
    //   'http://10.0.2.2:$port/api',
    //   'http://localhost:$port/api',
    // ];
    // for (final candidate in standardCandidates) {
    //   if (!list.contains(candidate)) {
    //     list.add(candidate);
    //   }
    // }

    return list;
  }

  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.trim().isNotEmpty) {
      return customBaseUrl!.trim();
    }

    return _activeBaseUrl ?? defaultBaseUrl;
  }

  // Endpoints
  static const String health = '/health';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String profile = '/users/me';

  static const String createRoom = '/rooms/create';
  static const String joinRoom = '/rooms/join';
  static const String leaveRoom = '/rooms/leave';
  static const String myActiveRoom = '/rooms/me/active';

  static String getRoom(String roomCode) =>
      '/rooms/${roomCode.trim()}';

  static const String startGame = '/games/start';

  static String getSession(String sessionId) =>
      '/games/session/${sessionId.trim()}';

  static String rollDice(String sessionId) =>
      '/games/session/${sessionId.trim()}/roll-dice';

  static String moveToken(String sessionId) =>
      '/games/session/${sessionId.trim()}/move-token';

  static String timeoutGame(String sessionId) =>
      '/games/session/${sessionId.trim()}/timeout';

  static String surrenderGame(String sessionId) =>
      '/games/session/${sessionId.trim()}/surrender';

  static String completeGame(String sessionId) =>
      '/games/session/${sessionId.trim()}/complete';

  static String myGameHistory({
    int page = 1,
    int limit = 10,
  }) =>
      '/games/history/my-games?page=$page&limit=$limit';

  static const String leaderboard = '/leaderboard';
  static const String leaderboardMe = '/leaderboard/me';
  static const String leaderboardUpdateResult =
      '/leaderboard/update-result';

  static const String rewards = '/rewards';
  static const String rewardsMe = '/rewards/me';
  static const String rewardsSummary = '/rewards/summary';

  static String claimReward(String rewardId) =>
      '/rewards/${rewardId.trim()}/claim';

  // Razorpay Configuration
  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: '',
  );

  // Wallet & Payment Endpoints
  static const String wallet = '/wallet';
  static const String walletMe = '/wallet/me';
  static const String walletTransactions =
      '/wallet/transactions';

  static String walletTransactionsPaginated({
    int page = 1,
    int limit = 20,
  }) =>
      '/wallet/transactions?page=$page&limit=$limit';

  // Deposit (Razorpay) Endpoints
  static const String walletDepositCreateOrder = '/wallet/deposit/create-order';
  static const String walletDepositVerify = '/wallet/deposit/verify';

  static String walletDepositHistory({
    int page = 1,
    int limit = 20,
  }) =>
      '/wallet/deposit/history?page=$page&limit=$limit';

  // Withdrawal Endpoints
  static const String walletWithdrawRequest = '/wallet/withdraw/request';

  static String walletWithdrawHistory({
    int page = 1,
    int limit = 20,
  }) =>
      '/wallet/withdraw/history?page=$page&limit=$limit';
}