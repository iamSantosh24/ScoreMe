import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:scorer/config.dart';

class UpdateTeamsScreen extends StatefulWidget {
  final String leagueId;
  final String leagueName;
  final String? teamId;
  const UpdateTeamsScreen({super.key, required this.leagueId, required this.leagueName, this.teamId});

  @override
  State<UpdateTeamsScreen> createState() => _UpdateTeamsScreenState();
}

class _UpdateTeamsScreenState extends State<UpdateTeamsScreen> {
  final TextEditingController _nameController = TextEditingController();
  File? _logoFile;
  String? _logoUrl;
  List<String> players = [];
  final TextEditingController _playerController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeamInfo();
  }

  Future<void> _fetchTeamInfo() async {
    if (widget.teamId == null || widget.teamId!.isEmpty) {
      setState(() { isLoading = false; });
      return;
    }
    final response = await http.get(Uri.parse('${Config.apiBaseUrl}/teams/list'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final team = (data['teams'] as List).firstWhere(
        (t) => t['_id'] == widget.teamId,
        orElse: () => null,
      );
      if (team != null) {
        _nameController.text = team['name'] ?? '';
        _logoUrl = team['logo'] ?? null;
        players = List<String>.from(team['members'] ?? []);
      }
    }
    setState(() { isLoading = false; });
  }

  Future<void> _pickLogo() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Upload from Gallery'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setState(() { _logoFile = File(picked.path); });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.camera);
                  if (picked != null) {
                    setState(() { _logoFile = File(picked.path); });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addPlayer() {
    final name = _playerController.text.trim();
    if (name.isNotEmpty && !players.contains(name)) {
      setState(() { players.add(name); });
      _playerController.clear();
    }
  }

  void _removePlayer(String name) {
    setState(() { players.remove(name); });
  }

  Future<void> _saveTeam() async {
    setState(() { isLoading = true; });
    String? logoUrl = _logoUrl;
    // Upload logo if changed
    if (_logoFile != null) {
      // Simulate upload, replace with actual upload logic if needed
      logoUrl = 'uploaded/${_logoFile!.path.split('/').last}';
    }
    final body = {
      'name': _nameController.text.trim(),
      'logo': logoUrl,
      'members': players,
      'leagueId': widget.leagueId,
    };
    final response = await http.put(
      Uri.parse('${Config.apiBaseUrl}/teams/${widget.teamId ?? ''}'),
      headers: { 'Content-Type': 'application/json' },
      body: json.encode(body),
    );
    setState(() { isLoading = false; });
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Team updated successfully')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update team')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Update Team: ${widget.leagueName}')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Team Name'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _logoFile != null
                          ? Image.file(_logoFile!, width: 64, height: 64)
                          : (_logoUrl != null && _logoUrl!.isNotEmpty)
                              ? Image.network(_logoUrl!, width: 64, height: 64)
                              : Container(width: 64, height: 64, color: Colors.grey[300]),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _pickLogo,
                        child: const Text('Change Logo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Players:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _playerController,
                          decoration: const InputDecoration(labelText: 'Add Player Name'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addPlayer,
                      ),
                    ],
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final name = players[index];
                      return ListTile(
                        title: Text(name),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removePlayer(name),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveTeam,
                    child: const Text('Save Team'),
                  ),
                ],
              ),
            ),
    );
  }
}
