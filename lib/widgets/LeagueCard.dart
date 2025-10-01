import 'package:flutter/material.dart';
import '../leagues_util.dart';
import '../LeagueHomeScreen.dart';

class LeagueCard extends StatelessWidget {
  final League league;
  final VoidCallback onTap;

  const LeagueCard({super.key, required this.league, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(league.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LeagueHomeScreen(league: league),
            ),
          );
        },
      ),
    );
  }
}
