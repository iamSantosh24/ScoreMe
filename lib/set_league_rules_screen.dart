import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ThrowballRulesWidget extends StatelessWidget {
  final TextEditingController setsController;
  final TextEditingController pointsController;
  final TextEditingController timeoutsController;
  const ThrowballRulesWidget({
    super.key,
    required this.setsController,
    required this.pointsController,
    required this.timeoutsController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: setsController,
          decoration: const InputDecoration(labelText: 'Number of Sets'),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: pointsController,
          decoration: const InputDecoration(labelText: 'Points per Set'),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: timeoutsController,
          decoration: const InputDecoration(labelText: 'Timeouts per Set'),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}

class CricketRulesWidget extends StatelessWidget {
  final TextEditingController oversController;
  final TextEditingController ballsController;
  final TextEditingController wicketsController;
  const CricketRulesWidget({
    super.key,
    required this.oversController,
    required this.ballsController,
    required this.wicketsController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: oversController,
          decoration: const InputDecoration(labelText: 'Overs'),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: ballsController,
          decoration: const InputDecoration(labelText: 'Balls per Over'),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: wicketsController,
          decoration: const InputDecoration(labelText: 'Wickets'),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}

class SetLeagueRulesScreen extends StatefulWidget {
  final String leagueId;
  final String leagueName;
  const SetLeagueRulesScreen({super.key, required this.leagueId, required this.leagueName});

  @override
  State<SetLeagueRulesScreen> createState() => _SetLeagueRulesScreenState();
}

class _SetLeagueRulesScreenState extends State<SetLeagueRulesScreen> {
  String? sport;
  Map<String, dynamic> rules = {};
  bool isLoading = true;

  // Controllers for rules fields
  final TextEditingController throwballSetsController = TextEditingController();
  final TextEditingController throwballPointsController = TextEditingController();
  final TextEditingController throwballTimeoutsController = TextEditingController();

  final TextEditingController cricketOversController = TextEditingController();
  final TextEditingController cricketBallsController = TextEditingController();
  final TextEditingController cricketWicketsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchLeagueData();
  }

  Future<void> _fetchLeagueData() async {
    setState(() { isLoading = true; });
    final response = await http.get(Uri.parse('http://192.168.1.134:3000/leagues'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final league = (data as List).firstWhere((l) => l['_id'] == widget.leagueId, orElse: () => null);
      if (league != null) {
        setState(() {
          sport = league['sport'];
          rules = league['rules'] ?? {};
        });
        // Set controllers based on rules
        if (sport == 'Throw Ball') {
          throwballSetsController.text = rules['numberOfSets']?.toString() ?? '';
          throwballPointsController.text = rules['pointsPerSet']?.toString() ?? '';
          throwballTimeoutsController.text = rules['timeoutsPerSet']?.toString() ?? '';
        } else if (sport == 'Cricket') {
          cricketOversController.text = rules['overs']?.toString() ?? '';
          cricketBallsController.text = rules['ballsPerOver']?.toString() ?? '';
          cricketWicketsController.text = rules['wickets']?.toString() ?? '';
        }
      }
    }
    setState(() { isLoading = false; });
  }

  Future<void> _saveRules() async {
    setState(() { isLoading = true; });
    Map<String, dynamic> updatedRules = {};
    if (sport == 'Throw Ball') {
      updatedRules = {
        'numberOfSets': int.tryParse(throwballSetsController.text) ?? 3,
        'pointsPerSet': int.tryParse(throwballPointsController.text) ?? 25,
        'timeoutsPerSet': int.tryParse(throwballTimeoutsController.text) ?? 2,
      };
    } else if (sport == 'Cricket') {
      updatedRules = {
        'overs': int.tryParse(cricketOversController.text) ?? 20,
        'ballsPerOver': int.tryParse(cricketBallsController.text) ?? 6,
        'wickets': int.tryParse(cricketWicketsController.text) ?? 10,
      };
    }
    final response = await http.put(
      Uri.parse('http://192.168.1.134:3000/leagues/${widget.leagueId}/rules'),
      headers: { 'Content-Type': 'application/json' },
      body: json.encode({ 'rules': updatedRules }),
    );
    setState(() { isLoading = false; });
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rules updated successfully')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update rules')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Set Rules: ${widget.leagueName}')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sport: ${sport ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (sport == 'Throw Ball')
                    ThrowballRulesWidget(
                      setsController: throwballSetsController,
                      pointsController: throwballPointsController,
                      timeoutsController: throwballTimeoutsController,
                    ),
                  if (sport == 'Cricket')
                    CricketRulesWidget(
                      oversController: cricketOversController,
                      ballsController: cricketBallsController,
                      wicketsController: cricketWicketsController,
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveRules,
                    child: const Text('Save Rules'),
                  ),
                ],
              ),
            ),
    );
  }
}
