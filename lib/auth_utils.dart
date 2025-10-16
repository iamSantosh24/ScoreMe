import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:scorer/config.dart';
import 'shared_utils.dart';

class AuthUtils {
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static Future<bool> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('${Config.apiBaseUrl}/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final token = data['token'] ?? '';
      await _secureStorage.write(key: 'auth_token', value: token);
      SharedUser.setUserDetails(
        firstName: data['firstName'] ?? '',
        lastName: data['lastName'] ?? '',
        email: data['email'] ?? '',
        contactNumber: data['contactNumber'] ?? '',
        profileId: data['profileId'] ?? '',
        roles: data['roles'] ?? [],
        godAdmin: data['god_admin'] ?? false,
      );
      return true;
    }
    return false;
  }
}
