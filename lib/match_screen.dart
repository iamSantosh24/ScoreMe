import 'package:flutter/material.dart';
import 'match_results_screen.dart';
import 'match_schedule_screen.dart';
import 'match_creation_screen.dart';

class MatchScreen extends StatefulWidget {
  final String league;

  const MatchScreen({super.key, required this.league});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRIC - SCORER'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Results'),
            Tab(text: 'Scheduled'),
            Tab(text: 'Create a Match'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.league,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Results tab
                MatchResultsScreen(league: widget.league),
                // Scheduled tab
                MatchScheduleScreen(leagueId: widget.league),
                // Create a Match tab
                MatchCreationScreen(league: widget.league),
              ],
            ),
          ),
        ],
      ),
    );
  }
}