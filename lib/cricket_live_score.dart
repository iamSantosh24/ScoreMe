import 'package:flutter/material.dart';

class CricketLiveScore extends StatefulWidget {
  final Map<String, dynamic> gameData;
  const CricketLiveScore({super.key, required this.gameData});

  @override
  State<CricketLiveScore> createState() => _CricketLiveScoreState();
}

class _CricketLiveScoreState extends State<CricketLiveScore> {
  int teamARuns = 0;
  int teamAWickets = 0;
  int teamBRuns = 0;
  int teamBWickets = 0;
  int overs = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Team A: ${widget.gameData['teamAName'] ?? 'A'}'),
        Row(
          children: [
            _scoreBox('Runs', teamARuns, () => setState(() => teamARuns++)),
            _scoreBox('Wickets', teamAWickets, () => setState(() => teamAWickets++)),
          ],
        ),
        SizedBox(height: 16),
        Text('Team B: ${widget.gameData['teamBName'] ?? 'B'}'),
        Row(
          children: [
            _scoreBox('Runs', teamBRuns, () => setState(() => teamBRuns++)),
            _scoreBox('Wickets', teamBWickets, () => setState(() => teamBWickets++)),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            _scoreBox('Overs', overs, () => setState(() => overs++)),
          ],
        ),
        Spacer(),
        ElevatedButton(
          onPressed: _submitCricketScore,
          child: Text('Submit Score'),
        ),
      ],
    );
  }

  Widget _scoreBox(String label, int value, VoidCallback onIncrement) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Text(label),
          Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          IconButton(icon: Icon(Icons.add), onPressed: onIncrement),
        ],
      ),
    );
  }

  void _submitCricketScore() {
    // TODO: Implement score submission logic
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cricket score submitted!')));
  }
}
