import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../leagues_util.dart';

class HomeTabbedViewModel extends ChangeNotifier {
  List<String> myGames = [];
  List<String> myLeagues = [];
  List<dynamic> scheduledGames = [];
  List<League> leagues = [];
  List<dynamic> teams = [];
  bool loading = false;
  String error = '';

  Future<void> fetchAllTabData(String username) async {
    loading = true;
    error = '';
    notifyListeners();
    try {
      final res = await http.get(
        Uri.parse('http://192.168.1.134:3000/user/leagues-games-teams?username=$username'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        // Scheduled Games
        scheduledGames = data['games'] ?? [];
        myGames = scheduledGames.map<String>((g) => g['gameName']?.toString() ?? '').toList();
        // Leagues
        final backendLeagues = data['leagues'] ?? [];
        leagues = backendLeagues.map<League>((l) => League.fromJson(l)).toList();
        myLeagues = leagues.map((l) => l.name).toList();
        // Teams
        teams = data['teams'] ?? [];
      } else {
        error = json.decode(res.body)['error'] ?? 'Failed to fetch tab data';
      }
    } catch (e) {
      error = 'Network error';
    }
    loading = false;
    notifyListeners();
  }
}
