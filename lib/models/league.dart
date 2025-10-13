class League {
  final String id;
  final String name;

  League({required this.id, required this.name});

  factory League.fromJson(Map<String, dynamic> json) {
    return League(
      id: json['id'].toString(),
      name: json['name'] ?? json['leagueName'] ?? '',
    );
  }
}

