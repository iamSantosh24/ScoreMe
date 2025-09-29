import 'package:flutter/material.dart';
import 'scoreboard_screen.dart';
import 'player_utils.dart';
import 'dart:math';

void openTossScreen(BuildContext context, {
  required String team1,
  required String team2,
  required String matchTitle,
  required Map<String, List<String>> teamPlayers,
}) {
  String? tossWinner;
  String? tossChoice;

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          void proceedToPlayerSelection() {
            if (tossWinner != null && tossChoice != null) {
              Navigator.of(dialogContext).pop(); // Close toss dialog
              _showPlayerSelectionDialog(
                context,
                team1: team1,
                team2: team2,
                tossWinner: tossWinner!,
                tossChoice: tossChoice!,
                teamPlayers: teamPlayers,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select a toss winner and toss choice!'),
                ),
              );
            }
          }

          return AlertDialog(
            title: Text(matchTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$team1 vs $team2',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Toss Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    hint: const Text('Select Toss Winner'),
                    value: tossWinner,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<String>(
                        value: team1,
                        child: Text(team1),
                      ),
                      DropdownMenuItem<String>(
                        value: team2,
                        child: Text(team2),
                      ),
                    ],
                    onChanged: (value) => setState(() => tossWinner = value),
                  ),
                  const SizedBox(height: 12),
                  if (tossWinner != null) ...[
                    const Text(
                      'Toss Choice',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    RadioListTile<String>(
                      title: const Text('Batting'),
                      value: 'Batting',
                      groupValue: tossChoice,
                      onChanged: (value) => setState(() => tossChoice = value),
                    ),
                    RadioListTile<String>(
                      title: const Text('Bowling'),
                      value: 'Bowling',
                      groupValue: tossChoice,
                      onChanged: (value) => setState(() => tossChoice = value),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: proceedToPlayerSelection,
                child: const Text('Next'),
              ),
            ],
          );
        },
      );
    },
  );
}

void _showPlayerSelectionDialog(BuildContext context, {
  required String team1,
  required String team2,
  required String tossWinner,
  required String tossChoice,
  required Map<String, List<String>> teamPlayers,
}) {
  final random = Random();

  // Preselect 11 random players for team1
  final List<String> team1Roster = teamPlayers[team1] ?? [];
  final List<String> team1SelectedPlayers = team1Roster.length >= 11
      ? (team1Roster..shuffle(random)).take(11).toList()
      : team1Roster;

  // Preselect 11 random players for team2
  final List<String> team2Roster = teamPlayers[team2] ?? [];
  final List<String> team2SelectedPlayers = team2Roster.length >= 11
      ? (team2Roster..shuffle(random)).take(11).toList()
      : team2Roster;

  // Assign random captain and wicketkeeper for team1
  String? team1Captain = team1SelectedPlayers.isNotEmpty ? team1SelectedPlayers[random.nextInt(team1SelectedPlayers.length)] : null;
  String? team1Wicketkeeper = team1SelectedPlayers.isNotEmpty
      ? team1SelectedPlayers.where((player) => player != team1Captain).isNotEmpty
      ? team1SelectedPlayers.where((player) => player != team1Captain).elementAt(random.nextInt(team1SelectedPlayers.where((player) => player != team1Captain).length))
      : team1SelectedPlayers[random.nextInt(team1SelectedPlayers.length)]
      : null;

  // Assign random captain and wicketkeeper for team2
  String? team2Captain = team2SelectedPlayers.isNotEmpty ? team2SelectedPlayers[random.nextInt(team2SelectedPlayers.length)] : null;
  String? team2Wicketkeeper = team2SelectedPlayers.isNotEmpty
      ? team2SelectedPlayers.where((player) => player != team2Captain).isNotEmpty
      ? team2SelectedPlayers.where((player) => player != team2Captain).elementAt(random.nextInt(team2SelectedPlayers.where((player) => player != team2Captain).length))
      : team2SelectedPlayers[random.nextInt(team2SelectedPlayers.length)]
      : null;

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          void startMatch() {
            if (team1SelectedPlayers.length <= 11 &&
                team2SelectedPlayers.length <= 11 &&
                team1Captain != null &&
                team1Wicketkeeper != null &&
                team2Captain != null &&
                team2Wicketkeeper != null) {
              Navigator.of(dialogContext).pop(); // Close player selection dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScoreboardScreen(
                    team1: team1,
                    team2: team2,
                    tossWinner: tossWinner,
                    tossChoice: tossChoice,
                    team1Players: team1SelectedPlayers,
                    team2Players: team2SelectedPlayers,
                    team1Captain: team1Captain!,
                    team1Wicketkeeper: team1Wicketkeeper!,
                    team2Captain: team2Captain!,
                    team2Wicketkeeper: team2Wicketkeeper!,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Select up to 11 players per team, a captain, and a wicketkeeper!'),
                ),
              );
            }
          }

          return AlertDialog(
            title: const Text('Select Playing XI'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select up to 11 players for $team1',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ...?teamPlayers[team1]?.map((player) => CheckboxListTile(
                    title: Text(player),
                    value: team1SelectedPlayers.contains(player),
                    onChanged: (value) {
                      setState(() {
                        if (value == true && team1SelectedPlayers.length < 11) {
                          team1SelectedPlayers.add(player);
                        } else if (value == false) {
                          team1SelectedPlayers.remove(player);
                          if (team1Captain == player) team1Captain = null;
                          if (team1Wicketkeeper == player) team1Wicketkeeper = null;
                        }
                      });
                    },
                  )),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    hint: Text('Select Captain for $team1'),
                    value: team1Captain,
                    isExpanded: true,
                    items: team1SelectedPlayers.map((player) {
                      return DropdownMenuItem<String>(
                        value: player,
                        child: Text(player),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => team1Captain = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    hint: Text('Select Wicketkeeper for $team1'),
                    value: team1Wicketkeeper,
                    isExpanded: true,
                    items: team1SelectedPlayers.map((player) {
                      return DropdownMenuItem<String>(
                        value: player,
                        child: Text(player),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => team1Wicketkeeper = value),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select up to 11 players for $team2',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ...?teamPlayers[team2]?.map((player) => CheckboxListTile(
                    title: Text(player),
                    value: team2SelectedPlayers.contains(player),
                    onChanged: (value) {
                      setState(() {
                        if (value == true && team2SelectedPlayers.length < 11) {
                          team2SelectedPlayers.add(player);
                        } else if (value == false) {
                          team2SelectedPlayers.remove(player);
                          if (team2Captain == player) team2Captain = null;
                          if (team2Wicketkeeper == player) team2Wicketkeeper = null;
                        }
                      });
                    },
                  )),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    hint: Text('Select Captain for $team2'),
                    value: team2Captain,
                    isExpanded: true,
                    items: team2SelectedPlayers.map((player) {
                      return DropdownMenuItem<String>(
                        value: player,
                        child: Text(player),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => team2Captain = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    hint: Text('Select Wicketkeeper for $team2'),
                    value: team2Wicketkeeper,
                    isExpanded: true,
                    items: team2SelectedPlayers.map((player) {
                      return DropdownMenuItem<String>(
                        value: player,
                        child: Text(player),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => team2Wicketkeeper = value),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: startMatch,
                child: const Text('Start Match'),
              ),
            ],
          );
        },
      );
    },
  );
}