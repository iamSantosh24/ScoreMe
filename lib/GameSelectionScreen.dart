import 'package:flutter/material.dart';
import 'league_selection_screen.dart'; // Assuming this is needed for navigation after game selection

class BadmintonScreen extends StatelessWidget {
  const BadmintonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Badminton')),
      body: const Center(child: Text('Badminton Screen')),
    );
  }
}

class BasketballScreen extends StatelessWidget {
  const BasketballScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Basketball')),
      body: const Center(child: Text('Basketball Screen')),
    );
  }
}

class ThrowBallScreen extends StatelessWidget {
  const ThrowBallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Throw Ball')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Icon(Icons.sports_volleyball, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'Welcome to Throw Ball!',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Throw Ball is a fast-paced team sport played on a rectangular court. Get ready to create matches, view rules, and track scores!',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement match creation or navigation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Start Match feature coming soon!')),
                );
              },
              child: const Text('Start Match'),
            ),
          ],
        ),
      ),
    );
  }
}

class GameSelectionScreen extends StatelessWidget {
  const GameSelectionScreen({super.key});

  // List of games in alphabetical order
  static const List<String> games = [
    'Badminton',
    'Basketball',
    'Cricket',
    'Throw Ball',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SCORER'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Select a Game',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: games.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    games[index],
                    style: const TextStyle(fontSize: 18),
                  ),
                  onTap: () {
                    final selectedGame = games[index];
                    if (selectedGame == 'Cricket') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LeagueSelectionScreen(),
                        ),
                      );
                    } else if (selectedGame == 'Badminton') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BadmintonScreen(),
                        ),
                      );
                    } else if (selectedGame == 'Basketball') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BasketballScreen(),
                        ),
                      );
                    } else if (selectedGame == 'Throw Ball') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ThrowBallScreen(),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}