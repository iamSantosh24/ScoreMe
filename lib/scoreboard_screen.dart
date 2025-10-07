import 'package:flutter/material.dart';

// Data class to store bowler stats
class BowlerStats {
  double overs;
  int maidens;
  int runs;
  int wickets;
  int wides;
  int noBalls;

  BowlerStats({
    required this.overs,
    required this.maidens,
    required this.runs,
    required this.wickets,
    required this.wides,
    required this.noBalls,
  });
}

class ScoreboardScreen extends StatefulWidget {
  final String team1;
  final String team2;
  final String tossWinner;
  final String tossChoice;
  final List<String> team1Players;
  final List<String> team2Players;
  final String team1Captain;
  final String team1Wicketkeeper;
  final String team2Captain;
  final String team2Wicketkeeper;

  const ScoreboardScreen({
    super.key,
    required this.team1,
    required this.team2,
    required this.tossWinner,
    required this.tossChoice,
    required this.team1Players,
    required this.team2Players,
    required this.team1Captain,
    required this.team1Wicketkeeper,
    required this.team2Captain,
    required this.team2Wicketkeeper,
  });

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  int _runs = 0;
  int _wickets = 0;
  String? _batter1;
  String? _batter2;
  String? _bowler;
  bool _hasSelectedBatters = false;
  bool _hasSelectedBowler = false;
  int _batter1Runs = 0;
  int _batter1Balls = 0;
  int _batter1Fours = 0;
  int _batter1Sixes = 0;
  int _batter2Runs = 0;
  int _batter2Balls = 0;
  int _batter2Fours = 0;
  int _batter2Sixes = 0;
  double _bowlerOvers = 0.0;
  int _bowlerMaidens = 0;
  int _bowlerRuns = 0;
  int _bowlerWickets = 0;
  int _bowlerWides = 0;
  int _bowlerNoBalls = 0;
  int _inningsLegByes = 0; // Track leg byes at innings level
  int _inningsByes = 0; // Track byes at innings level
  int _legitimateBalls = 0; // Track legitimate balls in the current over
  int _overRuns = 0; // Track runs in the current over for maiden calculation
  bool _batter1OnStrike = true; // Track which batter is on strike
  Map<String, double> _bowlerOversMap = {}; // Track total overs per bowler
  Map<String, BowlerStats> _bowlerStatsMap = {}; // Track all stats per bowler
  List<String> _currentOverResults =
      []; // Track ball-by-ball results for current over
  List<String> _bowlerOrder = []; // Track order of bowlers
  final int _totalOvers = 20; // Total overs in the match
  final double _maxOversPerBowler = 4.0; // 20% of 20 overs

