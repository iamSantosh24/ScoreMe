import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'tournament_details_screen.dart';

const String apiBaseUrl = 'http://192.168.1.134:3000';

class ExistingTournamentsScreen extends StatefulWidget {
  const ExistingTournamentsScreen({super.key});

  @override
  State<ExistingTournamentsScreen> createState() => _ExistingTournamentsScreenState();
}

class _ExistingTournamentsScreenState extends State<ExistingTournamentsScreen> {
  List<Map<String, dynamic>> tournaments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTournaments();
  }

  Future<void> _fetchTournaments() async {
    setState(() { isLoading = true; });
    final response = await http.get(Uri.parse('$apiBaseUrl/tournaments'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        tournaments = List<Map<String, dynamic>>.from(data['tournaments']);
        isLoading = false;
      });
    } else {
      setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Existing Tournaments')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tournaments.isEmpty
              ? const Center(child: Text('No tournaments found.'))
              : ListView.builder(
                  itemCount: tournaments.length,
                  itemBuilder: (context, index) {
                    final t = tournaments[index];
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

