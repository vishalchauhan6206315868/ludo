import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/core/network/api_config.dart';
import 'package:ludo/core/network/api_service.dart';
import 'package:ludo/models/leaderboard_model.dart';
import 'package:ludo/screens/leaderboard_screen.dart';

class FakeTestApiService implements ApiService {
  final Map<String, dynamic>? leaderboardResponse;
  final Map<String, dynamic>? meResponse;
  final Map<String, dynamic>? updateResultResponse;

  FakeTestApiService({
    this.leaderboardResponse,
    this.meResponse,
    this.updateResultResponse,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Map<String, dynamic>> getLeaderboard({int limit = 50}) async {
    return leaderboardResponse ??
        {
          'success': true,
          'statusCode': 200,
          'message': 'Leaderboard fetched successfully',
          'data': {
            'leaderboard': [
              {
                'rank': 1,
                'user': {
                  'id': 'user_01',
                  'name': 'Ludo Champion',
                  'avatar': '',
                },
                'score': 2000,
                'wins': 20,
                'gamesPlayed': 25,
              },
            ],
            'currentUser': {
              'rank': 1,
              'score': 2000,
              'wins': 20,
              'gamesPlayed': 25,
            },
          },
        };
  }

  @override
  Future<Map<String, dynamic>> getMyLeaderboard() async {
    return meResponse ??
        {
          'success': true,
          'statusCode': 200,
          'message': 'User ranking fetched successfully',
          'data': {
            'rank': 1,
            'score': 2000,
            'wins': 20,
            'losses': 5,
            'gamesPlayed': 25,
          },
        };
  }

  @override
  Future<Map<String, dynamic>> updateLeaderboardResult({
    required String result,
  }) async {
    return updateResultResponse ??
        {
          'success': true,
          'statusCode': 200,
          'message': 'Game result updated successfully',
          'data': {
            'score': 2100,
            'wins': 21,
            'losses': 5,
            'gamesPlayed': 26,
          },
        };
  }
}

void main() {
  group('Leaderboard API & Models Test Suite', () {
    test('ApiConfig contains the 3 exact required leaderboard endpoints', () {
      expect(ApiConfig.leaderboard, equals('/leaderboard'));
      expect(ApiConfig.leaderboardMe, equals('/leaderboard/me'));
      expect(ApiConfig.leaderboardUpdateResult, equals('/leaderboard/update-result'));
    });

    test('LeaderboardEntry and LeaderboardUser correctly parse backend contract', () {
      final sampleBackendJson = {
        'rank': 1,
        'user': {
          'id': '673f1234567890abcdef1234',
          'name': 'Master Ludo',
          'avatar': 'https://example.com/avatar.png',
        },
        'score': 1500,
        'wins': 120,
        'gamesPlayed': 180,
      };

      final entry = LeaderboardEntry.fromJson(sampleBackendJson);
      expect(entry.rank, equals(1));
      expect(entry.user.id, equals('673f1234567890abcdef1234'));
      expect(entry.user.name, equals('Master Ludo'));
      expect(entry.user.avatar, equals('https://example.com/avatar.png'));
      expect(entry.score, equals(1500));
      expect(entry.wins, equals(120));
      expect(entry.gamesPlayed, equals(180));
    });

    test('UserRanking parses GET /api/leaderboard/me response structure', () {
      final sampleMeJson = {
        'rank': 25,
        'score': 850,
        'wins': 50,
        'losses': 30,
        'gamesPlayed': 80,
      };

      final me = UserRanking.fromJson(sampleMeJson);
      expect(me.rank, equals(25));
      expect(me.score, equals(850));
      expect(me.wins, equals(50));
      expect(me.losses, equals(30));
      expect(me.gamesPlayed, equals(80));
    });

    test('LeaderboardEntry handles fallback values when user is null or missing fields', () {
      final emptyJson = <String, dynamic>{
        'rank': null,
        'user': null,
        'score': null,
        'wins': null,
        'gamesPlayed': null,
      };

      final entry = LeaderboardEntry.fromJson(emptyJson);
      expect(entry.rank, equals(0));
      expect(entry.user.name, equals('Player'));
      expect(entry.user.avatar, isEmpty);
      expect(entry.score, equals(0));
      expect(entry.wins, equals(0));
      expect(entry.gamesPlayed, equals(0));
    });

    test('ApiService exposes the 3 required leaderboard methods', () {
      final apiService = ApiService();
      expect(apiService.getLeaderboard, isNotNull);
      expect(apiService.getMyLeaderboard, isNotNull);
      expect(apiService.updateLeaderboardResult, isNotNull);
    });

    testWidgets('LeaderboardScreen renders properly with populated data', (WidgetTester tester) async {
      final fakeApi = FakeTestApiService();

      await tester.pumpWidget(
        MaterialApp(
          home: LeaderboardScreen(apiService: fakeApi),
        ),
      );

      // Settle async fetch
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('LEADERBOARD'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events_rounded), findsWidgets);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      // Verify Player Tile
      expect(find.text('Ludo Champion'), findsOneWidget);
      expect(find.text('Wins: 20 • Matches: 25'), findsOneWidget);
      expect(find.text('2000 pts'), findsOneWidget);

      // Verify Bottom "My Position" Banner
      expect(find.text('MY POSITION'), findsOneWidget);
      expect(find.text('Rank #1'), findsOneWidget);
      expect(find.text('Wins: 20 • Losses: 5 • Matches: 25'), findsOneWidget);
    });

    testWidgets('LeaderboardScreen displays error state and retry on API failure', (WidgetTester tester) async {
      final errorApi = FakeTestApiService(
        leaderboardResponse: {
          'success': false,
          'statusCode': 500,
          'message': 'Database connection error',
          'data': null,
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LeaderboardScreen(apiService: errorApi),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Database connection error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('LeaderboardScreen displays empty state when leaderboard is empty', (WidgetTester tester) async {
      final emptyApi = FakeTestApiService(
        leaderboardResponse: {
          'success': true,
          'statusCode': 200,
          'message': 'Success',
          'data': {
            'leaderboard': [],
            'currentUser': {
              'rank': 1,
              'score': 0,
              'wins': 0,
              'gamesPlayed': 0,
            },
          },
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LeaderboardScreen(apiService: emptyApi),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No leaderboard rankings yet.'), findsOneWidget);
    });
  });
}
