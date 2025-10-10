import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterViewModel extends ChangeNotifier {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  Future<bool> register() async {
    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    final contactNumber = contactNumberController.text.trim();
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
      isLoading = false;
      if (response.statusCode == 201) {
        successMessage = 'Registration successful!';
        notifyListeners();
        return true;
      } else {
        errorMessage = json.decode(response.body)['error'] ?? 'Registration failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      isLoading = false;
      errorMessage = 'Registration failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    contactNumberController.dispose();
    super.dispose();
  }
}

