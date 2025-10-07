import 'package:flutter/material.dart';
import 'leagues_util.dart';
import 'package:provider/provider.dart';
import 'viewmodels/LeagueHomeViewModel.dart';
import 'widgets/GameCard.dart';
import 'match_results_screen.dart';

class LeagueHomeScreen extends StatefulWidget {
  final League league;
  final List<dynamic> scheduledGames;
  const LeagueHomeScreen({super.key, required this.league, required this.scheduledGames});

  @override
  State<LeagueHomeScreen> createState() => _LeagueHomeScreenState();
}

class _LeagueHomeScreenState extends State<LeagueHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Widget buildScheduledTab() {
    if (widget.scheduledGames.isEmpty) {
      return const Center(child: Text('No scheduled games found'));
    }
    return ListView.builder(
      itemCount: widget.scheduledGames.length,
      itemBuilder: (context, index) {
        final game = widget.scheduledGames[index];
        return GameCard(game: game, variant: GameCardVariant.scheduled);
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LeagueHomeViewModel(league: widget.league),
      child: Consumer<LeagueHomeViewModel>(
        builder: (context, vm, _) {
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
                MatchResultsScreen(league: widget.league.id),
                buildScheduledTab(),
              ],
            ),
          );
        },
      ),
    );
  }
}
