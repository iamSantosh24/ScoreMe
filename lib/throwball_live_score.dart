import 'package:flutter/material.dart';

class ThrowballLiveScore extends StatefulWidget {
  final Map<String, dynamic> gameData;
  const ThrowballLiveScore({super.key, required this.gameData});

  @override
  State<ThrowballLiveScore> createState() => _ThrowballLiveScoreState();
}

class _ThrowballLiveScoreState extends State<ThrowballLiveScore> {
  int teamASets = 0;
  int teamBSets = 0;
  List<int> teamAPoints = [0, 0, 0];
  List<int> teamBPoints = [0, 0, 0];
  int teamATimeouts = 0;
  int teamBTimeouts = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Team A: ${widget.gameData['teamAName'] ?? 'A'}'),
          Row(
            children: [
              Expanded(child: _scoreBox('Sets Won', teamASets, () => setState(() => teamASets++))),
              Expanded(child: _scoreBox('Timeouts', teamATimeouts, () => setState(() => teamATimeouts++))),
            ],
          ),
          SizedBox(height: 8),
          Text('Points per Set'),
          Row(
            children: List.generate(3, (i) => Expanded(child: _scoreBox('Set ${i+1}', teamAPoints[i], () => setState(() => teamAPoints[i]++)))),
          ),
          SizedBox(height: 16),
          Text('Team B: ${widget.gameData['teamBName'] ?? 'B'}'),
          Row(
            children: [
              Expanded(child: _scoreBox('Sets Won', teamBSets, () => setState(() => teamBSets++))),
              Expanded(child: _scoreBox('Timeouts', teamBTimeouts, () => setState(() => teamBTimeouts++))),
            ],
          ),
          SizedBox(height: 8),
          Text('Points per Set'),
          Row(
            children: List.generate(3, (i) => Expanded(child: _scoreBox('Set ${i+1}', teamBPoints[i], () => setState(() => teamBPoints[i]++)))),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitThrowballScore,
            child: Text('Submit Score'),
          ),
        ],
      ),
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

  void _submitThrowballScore() {
    // TODO: Implement score submission logic
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Throwball score submitted!')));
  }
}
