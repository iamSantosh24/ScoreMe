import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'tournament_home_screen.dart';
import 'player_profile_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'profile_screen.dart';
import 'league_home_screen.dart';
import 'team_home_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String query = '';
  bool loading = false;
  String error = '';
  List<dynamic> tournaments = [];
  List<dynamic> players = [];
  List<dynamic> leagues = [];
  List<dynamic> teams = [];

  Future<void> performSearch() async {
    setState(() { loading = true; error = ''; tournaments = []; players = []; leagues = []; teams = []; });
    try {
      final res = await http.get(
        Uri.parse('http://192.168.1.134:3000/search?query=$query'),
      );
      print('Search response status: \\${res.statusCode}');
      print('Search response body: \\${res.body}');
      setState(() { loading = false; });
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          tournaments = data['tournaments'] ?? [];
          players = data['players'] ?? [];
          leagues = data['leagues'] ?? [];
          teams = data['teams'] ?? [];
        });
        print('Tournaments found: \\${tournaments.length}');
        print('Players found: \\${players.length}');
        print('Leagues found: \\${leagues.length}');
        print('Teams found: \\${teams.length}');
        if (tournaments.isEmpty && players.isEmpty && leagues.isEmpty && teams.isEmpty) {
          setState(() { error = 'No results found.'; });
        } else {
          setState(() { error = ''; });
        }
      } else {
        setState(() { error = json.decode(res.body)['error'] ?? 'Search failed'; });
      }
    } catch (e) {
      print('Search exception: \\${e.toString()}');
      setState(() { loading = false; error = 'Search failed. Please check your connection.'; });
    }
  }

  Future<void> openProfileOrPlayer(BuildContext context, String username) async {
    final storage = const FlutterSecureStorage();
    final loggedInUsername = await storage.read(key: 'auth_username');
    print("Logged in username: $loggedInUsername");
    final role = await storage.read(key: 'auth_role') ?? '';
    print("Role: $role");
    if (loggedInUsername == username) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlayerProfileScreen(username: username, role: role)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Search tournaments, players, leagues, or teams'),
              onChanged: (val) => query = val,
            ),
            ElevatedButton(
              onPressed: performSearch,
              child: const Text('Search'),
            ),
            if (loading) const Center(child: CircularProgressIndicator()),
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(error, style: const TextStyle(color: Colors.red)),
              ),
            if (tournaments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Text('Tournaments:', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ...tournaments.map((t) => ListTile(
              title: Text(t['name']),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TournamentHomeScreen(tournamentName: t['name']),
                  ),
                );
              },
            )),
            if (players.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Text('Players:', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ...players.map((p) => ListTile(
              title: Text(p['username']),
              onTap: () {
                openProfileOrPlayer(context, p['username']);
              },
            )),
            if (leagues.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Text('Leagues:', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ...leagues.map((l) => ListTile(
              title: Text(l['name'] ?? l.toString()),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LeagueHomeScreen(league: l, scheduledGames: []),
                  ),
                );
              },
            )),
            if (teams.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Text('Teams:', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ...teams.map((t) => ListTile(
              title: Text(t['name'] ?? t.toString()),
              onTap: () async {
                final storage = const FlutterSecureStorage();
                final role = await storage.read(key: 'auth_role') ?? '';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeamHomeScreen(team: t, leagues: [], scheduledGames: [], role: role),
                  ),
                );
              },
            )),
          ],
        ),
      ),
    );
  }
}
