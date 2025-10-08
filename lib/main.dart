import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/NotificationsViewModel.dart';
import 'login_screen.dart';

void main() => runApp(
  ChangeNotifierProvider(
    create: (_) => NotificationsViewModel(),
    child: const MyApp(),
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cricket Scoreboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LoginScreen(),
    );
  }
}
