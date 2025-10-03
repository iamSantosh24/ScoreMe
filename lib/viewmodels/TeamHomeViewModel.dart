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
      final response = await http.get(Uri.parse('http://192.168.1.134:3000/team/members?teamId=$teamId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        teamMembers = (data['members'] as List<dynamic>? ?? []).cast<String>();
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

