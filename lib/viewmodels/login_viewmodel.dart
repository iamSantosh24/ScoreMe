import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../shared_utils.dart';
import '../home_tabbed_screen.dart';

const String apiBaseUrl = 'http://192.168.1.134:3000';

class LoginViewModel extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  bool isLoading = false;
  String? errorMessage;
  bool rememberMe = false;
  bool obscurePassword = true;

  LoginViewModel() {
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final savedEmail = await secureStorage.read(key: 'saved_email');
    final savedPassword = await secureStorage.read(key: 'saved_password');
    if (savedEmail != null && savedPassword != null) {
      emailController.text = savedEmail;
      passwordController.text = savedPassword;
      rememberMe = true;
      notifyListeners();
    }
  }

  void toggleRememberMe(bool? value) {
    rememberMe = value ?? false;
    notifyListeners();
  }

  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> login() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    final email = emailController.text;
    final password = passwordController.text;
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      isLoading = false;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (rememberMe) {
          await secureStorage.write(key: 'saved_email', value: email);
          await secureStorage.write(key: 'saved_password', value: password);
        }
        SharedUser.setUserDetails(
          firstName: data['firstName'] ?? '',
          lastName: data['lastName'] ?? '',
          email: data['email'] ?? '',
          contactNumber: data['contactNumber'] ?? '',
          profileId: data['profileId'] ?? '',
          roles: data['roles'] ?? [],
          godAdmin: data['god_admin'] ?? false,
        );
        notifyListeners();
        return data;
      } else {
        errorMessage = json.decode(response.body)['error'] ?? 'Login failed';
        notifyListeners();
        return null;
      }
    } catch (e) {
      isLoading = false;
      errorMessage = 'Login failed. Please try again.';
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

