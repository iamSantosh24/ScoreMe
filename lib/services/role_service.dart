// RoleService with injectable http client and storage for easier testing
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:scorer/models/role_models.dart';
import 'package:flutter/foundation.dart'; // for debugPrint
import 'package:scorer/config.dart';

class RoleService {
  final dynamic _storage; // accept any storage implementation with read() for testing
  final String baseUrl;
  final http.Client client;

  RoleService({String? baseUrl, http.Client? client, dynamic storage})
      : baseUrl = baseUrl ?? Config.apiBaseUrl,
        client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  Future<Map<String, String>> _authHeaders() async {
    String? token;
    try {
      token = await _storage.read(key: 'auth_token');
    } catch (_) {
      // if storage doesn't support named args, try positional (unlikely) or ignore
      try {
        token = await _storage.read('auth_token');
      } catch (_) {
        token = null;
      }
    }
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    // Debug: indicate whether we found a token (masked) so developers can see if auth headers will be sent
    try {
      final masked = (token == null || token.isEmpty) ? '<none>' : '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
      debugPrint('RoleService._authHeaders -> token: $masked');
    } catch (_) {
      debugPrint('RoleService._authHeaders -> token present');
    }
    return headers;
  }

  Future<List<User>> searchUsers(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/api/users').replace(queryParameters: query.isNotEmpty ? {'search': query} : null);
      final headers = await _authHeaders();
      final res = await client.get(uri, headers: headers);
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        return data.map((e) => User.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<Team>> fetchTeams() async {
    try {
      final headers = await _authHeaders();
      final res = await client.get(Uri.parse('$baseUrl/api/teams'), headers: headers);
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        return data.map((e) => Team.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<LeagueItem>> fetchLeagues() async {
    try {
      final headers = await _authHeaders();
      final res = await client.get(Uri.parse('$baseUrl/api/leagues'), headers: headers);
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        return data.map((e) => LeagueItem.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> assignRoleToUser({required String userId, required String role, String? teamId, String? leagueId}) async {
    try {
      final headers = await _authHeaders();
      final body = {'userId': userId, 'role': role};
      if (teamId != null) body['teamId'] = teamId;
      if (leagueId != null) body['leagueId'] = leagueId;
      final res = await client.post(Uri.parse('$baseUrl/api/assign-role'), headers: headers, body: json.encode(body));
      // Try parse message and user from body
      String? message;
      User? updatedUser;
      try {
        final decoded = res.body.isNotEmpty ? json.decode(res.body) : null;
        if (decoded is Map) {
          if (decoded['message'] != null) message = decoded['message'].toString();
          if (decoded['error'] != null && (message == null || message!.isEmpty)) message = decoded['error'].toString();
          // backend may include updated user under 'user'
          if (decoded['user'] is Map<String, dynamic>) {
            try {
              updatedUser = User.fromJson(decoded['user'] as Map<String, dynamic>);
            } catch (_) {}
          }
        }
      } catch (_) {}
      final ok = res.statusCode == 200 || res.statusCode == 201;
      return {'ok': ok, 'message': message ?? (ok ? 'Role assigned' : 'Server error'), 'user': updatedUser};
    } catch (e) {
      return {'ok': false, 'message': 'Network error'};
    }
  }

  // Remove/unassign a role from a user. Mirrors the assign endpoint's response shape.
  Future<Map<String, dynamic>> removeRoleFromUser({required String userId, required String role, String? teamId, String? leagueId}) async {
    try {
      final headers = await _authHeaders();
      final body = {'userId': userId, 'role': role};
      if (teamId != null) body['teamId'] = teamId;
      if (leagueId != null) body['leagueId'] = leagueId;
      // Try a conventional endpoint name used alongside assign-role
      final res = await client.post(Uri.parse('$baseUrl/api/remove-role'), headers: headers, body: json.encode(body));

      String? message;
      User? updatedUser;
      try {
        final decoded = res.body.isNotEmpty ? json.decode(res.body) : null;
        if (decoded is Map) {
          if (decoded['message'] != null) message = decoded['message'].toString();
          if (decoded['error'] != null && (message == null || message!.isEmpty)) message = decoded['error'].toString();
          if (decoded['user'] is Map<String, dynamic>) {
            try {
              updatedUser = User.fromJson(decoded['user'] as Map<String, dynamic>);
            } catch (_) {}
          }
        }
      } catch (_) {}

      final ok = res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204;
      return {'ok': ok, 'message': message ?? (ok ? 'Role removed' : 'Server error'), 'user': updatedUser};
    } catch (e) {
      return {'ok': false, 'message': 'Network error'};
    }
  }

  // Fetch a single user's details (includes roles, first/last name when available)
  Future<User?> getUserById(String userId) async {
    // Try a few common endpoints for fetching a single user — some backends expose different routes.
    final headers = await _authHeaders();
    final candidates = <Uri>[
      Uri.parse('$baseUrl/api/users/$userId'),
      Uri.parse('$baseUrl/api/user/$userId'),
      Uri.parse('$baseUrl/api/users').replace(queryParameters: {'id': userId}),
      Uri.parse('$baseUrl/api/users').replace(queryParameters: {'_id': userId}),
      Uri.parse('$baseUrl/api/users').replace(queryParameters: {'search': userId}),
    ];

    for (final uri in candidates) {
      try {
        final res = await client.get(uri, headers: headers);
        try {
          debugPrint('RoleService.getUserById -> GET $uri status=${res.statusCode}');
        } catch (_) {}

        if (res.statusCode != 200 || res.body.isEmpty) continue;

        // Quick heuristic: accept JSON bodies only
        final body = res.body.trimLeft();
        if (!body.startsWith('{') && !body.startsWith('[')) {
          debugPrint('RoleService.getUserById -> non-JSON response for $uri');
          continue;
        }

        final decoded = json.decode(res.body);
        if (decoded is Map<String, dynamic>) {
          return User.fromJson(decoded);
        }
        // some endpoints may return a list with single user
        if (decoded is List && decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
          return User.fromJson(decoded.first as Map<String, dynamic>);
        }
      } catch (e) {
        debugPrint('RoleService.getUserById -> error calling $uri : $e');
        // continue to next candidate
      }
    }

    return null;
  }
}
