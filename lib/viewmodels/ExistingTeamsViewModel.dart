import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:scorer/config.dart';

class ExistingTeamsViewModel extends ChangeNotifier {
  bool isLoading = true;
  String? error;
  List<dynamic> teams = [];

  Future<void> fetchTeams() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('${Config.apiBaseUrl}/teams'));
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
