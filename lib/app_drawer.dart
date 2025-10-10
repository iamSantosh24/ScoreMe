import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorer/update_admin_screen.dart';
import 'package:scorer/update_super_admin_screen.dart';
import 'package:scorer/update_teams_screen.dart';
import 'package:scorer/viewmodels/NotificationsViewModel.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'login_screen.dart';
import 'live_score_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AppDrawer extends StatelessWidget {
  final String role;
  final String email;
  const AppDrawer({super.key, required this.role, required this.email});

  Future<void> _selectLeagueAndNavigate(BuildContext context) async {
    final response = await http.get(Uri.parse('http://192.168.1.134:3000/leagues'));
    if (response.statusCode == 200) {
      final List leagues = json.decode(response.body);
      showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return ListView.builder(
            itemCount: leagues.length,
            itemBuilder: (context, index) {
              final league = leagues[index];
              return ListTile(
                title: Text(league['name'] ?? ''),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UpdateTeamsScreen(
                        leagueId: league['_id'],
                        leagueName: league['name'] ?? '',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to fetch leagues')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepPurple),
            child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
            },
          ),
          if (role == 'god_admin') ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Update Super Admin'),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => UpdateSuperAdminScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Update Admin'),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => UpdateAdminScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_work),
              title: const Text('Update Teams'),
              onTap: () {
                _selectLeagueAndNavigate(context);
              },
            ),
          ],
          if (role == 'super_admin') ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Update Admin'),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => UpdateAdminScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_work),
              title: const Text('Update Teams'),
              onTap: () {
                _selectLeagueAndNavigate(context);
              },
            ),
          ],
          if (role == 'admin') ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.group_work),
              title: const Text('Update Teams'),
              onTap: () {
                _selectLeagueAndNavigate(context);
              },
            ),
          ],
          // Notifications should be visible for any role
          Consumer<NotificationsViewModel>(
            builder: (context, vm, _) {
              return ListTile(
                leading: Stack(
                  children: [
                    const Icon(Icons.notifications),
                    if (vm.unreadCount > 0)
                      Positioned(
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            vm.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                title: const Text('Notifications'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NotificationsScreen(role: role, userId: email),
                    ),
                  );
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.sports_score),
            title: const Text('Start Scoring'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => LiveScoreScreen(
                  sportType: '', // Will be selected in the screen
                  gameData: {}, // Will be selected in the screen
                  role: role, // Pass the user role
                  username: email, // Pass the actual username
                ),
              ));
            },
          ),
        ],
      ),
    );
  }
}