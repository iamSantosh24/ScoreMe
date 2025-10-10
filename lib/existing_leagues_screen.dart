import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorer/viewmodels/ExistingLeaguesViewModel.dart';
import 'update_teams_screen.dart';
import 'set_league_rules_screen.dart';

class ExistingLeaguesScreen extends StatelessWidget {
  const ExistingLeaguesScreen({super.key});

  void _showLeagueOptions(BuildContext context, Map<String, dynamic> league) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Update Teams'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdateTeamsScreen(
                      leagueId: league['_id'],
                      leagueName: league['name'] ?? '',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.rule),
              title: const Text('Set Rules'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SetLeagueRulesScreen(
                      leagueId: league['_id'],
                      leagueName: league['name'] ?? '',
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = ExistingLeaguesViewModel();
        vm.fetchLeagues();
        return vm;
      },
      child: Consumer<ExistingLeaguesViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(title: const Text('Existing Leagues')),
            body: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vm.leagues.isEmpty
                    ? const Center(child: Text('No leagues found.'))
                    : ListView.builder(
                        itemCount: vm.leagues.length,
                        itemBuilder: (context, index) {
                          final t = vm.leagues[index];
                          return ListTile(
                            title: Text(t['leagueName'] ?? ''),
                            trailing: ElevatedButton(
                              onPressed: () {
                                _showLeagueOptions(context, t);
                              },
                              child: const Text('Open'),
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
