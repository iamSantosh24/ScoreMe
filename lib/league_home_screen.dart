import 'package:flutter/material.dart';
import 'leagues_util.dart';
import 'package:provider/provider.dart';
import 'viewmodels/LeagueHomeViewModel.dart';
import 'widgets/GameCard.dart';
import 'match_results_screen.dart';
import 'widgets/points_table_widget.dart';
import 'widgets/player_stats_widget.dart';
import 'widgets/rules_widget.dart';

class LeagueHomeScreen extends StatefulWidget {
  final League league;
  final List<dynamic> scheduledGames;
  const LeagueHomeScreen({super.key, required this.league, required this.scheduledGames});

  @override
  State<LeagueHomeScreen> createState() => _LeagueHomeScreenState();
}

class _LeagueHomeScreenState extends State<LeagueHomeScreen> with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _matchesTabController;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 4, vsync: this);
    _matchesTabController = TabController(length: 2, vsync: this);
  }

  Widget buildScheduledTab() {
    final leagueScheduledGames = widget.scheduledGames.where((game) {
      // Adjust this property access if your game model uses a different field for league id
      return game['leagueId'] == widget.league.id;
    }).toList();
    if (leagueScheduledGames.isEmpty) {
      return const Center(child: Text('No scheduled games found'));
    }
    return ListView.builder(
      itemCount: leagueScheduledGames.length,
      itemBuilder: (context, index) {
        final game = leagueScheduledGames[index];
        return GameCard(game: game, variant: GameCardVariant.scheduled);
      },
    );
  }

  Widget buildMatchesTab() {
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
              buildScheduledTab(),
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
                buildMatchesTab(),
                PointsTableWidget(leagueId: widget.league.id),
                PlayerStatsWidget(),
                RulesWidget(),
              ],
            ),
          );
        },
      ),
    );
  }
}
