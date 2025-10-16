import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../shared_utils.dart';
import '../login_screen.dart';
import 'package:scorer/config.dart';

class ProfileViewModel extends ChangeNotifier {
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

  Future<bool> validateOldPassword(String oldPassword) async {
    final token = await _secureStorage.read(key: 'auth_token') ?? '';
    final res = await http.post(
      Uri.parse('${Config.apiBaseUrl}/validate-password'),
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
    showOldPasswordField = true;
    passwordError = '';
    notifyListeners();
  }

  void resetPasswordFlow() {
    showOldPasswordField = false;
    showPasswordFields = false;
    passwordError = '';
    oldPassword = '';
    newPassword = '';
    confirmNewPassword = '';
    notifyListeners();
  }

  Future<void> submitOldPassword() async {
    loading = true;
    passwordError = '';
    notifyListeners();
    bool valid = await validateOldPassword(oldPassword);
    loading = false;
    if (valid) {
      showPasswordFields = true;
      showOldPasswordField = false;
      passwordError = '';
    } else {
      passwordError = 'Old password is incorrect.';
    }
    notifyListeners();
  }

  bool get canUpdatePassword {
    return newPassword.isNotEmpty && confirmNewPassword.isNotEmpty;
  }

  Future<void> changePassword(BuildContext context) async {
    loading = true;
    passwordError = '';
    notifyListeners();
    if (newPassword.isEmpty || confirmNewPassword.isEmpty) {
      passwordError = 'Please enter both new password fields.';
      loading = false;
      notifyListeners();
      return;
    }
    if (newPassword != confirmNewPassword) {
      passwordError = 'New passwords do not match.';
      loading = false;
      notifyListeners();
      return;
    }
    if (newPassword == oldPassword) {
      passwordError = 'New password must be different from old password.';
      loading = false;
      notifyListeners();
      return;
    }
    final token = await _secureStorage.read(key: 'auth_token') ?? '';
    final res = await http.post(
      Uri.parse('${Config.apiBaseUrl}/change-password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'newPassword': newPassword}),
    );
    loading = false;
    if (res.statusCode == 200) {
      newPassword = '';
      confirmNewPassword = '';
      showPasswordFields = false;
      showOldPasswordField = false;
      passwordError = '';
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
    } else {
      passwordError = json.decode(res.body)['error'] ?? 'Failed to update password';
      notifyListeners();
    }
  }

  Future<void> deleteAccount(BuildContext context) async {
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
    loading = true;
    deleteError = '';
    notifyListeners();
    final token = await _secureStorage.read(key: 'auth_token') ?? '';
    final res = await http.post(
      Uri.parse('${Config.apiBaseUrl}/delete-account'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    loading = false;
    if (res.statusCode == 200) {
      SharedUser.clear();
      notifyListeners();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      deleteError = json.decode(res.body)['error'] ?? 'Failed to delete account';
      notifyListeners();
    }
  }
}
