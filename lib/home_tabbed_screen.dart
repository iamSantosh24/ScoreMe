import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_drawer.dart';
import 'viewmodels/HomeTabbedViewModel.dart';
import 'widgets/GameCard.dart';
import 'leagues_util.dart';
import 'league_home_screen.dart';
import 'team_home_screen.dart';
import 'league_management_screen.dart'; // Import the TournamentManagementScreen

class HomeTabbedScreen extends StatefulWidget {
  final String username;
  final String role;

  const HomeTabbedScreen({super.key, required this.username, required this.role});

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
            drawer: AppDrawer(role: widget.role, username: widget.username),
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
                        final upcomingGames = vm.upcomingScheduledGames;
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
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                        : Column(
                            children: [
                              if (widget.role == 'god_admin')
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.add),
                                    label: const Text('Manage Leagues'),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const LeagueManagementScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: vm.leagues.length,
                                itemBuilder: (context, index) {
                                  final league = vm.leagues[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    child: ListTile(
                                      title: Text(league.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => LeagueHomeScreen(
                                              league: league,
                                              scheduledGames: viewModel.upcomingScheduledGames,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                      // My Teams Tab
                      vm.teams == null || vm.teams.isEmpty
                          ? const Center(child: Text('No teams found'))
                          : ListView.builder(
                              itemCount: vm.teams.length,
                              itemBuilder: (context, index) {
                                final team = vm.teams[index];
                                // Find leagues for this team
                                final teamLeagues = vm.leagues.where((league) {
                                  if (league.id != null && team['leagueId'] != null) {
                                    if (team['leagueId'] is List) {
                                      return team['leagueId'].contains(league.id);
                                    } else {
                                      return team['leagueId'] == league.id;
                                    }
                                  }
                                  return false;
                                }).toList();
                                // Find scheduled games for this team
                                final teamGames = viewModel.upcomingScheduledGames.where((game) =>
                                  game['teamAId'] == team['_id'] || game['teamBId'] == team['_id']
                                ).toList();
                                print('Upcoming Games: ${viewModel.upcomingScheduledGames}');
                                print('TeamGames: $teamGames');
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                  child: ListTile(
                                    title: Text(team['name'] ?? 'Team', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TeamHomeScreen(
                                            team: team,
                                            leagues: teamLeagues,
                                            scheduledGames: teamGames,
                                            role: widget.role,
                                          ),
                                        ),
                                      );
                                    },
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
