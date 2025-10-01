import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GodAdminScreen extends StatefulWidget {
  @override
  _GodAdminScreenState createState() => _GodAdminScreenState();
}

class _GodAdminScreenState extends State<GodAdminScreen> {
  List<dynamic> users = [];
  String? selectedUser;
  String? message;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final response = await http.get(Uri.parse('http://localhost:3000/users'));
    if (response.statusCode == 200) {
      setState(() {
        users = json.decode(response.body)['users'];
      });
    }
  }

  Future<void> grantSuperAdmin(String username) async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/grant-super-admin'),
      headers: {'Authorization': 'Bearer YOUR_GOD_ADMIN_TOKEN', 'Content-Type': 'application/json'},
      body: json.encode({'username': username}),
    );
    setState(() {
      message = json.decode(response.body)['message'] ?? json.decode(response.body)['error'];
    });
    fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('God Admin Panel')),
      body: Column(
        children: [
          Text('Select a user to grant Super Admin:'),
          DropdownButton<String>(
            value: selectedUser,
            items: users
                .where((u) => u['role'] != 'super_admin' && u['role'] != 'god_admin')
                .map<DropdownMenuItem<String>>((user) => DropdownMenuItem<String>(
                      value: user['username'],
                      child: Text(user['username']),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedUser = value;
              });
            },
          ),
          ElevatedButton(
            onPressed: selectedUser == null
                ? null
                : () => grantSuperAdmin(selectedUser!),
            child: Text('Grant Super Admin'),
          ),
          if (message != null) Text(message!),
        ],
      ),
    );
  }
}