  void _undoLastBall() {
    if (_currentOverResults.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No action to undo!')));
      return;
    }

    final lastResult = _currentOverResults.removeLast();
    setState(() {
      // Parse and reverse based on last result
      if (lastResult == 'W') {
        // Undo wicket
        if (_wickets > 0) _wickets -= 1;
        if (_bowlerWickets > 0) _bowlerWickets -= 1;
        _legitimateBalls = (_legitimateBalls > 0) ? _legitimateBalls - 1 : 0;
        _overRuns = (_overRuns >= 0) ? _overRuns : 0; // No runs on wicket
      } else if (int.tryParse(lastResult) != null) {
        // Undo runs (0-6)
        final runs = int.parse(lastResult);
        if (_runs >= runs) _runs -= runs;
        if (_bowlerRuns >= runs) _bowlerRuns -= runs;
        _overRuns = (_overRuns >= runs) ? _overRuns - runs : 0;
        _legitimateBalls = (_legitimateBalls > 0) ? _legitimateBalls - 1 : 0;

        // Undo batter stats
        if (_batter1OnStrike) {
          if (_batter1Runs >= runs) _batter1Runs -= runs;
          if (_batter1Balls > 0) _batter1Balls -= 1;
          if (runs == 4 && _batter1Fours > 0) _batter1Fours -= 1;
          if (runs == 6 && _batter1Sixes > 0) _batter1Sixes -= 1;
        } else {
          if (_batter2Runs >= runs) _batter2Runs -= runs;
          if (_batter2Balls > 0) _batter2Balls -= 1;
          if (runs == 4 && _batter2Fours > 0) _batter2Fours -= 1;
          if (runs == 6 && _batter2Sixes > 0) _batter2Sixes -= 1;
        }

        // Restore strike if odd runs were undone
        if (runs % 2 == 1) {
          _batter1OnStrike = !_batter1OnStrike;
        }
      } else if (lastResult.startsWith('wd') ||
          lastResult.startsWith('nb') ||
          lastResult.startsWith('lb') ||
          lastResult.startsWith('b')) {
        // Undo extras (simplified: parse runs from result string)
        int extraRuns = 1; // Default
        if (lastResult.contains('+')) {
          extraRuns = int.parse(lastResult.split('+')[1]) + 1;
        }
        if (_runs >= extraRuns) _runs -= extraRuns;
        if (_bowlerRuns >= extraRuns) _bowlerRuns -= extraRuns;
        _overRuns = (_overRuns >= extraRuns) ? _overRuns - extraRuns : 0;

        // Restore strike if odd extras
        if (extraRuns % 2 == 1) {
          _batter1OnStrike = !_batter1OnStrike;
        }

        // Undo counters (basic; expand as needed)
        if (lastResult.startsWith('wd'))
          _bowlerWides = (_bowlerWides > 0) ? _bowlerWides - 1 : 0;
        else if (lastResult.startsWith('nb'))
          _bowlerNoBalls = (_bowlerNoBalls > 0) ? _bowlerNoBalls - 1 : 0;
        else if (lastResult.startsWith('lb'))
          _inningsLegByes = (_inningsLegByes > extraRuns)
              ? _inningsLegByes - extraRuns
              : 0;
        else if (lastResult.startsWith('b'))
          _inningsByes = (_inningsByes > extraRuns)
              ? _inningsByes - extraRuns
              : 0;

        // No ball extras: undo batter runs if awarded
        if (lastResult.startsWith('nb')) {
          int batterRuns = extraRuns - 1;
          if (batterRuns > 0) {
            if (_batter1OnStrike) {
              if (_batter1Runs >= batterRuns) _batter1Runs -= batterRuns;
              if (batterRuns == 4 && _batter1Fours > 0) _batter1Fours -= 1;
              if (batterRuns == 6 && _batter1Sixes > 0) _batter1Sixes -= 1;
            } else {
              if (_batter2Runs >= batterRuns) _batter2Runs -= batterRuns;
              if (batterRuns == 4 && _batter2Fours > 0) _batter2Fours -= 1;
              if (batterRuns == 6 && _batter2Sixes > 0) _batter2Sixes -= 1;
            }
          }
        }

        // Extras don't count as legitimate balls, so no change to _legitimateBalls
      }

      // Revert overs update (simplified: subtract 0.1 if legitimate ball undone)
      if (_bowler != null && RegExp(r'^\d$|W|lb|b').hasMatch(lastResult)) {
        _legitimateBalls = (_legitimateBalls > 0) ? _legitimateBalls - 1 : 0;
        final previousOvers = (_bowlerOversMap[_bowler!] ?? 0.0) - 0.1;
        _bowlerOversMap[_bowler!] = previousOvers.clamp(0.0, double.infinity);
        // Update stats map
        _bowlerStatsMap[_bowler!] = BowlerStats(
          overs: previousOvers,
          maidens: _bowlerMaidens,
          runs: _bowlerRuns,
          wickets: _bowlerWickets,
          wides: _bowlerWides,
          noBalls: _bowlerNoBalls,
        );
      }
    });
  }

