import 'package:flutter/material.dart';
import 'package:scorer/viewmodels/NotificationsViewModel.dart';
import 'existing_leagues_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

class LeagueManagementScreen extends StatefulWidget {
  const LeagueManagementScreen({super.key});

  @override
  State<LeagueManagementScreen> createState() => _LeagueManagementScreenState();
}

class _LeagueManagementScreenState extends State<LeagueManagementScreen> {
  void _showCreateLeagueDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController regionController = TextEditingController();
    final TextEditingController statusController = TextEditingController(text: 'active');
    final TextEditingController teamsController = TextEditingController();
    String selectedSport = 'Throw Ball';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create League'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'League Name'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedSport,
                  decoration: const InputDecoration(labelText: 'Sport'),
                  items: const [
                    DropdownMenuItem(value: 'Throw Ball', child: Text('Throw Ball')),
                    DropdownMenuItem(value: 'Cricket', child: Text('Cricket')),
                  ],
                  onChanged: (value) {
                    if (value != null) selectedSport = value;
                  },
                ),
                TextField(
                  controller: regionController,
                  decoration: const InputDecoration(labelText: 'Region'),
                ),
                TextField(
                  controller: statusController,
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
                TextField(
                  controller: teamsController,
                  decoration: const InputDecoration(labelText: 'Teams (comma separated)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final sport = selectedSport;
                final region = regionController.text.trim();
                final status = statusController.text.trim();
                final teams = teamsController.text.trim().isNotEmpty
                  ? teamsController.text.split(',').map((t) => t.trim()).toList()
                  : [];
                final response = await http.post(
                  Uri.parse('http://192.168.1.134:3000/leagues'),
                  headers: { 'Content-Type': 'application/json' },
                  body: json.encode({
                    'name': name,
                    'sport': sport,
                    'region': region,
                    'status': status,
                    'teams': teams,
                  }),
                );
                if (response.statusCode == 200) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('League created successfully')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create league')));
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Assume user role and username are passed via ModalRoute arguments or Provider
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final role = args?['role'] ?? '';
    final username = args?['username'] ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('League Management')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (role != 'admin' && role != 'super_admin' && role != 'god_admin')
              ChangeNotifierProvider(
                create: (_) => NotificationsViewModel(),
                child: Consumer<NotificationsViewModel>(
                  builder: (context, vm, _) {
                    return Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.admin_panel_settings),
                          label: const Text('Request Admin'),
                          onPressed: () async {
                            final success = await vm.sendPermissionRequest(
                              username,
                              'admin',
                              'League Management',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(success ? 'Admin request sent!' : 'Failed to send request')),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.security),
                          label: const Text('Request Super Admin'),
                          onPressed: () async {
                            final success = await vm.sendPermissionRequest(
                              username,
                              'super_admin',
                              'League Management',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(success ? 'Super Admin request sent!' : 'Failed to send request')),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ElevatedButton(
              onPressed: _showCreateLeagueDialog,
              child: const Text('Create League'),
            ),
            const Divider(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExistingLeaguesScreen(),
                  ),
                );
              },
              child: const Text('Existing Leagues'),
            ),
          ],
        ),
      ),
    );
  }
}
