import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/manage_team_players_viewmodel.dart';

class ManageTeamPlayersScreen extends StatefulWidget {
  final String teamId;
  final String teamName;
  final List<dynamic> currentPlayers;

  const ManageTeamPlayersScreen({
    Key? key,
    required this.teamId,
    required this.teamName,
    required this.currentPlayers,
  }) : super(key: key);

  @override
  State<ManageTeamPlayersScreen> createState() => _ManageTeamPlayersScreenState();
}

class _ManageTeamPlayersScreenState extends State<ManageTeamPlayersScreen> {
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Initialize the viewmodel and immediately fetch team players so
      // the roster is populated when the provider is created.
      create: (_) {
        final vm = ManageTeamPlayersViewModel();
        vm.fetchTeamPlayers(widget.teamId);
        return vm;
      },
      child: Consumer<ManageTeamPlayersViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(title: Text('Manage Players for ${widget.teamName}')),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Players',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          vm.searchPlayers(searchController.text);
                        },
                      ),
                    ),
                    onSubmitted: vm.searchPlayers,
                  ),
                ),
                if (vm.isSearching)
                  const LinearProgressIndicator(),
                if (vm.searchResults.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: vm.searchResults.length,
                      itemBuilder: (context, index) {
                        final player = vm.searchResults[index];
                        final playerId = player['profileId'];
                        final fullName = '${player['firstName']} ${player['lastName']}';
                        final alreadyInTeam = vm.isPlayerInTeam(playerId);
                        return ListTile(
                          title: Text(fullName),
                          subtitle: Text(player['email'] ?? ''),
                          trailing: alreadyInTeam
                              ? const Text('In Team', style: TextStyle(color: Colors.green))
                              : ElevatedButton(
                                  onPressed: () async {
                                    final error = await vm.addPlayerToTeam(widget.teamId, player);
                                    if (error != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(error)),
                                      );
                                    }
                                  },
                                  child: const Text('Add'),
                                ),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Team Roster', style: Theme.of(context).textTheme.titleMedium),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: vm.teamPlayers.length,
                    itemBuilder: (context, index) {
                      final player = vm.teamPlayers[index];
                      String displayName = '';
                      if (player is Map && player.containsKey('firstName') && player.containsKey('lastName')) {
                        displayName = '${player['firstName']} ${player['lastName']}';
                      } else {
                        displayName = 'Unknown Player';
                      }
                      return ListTile(
                        title: Text(displayName),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            final error = await vm.removePlayerFromTeam(
                              widget.teamId,
                              player is Map && player.containsKey('profileId') ? player['profileId'] : player.toString(),
                            );
                            if (error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error)),
                              );
                            }
                          },
                          child: const Text('Remove'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
