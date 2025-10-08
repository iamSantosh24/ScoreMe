import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'tournament_details_screen.dart';

const String apiBaseUrl = 'http://192.168.1.134:3000';

class ExistingLeaguesScreen extends StatefulWidget {
  const ExistingLeaguesScreen({super.key});

  @override
  State<ExistingLeaguesScreen> createState() => _ExistingLeaguesScreenState();
}

class _ExistingLeaguesScreenState extends State<ExistingLeaguesScreen> {
  List<Map<String, dynamic>> leagues = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeagues();
  }

  Future<void> _fetchLeagues() async {
    setState(() { isLoading = true; });
    final response = await http.get(Uri.parse('$apiBaseUrl/leagues'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        leagues = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } else {
      setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Existing Leagues')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : leagues.isEmpty
              ? const Center(child: Text('No leagues found.'))
              : ListView.builder(
                  itemCount: leagues.length,
                  itemBuilder: (context, index) {
                    final t = leagues[index];
                    return ListTile(
                      title: Text(t['name'] ?? ''),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TournamentDetailsScreen(
                                tournamentName: t['name'] ?? '',
                                tournamentId: t['_id'],
                              ),
                            ),
                          );
                        },
                        child: const Text('Open'),
                      ),
                    );
                  },
                ),
    );
  }
}
