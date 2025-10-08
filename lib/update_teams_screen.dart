import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UpdateTeamsScreen extends StatefulWidget {
  final String leagueId;
  final String leagueName;
  const UpdateTeamsScreen({super.key, required this.leagueId, required this.leagueName});

  @override
  State<UpdateTeamsScreen> createState() => _UpdateTeamsScreenState();
}

class _UpdateTeamsScreenState extends State<UpdateTeamsScreen> {
  List<String> teams = [];
  bool isLoading = true;
  final TextEditingController _teamController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTeams();
  }

  Future<void> _fetchTeams() async {
    setState(() { isLoading = true; });
    final response = await http.get(Uri.parse('http://192.168.1.134:3000/leagues'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final league = (data as List).firstWhere((l) => l['_id'] == widget.leagueId, orElse: () => null);
      if (league != null && league['teams'] != null) {
        setState(() {
          teams = List<String>.from(league['teams']);
        });
      }
    }
    setState(() { isLoading = false; });
  }

  void _addTeam() {
    final name = _teamController.text.trim();
    if (name.isNotEmpty && !teams.contains(name)) {
      setState(() { teams.add(name); });
      _teamController.clear();
    }
  }

  void _removeTeam(String name) {
    setState(() { teams.remove(name); });
  }

  Future<void> _saveTeams() async {
    setState(() { isLoading = true; });
    final response = await http.put(
      Uri.parse('http://192.168.1.134:3000/leagues/${widget.leagueId}/teams'),
      headers: { 'Content-Type': 'application/json' },
      body: json.encode({ 'teams': teams }),
    );
    setState(() { isLoading = false; });
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teams updated successfully')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update teams')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Update Teams: ${widget.leagueName}')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _teamController,
                          decoration: const InputDecoration(labelText: 'Add Team Name'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addTeam,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: teams.length,
                    itemBuilder: (context, index) {
                      final name = teams[index];
                      return ListTile(
                        title: Text(name),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeTeam(name),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _saveTeams,
                    child: const Text('Save Teams'),
                  ),
                ),
              ],
            ),
    );
  }
}
