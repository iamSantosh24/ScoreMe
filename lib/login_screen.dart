import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'register_screen.dart';
import 'home_tabbed_screen.dart';
import 'shared_utils.dart';
import 'forgot_password_screen.dart';

const String apiBaseUrl = 'http://192.168.1.134:3000';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final savedEmail = await _secureStorage.read(key: 'saved_email');
    final savedPassword = await _secureStorage.read(key: 'saved_password');
    if (savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  Future<void> _login() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    final email = _emailController.text;
    final password = _passwordController.text;
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      setState(() { _isLoading = false; });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (_rememberMe) {
          await _secureStorage.write(key: 'saved_email', value: email);
          await _secureStorage.write(key: 'saved_password', value: password);
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
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => HomeTabbedScreen(
            username: data['email'],
            role: data['roles'].isNotEmpty ? data['roles'][0]['role'] : 'player',
          ),
        ));
      } else {
        setState(() { _errorMessage = json.decode(response.body)['error'] ?? 'Login failed'; });
      }
    } catch (e) {
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
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() { _obscurePassword = !_obscurePassword; });
                  },
                ),
              ),
              obscureText: _obscurePassword,
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
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                  },
                  child: const Text('Forgot Password?'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Login'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('New User?'),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                  },
                  child: const Text('Register'),
                ),
              ],
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
