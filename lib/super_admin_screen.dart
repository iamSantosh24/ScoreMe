import 'package:flutter/material.dart';
import 'tournament_management_screen.dart';

class SuperAdminScreen extends StatelessWidget {
  const SuperAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Super Admin Dashboard')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TournamentManagementScreen()),
            );
          },
          child: const Text('Open Tournament Management'),
        ),
      ),
    );
  }
}
