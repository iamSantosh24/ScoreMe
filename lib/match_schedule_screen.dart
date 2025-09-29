import 'package:flutter/material.dart';
import 'navigation_utils.dart';
import 'data.dart';
import 'player_utils.dart';

class MatchScheduleScreen extends StatelessWidget {
  final String league;

  const MatchScheduleScreen({super.key, required this.league});

  // Generate a round-robin schedule (each team plays every other team once)
  List<Map<String, String>> _generateSchedule(List<String> teams) {
    List<Map<String, String>> matches = [];
    for (int i = 0; i < teams.length; i++) {
      for (int j = i + 1; j < teams.length; j++) {
        final team1 = teams[i];
        final team2 = teams[j];
        final display = '$team1 vs $team2';
        final title = display; // Can include league if needed: '$league: $display'
        matches.add({
          'team1': team1,
          'team2': team2,
          'display': display,
          'title': title,
        });
      }
    }
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> teams = leagueTeams[league] ?? [];
    final List<Map<String, String>> matches = _generateSchedule(teams);
    final Map<String, List<String>> teamPlayers = PlayerUtils.generateTeamPlayers(teams);

    return Scaffold(
      body: matches.isEmpty
          ? const Center(
        child: Text(
          'No teams available for this league',
          style: TextStyle(fontSize: 20),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          return Card(
            child: ListTile(
              title: Text(
                match['display']!,
                style: const TextStyle(fontSize: 18),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => openTossScreen(
                context,
                team1: match['team1']!,
                team2: match['team2']!,
                matchTitle: match['title']!,
                teamPlayers: teamPlayers,
              ),
            ),
          );
        },
      ),
    );
  }
}