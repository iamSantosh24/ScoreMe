import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scorer/services/league_service.dart';
import 'package:scorer/models/role_models.dart';

class FakeSecureStorage {
  final Map<String, String> data;
  FakeSecureStorage(this.data);
  Future<String?> read({required String key}) async => data[key];
}

void main() {
  group('LeagueService', () {
    test('createLeague returns true on 201', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, contains('/add-league'));
        return http.Response('', 201);
      });

      final storage = FakeSecureStorage({'auth_token': 'abc'});
      final service = LeagueService(baseUrl: 'http://example.com', client: mockClient, storage: storage);

      final ok = await service.createLeague(leagueName: 'L', sport: 'cricket', status: 'scheduled');
      expect(ok, isTrue);
    });

    test('fetchTeams parses teams', () async {
      final mockClient = MockClient((request) async {
        final body = json.encode([
          {'teamId': 't1', 'teamName': 'Team 1'},
          {'teamId': 't2', 'teamName': 'Team 2'},
        ]);
        return http.Response(body, 200);
      });

      final service = LeagueService(baseUrl: 'http://example.com', client: mockClient, storage: FakeSecureStorage({}));
      final teams = await service.fetchTeams();
      expect(teams.length, 2);
      expect(teams[0].id, 't1');
      expect(teams[0].name, 'Team 1');
    });
  });
}

