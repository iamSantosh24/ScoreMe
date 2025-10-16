import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:scorer/config.dart';

class ManageLeagueTeamsViewModel extends ChangeNotifier {
  final String leagueId;
  final List<dynamic> currentTeams;

  List<dynamic> allTeams = [];
  Set<String> leagueTeamIds = {};
  bool isLoading = true;

  ManageLeagueTeamsViewModel({
    required this.leagueId,
    required this.currentTeams,
  }) {
    leagueTeamIds = currentTeams.map<String>((t) => t['teamId'] as String).toSet();
    fetchAllTeams();
  }

  Future<void> fetchAllTeams() async {
    isLoading = true;
    notifyListeners();
    final response = await http.get(Uri.parse('${Config.apiBaseUrl}/teams'));
    if (response.statusCode == 200) {
      allTeams = jsonDecode(response.body);
      isLoading = false;
      notifyListeners();
    } else {
      isLoading = false;
      notifyListeners();
      // Handle error
    }
  }

  Future<String?> handleTeamAction(String teamId, String teamName, bool add) async {
    final response = await http.post(
      Uri.parse('${Config.apiBaseUrl}/league/$leagueId/team'),
      body: jsonEncode({
        'action': add ? 'add' : 'remove',
        'teamId': teamId,
        if (add) 'teamName': teamName,
      }),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      if (add) {
        leagueTeamIds.add(teamId);
      } else {
        leagueTeamIds.remove(teamId);
      }
      notifyListeners();
      return null;
    } else {
      String errorMsg = 'Failed to ${add ? 'add' : 'remove'} team.';
      try {
        final resp = jsonDecode(response.body);
        if (resp['error'] != null && resp['leagueName'] != null) {
          errorMsg = 'Team is already part of another league: ${resp['leagueName']}';
        } else if (resp['error'] != null) {
          errorMsg = resp['error'];
        }
      } catch (_) {}
      return errorMsg;
    }
  }
}
