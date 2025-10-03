import 'package:flutter/material.dart';
class UpdateTeamsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Teams')),
      body: const Center(child: Text('Add/remove users from teams, add/remove teams from leagues here.')),
    );
  }
}

