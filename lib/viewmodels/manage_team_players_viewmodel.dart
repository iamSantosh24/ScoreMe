import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:scorer/config.dart';

class ManageTeamPlayersViewModel extends ChangeNotifier {
  List<dynamic> searchResults = [];
  List<dynamic> teamPlayers = [];
  bool isSearching = false;

  Future<void> fetchTeamPlayers(String teamId) async {
    final response = await http.get(Uri.parse('${Config.apiBaseUrl}/team-members-details/$teamId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final playerObjs = data['players'] ?? [];
      teamPlayers = playerObjs;
      notifyListeners();
    }
  }

  Future<void> searchPlayers(String query) async {
    isSearching = true;
    notifyListeners();
    final response = await http.get(Uri.parse('${Config.apiBaseUrl}/players?search=$query'));
    if (response.statusCode == 200) {
      searchResults = jsonDecode(response.body);
    } else {
      searchResults = [];
    }
    isSearching = false;
    notifyListeners();
  }

  bool isPlayerInTeam(String playerId) {
    return teamPlayers.any((p) => p is Map && p['profileId'] == playerId);
  }

  Future<String?> addPlayerToTeam(String teamId, Map player) async {
    final playerId = player['profileId'];
    if (isPlayerInTeam(playerId)) {
      return 'Player is already in this team.';
    }
    final response = await http.post(
      Uri.parse('${Config.apiBaseUrl}/team/$teamId/player'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'add',
        'player': playerId,
      }),
    );
    if (response.statusCode == 200) {
      await fetchTeamPlayers(teamId);
      return null;
    } else {
      try {
        final resp = jsonDecode(response.body);
        if (resp['error'] != null) {
          return resp['error'];
        }
      } catch (_) {}
      return 'Failed to add player.';
    }
  }

  Future<String?> removePlayerFromTeam(String teamId, String playerId) async {
    final response = await http.post(
      Uri.parse('${Config.apiBaseUrl}/team/$teamId/player'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'remove',
        'player': playerId,
      }),
    );
    if (response.statusCode == 200) {
      await fetchTeamPlayers(teamId);
      return null;
    } else {
      try {
        final resp = jsonDecode(response.body);
        if (resp['error'] != null) {
          return resp['error'];
        }
      } catch (_) {}
      return 'Failed to remove player.';
    }
  }
}
