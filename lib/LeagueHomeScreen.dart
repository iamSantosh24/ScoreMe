import 'package:flutter/material.dart';
import 'leagues_util.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LeagueHomeScreen extends StatefulWidget {
  final League league;
  const LeagueHomeScreen({super.key, required this.league});

  @override
  State<LeagueHomeScreen> createState() => _LeagueHomeScreenState();
}

class _LeagueHomeScreenState extends State<LeagueHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> scheduledGames = [];
  bool loadingScheduled = true;
  String errorScheduled = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchScheduledGames();
  }

  Future<void> fetchScheduledGames() async {
    setState(() {
      loadingScheduled = true;
      errorScheduled = '';
    });
    try {
      final res = await http.get(
        Uri.parse('http://192.168.1.134:3000/league/scheduled-games?leagueId=${widget.league.id}'),
      );
      print('Response Status Code: ${res.statusCode}');
      print('Response Body: ${res.body}');
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        print('Scheduled Games: $data');
        scheduledGames = data['games'] ?? [];
      } else {
        errorScheduled = 'Failed to fetch scheduled games';
      }
    } catch (e) {
      errorScheduled = 'Network error';
    }
    setState(() {
      loadingScheduled = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget buildScheduledTab() {
    if (loadingScheduled) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorScheduled.isNotEmpty) {
      return Center(child: Text(errorScheduled, style: const TextStyle(color: Colors.red)));
    }
    if (scheduledGames.isEmpty) {
      return const Center(child: Text('No scheduled games found'));
    }
    return ListView.builder(
      itemCount: scheduledGames.length,
      itemBuilder: (context, index) {
        final game = scheduledGames[index];
        final teamA = game['teamA'] ?? '';
        final teamB = game['teamB'] ?? '';
        final gameName = game['gameName'] ?? '';
        final date = game['date'] != null ? DateTime.parse(game['date']).toLocal() : null;
        String formattedDate = '';
        if (date != null) {
          formattedDate = '${monthName(date.month)} ${date.day}, ${date.year}  ${formatTime(date)}';
        }
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Game: $gameName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (formattedDate.isNotEmpty)
                  Text('Date: $formattedDate', style: const TextStyle(fontSize: 14)),
                Text('Teams: $teamA vs $teamB', style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.league.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Results'),
            Tab(text: 'Scheduled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Center(child: Text('Results for ${widget.league.name}')), // Placeholder
          buildScheduledTab(),
        ],
      ),
    );
  }
}
