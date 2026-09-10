import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const WorldCompanionApp());
}

class WorldCompanionApp extends StatelessWidget {
  const WorldCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'World Companion',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
