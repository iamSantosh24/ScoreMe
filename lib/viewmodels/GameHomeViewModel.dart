import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GameHomeViewModel extends ChangeNotifier {
  List<String> teamAPlayers = [];
  List<String> teamBPlayers = [];
  bool loading = true;
  String error = '';

  Future<void> fetchTeamMembers(String teamAId, String teamBId) async {
    loading = true;
    error = '';
    notifyListeners();
    try {
      final teamARes = await http.get(Uri.parse('http://192.168.1.134:3000/team/members?teamId=$teamAId'));
      final teamBRes = await http.get(Uri.parse('http://192.168.1.134:3000/team/members?teamId=$teamBId'));
      if (teamARes.statusCode == 200 && teamBRes.statusCode == 200) {
        final teamAData = json.decode(teamARes.body);
        final teamBData = json.decode(teamBRes.body);
        teamAPlayers = (teamAData['members'] as List<dynamic>? ?? []).cast<String>();
        teamBPlayers = (teamBData['members'] as List<dynamic>? ?? []).cast<String>();
        loading = false;
      } else {
        error = 'Failed to fetch team members.';
        loading = false;
      }
    } catch (e) {
      error = 'Error fetching team members.';
      loading = false;
    }
    notifyListeners();
  }
}

