import 'package:flutter/material.dart';
import '../leagues_util.dart';

class GameCard extends StatelessWidget {
  final Map<String, dynamic> game;

  const GameCard({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final teamA = game['teamA'] ?? '';
    final teamB = game['teamB'] ?? '';
    final date = game['date'] != null ? DateTime.parse(game['date']).toLocal() : null;
    String formattedDate = '';
    if (date != null) {
      formattedDate = '${monthName(date.month)} ${date.day}, ${date.year}  ${formatTime(date)}';
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (formattedDate.isNotEmpty)
              Text('Date: $formattedDate', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Teams: $teamA vs $teamB', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
