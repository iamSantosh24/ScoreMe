import 'package:flutter/material.dart';
import 'leagues_util.dart';
import 'package:provider/provider.dart';
import 'viewmodels/LeagueHomeViewModel.dart';
import 'widgets/GameCard.dart';

class LeagueHomeScreen extends StatefulWidget {
  final League league;
  const LeagueHomeScreen({super.key, required this.league});

  @override
  State<LeagueHomeScreen> createState() => _LeagueHomeScreenState();
}

class _LeagueHomeScreenState extends State<LeagueHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Widget buildScheduledTab(LeagueHomeViewModel vm) {
    if (vm.loadingScheduled) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.errorScheduled.isNotEmpty) {
      return Center(child: Text(vm.errorScheduled, style: const TextStyle(color: Colors.red)));
    }
    if (vm.scheduledGames.isEmpty) {
      return const Center(child: Text('No scheduled games found'));
    }
    return ListView.builder(
      itemCount: vm.scheduledGames.length,
      itemBuilder: (context, index) {
        final game = vm.scheduledGames[index];
        return GameCard(game: game);
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LeagueHomeViewModel(league: widget.league),
      child: Consumer<LeagueHomeViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.league.name),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Results'),
                  Tab(text: 'Scheduled'),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                Center(child: Text('Results for ${widget.league.name}')), // Placeholder
                buildScheduledTab(vm),
              ],
            ),
          );
        },
      ),
    );
  }
}
