import 'package:flutter/material.dart';
import '../leagues_util.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:scorer/config.dart';
import '../models/league.dart';

class LeagueHomeViewModel extends ChangeNotifier {
  final League league;
  List<dynamic> scheduledGames = [];
  bool loadingScheduled = true;
  String errorScheduled = '';

  LeagueHomeViewModel({required this.league}) {
    fetchScheduledGames();
  }

  Future<void> fetchScheduledGames() async {
    loadingScheduled = true;
    errorScheduled = '';
    notifyListeners();
    try {
      final res = await http.get(
        Uri.parse('${Config.apiBaseUrl}/league/scheduled-games?leagueId=${league.id}'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        scheduledGames = data['games'] ?? [];
      } else {
        errorScheduled = 'Failed to fetch scheduled games: Status ${res.statusCode}';
      }
    } catch (e) {
      errorScheduled = 'Network error: $e';
    }
    loadingScheduled = false;
    notifyListeners();
  }
}
