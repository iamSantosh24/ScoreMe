import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'shared_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String oldPassword = '';
  String newPassword = '';
  String confirmNewPassword = '';
  bool loading = false;
  String passwordError = '';
  String deleteError = '';
  bool showPasswordFields = false;
  bool showOldPasswordField = false;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String get username => SharedUser.email ?? '';
  String get profileId => SharedUser.profileId ?? '';
  String get contactNumber => SharedUser.contactNumber ?? '';

  @override
  void initState() {
    super.initState();
    // Assume SharedUser is already populated elsewhere after login
  }

  Future<bool> validateOldPassword(String oldPassword) async {
    final token = await _secureStorage.read(key: 'auth_token') ?? '';
    print('Validating password with token: $token');
    final res = await http.post(
      Uri.parse('http://192.168.1.134:3000/validate-password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'oldPassword': oldPassword}),
    );
    if (res.statusCode == 200) {
      return json.decode(res.body)['valid'] == true;
    }
    return false;
  }

  void startPasswordChange() {
    setState(() { showOldPasswordField = true; passwordError = ''; });
  }

  void resetPasswordFlow() {
    setState(() {
      showOldPasswordField = false;
      showPasswordFields = false;
      passwordError = '';
      oldPassword = '';
      newPassword = '';
      confirmNewPassword = '';
    });
  }

  Future<void> submitOldPassword() async {
    setState(() { loading = true; passwordError = ''; });
    bool valid = await validateOldPassword(oldPassword);
    setState(() { loading = false; });
    if (valid) {
      setState(() { showPasswordFields = true; showOldPasswordField = false; passwordError = ''; });
    } else {
      setState(() { passwordError = 'Old password is incorrect.'; });
    }
  }

  bool get canUpdatePassword {
    return newPassword.isNotEmpty &&
      confirmNewPassword.isNotEmpty;
  }

  Future<void> changePassword() async {
    setState(() { loading = true; passwordError = ''; });
    if (newPassword.isEmpty || confirmNewPassword.isEmpty) {
      setState(() { passwordError = 'Please enter both new password fields.'; loading = false; });
      return;
    }
    if (newPassword != confirmNewPassword) {
      setState(() { passwordError = 'New passwords do not match.'; loading = false; });
      return;
    }
    if (newPassword == oldPassword) {
      setState(() { passwordError = 'New password must be different from old password.'; loading = false; });
      return;
    }
    final token = await _secureStorage.read(key: 'auth_token') ?? '';
    final res = await http.post(
      Uri.parse('http://192.168.1.134:3000/change-password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'newPassword': newPassword}),
    );
    setState(() { loading = false; });
    if (res.statusCode == 200) {
      setState(() {
        newPassword = '';
        confirmNewPassword = '';
        showPasswordFields = false;
        showOldPasswordField = false;
        passwordError = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
    } else {
      setState(() { passwordError = json.decode(res.body)['error'] ?? 'Failed to update password'; });
    }
  }

  Future<void> deleteAccount() async {
    bool confirmed = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() { loading = true; deleteError = ''; });
    final token = await _secureStorage.read(key: 'auth_token') ?? '';
    final res = await http.post(
      Uri.parse('http://192.168.1.134:3000/delete-account'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    setState(() { loading = false; });
    if (res.statusCode == 200) {
      SharedUser.clear();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      setState(() { deleteError = json.decode(res.body)['error'] ?? 'Failed to delete account'; });
    }
  }

  @override
  void dispose() {
    resetPasswordFlow();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Profile Id: $profileId', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Username: $username', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Contact Number: $contactNumber', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 24),
                  if (!showOldPasswordField && !showPasswordFields)
                    ElevatedButton(
                      onPressed: startPasswordChange,
                      child: const Text('Change Password'),
                    ),
                  if (showOldPasswordField) ...[
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Old Password'),
                      obscureText: true,
                      onChanged: (val) => oldPassword = val,
                    ),
                    ElevatedButton(
                      onPressed: submitOldPassword,
                      child: const Text('Next'),
                    ),
                    if (passwordError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(passwordError, style: const TextStyle(color: Colors.red)),
                      ),
                  ],
                  if (showPasswordFields) ...[
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(labelText: 'New Password'),
                      obscureText: true,
                      onChanged: (val) {
                        setState(() { newPassword = val; });
                      },
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Confirm New Password'),
                      obscureText: true,
                      onChanged: (val) {
                        setState(() { confirmNewPassword = val; });
                      },
                    ),
                    ElevatedButton(
                      onPressed: canUpdatePassword ? changePassword : null,
                      child: const Text('Update Password'),
                    ),
                    if (passwordError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(passwordError, style: const TextStyle(color: Colors.red)),
                      ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: deleteAccount,
                    child: const Text('Delete Account'),
                  ),
                  if (deleteError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(deleteError, style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
    );
  }
}
