import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/manage_league_teams_viewmodel.dart';

class ManageLeagueTeamsScreen extends StatelessWidget {
  final String leagueId;
  final String leagueName;
  final List<dynamic> currentTeams;

  const ManageLeagueTeamsScreen({
    Key? key,
    required this.leagueId,
    required this.leagueName,
    required this.currentTeams,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ManageLeagueTeamsViewModel(
        leagueId: leagueId,
        currentTeams: currentTeams,
      ),
      child: Consumer<ManageLeagueTeamsViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(title: Text('Manage Teams for $leagueName')),
            body: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: viewModel.allTeams.length,
                    itemBuilder: (context, index) {
                      final team = viewModel.allTeams[index];
                      final teamId = team['teamId'];
                      final teamName = team['teamName'];
                      final inLeague = viewModel.leagueTeamIds.contains(teamId);
                      return ListTile(
                        title: Text(teamName ?? ''),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            final errorMsg = await viewModel.handleTeamAction(teamId, teamName, !inLeague);
                            if (errorMsg != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(errorMsg)),
                              );
                            }
                          },
                          child: Text(inLeague ? 'Remove' : 'Add'),
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
