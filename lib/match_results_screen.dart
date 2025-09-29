import 'package:flutter/material.dart';

class MatchResultsScreen extends StatelessWidget {
  final String league;

  const MatchResultsScreen({super.key, required this.league});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Match results for $league coming soon',
        style: const TextStyle(fontSize: 20),
      ),
    );
  }
}