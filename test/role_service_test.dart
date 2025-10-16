import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scorer/services/role_service.dart';
import 'package:scorer/models/role_models.dart';

class FakeSecureStorage {
  final Map<String, String> data;
  FakeSecureStorage(this.data);

  // Provide a read method compatible with how RoleService calls it
  Future<String?> read({required String key}) async => data[key];
}

void main() {
  group('RoleService', () {
    test('searchUsers returns parsed users on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('GET'));
        final body = json.encode([
          {'_id': 'u1', 'username': 'alice', 'displayName': 'Alice'},
          {'_id': 'u2', 'username': 'bob', 'displayName': 'Bob'},
        ]);
        return http.Response(body, 200);
      });

      final service = RoleService(baseUrl: 'http://example.com', client: mockClient, storage: FakeSecureStorage({}));
      final results = await service.searchUsers('alice');
      expect(results, isA<List<User>>());
      expect(results.length, 2);
      expect(results[0].username, 'alice');
    });

    test('assignRoleToUser sends correct body and returns true on 201', () async {
      late http.Request captured;
      final mockClient = MockClient((request) async {
        captured = request;
        // return created
        return http.Response('', 201);
      });

      final storage = FakeSecureStorage({'auth_token': 'token123'});
      final service = RoleService(baseUrl: 'http://example.com', client: mockClient, storage: storage);

      final resp = await service.assignRoleToUser(userId: 'u1', role: 'admin', teamId: 't1');
      expect(resp, isA<Map<String, dynamic>>());
      expect(resp['ok'], isTrue);
      expect(resp['message'], 'Role assigned');

      // verify body
      final sent = json.decode((captured.body));
      expect(sent['userId'], 'u1');
      expect(sent['role'], 'admin');
      expect(sent['teamId'], 't1');

      // verify Authorization header present
      expect(captured.headers['authorization'], isNotNull);
    });
  });
}
