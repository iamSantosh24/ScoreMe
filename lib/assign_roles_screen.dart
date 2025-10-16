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
        // Dialog-local state
        bool loading = false;
        String selectedRole = 'player';
        String? selectedTeamId;
        String? selectedLeagueId;
        List<Team> teams = List<Team>.from(screenTeams);
        List<LeagueItem> leagues = List<LeagueItem>.from(screenLeagues);
        List<UserRole> roles = List<UserRole>.from(user.roles);
        if (user.godAdmin == true && !roles.any((rr) => rr.role.toLowerCase() == 'god_admin')) {
          // Represent god_admin as a synthetic UserRole so the UI can render it like other roles
          roles.insert(0, UserRole(leagueId: null, teamId: null, role: 'god_admin'));
        }
        bool fetched = false;

        return StatefulBuilder(builder: (context, setStateDialog) {
          Future<void> loadTeams() async {
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

          Future<void> loadLeagues() async {
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

          // Fetch fresh roles once
          if (!fetched) {
            fetched = true;
            Future.microtask(() async {
              setStateDialog(() => loading = true);
              try {
                final fresh = await roleService.getUserById(user.id);
                if (!mounted) return;
                if (fresh != null) {
                  roles = List<UserRole>.from(fresh.roles);
                  if (fresh.godAdmin == true && !roles.any((rr) => rr.role.toLowerCase() == 'god_admin')) roles.insert(0, UserRole(leagueId: null, teamId: null, role: 'god_admin'));
                   // preload names if needed
                   if (roles.any((r) => r.teamId != null && r.teamId!.isNotEmpty)) await loadTeams();
                   if (roles.any((r) => r.leagueId != null && r.leagueId!.isNotEmpty)) await loadLeagues();
                  if (mounted) setStateDialog(() { roles = List<UserRole>.from(fresh.roles); if (fresh.godAdmin == true && !roles.any((rr) => rr.role.toLowerCase() == 'god_admin')) roles.insert(0, UserRole(leagueId: null, teamId: null, role: 'god_admin')); });
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
            final confirm = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Remove role?'),
                content: Text('Remove ${_friendlyRoleName(r.role)} from ${user.fullName}?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Remove')),
                ],
              ),
            );
            if (confirm != true) return;
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
              final updated = resp['user'] is User ? resp['user'] as User : null;
              if (updated != null) {
                setStateDialog(() { roles = List<UserRole>.from(updated.roles); if (updated.godAdmin == true && !roles.any((rr) => rr.role.toLowerCase() == 'god_admin')) roles.insert(0, UserRole(leagueId: null, teamId: null, role: 'god_admin')); });
                if (mounted) setState(() {
                  final i = results.indexWhere((u) => u.id == updated.id);
                  if (i != -1) results[i] = updated;
                });
              } else {
                setStateDialog(() { roles.removeWhere((er) => er.role == r.role && er.teamId == r.teamId && er.leagueId == r.leagueId); });
              }
              final serverMsg = _formatServerMessage(resp['message']?.toString() ?? 'Role removed', ok);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(serverMsg)));
            } else {
              final msg = resp['message']?.toString() ?? 'Failed to remove role';
              final serverMsg = _formatServerMessage(msg, ok);
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
            if (ok) {
              final updated = resp['user'] is User ? resp['user'] as User : null;
              if (updated != null) {
                setStateDialog(() { roles = List<UserRole>.from(updated.roles); if (updated.godAdmin == true && !roles.any((rr) => rr.role.toLowerCase() == 'god_admin')) roles.insert(0, UserRole(leagueId: null, teamId: null, role: 'god_admin')); });
                if (mounted) setState(() {
                  final i = results.indexWhere((r) => r.id == updated.id);
                  if (i != -1) results[i] = updated;
                });
              }
              final serverMsg = _formatServerMessage(resp['message']?.toString() ?? 'Role assigned', ok);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(serverMsg)));
            } else {
              final msg = resp['message']?.toString() ?? 'Failed to assign role';
              final serverMsg = _formatServerMessage(msg, ok);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(serverMsg)));
            }
          }

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
                                Row(mainAxisSize: MainAxisSize.min, children: [Text(roleLabel, style: const TextStyle(fontWeight: FontWeight.w600)), const Spacer(), IconButton(icon: const Icon(Icons.delete_outline), onPressed: loading ? null : () => doRemove(r))]),
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
                        if (selectedRole == 'admin') loadTeams();
                        if (selectedRole == 'super_admin') loadLeagues();
                      },
                      decoration: const InputDecoration(labelText: 'Role'),
                    ),

                    if (selectedRole == 'admin')
                      teams.isEmpty
                          ? const Padding(padding: EdgeInsets.only(top: 8), child: Text('No teams available', style: TextStyle(color: Colors.grey)))
                          : DropdownButtonFormField<String>(
                              value: selectedTeamId,
                              items: teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                              onChanged: loading ? null : (v) => setStateDialog(() => selectedTeamId = v),
                              decoration: const InputDecoration(labelText: 'Team'),
                            ),

                    if (selectedRole == 'super_admin')
                      leagues.isEmpty
                          ? const Padding(padding: EdgeInsets.only(top: 8), child: Text('No leagues available', style: TextStyle(color: Colors.grey)))
                          : DropdownButtonFormField<String>(
                              value: selectedLeagueId,
                              items: leagues.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
                              onChanged: loading ? null : (v) => setStateDialog(() => selectedLeagueId = v),
                              decoration: const InputDecoration(labelText: 'League'),
                            ),

                    if (loading) const Padding(padding: EdgeInsets.only(top: 12), child: Center(child: CircularProgressIndicator())),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: loading ? null : () => Navigator.of(context).pop(), child: const Text('Close')),
              ElevatedButton(onPressed: loading ? null : doAssign, child: const Text('Assign')),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Roles'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Search users', border: OutlineInputBorder()),
                    onChanged: (v) => setState(() => query = v),
                    onSubmitted: (_) => doSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: doSearch, child: const Text('Search')),
              ],
            ),
            const SizedBox(height: 12),
            if (loading) const Center(child: CircularProgressIndicator()),
            if (!loading && error.isNotEmpty) Text(error, style: const TextStyle(color: Colors.red)),
            if (!loading && results.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final u = results[idx];
                    final roleText = u.roles.isNotEmpty ? u.roles.map((r) => r.role).join(', ') : (u.godAdmin == true ? 'God Admin' : 'No roles');
                    return ListTile(
                      title: Text(u.fullName),
                      subtitle: Text(roleText),
                      trailing: TextButton(onPressed: () => _showRoleDialog(u), child: const Text('Change roles')),
                      onTap: () => _showRoleDialog(u),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _friendlyRoleName(String role) {
    // Small helper to map internal role names to friendly display names.
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Admin (team-scoped)';
      case 'super_admin':
        return 'Super Admin (league-scoped)';
      case 'god_admin':
        return 'God Admin (global)';
      default:
        return role;
    }
  }
}
