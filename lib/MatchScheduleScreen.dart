import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/MatchScheduleViewModel.dart';

class MatchScheduleScreen extends StatefulWidget {
  final String leagueName;
  final List<dynamic>? scheduledGames;

  const MatchScheduleScreen({super.key, required this.leagueName, this.scheduledGames});

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
      viewModel.setScheduledGames(widget.scheduledGames!, widget.leagueName);
      viewModel.fetchLeagueName(widget.leagueName);
    } else {
      viewModel.fetchScheduledGames(widget.leagueName);
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
                  onPressed: () => vm.fetchScheduledGames(widget.leagueName),
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
                              final gameName = game['gameName'] ?? '';
                              final date = game['date'] != null ? DateTime.parse(game['date']).toLocal() : null;
                              String formattedDate = '';
                              if (date != null) {
                                formattedDate = '${_monthName(date.month)} ${date.day}, ${date.year}  ${_formatTime(date)}';
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (vm.leagueName.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
                                      child: Text('League: ${vm.leagueName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  if (gameName.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                                      child: Text('Game: $gameName', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                    ),
                                  Card(
                                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (formattedDate.isNotEmpty)
                                            Center(
                                              child: Text(formattedDate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                            ),
                                          const SizedBox(height: 8),
                                          Center(
                                            child: Text('${game['teamA'] ?? ''} vs ${game['teamB'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                          ),
                                          const SizedBox(height: 8),
                                          if (formattedDate.isNotEmpty)
                                            Center(
                                              child: Text(formattedDate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
          );
        },
      ),
    );
  }
}

// Helper functions for formatting month and time
String _monthName(int month) {
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return months[month];
}

String _formatTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final ampm = date.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $ampm';
}