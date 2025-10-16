class User {
  final String id;
  final String username;
  final String displayName;
  final String? firstName;
  final String? lastName;
  final bool godAdmin;
  final List<UserRole> roles;

  User(
      {required this.id,
      required this.username,
      required this.displayName,
      this.firstName,
      this.lastName,
      this.godAdmin = false,
      List<UserRole>? roles})
      : roles = roles ?? [];

  factory User.fromJson(Map<String, dynamic> json) {
    // Normalize god admin flag from several possible shapes returned by backend
    final dynamic rawGod = json['god_admin'] ?? json['godAdmin'] ?? json['godadmin'];
    bool parsedGod = false;
    if (rawGod is bool) {
      parsedGod = rawGod;
    } else if (rawGod is num) {
      parsedGod = rawGod != 0;
    } else if (rawGod is String) {
      final lower = rawGod.toLowerCase().trim();
      parsedGod = (lower == 'true' || lower == '1');
    }

    // Normalize id: backend may return {_id: {"$oid": "..."}} or a string
    String resolvedId = '';
    final dynamic rawId = json['_id'] ?? json['id'];
    if (rawId is String) {
      resolvedId = rawId;
    } else if (rawId is Map && rawId.containsKey(r'$oid')) {
      final v = rawId[r'$oid'];
      if (v is String) resolvedId = v;
    } else if (rawId != null) {
      resolvedId = rawId.toString();
    }

    return User(
      id: resolvedId,
      username: json['username'] ?? json['email'] ?? json['name'] ?? '',
      displayName: json['displayName'] ?? json['name'] ?? json['username'] ?? json['email'] ?? '',
      firstName: json['firstName'] ?? json['first_name'] ?? null,
      lastName: json['lastName'] ?? json['last_name'] ?? null,
      godAdmin: parsedGod,
      roles: (json['roles'] is List)
          ? (json['roles'] as List).map((r) => UserRole.fromJson(r as Map<String, dynamic>)).toList()
          : null,
    );
  }

  String get fullName {
    final f = (firstName ?? '').trim();
    final l = (lastName ?? '').trim();
    if (f.isNotEmpty && l.isNotEmpty) return '$f $l';
    if (f.isNotEmpty) return f;
    if (displayName.isNotEmpty) return displayName;
    return username;
  }
}

class Team {
  final String id;
  final String name;
  Team({required this.id, required this.name});
  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['teamId'] ?? json['_id'] ?? json['id'] ?? '',
      name: json['teamName'] ?? json['name'] ?? '',
    );
  }
}

class LeagueItem {
  final String id;
  final String name;
  LeagueItem({required this.id, required this.name});
  factory LeagueItem.fromJson(Map<String, dynamic> json) {
    return LeagueItem(
      id: json['leagueId'] ?? json['_id'] ?? json['id'] ?? '',
      name: json['leagueName'] ?? json['name'] ?? '',
    );
  }
}

class UserRole {
  final String? leagueId;
  final String? teamId;
  final String role;

  UserRole({this.leagueId, this.teamId, required this.role});

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      leagueId: json['leagueId'] ?? json['league'] ?? null,
      teamId: json['teamId'] ?? json['team'] ?? null,
      role: json['role'] ?? '',
    );
  }
}
