import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scorer/services/role_service.dart';
import 'package:scorer/models/role_models.dart';
import 'package:scorer/assign_roles_screen.dart';

class DummyStorage {
  Future<String?> read({required String key}) async => 'tok';
}

class FakeRoleServiceForRolesTest extends RoleService {
  FakeRoleServiceForRolesTest()
      : super(
          baseUrl: 'http://example.com',
          client: null,
          storage: DummyStorage(),
        );

  @override
  Future<List<LeagueItem>> fetchLeagues() async {
    return [LeagueItem(id: 'YUTTXL8', name: 'Test League')];
  }

  @override
  Future<List<Team>> fetchTeams() async {
    return [Team(id: 'TEAM1', name: 'Test Team')];
  }

  @override
  Future<User?> getUserById(String userId) async {
    // Return a user with both a super_admin (league only) and an admin (league+team)
    final json = {
      '_id': 'u1',
      'username': 'test@example.com',
      'displayName': 'Test User',
      'firstName': 'Test',
      'lastName': 'User',
      'roles': [
        {'leagueId': null, 'teamId': null, 'role': 'player'},
        {'leagueId': 'YUTTXL8', 'teamId': null, 'role': 'super_admin'},
        {'leagueId': 'YUTTXL8', 'teamId': 'TEAM1', 'role': 'admin'},
      ],
    };
    return User.fromJson(json);
  }
}

void main() {
  testWidgets('AssignRolesScreen shows league/team for existing roles', (WidgetTester tester) async {
    final service = FakeRoleServiceForRolesTest();
    final initialUser = User(id: 'u1', username: 'test@example.com', displayName: 'Test User');

    await tester.pumpWidget(
      MultiProvider(
        providers: [Provider<RoleService>.value(value: service)],
        child: MaterialApp(home: AssignRolesScreen(initialResults: [initialUser])),
      ),
    );

    // Open the dialog (use the new Change roles button instead of tapping the name)
    await tester.tap(find.text('Change roles'));
    // Run a couple of frames to allow the dialog to build and the microtasks to run.
    await tester.pump();
    // Give time for the microtask that fetches user details and for subsequent name lookups.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Now the dialog should list existing roles including the super_admin and admin entries
    expect(find.text('Super Admin'), findsOneWidget);
    expect(find.textContaining('League: Test League'), findsWidgets);
    expect(find.textContaining('Team: Test Team'), findsOneWidget);
  });
}
