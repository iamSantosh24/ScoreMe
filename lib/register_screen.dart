import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  List<Map<String, dynamic>> _teams = [];
  List<String> _selectedTeamIds = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _fetchTeams();
  }

  Future<void> _fetchTeams() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.134:3000/teams/list'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _teams = List<Map<String, dynamic>>.from(data['teams']);
        });
      }
    } catch (e) {
      // Ignore team fetch errors for now
    }
  }

  Future<void> _sendJoinRequests(String username, List<String> teamIds) async {
    for (final teamId in teamIds) {
      try {
        await http.post(
          Uri.parse('http://192.168.1.134:3000/request-join-team'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'teamId': teamId, 'username': username}),
        );
      } catch (e) {
        // Ignore errors for individual requests
      }
    }
  }

  Future<void> _register() async {
    setState(() { _isLoading = true; _errorMessage = null; _successMessage = null; });
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final contactNumber = _contactNumberController.text.trim();
    final teams = _selectedTeamIds;
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.134:3000/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': email,
          'password': password,
          'confirmPassword': confirmPassword,
          'firstName': firstName,
          'lastName': lastName,
          'contactNumber': contactNumber.isNotEmpty ? contactNumber : null,
          'teams': teams,
        }),
      );
      setState(() { _isLoading = false; });
      if (response.statusCode == 200) {
        // Send join requests for selected teams
        if (teams.isNotEmpty) {
          await _sendJoinRequests(email, teams);
          setState(() { _successMessage = 'Registration successful! Join requests sent to team admins.'; });
        } else {
          setState(() { _successMessage = 'Registration successful!'; });
        }
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        });
      } else {
        setState(() { _errorMessage = json.decode(response.body)['error'] ?? 'Registration failed'; });
      }
    } catch (e) {
      setState(() { _isLoading = false; _errorMessage = 'Registration failed. Please try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contactNumberController,
                decoration: const InputDecoration(labelText: 'Contact Number (optional)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              if (_teams.isNotEmpty) ...[
                const Text('Select Teams (optional):', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Teams'),
                  items: _teams.map((team) => DropdownMenuItem<String>(
                    value: team['_id'],
                    child: Text('${team['name']} (${team['sport']})'),
                  )).toList(),
                  onChanged: (teamId) {
                    if (teamId != null && !_selectedTeamIds.contains(teamId)) {
                      setState(() { _selectedTeamIds.add(teamId); });
                    }
                  },
                ),
                Wrap(
                  spacing: 8,
                  children: _selectedTeamIds.map((id) {
                    final team = _teams.firstWhere((t) => t['_id'] == id, orElse: () => {});
                    return Chip(
                      label: Text(team.isNotEmpty ? '${team['name']} (${team['sport']})' : id),
                      onDeleted: () {
                        setState(() { _selectedTeamIds.remove(id); });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Register'),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
              if (_successMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(_successMessage!, style: const TextStyle(color: Colors.green)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
