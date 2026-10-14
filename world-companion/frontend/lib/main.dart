
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/app_shell.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
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

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<_StartupState> _startupFuture;
  bool _onboardingFinished = false;

  @override
  void initState() {
    super.initState();
    _startupFuture = _loadStartupState();
  }

  Future<_StartupState> _loadStartupState() async {
    // Verify an existing session before deciding which screen to show.
    final isAuthenticated = await AuthService.verifyToken();

    // Only show onboarding to signed-out users who have not completed it.
    final preferences = await SharedPreferences.getInstance();
    final onboardingCompleted =
        preferences.getBool('onboarding_completed') ?? false;

    return _StartupState(
      isAuthenticated: isAuthenticated,
      onboardingCompleted: onboardingCompleted,
    );
  }

  void _retryStartup() {
    setState(() {
      _onboardingFinished = false;
      _startupFuture = _loadStartupState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StartupState>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _WorldCompanionSplash();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _StartupErrorScreen(onRetry: _retryStartup);
        }

        final startup = snapshot.data!;

        // Preserve the existing signed-in experience.
        if (startup.isAuthenticated) {
          return const AppShell();
        }

        // Show onboarding only once, for a first-time signed-out user.
        if (!startup.onboardingCompleted && !_onboardingFinished) {
          return OnboardingScreen(
            onFinished: () {
              if (!mounted) return;

              setState(() {
                _onboardingFinished = true;
              });
            },
          );
        }

        // Keep the existing login, registration, and Google sign-in screen.
        return const AuthScreen();
      },
    );
  }
}

class _StartupState {
  final bool isAuthenticated;
  final bool onboardingCompleted;

  const _StartupState({
    required this.isAuthenticated,
    required this.onboardingCompleted,
  });
}

class _WorldCompanionSplash extends StatelessWidget {
  const _WorldCompanionSplash();

  static const Color navy = Color(0xFF0B2545);
  static const Color ivory = Color(0xFFEEF4ED);
  static const Color softBlue = Color(0xFF8DA9C4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/world_companion_mark.png',
                width: 76,
                height: 76,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.explore_rounded,
                  size: 72,
                  color: ivory,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'WorldCompanion',
                style: TextStyle(
                  color: ivory,
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'THE WORLD, MORE CONNECTED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: softBlue,
                  fontSize: 10,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 34),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ivory,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const _StartupErrorScreen({
    required this.onRetry,
  });

  static const Color navy = Color(0xFF0B2545);
  static const Color ivory = Color(0xFFEEF4ED);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 48,
                    color: Color(0xFFE5C28A),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Unable to connect',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ivory,
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'WorldCompanion could not verify your session. '
                    'Check your connection and make sure the backend '
                    'is running, then try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFD8E1E9),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: onRetry,
                      style: FilledButton.styleFrom(
                        backgroundColor: ivory,
                        foregroundColor: navy,
                      ),
                      child: const Text('Try again'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
