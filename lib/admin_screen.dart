import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Team Roster Management')),
      body: const Center(
        child: Text('Admin: Update your team players to the roster.'),
      ),
    );
  }
}

