import 'package:flutter/material.dart';
import 'tournament_details_screen.dart';
import 'existing_tournaments_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TournamentManagementScreen extends StatefulWidget {
  const TournamentManagementScreen({super.key});

  @override
  State<TournamentManagementScreen> createState() => _TournamentManagementScreenState();
}

class _TournamentManagementScreenState extends State<TournamentManagementScreen> {
  void _showCreateTournamentDialog() {
    final TextEditingController dialogController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Tournament'),
          content: TextField(
            controller: dialogController,
            decoration: const InputDecoration(labelText: 'Tournament Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = dialogController.text.trim();
                if (name.isEmpty) return;
                final response = await http.post(
                  Uri.parse('http://192.168.1.134:3000/tournaments'),
                  headers: {'Content-Type': 'application/json'},
                  body: '{"name":"$name"}',
                );
                if (response.statusCode == 200) {
                  final data = json.decode(response.body);
                  final tournament = data['tournament'];
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TournamentDetailsScreen(
                        tournamentName: tournament['name'],
                        tournamentId: tournament['_id'],
                      ),
                    ),
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
      appBar: AppBar(title: const Text('Tournament Management')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _showCreateTournamentDialog,
              child: const Text('Create Tournament'),
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
