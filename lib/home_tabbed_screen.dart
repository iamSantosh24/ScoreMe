import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_drawer.dart';
import 'match_schedule_screen.dart';
import 'viewmodels/HomeTabbedViewModel.dart';
import 'widgets/GameCard.dart';
import 'widgets/LeagueCard.dart';
import 'leagues_util.dart';

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
    _tabController = TabController(length: 3, vsync: this);
    viewModel = HomeTabbedViewModel();
    // Fetch all tab data once after login
    viewModel.fetchAllTabData(widget.username);
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
                  Tab(text: 'My Teams'), // New tab
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
                      (() {
                        final sortedGames = List<Map<String, dynamic>>.from(vm.scheduledGames);
                        sortedGames.sort((a, b) {
                          final aDateStr = a['scheduledDate']?.toString() ?? '';
                          final bDateStr = b['scheduledDate']?.toString() ?? '';
                          DateTime? aDate = aDateStr.isNotEmpty ? DateTime.tryParse(aDateStr) : null;
                          DateTime? bDate = bDateStr.isNotEmpty ? DateTime.tryParse(bDateStr) : null;
                          if (aDate == null && bDate == null) return 0;
                          if (aDate == null) return 1;
                          if (bDate == null) return -1;
                          return aDate.compareTo(bDate);
                        });
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        final upcomingGames = sortedGames.where((game) {
                          final dateStr = game['scheduledDate']?.toString() ?? '';
                          if (dateStr.isEmpty) return false;
                          final gameDate = DateTime.tryParse(dateStr)?.toLocal();
                          if (gameDate == null) return false;
                          final gameDay = DateTime(gameDate.year, gameDate.month, gameDate.day);
                          return !gameDay.isBefore(today);
                        }).toList();
                        return upcomingGames.isEmpty
                            ? const Center(child: Text('No scheduled games found'))
                            : ListView.builder(
                                itemCount: upcomingGames.length,
                                itemBuilder: (context, index) {
                                  final game = upcomingGames[index];
                                  final dateStr = game['scheduledDate']?.toString() ?? '';
                                  String formattedDate = '';
                                  if (dateStr.isNotEmpty) {
                                    try {
                                      final date = DateTime.parse(dateStr).toLocal();
                                      final month = monthName(date.month);
                                      final time = formatTime(date);
                                      formattedDate = '$month ${date.day.toString().padLeft(2, '0')}, ${date.year} at $time';
                                    } catch (_) {}
                                  }
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (formattedDate.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          child: Text(
                                            formattedDate,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      GameCard(game: game),
                                    ],
                                  );
                                },
                              );
                      })(),
                      // My Leagues Tab
                      vm.leagues.isEmpty
                          ? const Center(child: Text('No leagues found'))
                          : ListView.builder(
                              itemCount: vm.leagues.length,
                              itemBuilder: (context, index) {
                                final league = vm.leagues[index];
                                print('LeagueCard league: ${league.toJson()}');
                                return LeagueCard(
                                  league: league,
                                  onTap: () => openLeagueSchedule(league.id),
                                );
                              },
                            ),
                      // My Teams Tab
                      vm.teams == null || vm.teams.isEmpty
                          ? const Center(child: Text('No teams found'))
                          : ListView.builder(
                              itemCount: vm.teams.length,
                              itemBuilder: (context, index) {
                                final team = vm.teams[index];
                                // If you have a TeamCard widget, use it here. Otherwise, use a simple Card.
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: ListTile(
                                    title: Text(team['name'] ?? 'Team'),
                                    subtitle: Text(
                                      'Sport: ${team['sport'] ?? ''}',
                                    ),
                                  ),
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
