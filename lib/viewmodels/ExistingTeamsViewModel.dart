import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ExistingTeamsViewModel extends ChangeNotifier {
  bool isLoading = true;
  String? error;
  List<dynamic> teams = [];

  Future<void> fetchTeams() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('http://192.168.1.134:3000/teams'));
      if (response.statusCode == 200) {
        teams = json.decode(response.body);
      } else {
        error = 'Failed to load teams.';
      }
    } catch (e) {
      error = 'Error: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

