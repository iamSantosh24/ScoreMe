import 'package:flutter/material.dart';
import 'navigation_utils.dart';
import 'data.dart';
import 'player_utils.dart';

class MatchCreationScreen extends StatefulWidget {
  final String league;

  const MatchCreationScreen({super.key, required this.league});

  @override
  State<MatchCreationScreen> createState() => _MatchCreationScreenState();
}

class _MatchCreationScreenState extends State<MatchCreationScreen> {
  String? team1;
  String? team2;
  String sportType = 'Cricket'; // Default sport type
  final TextEditingController _matchTitleController = TextEditingController();

  void _createMatch() {
    if (team1 == null || team2 == null || team1 == team2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select two different teams!'),
        ),
      );
      return;
    }

    if (_matchTitleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a match title!'),
        ),
      );
      return;
    }

    // Generate team rosters for the selected teams
    final Map<String, List<String>> teamPlayers = PlayerUtils.generateTeamPlayers([team1!, team2!]);

    openTossScreen(
      context,
      sportType: sportType,
      team1: team1!,
      team2: team2!,
      matchTitle: _matchTitleController.text,
      teamPlayers: teamPlayers,
    );
  }

  @override
  void dispose() {
    _matchTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> teams = leagueTeams[widget.league] ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Match'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Create New Match',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _matchTitleController,
                decoration: const InputDecoration(
                  labelText: 'Match Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButton<String>(
                hint: const Text('Select Sport Type'),
                value: sportType,
                isExpanded: true,
                items: ['Cricket', 'Throwball'].map((String sport) {
                  return DropdownMenuItem<String>(
                    value: sport,
                    child: Text(sport),
                  );
                }).toList(),
                onChanged: (value) => setState(() => sportType = value!),
              ),
              const SizedBox(height: 20),
              DropdownButton<String>(
                hint: const Text('Select Team 1'),
                value: team1,
                isExpanded: true,
                items: teams.map((String team) {
                  return DropdownMenuItem<String>(
                    value: team,
                    child: Text(team),
                  );
                }).toList(),
                onChanged: (value) => setState(() => team1 = value),
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                hint: const Text('Select Team 2'),
                value: team2,
                isExpanded: true,
                items: teams.map((String team) {
                  return DropdownMenuItem<String>(
                    value: team,
                    child: Text(team),
                  );
                }).toList(),
                onChanged: (value) => setState(() => team2 = value),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createMatch,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'Start Match',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}