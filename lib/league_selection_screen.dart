import 'package:flutter/material.dart';
import 'match_screen.dart';

class LeagueSelectionScreen extends StatefulWidget {
  const LeagueSelectionScreen({super.key});

  @override
  State<LeagueSelectionScreen> createState() => _LeagueSelectionScreenState();
}

class _LeagueSelectionScreenState extends State<LeagueSelectionScreen> {
  final List<String> leagues = [
    'El Monte Winter League',
    'Southern California Cricket League',
    'Eastvale Premier League',
  ];
  String? selectedLeague;

  void _goToMatchCreation() {
    if (selectedLeague != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MatchScreen(league: selectedLeague!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a league!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRIC - SCORER'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Choose a League',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              hint: const Text('Select a League'),
              value: selectedLeague,
              isExpanded: true,
              items: leagues.map((String league) {
                return DropdownMenuItem<String>(
                  value: league,
                  child: Text(league),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedLeague = value),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _goToMatchCreation,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}