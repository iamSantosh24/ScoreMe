import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TeamHomeViewModel extends ChangeNotifier {
  bool loading = false;
  String error = '';
  List<String> teamMembers = [];

  Future<void> fetchTeamMembers(String teamId) async {
    loading = true;
    error = '';
    notifyListeners();
    try {
      // Fetch the team members from the new endpoint
      final response = await http.get(Uri.parse('http://192.168.1.134:3000/team-members/$teamId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // 'players' is a list of player names
        teamMembers = (data['players'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
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
