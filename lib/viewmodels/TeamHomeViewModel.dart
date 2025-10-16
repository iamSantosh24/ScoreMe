import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:scorer/config.dart';

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
      final response = await http.get(Uri.parse('${Config.apiBaseUrl}/team-members/$teamId'));
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
