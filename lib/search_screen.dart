import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'tournament_home_screen.dart';
import 'player_profile_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'profile_screen.dart';

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

  Future<void> performSearch() async {
    setState(() { loading = true; error = ''; tournaments = []; players = []; });
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
        });
        print('Tournaments found: \\${tournaments.length}');
        print('Players found: \\${players.length}');
        if (tournaments.isEmpty && players.isEmpty) {
          setState(() { error = 'No results found.'; });
        } else if (tournaments.isEmpty) {
          setState(() { error = 'No tournaments found.'; });
        } else if (players.isEmpty) {
          setState(() { error = 'No players found.'; });
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
    if (loggedInUsername == username) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlayerProfileScreen(username: username)),
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
              decoration: const InputDecoration(labelText: 'Search tournaments or players'),
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
          ],
        ),
      ),
    );
  }
}
