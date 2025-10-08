import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorer/update_teams_screen.dart';
import 'viewmodels/TeamHomeViewModel.dart';
import 'widgets/GameCard.dart';

class TeamHomeScreen extends StatefulWidget {
  final Map<String, dynamic> team;
  final List<dynamic> leagues;
  final List<dynamic> scheduledGames;
  final String role;

  const TeamHomeScreen({super.key, required this.team, required this.leagues, required this.scheduledGames, required this.role});

  @override
  State<TeamHomeScreen> createState() => _TeamHomeScreenState();
}

class _TeamHomeScreenState extends State<TeamHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = TeamHomeViewModel();
        final teamId = widget.team['_id'] ?? widget.team['id'];
        if (teamId != null) {
          vm.fetchTeamMembers(teamId);
        }
        return vm;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.team['name'] ?? 'Team'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.role != 'player')
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ElevatedButton(
                    onPressed: () {
                      var leagueId = widget.team['leagueId'];
                      if (leagueId is List && leagueId.isNotEmpty) {
                        leagueId = leagueId[0];
                      }
                      if (leagueId is! String) {
                        leagueId = leagueId?.toString() ?? '';
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => UpdateTeamsScreen(
                            leagueId: leagueId,
                            leagueName: widget.leagues.isNotEmpty ? (widget.leagues[0].name ?? '') : '',
                          ),
                        ),
                      );
                    },
                    child: const Text('Update Team Info'),
                  ),
                ),
              Text('Leagues:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ...widget.leagues.map((league) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(league.name ?? league.toString(), style: const TextStyle(fontSize: 15)),
                  )),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Players'),
                  Tab(text: 'Schedule'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Players Tab
                    Consumer<TeamHomeViewModel>(
                      builder: (context, vm, _) {
                        if (vm.loading) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (vm.error.isNotEmpty) {
                          return Center(child: Text(vm.error, style: const TextStyle(color: Colors.red)));
                        } else if (vm.teamMembers.isEmpty) {
                          return const Center(child: Text('No players found'));
                        } else {
                          return ListView.builder(
                            itemCount: vm.teamMembers.length,
                            itemBuilder: (context, idx) {
                              return ListTile(
                                title: Text(vm.teamMembers[idx]),
                              );
                            },
                          );
                        }
                      },
                    ),
                    // Schedule Tab
                    widget.scheduledGames.isEmpty
                        ? const Center(child: Text('No scheduled games found'))
                        : ListView.builder(
                            itemCount: widget.scheduledGames.length,
                            itemBuilder: (context, idx) {
                              final game = widget.scheduledGames[idx];
                              return GameCard(game: game, variant: GameCardVariant.scheduled);
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
