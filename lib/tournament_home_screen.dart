import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:scorer/config.dart';

class TournamentHomeScreen extends StatefulWidget {
  final String tournamentName;
  const TournamentHomeScreen({super.key, required this.tournamentName});

  @override
  State<TournamentHomeScreen> createState() => _TournamentHomeScreenState();
}

class _TournamentHomeScreenState extends State<TournamentHomeScreen> {
  bool loading = false;
  String error = '';
  Map<String, dynamic> tournamentDetails = {};

  @override
  void initState() {
    super.initState();
    fetchTournamentDetails();
  }

  Future<void> fetchTournamentDetails() async {
    setState(() { loading = true; });
    final res = await http.get(
      Uri.parse('${Config.apiBaseUrl}/tournament?name=${widget.tournamentName}'),
    );
    setState(() { loading = false; });
    if (res.statusCode == 200) {
      setState(() { tournamentDetails = json.decode(res.body); });
    } else {
      setState(() { error = 'Failed to fetch tournament details'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tournamentName)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: error.isNotEmpty
                  ? Text(error, style: const TextStyle(color: Colors.red))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tournament: ${widget.tournamentName}', style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 24),
                        Text('Details: ${tournamentDetails.toString()}'),
                      ],
                    ),
            ),
    );
  }
}
