// League service: create leagues and fetch teams/leagues
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:scorer/models/role_models.dart';
import 'package:scorer/config.dart';

class LeagueService {
  final String baseUrl;
  final dynamic _storage;
  final http.Client client;

  LeagueService({String? baseUrl, http.Client? client, dynamic storage})
      : baseUrl = baseUrl ?? Config.apiBaseUrl,
        client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  Future<Map<String, String>> _authHeaders() async {
    String? token;
    try {
      token = await _storage.read(key: 'auth_token');
    } catch (_) {
      try {
        token = await _storage.read('auth_token');
      } catch (_) {
        token = null;
      }
    }
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<bool> createLeague({required String leagueName, required String sport, required String status, List<dynamic>? teams}) async {
    final payload = {
      'leagueName': leagueName,
      'sport': sport,
      'status': status,
      'teams': teams ?? [],
    };
    try {
      final headers = await _authHeaders();
      final res = await client.post(Uri.parse('$baseUrl/add-league'), headers: headers, body: json.encode(payload));
      return res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<List<Team>> fetchTeams() async {
    try {
      final res = await client.get(Uri.parse('$baseUrl/api/teams'));
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        return data.map((e) => Team.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<LeagueItem>> fetchLeagues() async {
    try {
      final res = await client.get(Uri.parse('$baseUrl/api/leagues'));
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        return data.map((e) => LeagueItem.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }
}
