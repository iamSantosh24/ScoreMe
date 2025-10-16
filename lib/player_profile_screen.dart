import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:scorer/config.dart';

class PlayerProfileScreen extends StatefulWidget {
  final String username;
  final String role;
  const PlayerProfileScreen({super.key, required this.username, required this.role});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  String teamName = '';
  String contactNumber = '';
  bool loading = false;
  String error = '';
  String playerRole = '';

  @override
  void initState() {
    super.initState();
    fetchPlayerDetails();
  }

  Future<void> fetchPlayerDetails() async {
    setState(() { loading = true; });
    final res = await http.get(
      Uri.parse('${Config.apiBaseUrl}/player?username=${widget.username}'),
    );
    setState(() { loading = false; });
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        teamName = data['teamName'] ?? '';
        contactNumber = data['contactNumber'] ?? '';
        playerRole = data['role'] ?? '';
      });
    } else {
      setState(() { error = 'Failed to fetch player details'; });
    }
  }

  Future<void> assignRole(String newRole) async {
    final res = await http.post(
      Uri.parse('${Config.apiBaseUrl}/user/assign-role'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': widget.username,
        'role': newRole,
      }),
    );
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role changed to $newRole')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change role')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('PlayerProfileScreen role: \'${widget.role}\''); // Debug print
    return Scaffold(
      appBar: AppBar(title: Text('Player: ${widget.username}')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Username: ${widget.username}', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 24),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Team Name (optional)'),
                    onChanged: (val) => teamName = val,
                    controller: TextEditingController(text: teamName),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Contact Number (optional)'),
                    onChanged: (val) => contactNumber = val,
                    controller: TextEditingController(text: contactNumber),
                  ),
                  const SizedBox(height: 16),
                  if (error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(error, style: const TextStyle(color: Colors.red)),
                    ),
                  if (widget.role == 'god_admin' || widget.role == 'super_admin')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text('Player\'s Current Role: ' + (playerRole.isNotEmpty ? playerRole : 'Player'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  if (widget.role == 'god_admin' || widget.role == 'super_admin')
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        child: const Text('Make'),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              List<String> options = [];
                              if (widget.role == 'god_admin') {
                                options = ['Super Admin', 'Admin'];
                              } else if (widget.role == 'super_admin') {
                                options = ['Admin'];
                              }
                              return AlertDialog(
                                title: const Text('Make user'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: options.map((opt) => ListTile(
                                    title: Text(opt),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      String backendRole = opt == 'Super Admin' ? 'super_admin' : 'admin';
                                      await assignRole(backendRole);
                                    },
                                  )).toList(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
