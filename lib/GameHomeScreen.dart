import 'package:flutter/material.dart';

class GameHomeScreen extends StatelessWidget {
  final Map<String, dynamic> game;
  const GameHomeScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final teamA = game['teamA'] ?? '';
    final teamB = game['teamB'] ?? '';
    final date = game['date'] != null ? DateTime.parse(game['date']).toLocal() : null;
    String formattedDate = '';
    if (date != null) {
      formattedDate = '${date.day}/${date.month}/${date.year}';
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Teams: $teamA vs $teamB', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (formattedDate.isNotEmpty)
              Text('Date: $formattedDate', style: const TextStyle(fontSize: 16)),
            // Add more game details here as needed
          ],
        ),
      ),
    );
  }
}

