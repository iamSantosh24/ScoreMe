import 'package:flutter/material.dart';
import 'tournament_details_screen.dart';
import 'existing_tournaments_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LeagueManagementScreen extends StatefulWidget {
  const LeagueManagementScreen({super.key});

  @override
  State<LeagueManagementScreen> createState() => _LeagueManagementScreenState();
}

class _LeagueManagementScreenState extends State<LeagueManagementScreen> {
  void _showCreateLeagueDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController sportController = TextEditingController();
    final TextEditingController regionController = TextEditingController();
    final TextEditingController statusController = TextEditingController(text: 'active');
    final TextEditingController teamsController = TextEditingController();
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
                TextField(
                  controller: sportController,
                  decoration: const InputDecoration(labelText: 'Sport'),
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
                final sport = sportController.text.trim();
                final region = regionController.text.trim();
                final status = statusController.text.trim();
                final teams = teamsController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                if (name.isEmpty || sport.isEmpty || region.isEmpty || status.isEmpty || teams.isEmpty) return;
                final response = await http.post(
                  Uri.parse('http://192.168.1.134:3000/leagues'),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({
                    'name': name,
                    'sport': sport,
                    'region': region,
                    'status': status,
                    'teams': teams,
                    'createdAt': DateTime.now().toUtc().toIso8601String(),
                  }),
                );
                if (response.statusCode == 200) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('League Management')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    builder: (context) => const ExistingTournamentsScreen(),
                  ),
                );
              },
              child: const Text('Existing Tournament'),
            ),
          ],
        ),
      ),
    );
  }
}
