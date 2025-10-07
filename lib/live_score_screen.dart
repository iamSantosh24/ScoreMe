import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorer/widgets/GameCard.dart';
import 'cricket_live_score.dart';
import 'throwball_live_score.dart';
import 'viewmodels/HomeTabbedViewModel.dart';

class LiveScoreScreen extends StatefulWidget {
  final String sportType;
  final Map<String, dynamic> gameData;
  final String role;
  final String username;

  const LiveScoreScreen({super.key, required this.sportType, required this.gameData, required this.role, required this.username});

  @override
  State<LiveScoreScreen> createState() => _LiveScoreScreenState();
}

class _LiveScoreScreenState extends State<LiveScoreScreen> {
  dynamic selectedLeague;
  String? selectedGame;
  List<dynamic> availableLeagues = [];
  List<dynamic> availableGames = [];
  late HomeTabbedViewModel viewModel;
  bool isLoadingLeagues = true;
  String leagueError = '';

  @override
  void initState() {
    super.initState();
    viewModel = HomeTabbedViewModel();
    _fetchLeagues();
  }

  Future<void> _fetchLeagues() async {
    setState(() {
      isLoadingLeagues = true;
      leagueError = '';
    });
    try {
      await viewModel.fetchAllTabData(widget.username);
      final leagues = viewModel.leagues;
      if (leagues.isEmpty) {
        leagueError = 'No leagues found';
      } else {
        if (widget.role == 'god_admin' || widget.role == 'super_admin') {
          availableLeagues = leagues;
        } else {
          // For admin/player, filter leagues they are part of
          availableLeagues = leagues.where((league) => _isUserInLeague(league)).toList();
        }
      }
    } catch (e) {
      leagueError = 'Error fetching leagues';
    }
    setState(() {
      isLoadingLeagues = false;
    });
  }

  bool _isUserInLeague(dynamic league) {
    // TODO: Implement actual check based on user data
    // For now, allow all leagues for demo
    return true;
  }

  void _loadGames() async {
    if (selectedLeague == null) {
      availableGames = [];
      setState(() {});
      return;
    }
    await viewModel.fetchAllTabData(widget.username);
    List<dynamic> allGames = viewModel.upcomingScheduledGames;
    List<dynamic> filteredGames = [];
    if (widget.role == 'god_admin' || widget.role == 'super_admin') {
      filteredGames = allGames.where((g) => (g['leagueId'] == selectedLeague.id || g['leagueId'] == selectedLeague['id'])).toList();
      print('Filtered Games: $filteredGames');
    } else {
      List<dynamic> userTeams = viewModel.teams;
      List<dynamic> userTeamIds = userTeams.map((t) => t['_id'] ?? t['id']).toList();
      filteredGames = allGames.where((g) =>
        (g['leagueId'] == selectedLeague.id || g['leagueId'] == selectedLeague['id']) &&
        (userTeamIds.contains(g['teamAId']) || userTeamIds.contains(g['teamBId']))
      ).toList();
      print('Filtered Games: $filteredGames');
    }
    availableGames = filteredGames;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<HomeTabbedViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Live Score'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 32),
                  Text('League:'),
                  SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: (isLoadingLeagues)
                          ? CircularProgressIndicator()
                          : (leagueError.isNotEmpty)
                            ? Text(leagueError, style: TextStyle(color: Colors.red))
                            : DropdownButtonFormField<dynamic>(
                                value: selectedLeague,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                isExpanded: true,
                                hint: Text('Choose League'),
                                items: availableLeagues.map((league) => DropdownMenuItem(
                                  value: league,
                                  child: Text(league.name ?? league['name'] ?? league.toString()),
                                )).toList(),
                                onChanged: (league) {
                                  setState(() {
                                    selectedLeague = league;
                                    selectedGame = null;
                                    _loadGames();
                                  });
                                },
                              ),
                      ),
                    ),
                  ),
                  if (selectedLeague != null) ...[
                    SizedBox(height: 16),
                    Text('Games:'),
                    availableGames.isEmpty
                      ? const Center(child: Text('No games found'))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: availableGames.length,
                          itemBuilder: (context, index) {
                            final game = availableGames[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: GameCard(
                                game: game,
                                onTap: () {
                                  final sportType = game['sport'] ?? game['sportType'] ?? '';
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => _getSportWidget(sportType, game),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getSportWidget(String sportType, Map<String, dynamic> gameData) {
    switch (sportType) {
      case 'Cricket':
        return CricketLiveScore(gameData: gameData);
      case 'Throwball':
        return ThrowballLiveScore(gameData: gameData);
      default:
        return Center(child: Text('Unsupported sport type'));
    }
  }
}
