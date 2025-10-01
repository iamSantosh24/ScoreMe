import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'RegisterScreen.dart';
import 'HomeTabbedScreen.dart';

const String apiBaseUrl = 'http://192.168.1.134:3000'; // Replace with your actual IP

class User {
  final String username;
  final String role; // 'player', 'admin', 'super_admin'

  User({required this.username, required this.role});
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final savedUsername = await _secureStorage.read(key: 'saved_username');
    final savedPassword = await _secureStorage.read(key: 'saved_password');
    if (savedUsername != null && savedPassword != null) {
      setState(() {
        _usernameController.text = savedUsername;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  Future<void> _login() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    final username = _usernameController.text;
    final password = _passwordController.text;
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );
      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');
      setState(() { _isLoading = false; });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        if (_rememberMe) {
          await _secureStorage.write(key: 'saved_username', value: username);
          await _secureStorage.write(key: 'saved_password', value: password);
        }
        // Save token and username for profile screen
        await _secureStorage.write(key: 'auth_token', value: token);
        await _secureStorage.write(key: 'auth_username', value: username);
        // Navigate to HomeTabbedScreen after login
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeTabbedScreen(username: username)));
      } else {
        print('Login error: ${response.body}');
        setState(() { _errorMessage = json.decode(response.body)['error'] ?? 'Login failed'; });
      }
    } catch (e) {
      print('Login exception: ${e.toString()}');
      setState(() { _isLoading = false; _errorMessage = 'Login failed. Please try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (val) {
                    setState(() { _rememberMe = val ?? false; });
                  },
                ),
                const Text('Remember Me'),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Login'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
              },
              child: const Text('Register'),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
