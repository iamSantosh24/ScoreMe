import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = '';
  String newUsername = '';
  String newPassword = '';
  bool loading = false;
  String error = '';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    loadUsername();
  }

  Future<void> loadUsername() async {
    setState(() { loading = true; });
    final savedUsername = await _secureStorage.read(key: 'auth_username') ?? '';
    setState(() {
      username = savedUsername;
      loading = false;
    });
  }

  Future<void> changeUsername() async {
    setState(() { loading = true; error = ''; });
    final token = await _secureStorage.read(key: 'auth_token') ?? '';
    final res = await http.post(
      Uri.parse('http://localhost:3000/change-username'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'newUsername': newUsername}),
    );
    setState(() { loading = false; });
    if (res.statusCode == 200) {
      setState(() { username = newUsername; newUsername = ''; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username updated')));
    } else {
      setState(() { error = json.decode(res.body)['error'] ?? 'Failed to update username'; });
    }
  }

  Future<void> changePassword() async {
    setState(() { loading = true; error = ''; });
    final token = await _secureStorage.read(key: 'auth_token') ?? '';
    final res = await http.post(
      Uri.parse('http://localhost:3000/change-password'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'newPassword': newPassword}),
    );
    setState(() { loading = false; });
    if (res.statusCode == 200) {
      setState(() { newPassword = ''; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
    } else {
      setState(() { error = json.decode(res.body)['error'] ?? 'Failed to update password'; });
    }
  }

  Future<void> deleteAccount() async {
    setState(() { loading = true; error = ''; });
    final token = await _secureStorage.read(key: 'auth_token') ?? '';
    final res = await http.post(
      Uri.parse('http://localhost:3000/delete-account'),
      headers: {'Authorization': 'Bearer $token'},
    );
    setState(() { loading = false; });
    if (res.statusCode == 200) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      setState(() { error = json.decode(res.body)['error'] ?? 'Failed to delete account'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Username: $username', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 24),
                  TextField(
                    decoration: const InputDecoration(labelText: 'New Username (email)'),
                    onChanged: (val) => newUsername = val,
                  ),
                  ElevatedButton(
                    onPressed: changeUsername,
                    child: const Text('Change Username'),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    decoration: const InputDecoration(labelText: 'New Password'),
                    obscureText: true,
                    onChanged: (val) => newPassword = val,
                  ),
                  ElevatedButton(
                    onPressed: changePassword,
                    child: const Text('Change Password'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: deleteAccount,
                    child: const Text('Delete Account'),
                  ),
                  if (error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(error, style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
    );
  }
}
