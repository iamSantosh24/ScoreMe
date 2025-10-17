import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorer/services/role_service.dart';
import 'package:scorer/models/role_models.dart';

class AssignRolesScreen extends StatefulWidget {
  // Allow injecting initial results for tests
  final List<User>? initialResults;
  const AssignRolesScreen({super.key, this.initialResults});

  @override
  State<AssignRolesScreen> createState() => _AssignRolesScreenState();
}

class _AssignRolesScreenState extends State<AssignRolesScreen> {
  String query = '';
  bool loading = false;
  List<User> results = [];
  String error = '';
  // screen-level caches for resolving friendly names
  List<Team> screenTeams = [];
  List<LeagueItem> screenLeagues = [];
  bool loadingRoleContext = false;

  @override
  void initState() {
    super.initState();
    // populate results if provided (useful in widget tests)
    results = widget.initialResults ?? [];
    // If initial results are provided (e.g., navigating into the screen with a list), fetch their details once mounted
    if (results.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchDetailsForResults();
      });
    }
  }

  // Fetch full user details and role context (teams/leagues) for the current `results` list.
  Future<void> _fetchDetailsForResults() async {
    final service = Provider.of<RoleService>(context, listen: false);
    try {
      final detailFutures = results.map((u) => service.getUserById(u.id)).toList();
      final details = await Future.wait(detailFutures);
      bool needContext = false;
      final merged = <User>[];
      for (var i = 0; i < results.length; i++) {
        final fresh = details[i];
        debugPrint('init fetch -> detail for ${results[i].id}: fresh=${fresh != null} roles=${fresh?.roles.length ?? 0} godAdmin=${fresh?.godAdmin ?? false}');
        if (fresh != null) {
          merged.add(fresh);
          if (fresh.roles.any((r) => (r.leagueId != null && r.leagueId!.isNotEmpty) || (r.teamId != null && r.teamId!.isNotEmpty))) {
            needContext = true;
          }
        } else {
          merged.add(results[i]);
        }
      }

      if (needContext) {
        setState(() => loadingRoleContext = true);
        try {
          final teams = await service.fetchTeams();
          final leagues = await service.fetchLeagues();
          if (!mounted) return;
          setState(() {
            screenTeams = teams;
            screenLeagues = leagues;
          });
        } catch (_) {}
        if (mounted) setState(() => loadingRoleContext = false);
      }

      if (mounted) setState(() => results = merged);
    } catch (e) {
      debugPrint('init fetch error: $e');
    }
  }

  String screenLeagueNameForId(String? id) {
    if (id == null) return '—';
    final found = screenLeagues.firstWhere((l) => l.id == id, orElse: () => LeagueItem(id: id, name: id));
    return found.name.isNotEmpty ? found.name : id;
  }

  String screenTeamNameForId(String? id) {
    if (id == null) return '—';
    final found = screenTeams.firstWhere((t) => t.id == id, orElse: () => Team(id: id, name: id));
    return found.name.isNotEmpty ? found.name : id;
  }

  String _formatServerMessage(String raw, bool? ok) {
    // Small helper to map server messages to friendly/localizable text.
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return ok == true ? 'Role successfully assigned.' : 'An error occurred.';
    // Map some common server messages to friendlier variants
    if (trimmed.toLowerCase().contains('role assigned') || trimmed.toLowerCase().contains('assigned')) {
      return 'Role successfully assigned.';
    }
    if (trimmed.toLowerCase().contains('error') || trimmed.toLowerCase().contains('failed')) {
      return 'Failed to assign role: $trimmed';
    }
    // default: echo the server message (could be localized later)
    return trimmed;
  }

  Future<void> doSearch() async {
    setState(() {
      loading = true;
      error = '';
      results = [];
    });
    try {
      final service = Provider.of<RoleService>(context, listen: false);
      final fetched = await service.searchUsers(query);
      debugPrint('doSearch -> fetched ${fetched.length} users from search');
      debugPrint('FetchedSearch -> $fetched');
      if (!mounted) return;
      setState(() {
        results = fetched;
        loading = false;
        if (results.isEmpty) error = 'No users found';
      });

      // After showing basic results, fetch full user details (roles/godAdmin) in parallel
      if (results.isNotEmpty) {
        Future.microtask(() async {
          try {
            // Only call getUserById for items that do NOT already include roles or godAdmin
            final detailFutures = results.map((u) {
              final needsDetail = (u.roles.isEmpty) && (u.godAdmin != true);
              return needsDetail ? service.getUserById(u.id) : Future<User?>.value(null);
            }).toList();

            final details = await Future.wait(detailFutures);

            // Update results with any fresher user objects
            bool needContext = false; // whether we need league/team names
            final merged = <User>[];
            for (var i = 0; i < results.length; i++) {
              final fresh = details[i];
              debugPrint('doSearch -> detail for ${results[i].id}: fresh=${fresh != null} roles=${fresh?.roles.length ?? results[i].roles.length} godAdmin=${fresh?.godAdmin ?? results[i].godAdmin}');
              if (fresh != null) {
                merged.add(fresh);
                if (fresh.roles.any((r) => (r.leagueId != null && r.leagueId!.isNotEmpty) || (r.teamId != null && r.teamId!.isNotEmpty))) {
                  needContext = true;
                }
              } else {
                merged.add(results[i]);
                if (results[i].roles.any((r) => (r.leagueId != null && r.leagueId!.isNotEmpty) || (r.teamId != null && r.teamId!.isNotEmpty))) {
                  needContext = true;
                }
              }
            }

            if (needContext) {
              setState(() => loadingRoleContext = true);
              try {
                final teams = await service.fetchTeams();
                final leagues = await service.fetchLeagues();
                if (!mounted) return;
                setState(() {
                  screenTeams = teams;
                  screenLeagues = leagues;
                });
              } catch (_) {}
              if (mounted) setState(() => loadingRoleContext = false);
            }

            if (mounted) setState(() => results = merged);
          } catch (_) {
            // ignore errors here; user will still be shown without roles
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Search failed';
      });
    }
  }

  void _showRoleDialog(User user) {
    final roleService = Provider.of<RoleService>(context, listen: false);

    showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) {
        // dialog-local state
        bool loading = false;
        String selectedRole = 'player';
        String? selectedTeamId;
        String? selectedLeagueId;
        List<Team> teams = List<Team>.from(screenTeams);
        List<LeagueItem> leagues = List<LeagueItem>.from(screenLeagues);
        List<UserRole> roles = List<UserRole>.from(user.roles);
        if (user.godAdmin == true && !roles.any((rr) => rr.role.toLowerCase() == 'god_admin')) {
          roles.insert(0, UserRole(leagueId: null, teamId: null, role: 'god_admin'));
        }
        bool fetchedDetails = false;

        return StatefulBuilder(builder: (context, setStateDialog) {
          Future<void> _loadTeams() async {
            if (teams.isNotEmpty) return;
            setStateDialog(() => loading = true);
            try {
              final t = await roleService.fetchTeams();
              if (!mounted) return;
              setStateDialog(() {
                teams = t;
                if (teams.isNotEmpty && selectedTeamId == null) selectedTeamId = teams.first.id;
              });
              if (mounted && teams.isNotEmpty) setState(() {
                for (final tt in teams) {
                  final i = screenTeams.indexWhere((st) => st.id == tt.id);
                  if (i == -1) screenTeams.add(tt); else screenTeams[i] = tt;
                }
              });
            } catch (_) {}
            if (mounted) setStateDialog(() => loading = false);
          }

          Future<void> _loadLeagues() async {
            if (leagues.isNotEmpty) return;
            setStateDialog(() => loading = true);
            try {
              final l = await roleService.fetchLeagues();
              if (!mounted) return;
              setStateDialog(() {
                leagues = l;
                if (leagues.isNotEmpty && selectedLeagueId == null) selectedLeagueId = leagues.first.id;
              });
              if (mounted && leagues.isNotEmpty) setState(() {
                for (final ll in leagues) {
                  final i = screenLeagues.indexWhere((sl) => sl.id == ll.id);
                  if (i == -1) screenLeagues.add(ll); else screenLeagues[i] = ll;
                }
              });
            } catch (_) {}
            if (mounted) setStateDialog(() => loading = false);
          }

          // fetch fresh user roles/details once when dialog opens
          if (!fetchedDetails) {
            fetchedDetails = true;
            Future.microtask(() async {
              setStateDialog(() => loading = true);
              try {
                final fresh = await roleService.getUserById(user.id);
                if (!mounted) return;
                if (fresh != null) {
                  roles = List<UserRole>.from(fresh.roles);
                  if (fresh.godAdmin == true && !roles.any((rr) => rr.role.toLowerCase() == 'god_admin')) {
                    roles.insert(0, UserRole(leagueId: null, teamId: null, role: 'god_admin'));
                  }
                  if (roles.any((r) => r.teamId != null && r.teamId!.isNotEmpty)) await _loadTeams();
                  if (roles.any((r) => r.leagueId != null && r.leagueId!.isNotEmpty)) await _loadLeagues();
                  if (mounted) setState(() {
                    final idx = results.indexWhere((r) => r.id == fresh.id);
                    if (idx != -1) results[idx] = fresh;
                  });
                }
              } catch (_) {}
              if (mounted) setStateDialog(() => loading = false);
            });
          }

          Future<void> doRemove(UserRole r) async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Remove role?'),
                content: Text('${_friendlyRoleName(r.role)} will be removed from ${user.fullName}. Continue?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Remove')),
                ],
              ),
            );
            if (confirmed != true) return;
            setStateDialog(() => loading = true);
            Map<String, dynamic> resp = {'ok': false, 'message': 'Unknown error'};
            try {
              resp = await roleService.removeRoleFromUser(userId: user.id, role: r.role, teamId: r.teamId, leagueId: r.leagueId);
            } catch (_) {
              resp = {'ok': false, 'message': 'Network error'};
            }
            if (!mounted) return;
            setStateDialog(() => loading = false);

            final ok = resp['ok'] is bool ? resp['ok'] as bool : false;
            if (ok) {
              // update dialog and parent results from returned user or fetched user
              final updated = resp['user'] is User ? resp['user'] as User : null;
              User? finalUser = updated;
              if (finalUser == null) {
                try {
                  final fetched = await roleService.getUserById(user.id);
                  if (fetched != null) finalUser = fetched;
                } catch (_) {}
              }

              if (finalUser != null) {
                final fu = finalUser; // capture non-null user for closures
                setStateDialog(() {
                  roles = List<UserRole>.from(fu.roles);
                  if (fu.godAdmin == true && !roles.any((rr) => rr.role.toLowerCase() == 'god_admin')) {
                    roles.insert(0, UserRole(leagueId: null, teamId: null, role: 'god_admin'));
                  }
                });
                if (mounted) {
                  setState(() {
                    final idx = results.indexWhere((r) => r.id == fu.id);
                    if (idx != -1) results[idx] = fu;
                  });
                }
              }

              final serverMsg = _formatServerMessage(resp['message']?.toString() ?? 'Role removed', ok);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(serverMsg)));
            } else {
              final msg = resp['message']?.toString() ?? 'Failed to remove role';
              final serverMsg = _formatServerMessage(msg, false);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(serverMsg)));
            }
          }

          Future<void> doAssign() async {
            if (selectedRole == 'admin' && (selectedTeamId == null || selectedTeamId!.isEmpty)) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a team')));
              return;
            }
            if (selectedRole == 'super_admin' && (selectedLeagueId == null || selectedLeagueId!.isEmpty)) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a league')));
              return;
            }

            setStateDialog(() => loading = true);
            Map<String, dynamic> resp = {'ok': false, 'message': 'Unknown error'};
            try {
              if (selectedRole == 'admin') {
                resp = await roleService.assignRoleToUser(userId: user.id, role: 'admin', teamId: selectedTeamId);
              } else if (selectedRole == 'super_admin') {
                resp = await roleService.assignRoleToUser(userId: user.id, role: 'super_admin', leagueId: selectedLeagueId);
              } else {
                resp = await roleService.assignRoleToUser(userId: user.id, role: selectedRole);
              }
            } catch (_) {
              resp = {'ok': false, 'message': 'Network error'};
            }
            if (!mounted) return;
            setStateDialog(() => loading = false);

            final ok = resp['ok'] is bool ? resp['ok'] as bool : false;
            final updated = resp['user'] is User ? resp['user'] as User : null;
            User? finalUser = updated;
            if (finalUser == null) {
              try {
                final fetched = await roleService.getUserById(user.id);
                if (fetched != null) finalUser = fetched;
              } catch (_) {}
            }

            if (ok) {
              if (finalUser != null) {
                final fu = finalUser;
                setStateDialog(() {
                  roles = List<UserRole>.from(fu.roles);
                  if (fu.godAdmin == true && !roles.any((rr) => rr.role.toLowerCase() == 'god_admin')) {
                    roles.insert(0, UserRole(leagueId: null, teamId: null, role: 'god_admin'));
                  }
                });
                if (mounted) setState(() {
                  final idx = results.indexWhere((r) => r.id == fu.id);
                  if (idx != -1) results[idx] = fu;
                });
              }
              final serverMsg = _formatServerMessage(resp['message']?.toString() ?? 'Role assigned', ok);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(serverMsg)));
            } else {
              final msg = resp['message']?.toString() ?? 'Failed to assign role';
              final serverMsg = _formatServerMessage(msg, false);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(serverMsg)));
            }
          }

          // Dialog UI
          return AlertDialog(
            title: Text('Roles for ${user.fullName}'),
            content: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (roles.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: roles.map((r) {
                          final roleLabel = r.role.toLowerCase() == 'admin'
                              ? 'Admin'
                              : r.role.toLowerCase() == 'super_admin'
                                  ? 'Super Admin'
                                  : r.role.toLowerCase() == 'god_admin'
                                      ? 'God Admin'
                                      : _friendlyRoleName(r.role);
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(roleLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const Spacer(),
                                    IconButton(icon: const Icon(Icons.delete_outline), onPressed: loading ? null : () => doRemove(r)),
                                  ],
                                ),
                                if (r.leagueId != null) Text('League: ${screenLeagueNameForId(r.leagueId)}'),
                                if (r.teamId != null) Text('Team: ${screenTeamNameForId(r.teamId)}'),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    else
                      const Text('No roles assigned', style: TextStyle(color: Colors.grey)),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      items: const [
                        DropdownMenuItem(value: 'player', child: Text('Player')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin (team)')),
                        DropdownMenuItem(value: 'super_admin', child: Text('Super Admin (league)')),
                        DropdownMenuItem(value: 'god_admin', child: Text('God Admin')),
                      ],
                      onChanged: loading ? null : (v) {
                        setStateDialog(() {
                          selectedRole = v ?? 'player';
                          selectedTeamId = null;
                          selectedLeagueId = null;
                        });
                        if (selectedRole == 'admin') _loadTeams();
                        if (selectedRole == 'super_admin') _loadLeagues();
                      },
                      decoration: InputDecoration(labelText: 'Assign new role', border: OutlineInputBorder()),
                    ),

                    if (selectedRole == 'admin' && teams.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedTeamId,
                        items: teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                        onChanged: loading ? null : (v) => setStateDialog(() => selectedTeamId = v as String?),
                        decoration: InputDecoration(labelText: 'Select team', border: OutlineInputBorder()),
                      ),
                    ],

                    if (selectedRole == 'super_admin' && leagues.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedLeagueId,
                        items: leagues.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
                        onChanged: loading ? null : (v) => setStateDialog(() => selectedLeagueId = v as String?),
                        decoration: InputDecoration(labelText: 'Select league', border: OutlineInputBorder()),
                      ),
                    ],

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: loading ? null : () => Navigator.of(ctx).pop(), child: const Text('Close')),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: loading ? null : () => doAssign(),
                          child: loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.0)) : const Text('Assign'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  String _friendlyRoleName(String role) {
    final r = role.toLowerCase();
    if (r == 'player') return 'Player';
    if (r == 'admin') return 'Admin';
    if (r == 'super_admin' || r == 'super admin') return 'Super Admin';
    if (r == 'god_admin' || r == 'god admin') return 'God Admin';
    final cleaned = r.replaceAll('_', ' ');
    return cleaned.split(' ').map((s) => s.isEmpty ? '' : '${s[0].toUpperCase()}${s.substring(1)}').join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<RoleService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Roles')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => query = v,
                  decoration: const InputDecoration(labelText: 'Search users', border: OutlineInputBorder()),
                  onSubmitted: (_) => doSearch(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: loading ? null : doSearch,
                child: loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.0)) : const Text('Search'),
              )
            ]),
            if (error.isNotEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error))),
            const SizedBox(height: 8),
            if (loading && results.isEmpty)
              const Expanded(child: Center(child: CircularProgressIndicator())),
            if (!loading && results.isEmpty)
              const Expanded(child: Center(child: Text('No results', style: TextStyle(color: Colors.grey)))),
            if (results.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final u = results[idx];
                    final rolesText = u.roles.isNotEmpty ? u.roles.map((r) => _friendlyRoleName(r.role)).join(', ') : (u.godAdmin == true ? 'God Admin' : 'No roles');
                    return ListTile(
                      title: Text(u.fullName),
                      subtitle: Text(rolesText),
                      trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _showRoleDialog(u)),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
