import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MatchScheduleViewModel extends ChangeNotifier {
  List<dynamic> scheduledGames = [];
  bool loading = false;
  String error = '';
  String leagueName = '';
  String leagueId = '';

  void setScheduledGames(List<dynamic> games, String leagueId) {
    scheduledGames = games.where((game) {
      final gameLeagueId = game['leagueId'] ?? '';
      return gameLeagueId == leagueId;
    }).toList();
    this.leagueId = leagueId;
    loading = false;
    notifyListeners();
  }

  Future<void> fetchLeagueName(String leagueId) async {
    try {
      final res = await http.get(
        Uri.parse('http://192.168.1.134:3000/tournaments'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final tournaments = data['tournaments'] ?? [];
        for (final t in tournaments) {
          final id = t['_id'] ?? t['name'];
          if (id == leagueId) {
            leagueName = t['name'] ?? leagueId;
            break;
          }
        }
      }
    } catch (e) {
      leagueName = leagueId;
    }
    notifyListeners();
  }

  Future<void> fetchScheduledGames(String leagueId) async {
    loading = true;
    error = '';
    notifyListeners();
    try {
      final res = await http.get(
        Uri.parse('http://192.168.1.134:3000/scheduled-games?leagueId=$leagueId'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        scheduledGames = data['games'] ?? [];
        this.leagueId = leagueId;
        await fetchLeagueName(leagueId);
      } else {
        error = json.decode(res.body)['error'] ?? 'Failed to fetch games';
      }
    } catch (e) {
      error = 'Network error';
    }
    loading = false;
    notifyListeners();
  }
}