  void _runCounter(int value) {
    setState(() {
      _runs += value;
      _bowlerRuns += value;
      _overRuns += value;
      // Record ball result
      _currentOverResults.add('$value');
      // Update stats for the on-strike batter
      if (_batter1OnStrike) {
        _batter1Runs += value;
        _batter1Balls += 1;
        if (value == 4) _batter1Fours += 1;
        if (value == 6) _batter1Sixes += 1;
      } else {
        _batter2Runs += value;
        _batter2Balls += 1;
        if (value == 4) _batter2Fours += 1;
        if (value == 6) _batter2Sixes += 1;
      }
      // Switch strike if odd runs (1, 3, 5)
      if (value % 2 == 1) {
        _batter1OnStrike = !_batter1OnStrike;
      }
      // Update legitimate balls
      _legitimateBalls += 1;
      // Update overs: increment by 0.1 per legitimate ball
      if (_bowler != null) {
        double completedOvers = (_bowlerOversMap[_bowler!] ?? 0.0)
            .floorToDouble();
        _bowlerOvers = completedOvers + (_legitimateBalls * 0.1);
        _bowlerOversMap[_bowler!] = _bowlerOvers;
        // Update bowler stats in _bowlerStatsMap
        _bowlerStatsMap[_bowler!] = BowlerStats(
          overs: _bowlerOvers,
          maidens: _bowlerMaidens,
          runs: _bowlerRuns,
          wickets: _bowlerWickets,
          wides: _bowlerWides,
          noBalls: _bowlerNoBalls,
        );
      }
      _updateOversAndCheckNewBowler();
    });
  }

  void _openWickets() {
    setState(() {
      if (_wickets < 10) {
        _wickets += 1;
        _bowlerWickets += 1;
        // Record ball result
        _currentOverResults.add('W');
        // Count as a legitimate ball
        _legitimateBalls += 1;
        // Update overs and bowler stats
        if (_bowler != null) {
          double completedOvers = (_bowlerOversMap[_bowler!] ?? 0.0)
              .floorToDouble();
          _bowlerOvers = completedOvers + (_legitimateBalls * 0.1);
          _bowlerOversMap[_bowler!] = _bowlerOvers;
          _bowlerStatsMap[_bowler!] = BowlerStats(
            overs: _bowlerOvers,
            maidens: _bowlerMaidens,
            runs: _bowlerRuns,
            wickets: _bowlerWickets,
            wides: _bowlerWides,
            noBalls: _bowlerNoBalls,
          );
        }
        _updateOversAndCheckNewBowler();
      }
    });
  }

