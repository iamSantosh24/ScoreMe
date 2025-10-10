import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LeagueManagementViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  Future<bool> createLeague({
    required String leagueName,
    required String sport,
    required String status,
    List<dynamic>? teams,
  }) async {
    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();
    final payload = {
      'leagueName': leagueName,
      'sport': sport,
      'status': status,
      'teams': teams ?? [],
    };
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.134:3000/add-league'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      if (response.statusCode == 201) {
        successMessage = 'League created successfully!';
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        String errorMsg = 'Failed to create league.';
        try {
          final data = json.decode(response.body);
          if (data['error'] != null) errorMsg = data['error'];
        } catch (_) {}
        errorMessage = errorMsg;
        isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      errorMessage = 'Network error.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

