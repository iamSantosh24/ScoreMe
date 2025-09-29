import 'package:flutter/material.dart';
import 'data.dart';
import 'dart:math';

class TeamPlayersScreen extends StatelessWidget {
  final String league;

  const TeamPlayersScreen({super.key, required this.league});

  // Generate a pool of unique player names
  List<String> _generateUniquePlayerNames(int count) {
    // Base names for variety
    final List<String> firstNames = [
      'James', 'Michael', 'William', 'David', 'John', 'Robert', 'Thomas', 'Charles',
      'Christopher', 'Daniel', 'Matthew', 'Andrew', 'Joseph', 'Mark', 'Paul', 'Steven',
      'Richard', 'Edward', 'George', 'Benjamin', 'Samuel', 'Stephen', 'Jonathan', 'Peter',
      'Adam', 'Kevin', 'Brian', 'Jason', 'Timothy', 'Nathan', 'Scott', 'Brandon',
      'Gregory', 'Patrick', 'Ryan', 'Eric', 'Nicholas', 'Jeremy', 'Aaron', 'Frank',
    ];
    final List<String> lastNames = [
      'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis',
      'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson',
      'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin', 'Lee', 'Perez', 'Thompson',
      'White', 'Harris', 'Sanchez', 'Clark', 'Ramirez', 'Lewis', 'Walker', 'Hall',
      'Allen', 'Young', 'King', 'Wright', 'Scott', 'Green', 'Baker', 'Adams',
    ];

    final random = Random();
    final Set<String> uniqueNames = {};

    while (uniqueNames.length < count) {
      final first = firstNames[random.nextInt(firstNames.length)];
      final last = lastNames[random.nextInt(lastNames.length)];
      final name = '$first $last';
      uniqueNames.add(name);
    }

    return uniqueNames.toList();
  }

  // Assign 30 unique players to each team
  Map<String, List<String>> _assignPlayersToTeams(List<String> teams) {
    final totalPlayersNeeded = teams.length * 30;
    final allPlayers = _generateUniquePlayerNames(totalPlayersNeeded);
    final Map<String, List<String>> teamPlayers = {};

    for (int i = 0; i < teams.length; i++) {
      final startIndex = i * 30;
      teamPlayers[teams[i]] = allPlayers.sublist(startIndex, startIndex + 30);
    }

    return teamPlayers;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> teams = leagueTeams[league] ?? [];
    final Map<String, List<String>> teamPlayers = _assignPlayersToTeams(teams);

    return Scaffold(
      appBar: AppBar(
        title: Text('$league - Team Players'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: teams.isEmpty
          ? const Center(
        child: Text(
          'No teams available for this league',
          style: TextStyle(fontSize: 20),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: teams.length,
        itemBuilder: (context, index) {
          final team = teams[index];
          final players = teamPlayers[team] ?? [];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ExpansionTile(
              title: Text(
                team,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              children: players.map((player) => ListTile(
                title: Text(player),
              )).toList(),
            ),
          );
        },
      ),
    );
  }
}