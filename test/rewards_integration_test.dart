import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/core/network/api_config.dart';
import 'package:ludo/core/network/api_service.dart';
import 'package:ludo/models/reward_model.dart';
import 'package:ludo/screens/rewards_screen.dart';

class FakeTestApiService implements ApiService {
  final Map<String, dynamic>? rewardsResponse;
  final Map<String, dynamic>? myRewardsResponse;
  final Map<String, dynamic>? summaryResponse;
  final Map<String, dynamic>? claimResponse;
  String? lastClaimedId;

  FakeTestApiService({
    this.rewardsResponse,
    this.myRewardsResponse,
    this.summaryResponse,
    this.claimResponse,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Map<String, dynamic>> getRewards() async {
    return rewardsResponse ??
        {
          'success': true,
          'statusCode': 200,
          'message': 'Rewards fetched successfully',
          'data': {
            'rewards': [
              {
                '_id': 'reward_01',
                'title': 'Daily Login Reward',
                'description': 'Login daily and claim your reward',
                'rewardType': 'coins',
                'rewardValue': 100,
                'icon': 'daily_login',
                'isClaimed': false,
                'canClaim': true,
              },
              {
                '_id': 'reward_02',
                'title': 'Welcome Bonus',
                'description': 'Starter bonus',
                'rewardType': 'coins',
                'rewardValue': 500,
                'icon': 'welcome_bonus',
                'isClaimed': true,
                'canClaim': false,
              },
            ],
          },
        };
  }

  @override
  Future<Map<String, dynamic>> getMyRewards() async {
    return myRewardsResponse ??
        {
          'success': true,
          'statusCode': 200,
          'message': 'Reward history fetched successfully',
          'data': {
            'rewards': [
              {
                'rewardId': 'reward_02',
                'title': 'Welcome Bonus',
                'rewardType': 'coins',
                'rewardValue': 500,
                'claimedAt': '2026-10-06T08:00:00.000Z',
              },
            ],
          },
        };
  }

  @override
  Future<Map<String, dynamic>> getRewardsSummary() async {
    return summaryResponse ??
        {
          'success': true,
          'statusCode': 200,
          'message': 'Rewards summary fetched successfully',
          'data': {
            'totalRewards': 10,
            'claimedRewards': 1,
            'availableRewards': 9,
            'totalCoinsEarned': 500,
          },
        };
  }

  @override
  Future<Map<String, dynamic>> claimReward(String rewardId) async {
    lastClaimedId = rewardId;
    return claimResponse ??
        {
          'success': true,
          'statusCode': 200,
          'message': 'Reward claimed successfully',
          'data': {
            'reward': {
              '_id': rewardId,
              'title': 'Daily Login Reward',
              'rewardType': 'coins',
              'rewardValue': 100,
            },
          },
        };
  }
}

void main() {
  group('Rewards API & Models Test Suite', () {
    test('ApiConfig contains the 4 exact required rewards endpoints', () {
      expect(ApiConfig.rewards, equals('/rewards'));
      expect(ApiConfig.rewardsMe, equals('/rewards/me'));
      expect(ApiConfig.rewardsSummary, equals('/rewards/summary'));
      expect(ApiConfig.claimReward('reward123'), equals('/rewards/reward123/claim'));
    });

    test('RewardItem correctly parses backend GET /rewards response', () {
      final sampleJson = {
        '_id': '6ac4affd5c52c8f5e056dedb',
        'title': 'Daily Login Reward',
        'description': 'Login daily and claim your reward',
        'rewardType': 'coins',
        'rewardValue': 100,
        'icon': 'daily_login',
        'isClaimed': false,
        'canClaim': true,
      };

      final reward = RewardItem.fromJson(sampleJson);
      expect(reward.id, equals('6ac4affd5c52c8f5e056dedb'));
      expect(reward.title, equals('Daily Login Reward'));
      expect(reward.description, equals('Login daily and claim your reward'));
      expect(reward.rewardType, equals('coins'));
      expect(reward.rewardValue, equals(100));
      expect(reward.icon, equals('daily_login'));
      expect(reward.isClaimed, isFalse);
      expect(reward.canClaim, isTrue);
    });

    test('UserRewardClaim correctly parses backend GET /rewards/me response', () {
      final sampleJson = {
        'rewardId': '6ac4affd5c52c8f5e056dedb',
        'title': 'Daily Login Reward',
        'rewardType': 'coins',
        'rewardValue': 100,
        'claimedAt': '2026-10-06T08:23:45.000Z',
      };

      final claim = UserRewardClaim.fromJson(sampleJson);
      expect(claim.rewardId, equals('6ac4affd5c52c8f5e056dedb'));
      expect(claim.title, equals('Daily Login Reward'));
      expect(claim.rewardType, equals('coins'));
      expect(claim.rewardValue, equals(100));
      expect(claim.claimedAt, isNotNull);
      expect(claim.claimedAt?.year, equals(2026));
    });

    test('RewardsSummary correctly parses backend GET /rewards/summary response', () {
      final sampleJson = {
        'totalRewards': 10,
        'claimedRewards': 2,
        'availableRewards': 8,
        'totalCoinsEarned': 350,
      };

      final summary = RewardsSummary.fromJson(sampleJson);
      expect(summary.totalRewards, equals(10));
      expect(summary.claimedRewards, equals(2));
      expect(summary.availableRewards, equals(8));
      expect(summary.totalCoinsEarned, equals(350));
    });

    test('RewardItem handles null / missing fields safely with defaults', () {
      final minimalJson = <String, dynamic>{};
      final item = RewardItem.fromJson(minimalJson);

      expect(item.id, equals(''));
      expect(item.title, equals('Reward'));
      expect(item.rewardType, equals('coins'));
      expect(item.rewardValue, equals(0));
      expect(item.isClaimed, isFalse);
    });
  });

  group('RewardsScreen Widget Tests', () {
    testWidgets('RewardsScreen renders properly with AppBar, Summary, and Rewards list',
        (WidgetTester tester) async {
      final fakeApi = FakeTestApiService();

      await tester.pumpWidget(
        MaterialApp(
          home: RewardsScreen(apiService: fakeApi),
        ),
      );

      // Settle async fetch
      await tester.pumpAndSettle();

      // Check AppBar Title
      expect(find.text('REWARDS & BONUSES'), findsOneWidget);

      // Check Summary Cards
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Claimed'), findsOneWidget);
      expect(find.text('Coins Earned'), findsOneWidget);
      expect(find.text('9'), findsOneWidget); // available
      expect(find.text('1'), findsOneWidget); // claimed
      expect(find.text('500'), findsOneWidget); // coins earned

      // Check Reward Items
      expect(find.text('Daily Login Reward'), findsOneWidget);
      expect(find.text('Welcome Bonus'), findsOneWidget);

      // Check Buttons
      expect(find.text('CLAIM'), findsOneWidget); // unclimed item has CLAIM
      expect(find.text('CLAIMED'), findsOneWidget); // claimed item has CLAIMED
    });

    testWidgets('Tapping CLAIM invokes POST /rewards/:id/claim and updates state',
        (WidgetTester tester) async {
      final fakeApi = FakeTestApiService();

      await tester.pumpWidget(
        MaterialApp(
          home: RewardsScreen(apiService: fakeApi),
        ),
      );

      await tester.pumpAndSettle();

      // Tap CLAIM on reward_01
      final claimBtn = find.text('CLAIM');
      expect(claimBtn, findsOneWidget);
      await tester.tap(claimBtn);
      await tester.pump(); // Start claim

      // Verify fake API claim was called with reward_01
      expect(fakeApi.lastClaimedId, equals('reward_01'));

      await tester.pumpAndSettle();

      // Feedback snackbar should be displayed
      expect(find.textContaining('Claimed Daily Login Reward!'), findsOneWidget);
    });

    testWidgets('Switching tabs displays My Rewards History',
        (WidgetTester tester) async {
      final fakeApi = FakeTestApiService();

      await tester.pumpWidget(
        MaterialApp(
          home: RewardsScreen(apiService: fakeApi),
        ),
      );

      await tester.pumpAndSettle();

      // Tap tab 1 (My History)
      final historyTab = find.textContaining('My History');
      expect(historyTab, findsOneWidget);
      await tester.tap(historyTab);
      await tester.pumpAndSettle();

      // Should show Welcome Bonus with +500 Coins in history
      expect(find.text('Welcome Bonus'), findsOneWidget);
      expect(find.text('+500 Coins'), findsOneWidget);
    });

    testWidgets('RewardsScreen shows error view and retry button on API failure',
        (WidgetTester tester) async {
      final fakeApi = FakeTestApiService(
        rewardsResponse: {
          'success': false,
          'statusCode': 500,
          'message': 'Failed to fetch rewards from server',
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RewardsScreen(apiService: fakeApi),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to fetch rewards from server'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
