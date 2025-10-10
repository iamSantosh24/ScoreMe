import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'registration_success_splash.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _register() async {
    setState(() { _isLoading = true; _errorMessage = null; _successMessage = null; });
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final contactNumber = _contactNumberController.text.trim();
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.134:3000/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
          'firstName': firstName,
          'lastName': lastName,
          'contactNumber': contactNumber.isNotEmpty ? contactNumber : null,
        }),
      );
      setState(() { _isLoading = false; });
      if (response.statusCode == 201) {
        setState(() { _successMessage = 'Registration successful!'; });
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegistrationSuccessSplash()));
      } else {
        setState(() { _errorMessage = json.decode(response.body)['error'] ?? 'Registration failed'; });
      }
    } catch (e) {
      setState(() { _isLoading = false; _errorMessage = 'Registration failed. Please try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contactNumberController,
                decoration: const InputDecoration(labelText: 'Contact Number (optional)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Register'),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
              if (_successMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(_successMessage!, style: const TextStyle(color: Colors.green)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
