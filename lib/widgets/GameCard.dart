import 'package:flutter/material.dart';
import '../GameHomeScreen.dart';

class GameCard extends StatelessWidget {
  final Map<String, dynamic> game;

  const GameCard({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    String location = game['location'] ?? '';
    String leagueName = game['leagueName'] ?? '';
    List<String> subtitleLines = [];
    if (leagueName.isNotEmpty) subtitleLines.add(leagueName);
    if (location.isNotEmpty) subtitleLines.add(location);
    String subtitleText = subtitleLines.join('\n');
    String teamAName = game['teamAName'] ?? game['teamA'] ?? game['teamAId'] ?? '';
    String teamBName = game['teamBName'] ?? game['teamB'] ?? game['teamBId'] ?? '';
    String titleText = '';
    if (teamAName.isNotEmpty && teamBName.isNotEmpty) {
      titleText = '$teamAName vs $teamBName';
    } else {
      titleText = game['gameName'] ?? '';
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitleText.isNotEmpty ? Text(subtitleText) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GameHomeScreen(game: game),
            ),
          );
        },
      ),
    );
  }
}
