import 'package:flutter/material.dart';
import '../game_home_screen.dart';
import '../leagues_util.dart';

enum GameCardVariant { defaultView, scheduled }

class GameCard extends StatelessWidget {
  final Map<String, dynamic> game;
  final GameCardVariant variant;

  const GameCard({super.key, required this.game, this.variant = GameCardVariant.defaultView});

  @override
  Widget build(BuildContext context) {
    if (variant == GameCardVariant.scheduled) {
      // Scheduled tab UI: teamAName vs teamBName, scheduledDate, location
      String teamAName = game['teamAName'] ?? game['teamA'] ?? game['teamAId'] ?? '';
      String teamBName = game['teamBName'] ?? game['teamB'] ?? game['teamBId'] ?? '';
      String titleText = (teamAName.isNotEmpty && teamBName.isNotEmpty)
          ? '$teamAName vs $teamBName'
          : game['gameName'] ?? '';
      String dateText = '';
      if (game['scheduledDate'] != null) {
        final date = DateTime.tryParse(game['scheduledDate'].toString());
        if (date != null) {
          dateText = '${monthName(date.month)} ${date.day}, ${date.year}  ${formatTime(date)}';
        }
      }
      String location = game['location'] ?? '';
      List<String> subtitleLines = [];
      if (dateText.isNotEmpty) subtitleLines.add(dateText);
      if (location.isNotEmpty) subtitleLines.add(location);
      String subtitleText = subtitleLines.join('\n');
      print('titleText: $titleText, subtitleText: $subtitleText');
      print('game: $game');
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
    } else {
      // Default UI (My Games tab)
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
}
