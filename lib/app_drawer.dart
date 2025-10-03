import 'package:flutter/material.dart';
import 'package:scorer/update_admin_screen.dart';
import 'package:scorer/update_super_admin_screen.dart';
import 'package:scorer/update_teams_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'login_screen.dart';

class AppDrawer extends StatelessWidget {
  final String role;
  const AppDrawer({super.key, required this.role});

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
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => UpdateTeamsScreen()));
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
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => UpdateTeamsScreen()));
              },
            ),
          ],
          if (role == 'admin') ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.group_work),
              title: const Text('Update Teams'),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => UpdateTeamsScreen()));
              },
            ),
          ],
          // Notifications should be visible for any role
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => NotificationsScreen()));
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
        ],
      ),
    );
  }
}
