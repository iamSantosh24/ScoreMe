import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorer/viewmodels/NotificationsViewModel.dart';
import 'package:scorer/assign_roles_screen.dart';
import 'package:scorer/services/role_service.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'login_screen.dart';
import 'live_score_screen.dart';

class AppDrawer extends StatelessWidget {
  final String role;
  final String email;
  const AppDrawer({super.key, required this.role, required this.email});

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
          // Assign Roles entry — visible to god_admin and super_admin (and admin if desired)
          if (role == 'god_admin' || role == 'super_admin' || role == 'admin') ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.assignment_ind),
              title: const Text('Assign Roles'),
              onTap: () {
                // Obtain RoleService from Provider and navigate to the Assign Roles screen
                final service = Provider.of<RoleService>(context, listen: false);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AssignRolesScreen()));
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