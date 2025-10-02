import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlayerProfileScreen extends StatefulWidget {
  final String username;
  const PlayerProfileScreen({super.key, required this.username});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  String teamName = '';
  String contactNumber = '';
  bool loading = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchPlayerDetails();
  }

  Future<void> fetchPlayerDetails() async {
    setState(() { loading = true; });
    final res = await http.get(
      Uri.parse('http://192.168.1.134:3000/player?username=${widget.username}'),
    );
    setState(() { loading = false; });
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        teamName = data['teamName'] ?? '';
        contactNumber = data['contactNumber'] ?? '';
      });
    } else {
      setState(() { error = 'Failed to fetch player details'; });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                ],
              ),
            ),
    );
  }
}

