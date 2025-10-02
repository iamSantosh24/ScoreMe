import 'package:flutter/material.dart';
import 'PlayerProfileScreen.dart';
import 'leagues_util.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'ProfileScreen.dart';

class GameHomeScreen extends StatefulWidget {
  final Map<String, dynamic> game;
  const GameHomeScreen({super.key, required this.game});

  @override
  State<GameHomeScreen> createState() => _GameHomeScreenState();
}

class _GameHomeScreenState extends State<GameHomeScreen> with SingleTickerProviderStateMixin {
  List<String> teamAPlayers = [];
  List<String> teamBPlayers = [];
  bool loading = true;
  String error = '';
  final ScrollController _teamAScrollController = ScrollController();
  final ScrollController _teamBScrollController = ScrollController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        if (_tabController.index == 0) {
          _teamAScrollController.jumpTo(0);
        } else if (_tabController.index == 1) {
          _teamBScrollController.jumpTo(0);
        }
      }
    });
    fetchTeamMembers();
  }

  @override
  void dispose() {
    _teamAScrollController.dispose();
    _teamBScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchTeamMembers() async {
    final teamAId = widget.game['teamAId'] ?? '';
    final teamBId = widget.game['teamBId'] ?? '';
    try {
      final teamARes = await http.get(Uri.parse('http://192.168.1.134:3000/team/members?teamId=$teamAId'));
      final teamBRes = await http.get(Uri.parse('http://192.168.1.134:3000/team/members?teamId=$teamBId'));
      if (teamARes.statusCode == 200 && teamBRes.statusCode == 200) {
        final teamAData = json.decode(teamARes.body);
        final teamBData = json.decode(teamBRes.body);
        setState(() {
          teamAPlayers = (teamAData['members'] as List<dynamic>? ?? []).cast<String>();
          teamBPlayers = (teamBData['members'] as List<dynamic>? ?? []).cast<String>();
          loading = false;
        });
      } else {
        setState(() {
          error = 'Failed to fetch team members.';
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error fetching team members.';
        loading = false;
      });
    }
  }

  Future<void> openProfileOrPlayer(BuildContext context, String username) async {
    final storage = const FlutterSecureStorage();
    final loggedInUsername = await storage.read(key: 'auth_username');
    if (loggedInUsername == username) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlayerProfileScreen(username: username)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamA = widget.game['teamAName'] ?? widget.game['teamA'] ?? '';
    final teamB = widget.game['teamBName'] ?? widget.game['teamB'] ?? '';
    final dateStr = widget.game['scheduledDate']?.toString() ?? widget.game['date']?.toString();
    final date = dateStr != null && dateStr.isNotEmpty ? DateTime.parse(dateStr).toLocal() : null;
    String formattedDate = '';
    String formattedTime = '';
    if (date != null) {
      formattedDate = monthName(date.month) + ' ' + date.day.toString().padLeft(2, '0') + ', ' + date.year.toString();
      formattedTime = formatTime(date);
    }
    final location = widget.game['location'] ?? '';
    final leagueName = widget.game['leagueName'] ?? '';
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Game Details'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error.isNotEmpty
                  ? Center(child: Text(error, style: const TextStyle(color: Colors.red)))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$teamA vs $teamB', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (formattedDate.isNotEmpty && formattedTime.isNotEmpty)
                          Text('Date: $formattedDate at $formattedTime', style: const TextStyle(fontSize: 16)),
                        if (location.isNotEmpty)
                          Text('Location: $location', style: const TextStyle(fontSize: 16)),
                        if (leagueName.isNotEmpty)
                          Text('League: $leagueName', style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 16),
                        TabBar(
                          controller: _tabController,
                          tabs: [
                            Tab(text: teamA.isNotEmpty ? teamA : 'Team A'),
                            Tab(text: teamB.isNotEmpty ? teamB : 'Team B'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _TeamPlayersTab(players: teamAPlayers, onTap: openProfileOrPlayer, scrollController: _teamAScrollController),
                              _TeamPlayersTab(players: teamBPlayers, onTap: openProfileOrPlayer, scrollController: _teamBScrollController),
                            ],
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _TeamPlayersTab extends StatelessWidget {
  final List<String> players;
  final Function(BuildContext, String) onTap;
  final ScrollController scrollController;
  const _TeamPlayersTab({required this.players, required this.onTap, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    if (players.isNotEmpty) {
      return Expanded(
        child: ListView.builder(
          controller: scrollController,
          padding: EdgeInsets.zero,
          itemCount: players.length,
          itemBuilder: (context, idx) {
            final username = players[idx];
            return ListTile(
              title: Text(username),
              onTap: () {
                onTap(context, username);
              },
            );
          },
        ),
      );
    } else {
      return const Center(child: Text('No players found for this team.'));
    }
  }
}
