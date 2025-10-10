import 'package:flutter/material.dart';
import 'login_screen.dart';

class RegistrationSuccessSplash extends StatefulWidget {
  const RegistrationSuccessSplash({super.key});

  @override
  State<RegistrationSuccessSplash> createState() => _RegistrationSuccessSplashState();
}

class _RegistrationSuccessSplashState extends State<RegistrationSuccessSplash> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 24),
            const Text(
              'Registration Success!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