  void _openLegitimateExtras(String extraTitle, String extraType) {
    int? extraRuns;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            return AlertDialog(
              title: Text('Select $extraTitle Runs'),
              content: DropdownButton<int>(
                hint: const Text('Select Runs'),
                value: extraRuns,
                isExpanded: true,
                items: [1, 2, 3, 4, 5, 6].map((runs) {
                  return DropdownMenuItem<int>(
                    value: runs,
                    child: Text(runs == 1 ? extraType : '$runs$extraType'),
                  );
                }).toList(),
                onChanged: (value) {
                  dialogSetState(() {
                    extraRuns = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (extraRuns != null) {
                      setState(() {
                        _runs += extraRuns!;
                        _bowlerRuns += extraRuns!;
                        _overRuns += extraRuns!;
                        // Record ball result
                        _currentOverResults.add(
                          extraRuns == 1
                              ? extraType
                              : '$extraType+${extraRuns! - 1}',
                        );
                        // Increment appropriate extra counter
                        if (extraType == 'b') {
                          _inningsByes += 1;
                        } else if (extraType == 'lb') {
                          _inningsLegByes += 1;
                        }
                        // Count as a legitimate ball
                        _legitimateBalls += 1;
                        // Switch strike if odd runs
                        if (extraRuns! % 2 == 1) {
                          if (extraType == "lb" || extraType == "b") {
                            _batter1OnStrike = !_batter1OnStrike;
                          }
                        }
                        // Update overs and bowler stats
                        if (_bowler != null) {
                          double completedOvers =
                              (_bowlerOversMap[_bowler!] ?? 0.0)
                                  .floorToDouble();
                          _bowlerOvers =
                              completedOvers + (_legitimateBalls * 0.1);
                          _bowlerOversMap[_bowler!] = _bowlerOvers;
                          _bowlerStatsMap[_bowler!] = BowlerStats(
                            overs: _bowlerOvers,
                            maidens: _bowlerMaidens,
                            runs: _bowlerRuns,
                            wickets: _bowlerWickets,
                            wides: _bowlerWides,
                            noBalls: _bowlerNoBalls,
                          );
                        }
                        _updateOversAndCheckNewBowler();
                      });
                      Navigator.of(dialogContext).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please select the number of extra runs!',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openNonLegitimateExtras(String extraTitle, String extraType) {
    int? extraRuns;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            return AlertDialog(
              title: Text('Select $extraTitle Runs'),
              content: DropdownButton<int>(
                hint: const Text('Select Runs'),
                value: extraRuns,
                isExpanded: true,
                items: [1, 2, 3, 4, 5, 6].map((runs) {
                  return DropdownMenuItem<int>(
                    value: runs,
                    child: Text(
                      runs == 1 ? extraType : '$extraType+${runs - 1}',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  dialogSetState(() {
                    extraRuns = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (extraRuns != null) {
                      setState(() {
                        _runs += extraRuns!;
                        _bowlerRuns += extraRuns!;
                        _overRuns += extraRuns!;
                        // Record ball result
                        _currentOverResults.add(
                          extraRuns == 1
                              ? extraType
                              : '$extraType+${extraRuns! - 1}',
                        );
                        // Increment appropriate extra counter
                        if (extraType == 'nb') {
                          _bowlerNoBalls += 1;
                          int batterRuns =
                              extraRuns! -
                              1; // Subtract 1 for the no ball penalty
                          if (batterRuns > 0) {
                            if (_batter1OnStrike) {
                              _batter1Runs += batterRuns;
                              _batter1Balls += 1;
                              if (batterRuns == 4) _batter1Fours += 1;
                              if (batterRuns == 6) _batter1Sixes += 1;
                            } else {
                              _batter2Runs += batterRuns;
                              _batter2Balls += 1;
                              if (batterRuns == 4) _batter2Fours += 1;
                              if (batterRuns == 6) _batter2Sixes += 1;
                            }
                          }
                        } else if (extraType == 'wd') {
                          _bowlerWides += 1;
                        }
                        // Switch strike if odd runs
                        if (extraRuns! % 2 != 1) {
                          _batter1OnStrike = !_batter1OnStrike;
                        }
                        // Update bowler stats (no overs update since not a legitimate ball)
                        if (_bowler != null) {
                          _bowlerStatsMap[_bowler!] = BowlerStats(
                            overs: _bowlerOversMap[_bowler!] ?? _bowlerOvers,
                            maidens: _bowlerMaidens,
                            runs: _bowlerRuns,
                            wickets: _bowlerWickets,
                            wides: _bowlerWides,
                            noBalls: _bowlerNoBalls,
                          );
                        }
                      });
                      Navigator.of(dialogContext).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please select the number of extra runs!',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _updateOversAndCheckNewBowler() {
    if (_wickets >= 10 ||
        _bowlerOversMap.values.fold(0.0, (sum, overs) => sum + overs) >=
            _totalOvers) {
      // Match ended: 10 wickets or 20 overs reached
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Match Ended'),
            content: Text(
              'Innings concluded with $_runs/$_wickets in ${_bowlerOversMap.values.fold(0.0, (sum, overs) => sum + overs).toStringAsFixed(1)} overs.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    if (_legitimateBalls == 6) {
      // Complete the over
      if (_bowler != null) {
        // Increment completed overs by 1, reset fractional part
        _bowlerOvers = (_bowlerOversMap[_bowler!] ?? 0.0).floorToDouble() + 1.0;
        _bowlerOversMap[_bowler!] = _bowlerOvers;
        // Update bowler stats in _bowlerStatsMap
        _bowlerStatsMap[_bowler!] = BowlerStats(
          overs: _bowlerOvers,
          maidens: _bowlerMaidens,
          runs: _bowlerRuns,
          wickets: _bowlerWickets,
          wides: _bowlerWides,
          noBalls: _bowlerNoBalls,
        );
      }
      // Check for maiden (no runs in the over, including extras)
      if (_overRuns == 0) _bowlerMaidens += 1;
      _legitimateBalls = 0;
      _overRuns = 0;
      _currentOverResults.clear(); // Clear ball-by-ball results for new over
      // Reset current over stats for the bowler
      _bowlerRuns = 0;
      _bowlerWickets = 0;
      _bowlerWides = 0;
      _bowlerNoBalls = 0;
      // Prompt for new bowler
      _showBowlerSelectionDialog();
    } else {
      // Update overs incrementally for partial overs
      if (_bowler != null) {
        double completedOvers = (_bowlerOversMap[_bowler!] ?? 0.0)
            .floorToDouble();
        _bowlerOvers = completedOvers + (_legitimateBalls * 0.1);
        _bowlerOversMap[_bowler!] = _bowlerOvers;
        _bowlerStatsMap[_bowler!] = BowlerStats(
          overs: _bowlerOvers,
          maidens: _bowlerMaidens,
          runs: _bowlerRuns,
          wickets: _bowlerWickets,
          wides: _bowlerWides,
          noBalls: _bowlerNoBalls,
        );
      }
    }
  }

  // Switch the on-strike batter
  void _switchBatterOnStrike() {
    setState(() {
      _batter1OnStrike = !_batter1OnStrike;
    });
  }

  // Determine the batting team based on toss
  String get _battingTeam => widget.tossChoice == 'Batting'
      ? widget.tossWinner
      : (widget.tossWinner == widget.team1 ? widget.team2 : widget.team1);

  // Determine the bowling team
  String get _bowlingTeam => widget.tossChoice == 'Batting'
      ? (widget.tossWinner == widget.team1 ? widget.team2 : widget.team1)
      : widget.tossWinner;

  // Get the player list for the batting team
  List<String> get _battingTeamPlayers =>
      _battingTeam == widget.team1 ? widget.team1Players : widget.team2Players;

  // Get the player list for the bowling team
  List<String> get _bowlingTeamPlayers =>
      _bowlingTeam == widget.team1 ? widget.team1Players : widget.team2Players;

  // Calculate strike rate: (Runs / Balls) * 100, rounded to 2 decimal places
  double _calculateStrikeRate(int runs, int balls) {
    if (balls == 0) return 0.0;
    return double.parse(((runs / balls) * 100).toStringAsFixed(2));
  }

  // Show dialog to select batters
  void _showBatterSelectionDialog() {
    String? tempBatter1;
    String? tempBatter2;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            return AlertDialog(
              title: Text('Select Batters for $_battingTeam'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButton<String>(
                      hint: const Text('Select Batter 1'),
                      value: tempBatter1,
                      isExpanded: true,
                      items: _battingTeamPlayers
                          .where((player) => player != tempBatter2)
                          .map((player) {
                            return DropdownMenuItem<String>(
                              value: player,
                              child: Text(player),
                            );
                          })
                          .toList(),
                      onChanged: (value) =>
                          dialogSetState(() => tempBatter1 = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButton<String>(
                      hint: const Text('Select Batter 2'),
                      value: tempBatter2,
                      isExpanded: true,
                      items: _battingTeamPlayers
                          .where((player) => player != tempBatter1)
                          .map((player) {
                            return DropdownMenuItem<String>(
                              value: player,
                              child: Text(player),
                            );
                          })
                          .toList(),
                      onChanged: (value) =>
                          dialogSetState(() => tempBatter2 = value),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    if (tempBatter1 != null &&
                        tempBatter2 != null &&
                        tempBatter1 != tempBatter2) {
                      setState(() {
                        _batter1 = tempBatter1;
                        _batter2 = tempBatter2;
                        _hasSelectedBatters = true;
                      });
                      Navigator.of(dialogContext).pop();
                      // Show bowler selection dialog after batters are selected
                      _showBowlerSelectionDialog();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select two different batters!'),
                        ),
                      );
                    }
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Show dialog to select bowler
  void _showBowlerSelectionDialog() {
    String? tempBowler;

    // Filter out current bowler and those who have bowled max overs
    final availableBowlers = _bowlingTeamPlayers
        .where(
          (player) =>
              player != _bowler &&
              (_bowlerOversMap[player] ?? 0.0) < _maxOversPerBowler,
        )
        .toList();

    if (availableBowlers.isEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('No Available Bowlers'),
            content: const Text(
              'All eligible bowlers have reached their maximum overs or no valid bowlers are available.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            return AlertDialog(
              title: Text('Select Bowler for $_bowlingTeam'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButton<String>(
                      hint: const Text('Select Bowler'),
                      value: tempBowler,
                      isExpanded: true,
                      items: availableBowlers.map((player) {
                        return DropdownMenuItem<String>(
                          value: player,
                          child: Text(
                            '$player (${(_bowlerOversMap[player] ?? 0.0).toStringAsFixed(1)} overs bowled)',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          dialogSetState(() => tempBowler = value),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    if (tempBowler != null) {
                      setState(() {
                        _bowler = tempBowler;
                        _hasSelectedBowler = true;
                        // Add bowler to _bowlerOrder
                        _bowlerOrder.add(tempBowler!);
                        // Restore previous stats if the bowler has bowled before
                        final previousStats = _bowlerStatsMap[tempBowler];
                        if (previousStats != null) {
                          _bowlerOvers = previousStats.overs;
                          _bowlerMaidens = previousStats.maidens;
                          _bowlerRuns = previousStats.runs;
                          _bowlerWickets = previousStats.wickets;
                          _bowlerWides = previousStats.wides;
                          _bowlerNoBalls = previousStats.noBalls;
                        } else {
                          // Initialize stats for new bowler
                          _bowlerOvers = _bowlerOversMap[tempBowler] ?? 0.0;
                          _bowlerMaidens = 0;
                          _bowlerRuns = 0;
                          _bowlerWickets = 0;
                          _bowlerWides = 0;
                          _bowlerNoBalls = 0;
                          // Add new bowler to _bowlerStatsMap immediately
                          _bowlerStatsMap[tempBowler!] = BowlerStats(
                            overs: _bowlerOvers,
                            maidens: _bowlerMaidens,
                            runs: _bowlerRuns,
                            wickets: _bowlerWickets,
                            wides: _bowlerWides,
                            noBalls: _bowlerNoBalls,
                          );
                        }
                        _legitimateBalls = 0;
                        _overRuns = 0;
                        _currentOverResults
                            .clear(); // Clear ball-by-ball results for new bowler
                      });
                      Navigator.of(dialogContext).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a bowler!'),
                        ),
                      );
                    }
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Show batter selection dialog when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasSelectedBatters) {
        _showBatterSelectionDialog();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text('${widget.team1} vs ${widget.team2}'),
        ),
        body: Column(
          children: [
            // Score, batter stats, and bowler stats at the top
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '$_battingTeam Batting',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_runs/$_wickets',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (_hasSelectedBatters) ...[
                    const SizedBox(height: 16),
                    Table(
                      border: TableBorder.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.2),
                      ),
                      columnWidths: const {
                        0: FlexColumnWidth(3),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                        3: FlexColumnWidth(1),
                        4: FlexColumnWidth(1),
                        5: FlexColumnWidth(2),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                          ),
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Batter',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Runs',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Balls',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                '4s',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                '6s',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Strike Rate',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        // First row: On-strike batter
                        TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _batter1OnStrike
                                    ? '${_batter1 ?? 'Batter 1'} *'
                                    : '${_batter2 ?? 'Batter 2'} *',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _batter1OnStrike
                                    ? '$_batter1Runs'
                                    : '$_batter2Runs',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _batter1OnStrike
                                    ? '$_batter1Balls'
                                    : '$_batter2Balls',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _batter1OnStrike
                                    ? '$_batter1Fours'
                                    : '$_batter2Fours',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _batter1OnStrike
                                    ? '$_batter1Sixes'
                                    : '$_batter2Sixes',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _batter1OnStrike
                                    ? '${_calculateStrikeRate(_batter1Runs, _batter1Balls)}'
                                    : '${_calculateStrikeRate(_batter2Runs, _batter2Balls)}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        // Second row: Non-strike batter
                        TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _batter1OnStrike
                                    ? _batter2 ?? 'Batter 2'
                                    : _batter1 ?? 'Batter 1',
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _batter1OnStrike
                                    ? '$_batter2Runs'
                                    : '$_batter1Runs',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _batter1OnStrike
                                    ? '$_batter2Balls'
                                    : '$_batter1Balls',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _batter1OnStrike
                                    ? '$_batter2Fours'
                                    : '$_batter1Fours',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _batter1OnStrike
                                    ? '$_batter2Sixes'
                                    : '$_batter1Sixes',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _batter1OnStrike
                                    ? '${_calculateStrikeRate(_batter2Runs, _batter2Balls)}'
                                    : '${_calculateStrikeRate(_batter1Runs, _batter1Balls)}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                  if (_hasSelectedBowler) ...[
                    const SizedBox(height: 16),
                    Table(
                      border: TableBorder.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.2),
                      ),
                      columnWidths: const {
                        0: FlexColumnWidth(3),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                        3: FlexColumnWidth(1),
                        4: FlexColumnWidth(1),
                        5: FlexColumnWidth(1),
                        6: FlexColumnWidth(1),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                          ),
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Bowler',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'O',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'M',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'R',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'W',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Wd',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Nb',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        // Show only current bowler and last bowler
                        ..._bowlerStatsMap.entries
                            .where((entry) {
                              final bowler = entry.key;
                              // Include current bowler
                              if (bowler == _bowler) return true;
                              // Include last bowler if there are at least two bowlers and it's not the current bowler
                              if (_bowlerOrder.length >= 2 &&
                                  bowler ==
                                      _bowlerOrder[_bowlerOrder.length - 2])
                                return true;
                              return false;
                            })
                            .map((entry) {
                              final bowler = entry.key;
                              final stats = entry.value;
                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '$bowler${bowler == _bowler ? ' *' : ''}',
                                      style: TextStyle(
                                        fontWeight: bowler == _bowler
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      stats.overs.toStringAsFixed(1),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '${stats.maidens}',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '${stats.runs}',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '${stats.wickets}',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '${stats.wides}',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '${stats.noBalls}',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              );
                            })
                            .toList(),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: _switchBatterOnStrike,
                        child: const Text('Switch Batter'),
                      ),
                      TextButton(
                        onPressed: _showBowlerSelectionDialog,
                        child: const Text('Change Bowler'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => _runCounter(1),
                        // Add 1 run; adjust if needed
                        child: const Text('Add Run'),
                      ),
                      TextButton(
                        onPressed: _undoLastBall,
                        child: const Text('Undo'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // TabBarView for the rest of the content
            Expanded(
              child: TabBarView(
                children: [
                  // Live Scoring Tab
                  SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // Display current over ball-by-ball result
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  'This Over: ${_currentOverResults.isEmpty ? '-' : _currentOverResults.join(" ")}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(
                                  5,
                                  (index) => Expanded(
                                    child: TextButton(
                                      onPressed: () => _runCounter(index),
                                      child: Text('$index'),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => _runCounter(5),
                                      child: const Text('5'),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => _runCounter(6),
                                      child: const Text('6'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: _openWickets,
                                      child: const Text('Wicket'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () =>
                                          _openNonLegitimateExtras('Wide', 'wd'),
                                      child: const Text('Wide'),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => _openNonLegitimateExtras(
                                        'No ball',
                                        'nb',
                                      ),
                                      child: const Text('No Ball'),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () =>
                                          _openLegitimateExtras('Leg Bye', 'lb'),
                                      child: const Text('Leg Bye'),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () =>
                                          _openLegitimateExtras('Bye', 'b'),
                                      child: const Text('Bye'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Squads Tab
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.tossWinner} won toss, chose ${widget.tossChoice}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${widget.team1} Playing XI:',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ...widget.team1Players.map(
                            (player) => Text(
                              '$player${player == widget.team1Captain ? ' (C)' : ''}${player == widget.team1Wicketkeeper ? ' (WK)' : ''}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${widget.team2} Playing XI:',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ...widget.team2Players.map(
                            (player) => Text(
                              '$player${player == widget.team2Captain ? ' (C)' : ''}${player == widget.team2Wicketkeeper ? ' (WK)' : ''}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Scorecard Tab
                  const Center(
                    child: Text(
                      'Scorecard - Work in Progress',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  // Actions Tab
                  const Center(
                    child: Text(
                      'Actions - Work in Progress',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: TabBar(
          isScrollable: true,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.only(left: 0, right: 16.0),
          tabs: [
            Tab(
              child: Text(
                'Live Scoring',
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Tab(
              child: Text(
                'Squads',
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Tab(
              child: Text(
                'Scorecard',
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Tab(
              child: Text(
                'Actions',
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
