import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MatchResultsScreen extends StatefulWidget {
  final String league;

  const MatchResultsScreen({super.key, required this.league});

  @override
  State<MatchResultsScreen> createState() => _MatchResultsScreenState();
}

class _MatchResultsScreenState extends State<MatchResultsScreen> {
  late Future<List<dynamic>> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _resultsFuture = fetchResults();
  }

  Future<List<dynamic>> fetchResults() async {
    final response = await http.get(
      Uri.parse('http://192.168.1.134:3000/games/results?leagueId=${widget.league}')
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'] ?? [];
    } else {
      throw Exception('Failed to load results');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _resultsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: \\${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No results found.'));
        }
        final results = snapshot.data!;
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            final score = result['score'] ?? {};
            final details = result['details'] ?? {};
            final teamA_batting = details['teamA_batting'] ?? [];
            final teamA_bowling = details['teamA_bowling'] ?? [];
            final teamB_batting = details['teamB_batting'] ?? [];
            final teamB_bowling = details['teamB_bowling'] ?? [];
            final extras = details['extras'] ?? {};
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${result['teamAName']} vs ${result['teamBName']}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Date: ${result['date'] != null ? result['date'].toString().substring(0, 10) : '-'}'),
                    Text('Location: ${result['location'] ?? '-'}'),
                    Text('Result: ${score['result'] ?? '-'}'),
                    const Divider(),
                    Text('Score Summary:', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${result['teamAName']}: ${score['teamA_runs'] ?? '-'} runs, ${score['teamA_wickets'] ?? '-'} wickets'),
                    Text('${result['teamBName']}: ${score['teamB_runs'] ?? '-'} runs, ${score['teamB_wickets'] ?? '-'} wickets'),
                    const Divider(),
                    Text('Batting - ${result['teamAName']}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ...teamA_batting.map<Widget>((b) => Text('${b['player']}: ${b['runs']} runs (${b['balls']} balls)')).toList(),
                    const SizedBox(height: 8),
                    Text('Bowling - ${result['teamAName']}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ...teamA_bowling.map<Widget>((b) => Text('${b['player']}: ${b['wickets']} wickets (${b['overs']} overs)')).toList(),
                    const Divider(),
                    Text('Batting - ${result['teamBName']}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ...teamB_batting.map<Widget>((b) => Text('${b['player']}: ${b['runs']} runs (${b['balls']} balls)')).toList(),
                    const SizedBox(height: 8),
                    Text('Bowling - ${result['teamBName']}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ...teamB_bowling.map<Widget>((b) => Text('${b['player']}: ${b['wickets']} wickets (${b['overs']} overs)')).toList(),
                    const Divider(),
                    Text('Extras:', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Wides: ${extras['wides'] ?? 0}, No Balls: ${extras['noBalls'] ?? 0}, Leg Byes: ${extras['legByes'] ?? 0}, Byes: ${extras['byes'] ?? 0}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}