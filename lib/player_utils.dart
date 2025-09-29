import 'dart:math';

class PlayerUtils {
  static Map<String, List<String>> generateTeamPlayers(List<String> teams) {
    final totalPlayersNeeded = teams.length * 30;
    final allPlayers = _generateUniquePlayerNames(totalPlayersNeeded);
    final Map<String, List<String>> teamPlayers = {};

    for (int i = 0; i < teams.length; i++) {
      final startIndex = i * 30;
      teamPlayers[teams[i]] = allPlayers.sublist(startIndex, startIndex + 30);
    }

    return teamPlayers;
  }

  static List<String> _generateUniquePlayerNames(int count) {
    final List<String> firstNames = [
      'James', 'Michael', 'William', 'David', 'John', 'Robert', 'Thomas', 'Charles',
      'Christopher', 'Daniel', 'Matthew', 'Andrew', 'Joseph', 'Mark', 'Paul', 'Steven',
      'Richard', 'Edward', 'George', 'Benjamin', 'Samuel', 'Stephen', 'Jonathan', 'Peter',
      'Adam', 'Kevin', 'Brian', 'Jason', 'Timothy', 'Nathan', 'Scott', 'Brandon',
      'Gregory', 'Patrick', 'Ryan', 'Eric', 'Nicholas', 'Jeremy', 'Aaron', 'Frank',
    ];
    final List<String> lastNames = [
      'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis',
      'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson',
      'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin', 'Lee', 'Perez', 'Thompson',
      'White', 'Harris', 'Sanchez', 'Clark', 'Ramirez', 'Lewis', 'Walker', 'Hall',
      'Allen', 'Young', 'King', 'Wright', 'Scott', 'Green', 'Baker', 'Adams',
    ];

    final random = Random();
    final Set<String> uniqueNames = {};

    while (uniqueNames.length < count) {
      final first = firstNames[random.nextInt(firstNames.length)];
      final last = lastNames[random.nextInt(lastNames.length)];
      final name = '$first $last';
      uniqueNames.add(name);
    }

    return uniqueNames.toList();
  }
}