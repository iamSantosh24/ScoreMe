import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_drawer.dart';
import 'league_home_screen.dart';
import 'viewmodels/HomeTabbedViewModel.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeTabbedViewModel>(context, listen: false).fetchLeagues();
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
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implement manage league navigation
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
                                title: Text(league['name'] ?? 'League'),
                                subtitle: Text(league['description'] ?? ''),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LeagueHomeScreen(league: league, scheduledGames: []),
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
      drawer: AppDrawer(role: widget.role, username: widget.username),
      body: Consumer<HomeTabbedViewModel>(
        builder: (context, viewModel, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              const Center(child: Text('No games to show.')), // My Games Tab
              _buildLeaguesTab(viewModel), // My Leagues Tab
              const Center(child: Text('No teams to show.')), // My Teams Tab
            ],
          );
        },
      ),
    );
  }
}
