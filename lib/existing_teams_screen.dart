import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'manage_team_players_screen.dart';
import 'viewmodels/ExistingTeamsViewModel.dart';
import 'team_home_screen.dart';

class ExistingTeamsScreen extends StatelessWidget {
  const ExistingTeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = ExistingTeamsViewModel();
        vm.fetchTeams();
        return vm;
      },
      child: Consumer<ExistingTeamsViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(title: const Text('Existing Teams')),
            body: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.error != null
                    ? Center(child: Text(viewModel.error!, style: const TextStyle(color: Colors.red)))
                    : viewModel.teams.isEmpty
                        ? const Center(child: Text('No teams found'))
                        : ListView.builder(
                            itemCount: viewModel.teams.length,
                            itemBuilder: (context, index) {
                              final team = viewModel.teams[index];
                              return ListTile(
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(team['teamName'] ?? 'Team', style: Theme.of(context).textTheme.titleMedium, maxLines: null),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => TeamHomeScreen(team: team),
                                              ),
                                            );
                                          },
                                          child: const Text('Open'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ManageTeamPlayersScreen(
                                                  teamId: team['teamId'],
                                                  teamName: team['teamName'] ?? '',
                                                  currentPlayers: team['players'] ?? [],
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text('Manage'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          );
        },
      ),
    );
  }
}
