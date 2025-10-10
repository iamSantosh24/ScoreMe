import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/ExistingTeamsViewModel.dart';

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
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: ListTile(
                                  title: Text(team['teamName'] ?? 'Team'),
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
