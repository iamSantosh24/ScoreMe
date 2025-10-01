import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../leagues_util.dart';

class HomeTabbedViewModel extends ChangeNotifier {
  List<String> myGames = [];
  List<String> myLeagues = [];
  List<dynamic> scheduledGames = [];
  List<League> leagues = [];
  bool loading = false;
  String error = '';

  Future<void> fetchScheduledGames(String username) async {
    try {
      final res = await http.get(
        Uri.parse('http://192.168.1.134:3000/user/scheduled-games?username=$username'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        scheduledGames = data['games'] ?? [];
      }
    } catch (e) {
      // Ignore errors for scheduled games
    }
  }

  Future<void> fetchUserLeaguesAndGames(String username) async {
    loading = true;
    error = '';
    notifyListeners();
    try {
      final res = await http.get(
        Uri.parse('http://192.168.1.134:3000/user/leagues-and-games?username=$username'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final backendLeagues = data['leagues'] ?? [];
        leagues = backendLeagues.map<League>((l) => League.fromJson(l)).toList();
        myLeagues = leagues.map((l) => l.name).toList();
        myGames = List<String>.from(data['games'] ?? []);
        await fetchScheduledGames(username);
      } else {
        error = json.decode(res.body)['error'] ?? 'Failed to fetch data';
      }
    } catch (e) {
      error = 'Network error';
    }
    loading = false;
    notifyListeners();
  }
}
