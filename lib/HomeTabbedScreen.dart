import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'AppDrawer.dart';
import 'MatchScheduleScreen.dart';
import 'viewmodels/HomeTabbedViewModel.dart';
import 'widgets/GameCard.dart';
import 'widgets/LeagueCard.dart';

class HomeTabbedScreen extends StatefulWidget {
  final String username;

  const HomeTabbedScreen({super.key, required this.username});

  @override
  State<HomeTabbedScreen> createState() => _HomeTabbedScreenState();
}

class _HomeTabbedScreenState extends State<HomeTabbedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late HomeTabbedViewModel viewModel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    viewModel = HomeTabbedViewModel();
    viewModel.fetchUserLeaguesAndGames(widget.username);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void openLeagueSchedule(String leagueId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchScheduleScreen(
          leagueName: leagueId,
          scheduledGames: viewModel.scheduledGames,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<HomeTabbedViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Home'),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'My Games'),
                  Tab(text: 'My Leagues'),
                ],
              ),
            ),
            drawer: const AppDrawer(),
            body: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : vm.error.isNotEmpty
                ? Center(
                    child: Text(
                      vm.error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // My Games Tab
                      vm.scheduledGames.isEmpty
                          ? const Center(child: Text('No scheduled games found'))
                          : ListView.builder(
                              itemCount: vm.scheduledGames.length,
                              itemBuilder: (context, index) {
                                final game = vm.scheduledGames[index];
                                final leagueName = game['leagueName'] ?? '';
                                final gameName = game['gameName'] ?? '';
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (leagueName.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        child: Text('League: $leagueName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      ),
                                    if (gameName.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                        child: Text('Game: $gameName', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                      ),
                                    GameCard(game: game),
                                  ],
                                );
                              },
                            ),
                      // My Leagues Tab
                      vm.leagues.isEmpty
                          ? const Center(child: Text('No leagues found'))
                          : ListView.builder(
                              itemCount: vm.leagues.length,
                              itemBuilder: (context, index) {
                                final league = vm.leagues[index];
                                return LeagueCard(
                                  league: league,
                                  onTap: () => openLeagueSchedule(league.id),
                                );
                              },
                            ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
