import 'package:flutter/material.dart';

class ThrowballLiveScore extends StatefulWidget {
  final Map<String, dynamic> gameData;
  const ThrowballLiveScore({super.key, required this.gameData});

  @override
  State<ThrowballLiveScore> createState() => _ThrowballLiveScoreState();
}

class _ThrowballLiveScoreState extends State<ThrowballLiveScore> {
  int teamASets = 0;
  int teamBSets = 0;
  List<int> teamAPoints = [0, 0, 0];
  List<int> teamBPoints = [0, 0, 0];
  int teamATimeouts = 0;
  int teamBTimeouts = 0;
  int maxTimeouts = 2; // Set max timeouts per team

  // Track the sequence of points and timeouts
  List<Map<String, dynamic>> pointsHistory = [];

  List<String> get teamAMembers => List<String>.from(widget.gameData['teamAOnCourt'] ?? []);
  List<String> get teamBMembers => List<String>.from(widget.gameData['teamBOnCourt'] ?? []);

  // Add helper to get roster for each team
  List<String> get teamARoster => List<String>.from(widget.gameData['teamARoster'] ?? []);
  List<String> get teamBRoster => List<String>.from(widget.gameData['teamBRoster'] ?? []);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Throwball Live Score'),
        backgroundColor: Colors.green[700], // Match cricket screen color
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade200, Colors.green.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${widget.gameData['teamAName'] ?? 'Team A'}',
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '${teamAPoints.reduce((a, b) => a + b)}',
                                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${widget.gameData['teamBName'] ?? 'Team B'}',
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '${teamBPoints.reduce((a, b) => a + b)}',
                                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Divider(thickness: 2),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Center(
                          child: _teamSection(
                            teamName: widget.gameData['teamAName'] ?? 'Team A',
                            members: teamAMembers,
                            points: teamAPoints.reduce((a, b) => a + b),
                            timeouts: teamATimeouts,
                            onPointsChange: (delta) {
                              setState(() {
                                int newPoints = teamAPoints.reduce((a, b) => a + b) + delta;
                                if (newPoints >= 0) {
                                  teamAPoints[0] = newPoints;
                                  if (delta > 0) {
                                    pointsHistory.add({'team': 'A', 'point': newPoints});
                                  } else if (delta < 0 && pointsHistory.isNotEmpty) {
                                    // Remove last Team A point if possible
                                    for (int i = pointsHistory.length - 1; i >= 0; i--) {
                                      if (pointsHistory[i]['team'] == 'A') {
                                        pointsHistory.removeAt(i);
                                        break;
                                      }
                                    }
                                  }
                                }
                              });
                            },
                            onTimeoutChange: (delta) {
                              setState(() {
                                int newTimeouts = teamATimeouts + delta;
                                if (newTimeouts >= 0 && newTimeouts <= maxTimeouts) {
                                  teamATimeouts = newTimeouts;
                                  if (delta > 0) {
                                    pointsHistory.add({'team': 'A', 'type': 'timeout', 'timeout': newTimeouts});
                                  }
                                }
                              });
                            },
                            maxTimeouts: maxTimeouts,
                            isRight: true,
                            roster: teamARoster.where((p) => !teamAMembers.contains(p)).toList(),
                            onSubstitute: (removePlayer, addPlayer) {
                              setState(() {
                                int idx = teamAMembers.indexOf(removePlayer);
                                if (idx != -1) {
                                  widget.gameData['teamAOnCourt'][idx] = addPlayer;
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      Container(
                        width: 2,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        color: Colors.green[700],
                      ),
                      Expanded(
                        child: Center(
                          child: _teamSection(
                            teamName: widget.gameData['teamBName'] ?? 'Team B',
                            members: teamBMembers,
                            points: teamBPoints.reduce((a, b) => a + b),
                            timeouts: teamBTimeouts,
                            onPointsChange: (delta) {
                              setState(() {
                                int newPoints = teamBPoints.reduce((a, b) => a + b) + delta;
                                if (newPoints >= 0) {
                                  teamBPoints[0] = newPoints;
                                  if (delta > 0) {
                                    pointsHistory.add({'team': 'B', 'point': newPoints});
                                  } else if (delta < 0 && pointsHistory.isNotEmpty) {
                                    // Remove last Team B point if possible
                                    for (int i = pointsHistory.length - 1; i >= 0; i--) {
                                      if (pointsHistory[i]['team'] == 'B') {
                                        pointsHistory.removeAt(i);
                                        break;
                                      }
                                    }
                                  }
                                }
                              });
                            },
                            onTimeoutChange: (delta) {
                              setState(() {
                                int newTimeouts = teamBTimeouts + delta;
                                if (newTimeouts >= 0 && newTimeouts <= maxTimeouts) {
                                  teamBTimeouts = newTimeouts;
                                  if (delta > 0) {
                                    pointsHistory.add({'team': 'B', 'type': 'timeout', 'timeout': newTimeouts});
                                  }
                                }
                              });
                            },
                            maxTimeouts: maxTimeouts,
                            isRight: false,
                            roster: teamBRoster.where((p) => !teamBMembers.contains(p)).toList(),
                            onSubstitute: (removePlayer, addPlayer) {
                              setState(() {
                                int idx = teamBMembers.indexOf(removePlayer);
                                if (idx != -1) {
                                  widget.gameData['teamBOnCourt'][idx] = addPlayer;
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(thickness: 2), // Single Divider below team sections
              SizedBox(height: 16),
              _livePointsTracker(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamSection({
    required String teamName,
    required List<String> members,
    required int points,
    required int timeouts,
    required int maxTimeouts,
    required void Function(int) onPointsChange,
    required void Function(int) onTimeoutChange,
    required bool isRight,
    required List<String> roster,
    required void Function(String removePlayer, String addPlayer) onSubstitute,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: isRight ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text('Current Team:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ...members.map((m) => Text(m, style: TextStyle(fontSize: 16))),
          SizedBox(height: 12),
          Text('Points', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Row(
            mainAxisAlignment: isRight ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.remove),
                onPressed: points > 0 ? () => onPointsChange(-1) : null,
              ),
              Text('$points', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () => onPointsChange(1),
              ),
            ],
          ),
          SizedBox(height: 32),
          Text('Timeouts: $timeouts / $maxTimeouts', style: TextStyle(fontSize: 16)),
          Row(
            mainAxisAlignment: isRight ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: (timeouts < maxTimeouts) ? () => onTimeoutChange(1) : null,
                child: Text('Call Timeout'),
              ),
            ],
          ),
          SizedBox(height: 32),
          Row(
            mainAxisAlignment: isRight ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: (members.length == 7 && roster.isNotEmpty)
                  ? () async {
                      String? removePlayer = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          String? selectedRemove;
                          return AlertDialog(
                            title: Text('Select player to remove'),
                            content: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedRemove,
                              items: members.map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(m),
                              )).toList(),
                              onChanged: (val) {
                                selectedRemove = val;
                                Navigator.of(context).pop(val);
                              },
                            ),
                          );
                        },
                      );
                      if (removePlayer != null) {
                        String? addPlayer = await showDialog<String>(
                          context: context,
                          builder: (context) {
                            String? selectedAdd;
                            return AlertDialog(
                              title: Text('Select player to add'),
                              content: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedAdd,
                                items: roster.map((r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(r),
                                )).toList(),
                                onChanged: (val) {
                                  selectedAdd = val;
                                  Navigator.of(context).pop(val);
                                },
                              ),
                            );
                          },
                        );
                        if (addPlayer != null) {
                          onSubstitute(removePlayer, addPlayer);
                        }
                      }
                    }
                  : null,
                child: Text('Substitution'),
              ),
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _livePointsTracker() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: pointsHistory.map((entry) {
          final isA = entry['team'] == 'A';
          if (entry['type'] == 'timeout') {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isA ? Colors.green[900] : Colors.orange[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text(
                    '${isA ? 'A' : 'B'} Timeout (${entry['timeout']})',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            );
          } else {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isA ? Colors.green[300] : Colors.orange[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(isA ? 'A' : 'B', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(width: 4),
                  Text(entry['point'].toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }
        }).toList(),
      ),
    );
  }

  void _submitThrowballScore() {
    // TODO: Implement score submission logic
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Throwball score submitted!')));
  }
}
