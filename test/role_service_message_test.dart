import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scorer/services/role_service.dart';

class FakeSecureStorage {
  final Map<String, String> data;
  FakeSecureStorage(this.data);
  Future<String?> read({required String key}) async => data[key];
}

void main() {
  test('assignRoleToUser surfaces server message when provided', () async {
    final mockClient = MockClient((request) async {
      final body = json.encode({'message': 'Custom server message'});
      return http.Response(body, 200);
    });

    final storage = FakeSecureStorage({'auth_token': 'tok'});
    final service = RoleService(baseUrl: 'http://example.com', client: mockClient, storage: storage);

    final resp = await service.assignRoleToUser(userId: 'u1', role: 'player');
    expect(resp, isA<Map<String, dynamic>>());
    expect(resp['ok'], isTrue);
    expect(resp['message'], 'Custom server message');
  });
}

