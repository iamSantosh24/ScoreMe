import 'package:flutter/material.dart';
import 'app_drawer.dart';

class HomeTabbedScreen extends StatefulWidget {
  final String username;
  final String role;

  const HomeTabbedScreen({super.key, required this.username, required this.role});

  @override
  State<HomeTabbedScreen> createState() => _HomeTabbedScreenState();
}

class _HomeTabbedScreenState extends State<HomeTabbedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Games'),
            Tab(text: 'My Leagues'),
            Tab(text: 'My Teams'),
          ],
        ),
      ),
      drawer: AppDrawer(role: widget.role, username: widget.username),
      body: TabBarView(
        controller: _tabController,
        children: const [
          Center(child: Text('No games to show.')), // My Games Tab
          Center(child: Text('No leagues to show.')), // My Leagues Tab
          Center(child: Text('No teams to show.')), // My Teams Tab
        ],
      ),
    );
  }
}
