import 'package:flutter/material.dart';
import 'package:scorer/viewmodels/NotificationsViewModel.dart';
import 'existing_leagues_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'viewmodels/LeagueManagementViewModel.dart';

class LeagueManagementScreen extends StatefulWidget {
  const LeagueManagementScreen({super.key});

  @override
  State<LeagueManagementScreen> createState() => _LeagueManagementScreenState();
}

class _LeagueManagementScreenState extends State<LeagueManagementScreen> {
  void _showCreateLeagueDialog() {
    final TextEditingController leagueNameController = TextEditingController();
    String selectedSport = 'cricket';
    String selectedStatus = 'scheduled';
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<LeagueManagementViewModel>(
          builder: (context, vm, _) {
            return AlertDialog(
              title: const Text('Create League'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: leagueNameController,
                      decoration: const InputDecoration(labelText: 'League Name'),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedSport,
                      decoration: const InputDecoration(labelText: 'Sport'),
                      items: const [
                        DropdownMenuItem(value: 'cricket', child: Text('Cricket')),
                        DropdownMenuItem(value: 'throwball', child: Text('Throwball')),
                      ],
                      onChanged: (value) {
                        if (value != null) selectedSport = value;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                        DropdownMenuItem(value: 'ongoing', child: Text('Ongoing')),
                      ],
                      onChanged: (value) {
                        if (value != null) selectedStatus = value;
                      },
                    ),
                    if (vm.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: CircularProgressIndicator(),
                      ),
                    if (vm.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(vm.errorMessage!, style: const TextStyle(color: Colors.red)),
                      ),
                    if (vm.successMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(vm.successMessage!, style: const TextStyle(color: Colors.green)),
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
                  onPressed: vm.isLoading
                      ? null
                      : () async {
                          final leagueName = leagueNameController.text.trim();
                          if (leagueName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('League Name is required.')),
                            );
                            return;
                          }
                          final success = await vm.createLeague(
                            leagueName: leagueName,
                            sport: selectedSport,
                            status: selectedStatus,
                            teams: [],
                          );
                          if (success) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('League created successfully!')),
                            );
                          }
                        },
                  child: const Text('Create'),
                ),
              ],
            );
          },
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
    return ChangeNotifierProvider(
      create: (_) => LeagueManagementViewModel(),
      child: Scaffold(
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
      ),
    );
  }
}
