import 'package:flutter_test/flutter_test.dart';
import 'package:scorer/models/role_models.dart';

void main() {
  test(r'User.fromJson parses god_admin and $oid-like _id correctly', () {
    final Map<String, dynamic> json = {
      '_id': {
        r'$oid': '68e883011823434365dad876',
      },
      'firstName': 'Test',
      'lastName': 'Godadmin',
      'email': 'test@godadmin.com',
      'god_admin': true,
      'roles': [
        {
          'leagueId': null,
          'teamId': null,
          'role': 'player',
          '_id': {
            r'$oid': '68e883011823434365dad877'
          }
        }
      ],
    };

    final user = User.fromJson(json);
    expect(user.id, '68e883011823434365dad876');
    expect(user.godAdmin, isTrue);
    expect(user.roles.length, 1);
    expect(user.roles.first.role, 'player');
  });
}
