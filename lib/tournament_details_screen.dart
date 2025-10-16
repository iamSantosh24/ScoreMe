import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:scorer/config.dart';

class TournamentDetailsScreen extends StatefulWidget {
  final String tournamentName;
  final String tournamentId;
  const TournamentDetailsScreen({super.key, required this.tournamentName, required this.tournamentId});

  @override
  State<TournamentDetailsScreen> createState() => _TournamentDetailsScreenState();
}

class _TournamentDetailsScreenState extends State<TournamentDetailsScreen> {
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _groupCountController = TextEditingController();

  List<String> teams = [];
  Map<String, List<String>> teamPlayers = {};
  bool groupsCreated = false;
  Map<String, List<String>> groups = {};
  String sortType = 'Random';
  String? selectedTeamToRemove;

  Future<void> _addTeam() async {
    final teamName = _teamNameController.text.trim();
    if (teamName.isNotEmpty && !teams.contains(teamName)) {
      final response = await http.post(
        Uri.parse('${Config.apiBaseUrl}/teams'),
        headers: {'Content-Type': 'application/json'},
        body: '{"name":"$teamName","tournamentId":"${widget.tournamentId}"}',
      );
      if (response.statusCode == 200) {
        setState(() {
          teams.add(teamName);
          teamPlayers[teamName] = [];
          _teamNameController.clear();
        });
      }
    }
  }

  void _removeTeam() {
    if (selectedTeamToRemove != null && teams.contains(selectedTeamToRemove)) {
      setState(() {
        teams.remove(selectedTeamToRemove);
        teamPlayers.remove(selectedTeamToRemove);
        selectedTeamToRemove = null;
      });
    }
  }

  void _addPlayer(String team) {
    final playerName = _playerNameController.text.trim();
    if (playerName.isNotEmpty) {
      setState(() {
        teamPlayers[team]?.add(playerName);
        _playerNameController.clear();
      });
    }
  }

  void _createGroups() {
    final groupCount = int.tryParse(_groupCountController.text.trim()) ?? 0;
    if (groupCount <= 0 || teams.isEmpty) return;
    setState(() {
      groups.clear();
      groupsCreated = true;
      List<String> sortedTeams = List.from(teams);
      if (sortType == 'Random') {
        sortedTeams.shuffle();
      }
      for (int i = 0; i < groupCount; i++) {
        groups['Group ${i + 1}'] = [];
      }
      for (int i = 0; i < sortedTeams.length; i++) {
        groups['Group ${(i % groupCount) + 1}']?.add(sortedTeams[i]);
      }
    });
  }

  void _assignTeamToGroup(String team, String group) {
    setState(() {
      groups.forEach((g, tList) => tList.remove(team));
      groups[group]?.add(team);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tournamentName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create Team', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: _teamNameController, decoration: const InputDecoration(labelText: 'Team Name')),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _addTeam, child: const Text('Add Team')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedTeamToRemove,
                    hint: const Text('Select Team to Remove'),
                    items: teams.map((team) => DropdownMenuItem(value: team, child: Text(team))).toList(),
                    onChanged: (value) {
                      setState(() { selectedTeamToRemove = value; });
                    },
                  ),
                ),
                ElevatedButton(onPressed: _removeTeam, child: const Text('Remove Team')),
              ],
            ),
            const Divider(height: 32),
            const Text('Edit Players in Roster', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...teams.map((team) => Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ...?teamPlayers[team]?.map((player) => ListTile(title: Text(player))),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _playerNameController, decoration: const InputDecoration(labelText: 'Player Name'))),
                        ElevatedButton(onPressed: () => _addPlayer(team), child: const Text('Add Player')),
                      ],
                    ),
                  ],
                ),
              ),
            )),
            const Divider(height: 32),
            const Text('Create Groups', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: _groupCountController, decoration: const InputDecoration(labelText: 'Number of Groups'), keyboardType: TextInputType.number),
            Row(
              children: [
                const Text('Sort Type: '),
                DropdownButton<String>(
                  value: sortType,
                  items: const [
                    DropdownMenuItem(value: 'Random', child: Text('Random')),
                    DropdownMenuItem(value: 'Manual', child: Text('Manual')),
                  ],
                  onChanged: (value) {
                    setState(() { sortType = value!; });
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton(onPressed: _createGroups, child: const Text('Create Groups')),
              ],
            ),
            if (groupsCreated) ...[
              const SizedBox(height: 16),
              ...groups.entries.map((entry) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ...entry.value.map((team) => ListTile(
                        title: Text(team),
                        trailing: sortType == 'Manual'
                          ? DropdownButton<String>(
                              value: entry.key,
                              items: groups.keys.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                              onChanged: (newGroup) {
                                if (newGroup != null) _assignTeamToGroup(team, newGroup);
                              },
                            )
                          : null,
                      )),
                    ],
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
