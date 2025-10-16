import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:scorer/config.dart';

class PointsTableWidget extends StatefulWidget {
  final String leagueId;
  const PointsTableWidget({Key? key, required this.leagueId}) : super(key: key);

  @override
  State<PointsTableWidget> createState() => _PointsTableWidgetState();
}

class _PointsTableWidgetState extends State<PointsTableWidget> {
  late Future<List<Map<String, dynamic>>> _pointsTableFuture;

  @override
  void initState() {
    super.initState();
    _pointsTableFuture = fetchPointsTable(widget.leagueId);
  }

  Future<List<Map<String, dynamic>>> fetchPointsTable(String leagueId) async {
    final url = '${Config.apiBaseUrl}/leagues/$leagueId/points-table';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['table']);
    } else {
      throw Exception('Failed to load points table: ${response.statusCode} ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _pointsTableFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading points table\n${snapshot.error}', textAlign: TextAlign.center));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No points table available'));
        }
        final pointsTable = List<Map<String, dynamic>>.from(snapshot.data!);
        pointsTable.sort((a, b) {
          if (b['totalPoints'] != a['totalPoints']) {
            return b['totalPoints'].compareTo(a['totalPoints']);
          } else {
            return b['pointsDifference'].compareTo(a['pointsDifference']);
          }
        });
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: const [
                  Expanded(child: Text('Team', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  Expanded(child: Text('M', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  Expanded(child: Text('W', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  Expanded(child: Text('L', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  Expanded(child: Text('Pts', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  Expanded(child: Text('PD', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                ],
              ),
              const Divider(),
              ...pointsTable.map((row) => Row(
                children: [
                  Expanded(child: Text(row['team'].toString(), textAlign: TextAlign.center)),
                  Expanded(child: Text(row['matches'].toString(), textAlign: TextAlign.center)),
                  Expanded(child: Text(row['wins'].toString(), textAlign: TextAlign.center)),
                  Expanded(child: Text(row['losses'].toString(), textAlign: TextAlign.center)),
                  Expanded(child: Text(row['totalPoints'].toString(), textAlign: TextAlign.center)),
                  Expanded(child: Text(row['pointsDifference'].toString(), textAlign: TextAlign.center)),
                ],
              )).toList(),
            ],
          ),
        );
      },
    );
  }
}
