class League {
  final String id;
  final String name;

  League({required this.id, required this.name});

  factory League.fromJson(Map<String, dynamic> json) {
    return League(
      id: json['leagueId'] ?? json['_id'] ?? json['id'] ?? '',
      name: json['leagueName'] ?? json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

// Utility to get League object from id (no formatting)
League getLeagueFromId(String id) {
  return League(id: id, name: id);
}

// Utility to build a list of League objects from backend ids (no formatting)
List<League> buildLeaguesList(List<String> ids) {
  return ids.map((id) => getLeagueFromId(id)).toList();
}


String monthName(int month) {
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return months[month];
}

String formatTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final ampm = date.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $ampm';
}
