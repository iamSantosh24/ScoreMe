import 'package:flutter/material.dart';
import 'leagues_util.dart';
import 'package:provider/provider.dart';
import 'viewmodels/LeagueHomeViewModel.dart';
import 'widgets/GameCard.dart';
import 'match_results_screen.dart';
import 'widgets/points_table_widget.dart';
import 'widgets/player_stats_widget.dart';
import 'models/league.dart';

class LeagueHomeScreen extends StatefulWidget {
  final League league;
  const LeagueHomeScreen({super.key, required this.league});

  @override
  State<LeagueHomeScreen> createState() => _LeagueHomeScreenState();
}

class _LeagueHomeScreenState extends State<LeagueHomeScreen> with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _matchesTabController;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
    _matchesTabController = TabController(length: 2, vsync: this);
  }

  Widget buildScheduledTab(LeagueHomeViewModel vm) {
    final scheduledGames = vm.scheduledGames?.where((game) {
      return game['leagueId'] == widget.league.id;
    }).toList() ?? [];

    if (scheduledGames.isEmpty) {
      return const Center(child: Text('No scheduled games found'));
    }
    return ListView.builder(
      itemCount: scheduledGames.length,
      itemBuilder: (context, index) {
        final game = scheduledGames[index];
        return GameCard(game: game, variant: GameCardVariant.scheduled);
      },
    );
  }

  Widget buildMatchesTab(LeagueHomeViewModel vm) {
    return Column(
      children: [
        TabBar(
          controller: _matchesTabController,
          tabs: const [
            Tab(text: 'Results'),
            Tab(text: 'Scheduled'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _matchesTabController,
            children: [
              MatchResultsScreen(league: widget.league.id),
              buildScheduledTab(vm),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _matchesTabController.dispose();
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
                controller: _mainTabController,
                tabs: const [
                  Tab(text: 'Matches'),
                  Tab(text: 'Points Table'),
                  Tab(text: 'Player Stats'),
                  Tab(text: 'Rules'),
                ],
              ),
            ),
            body: TabBarView(
              controller: _mainTabController,
              children: [
                buildMatchesTab(vm),
                PointsTableWidget(leagueId: widget.league.id),
                PlayerStatsWidget(),
              ],
            ),
          );
        },
      ),
    );
  }
}
