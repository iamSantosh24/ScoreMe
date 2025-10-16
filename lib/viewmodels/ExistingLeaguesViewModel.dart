import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:scorer/config.dart';

class ExistingLeaguesViewModel extends ChangeNotifier {
  List<Map<String, dynamic>> leagues = [];
  bool isLoading = true;
  String? error;

  Future<void> fetchLeagues() async {
    isLoading = true;
    error = null;
    notifyListeners();
    final response = await http.get(Uri.parse('${Config.apiBaseUrl}/leagues'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      leagues = List<Map<String, dynamic>>.from(data);
      isLoading = false;
    } else {
      error = 'Failed to load leagues.';
      isLoading = false;
    }
    notifyListeners();
  }
}
