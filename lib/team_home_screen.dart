import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'viewmodels/TeamHomeViewModel.dart';

class TeamHomeScreen extends StatefulWidget {
  final Map<String, dynamic> team;

  const TeamHomeScreen({super.key, required this.team});

  @override
  State<TeamHomeScreen> createState() => _TeamHomeScreenState();
}

class _TeamHomeScreenState extends State<TeamHomeScreen> with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _matchesTabController;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 4, vsync: this);
    _matchesTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _matchesTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = TeamHomeViewModel();
        final teamId = widget.team['_id'] ?? widget.team['id'];
        if (teamId != null) {
          vm.fetchTeamMembers(teamId);
        }
        return vm;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.team['name'] ?? 'Team'),
          bottom: TabBar(
            controller: _mainTabController,
            tabs: const [
              Tab(text: 'Players'),
              Tab(text: 'Matches'),
              Tab(text: 'Player Stats'),
              Tab(text: 'Albums'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _mainTabController,
          children: [
            // Players Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Consumer<TeamHomeViewModel>(
                builder: (context, vm, _) {
                  if (vm.loading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (vm.error.isNotEmpty) {
                    return Center(child: Text(vm.error, style: const TextStyle(color: Colors.red)));
                  } else if (vm.teamMembers.isEmpty) {
                    return const Center(child: Text('No players found'));
                  } else {
                    return ListView.builder(
                      itemCount: vm.teamMembers.length,
                      itemBuilder: (context, idx) {
                        return ListTile(
                          title: Text(vm.teamMembers[idx]),
                        );
                      },
                    );
                  }
                },
              ),
            ),
            // Matches Tab
            Column(
              children: [
                TabBar(
                  controller: _matchesTabController,
                  tabs: const [
                    Tab(text: 'Results'),
                    Tab(text: 'Scheduled'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _matchesTabController,
                    children: [
                      Center(child: Text('Results - To be implemented')), // Placeholder
                      Center(child: Text('Scheduled - To be implemented')), // Placeholder
                    ],
                  ),
                ),
              ],
            ),
            // Player Stats Tab
            Center(child: Text('Player Stats - To be implemented')), // Placeholder
            // Albums Tab
            AlbumsTab(teamId: widget.team['_id'] ?? widget.team['id']),
          ],
        ),
      ),
    );
  }
}

// Albums Tab Widget
class AlbumsTab extends StatelessWidget {
  final String? teamId;
  const AlbumsTab({Key? key, this.teamId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              // TODO: Implement file picker and upload logic
            },
            child: const Text('Upload Photo'),
          ),
          const SizedBox(height: 16),
          const Text('Uploaded photos will appear here.'),
        ],
      ),
    );
  }
}
