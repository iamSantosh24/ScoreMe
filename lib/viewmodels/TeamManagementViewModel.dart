import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:scorer/config.dart';

class TeamManagementViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  Future<void> createTeam({required String teamName}) async {
    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('${Config.apiBaseUrl}/add-teams'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'teamName': teamName,
          'players': [],
        }),
      );
      if (response.statusCode == 201) {
        successMessage = 'Team "$teamName" created!';
      } else {
        errorMessage = json.decode(response.body)['error'] ?? 'Failed to create team.';
      }
    } catch (e) {
      errorMessage = 'Error: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
