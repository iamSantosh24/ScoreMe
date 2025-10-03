import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/MatchScheduleViewModel.dart';
import 'leagues_util.dart';
import 'widgets/GameCard.dart';

class MatchScheduleScreen extends StatefulWidget {
  final String leagueId;
  final List<dynamic>? scheduledGames;

  const MatchScheduleScreen({super.key, required this.leagueId, this.scheduledGames});

  @override
  State<MatchScheduleScreen> createState() => _MatchScheduleScreenState();
}

class _MatchScheduleScreenState extends State<MatchScheduleScreen> {
  late MatchScheduleViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = MatchScheduleViewModel();
    if (widget.scheduledGames != null) {
      viewModel.setScheduledGames(widget.scheduledGames!, widget.leagueId);
    } else {
      viewModel.fetchScheduledGames(widget.leagueId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<MatchScheduleViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Scheduled Games: ${vm.leagueName}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => vm.fetchScheduledGames(widget.leagueId),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            body: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : vm.error.isNotEmpty
                ? Center(child: Text(vm.error, style: const TextStyle(color: Colors.red)))
                : vm.scheduledGames.isEmpty
                ? const Center(child: Text('No scheduled games found for this league'))
                : ListView.builder(
                    itemCount: vm.scheduledGames.length,
                    itemBuilder: (context, index) {
                      final game = vm.scheduledGames[index];
                      return GameCard(game: game, variant: GameCardVariant.scheduled);
                    },
                  ),
          );
        },
      ),
    );
  }
}
