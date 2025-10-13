import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/league.dart';

class HomeTabbedViewModel extends ChangeNotifier {
  List<League> leagues = [];
  bool isLoadingLeagues = false;
  String? leaguesError;

  List<dynamic> teams = [];
  bool isLoadingTeams = false;
  String? teamsError;

  Future<void> fetchLeagues() async {
    isLoadingLeagues = true;
    leaguesError = null;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('http://192.168.1.134:3000/leagues'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        leagues = data.map((item) => League.fromJson(item)).toList();
      } else {
        leaguesError = 'Failed to load leagues.';
      }
    } catch (e) {
      leaguesError = 'Error: $e';
    } finally {
      isLoadingLeagues = false;
      notifyListeners();
    }
  }

  Future<void> fetchTeams() async {
    isLoadingTeams = true;
    teamsError = null;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('http://192.168.1.134:3000/teams'));
      if (response.statusCode == 200) {
        teams = List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        teamsError = 'Failed to load teams.';
      }
    } catch (e) {
      teamsError = 'Error: $e';
    } finally {
      isLoadingTeams = false;
      notifyListeners();
    }
  }
}
