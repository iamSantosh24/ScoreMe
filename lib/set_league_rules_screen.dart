import 'package:flutter/material.dart';

class SetLeagueRulesScreen extends StatelessWidget {
  final String leagueId;
  final String leagueName;
  const SetLeagueRulesScreen({super.key, required this.leagueId, required this.leagueName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Set Rules: $leagueName')),
      body: Center(
        child: Text('Set rules for league "$leagueName" (ID: $leagueId)'),
      ),
    );
  }
}

