import 'package:flutter/material.dart';
import 'league_management_screen.dart';

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
              MaterialPageRoute(builder: (context) => const LeagueManagementScreen()),
            );
          },
          child: const Text('Open Tournament Management'),
        ),
      ),
    );
  }
}
