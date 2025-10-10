import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String apiBaseUrl = 'http://192.168.1.134:3000';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  Future<void> _sendResetEmail() async {
    setState(() { _isLoading = true; _message = null; });
    final email = _emailController.text;
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      setState(() { _isLoading = false; });
      if (response.statusCode == 200) {
        setState(() { _message = 'Password reset email sent. Please check your inbox.'; });
      } else {
        setState(() { _message = json.decode(response.body)['error'] ?? 'Failed to send reset email.'; });
      }
    } catch (e) {
      setState(() { _isLoading = false; _message = 'Error sending reset email.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your email to reset your password:'),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendResetEmail,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Send Reset Email'),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(_message!, style: TextStyle(color: _message!.contains('sent') ? Colors.green : Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}

