import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorer/league_home_screen.dart';
import 'package:scorer/team_home_screen.dart';
import 'app_drawer.dart';
import 'viewmodels/HomeTabbedViewModel.dart';
import 'league_management_screen.dart';
import 'team_management_screen.dart';
import 'shared_utils.dart';

class HomeTabbedScreen extends StatefulWidget {
  const HomeTabbedScreen({super.key});

  @override
  State<HomeTabbedScreen> createState() => _HomeTabbedScreenState();
}

class _HomeTabbedScreenState extends State<HomeTabbedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String email;
  late String role;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    email = SharedUser.email ?? '';
    // Prefer god_admin if true, else use first role from roles
    if (SharedUser.godAdmin) {
      role = 'god_admin';
    } else if (SharedUser.roles != null && SharedUser.roles!.isNotEmpty) {
      role = SharedUser.roles![0]['role'] ?? 'player';
    } else {
      role = 'player';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<HomeTabbedViewModel>(context, listen: false);
      vm.fetchLeagues();
      vm.fetchTeams();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildLeaguesTab(HomeTabbedViewModel viewModel) {
    return Column(
      children: [
        if (role == 'god_admin')
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LeagueManagementScreen(),
                    ),
                  ).then((_) {
                    final vm = Provider.of<HomeTabbedViewModel>(context, listen: false);
                    vm.fetchLeagues();
                  });
                },
                child: const Text('Manage League'),
              ),
            ),
          ),
        Expanded(
          child: viewModel.isLoadingLeagues
              ? const Center(child: CircularProgressIndicator())
              : (viewModel.leaguesError != null && viewModel.leaguesError!.isNotEmpty)
                  ? Center(child: Text(viewModel.leaguesError!))
                  : (viewModel.leagues.isEmpty)
                      ? const Center(child: Text('No leagues found'))
                      : ListView.builder(
                          itemCount: viewModel.leagues.length,
                          itemBuilder: (context, index) {
                            final league = viewModel.leagues[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text(league.name),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LeagueHomeScreen(league: league),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildTeamsTab(HomeTabbedViewModel viewModel) {
    return Column(
      children: [
        if (role == 'super_admin' || role == 'god_admin')
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeamManagementScreen(),
                    ),
                  ).then((_) {
                    final vm = Provider.of<HomeTabbedViewModel>(context, listen: false);
                    vm.fetchTeams();
                  });
                },
                child: const Text('Manage Teams'),
              ),
            ),
          ),
        Expanded(
          child: viewModel.isLoadingTeams
              ? const Center(child: CircularProgressIndicator())
              : (viewModel.teamsError != null && viewModel.teamsError!.isNotEmpty)
                  ? Center(child: Text(viewModel.teamsError!))
                  : (viewModel.teams.isEmpty)
                      ? const Center(child: Text('No teams found'))
                      : ListView.builder(
                          itemCount: viewModel.teams.length,
                          itemBuilder: (context, index) {
                            final team = viewModel.teams[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text(team['teamName'] ?? 'Team'),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TeamHomeScreen(
                                        team: team
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Games'),
            Tab(text: 'My Leagues'),
            Tab(text: 'My Teams'),
          ],
        ),
      ),
      drawer: AppDrawer(role: role, email: email),
      body: Consumer<HomeTabbedViewModel>(
        builder: (context, viewModel, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              const Center(child: Text('No games to show.')), // My Games Tab
              _buildLeaguesTab(viewModel), // My Leagues Tab
              _buildTeamsTab(viewModel), // My Teams Tab
            ],
          );
        },
      ),
    );
  }
}
