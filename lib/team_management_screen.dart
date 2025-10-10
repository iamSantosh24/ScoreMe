import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/TeamManagementViewModel.dart';
import 'existing_teams_screen.dart';

class TeamManagementScreen extends StatelessWidget {
  const TeamManagementScreen({super.key});

  void _showCreateTeamDialog(BuildContext context) {
    final TextEditingController teamNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return ChangeNotifierProvider(
          create: (_) => TeamManagementViewModel(),
          child: Consumer<TeamManagementViewModel>(
            builder: (context, viewModel, _) {
              return AlertDialog(
                title: const Text('Create Team'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: teamNameController,
                      decoration: const InputDecoration(labelText: 'Team Name'),
                    ),
                    if (viewModel.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: CircularProgressIndicator(),
                      ),
                    if (viewModel.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(viewModel.errorMessage!, style: const TextStyle(color: Colors.red)),
                      ),
                    if (viewModel.successMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(viewModel.successMessage!, style: const TextStyle(color: Colors.green)),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: viewModel.isLoading
                        ? null
                        : () async {
                            final teamName = teamNameController.text.trim();
                            if (teamName.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Team Name is required.')),
                              );
                              return;
                            }
                            await viewModel.createTeam(teamName: teamName);
                            if (viewModel.successMessage != null) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(viewModel.successMessage!)),
                              );
                            }
                          },
                    child: const Text('Create'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TeamManagementViewModel(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Manage Teams')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: () => _showCreateTeamDialog(context),
                child: const Text('Create Teams'),
              ),
              const Divider(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExistingTeamsScreen(),
                    ),
                  );
                },
                child: const Text('Existing Teams'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
