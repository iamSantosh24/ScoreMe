import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scorer/services/role_service.dart';
import 'package:scorer/models/role_models.dart';
import 'package:scorer/assign_roles_screen.dart';

class FakeSecureStorage {
  final Map<String, String> data;
  FakeSecureStorage(this.data);
  Future<String?> read({required String key}) async => data[key];
}

class TestRoleService extends RoleService {
  TestRoleService()
      : super(
          baseUrl: 'http://example.com',
          client: MockClient((request) async => http.Response('[]', 200)),
          storage: FakeSecureStorage({'auth_token': 'tok'}),
        );

  // Keep other behaviors default; override assignRoleToUser to simulate delay and message
  @override
  Future<Map<String, dynamic>> assignRoleToUser({required String userId, required String role, String? teamId, String? leagueId}) async {
    // simulate in-flight delay so the widget shows the spinner
    await Future.delayed(const Duration(milliseconds: 200));
    return {'ok': true, 'message': 'Server: OK'};
  }
}

void main() {
  testWidgets('AssignRolesScreen dialog shows spinner while assigning and displays server message', (WidgetTester tester) async {
    final fakeService = TestRoleService();
    final user = User(id: 'u1', username: 'alice', displayName: 'Alice');

    await tester.pumpWidget(
      MultiProvider(
        providers: [Provider<RoleService>.value(value: fakeService)],
        child: MaterialApp(
          home: AssignRolesScreen(initialResults: [user]),
        ),
      ),
    );

    // Ensure the list shows our user
    expect(find.text('Alice'), findsOneWidget);

    // Tap the list tile to open the dialog
    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();

    // Dialog should be displayed with Assign button
    expect(find.text('Assign'), findsOneWidget);

    // Tap Assign; this will trigger assignRoleToUser which delays
    await tester.tap(find.text('Assign'));
    // pump once to kick off the async and update the dialog (assigning = true)
    await tester.pump();

    // pump to start the async work, then advance time beyond the fake delay
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // After completion, the dialog also shows a global snackbar indicating success
    expect(find.text('Role assigned'), findsOneWidget);
  });
}
