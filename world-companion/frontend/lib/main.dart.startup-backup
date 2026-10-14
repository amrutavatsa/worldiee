
import 'package:flutter/material.dart';

import 'screens/app_shell.dart';
import 'screens/auth_screen.dart';
import 'services/auth_service.dart';
import 'theme/world_companion_theme.dart';

void main() {
  runApp(const WorldCompanionApp());
}

class WorldCompanionApp extends StatelessWidget {
  const WorldCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'World Companion',
      debugShowCheckedModeBanner: false,
      theme: WorldCompanionTheme.light,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.verifyToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.data == true) {
          return const AppShell();
        }

        return const AuthScreen();
      },
    );
  }
}
