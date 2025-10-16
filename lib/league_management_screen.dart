import 'package:flutter/material.dart';
import 'existing_leagues_screen.dart';
import 'package:provider/provider.dart';
import 'package:scorer/services/league_service.dart';

class LeagueManagementScreen extends StatefulWidget {
  const LeagueManagementScreen({super.key});

  @override
  State<LeagueManagementScreen> createState() => _LeagueManagementScreenState();
}

class _LeagueManagementScreenState extends State<LeagueManagementScreen> {
  void _showCreateLeagueDialog(BuildContext dialogContext) {
    final TextEditingController leagueNameController = TextEditingController();
    String selectedSport = 'cricket';
    String selectedStatus = 'scheduled';
    showDialog(
      context: dialogContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create League'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: leagueNameController,
                  decoration: const InputDecoration(labelText: 'League Name'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedSport,
                  decoration: const InputDecoration(labelText: 'Sport'),
                  items: const [
                    DropdownMenuItem(value: 'cricket', child: Text('Cricket')),
                    DropdownMenuItem(value: 'throwball', child: Text('Throwball')),
                  ],
                  onChanged: (value) {
                    if (value != null) selectedSport = value;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                  ],
                  onChanged: (value) {
                    if (value != null) selectedStatus = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final service = Provider.of<LeagueService>(dialogContext, listen: false);
                final success = await service.createLeague(
                  leagueName: leagueNameController.text,
                  sport: selectedSport,
                  status: selectedStatus,
                );
                Navigator.of(context).pop();
                if (success) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('League created')));
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Failed to create league')));
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final role = args?['role'] ?? '';
    // obtain LeagueService from Provider
    final leagueService = Provider.of<LeagueService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: const Text('League Management')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () => _showCreateLeagueDialog(context),
              child: const Text('Create League'),
            ),
            const Divider(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExistingLeaguesScreen(),
                  ),
                );
              },
              child: const Text('Existing Leagues'),
            ),
          ],
        ),
      ),
    );
  }
}
