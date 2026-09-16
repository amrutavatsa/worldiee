import 'package:flutter/material.dart';
import 'screens/app_shell.dart';
import 'screens/auth_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const WorldCompanionApp());
}

class WorldCompanionApp extends StatelessWidget {
  const WorldCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0E7774);
    const accent = Color(0xFFF27C4A);
    const background = Color(0xFFF7F9F8);
    const surface = Color(0xFFFFFFFF);
    const ink = Color(0xFF172326);
    const muted = Color(0xFF68777B);
    const line = Color(0xFFDCE5E4);

    final colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      secondary: accent,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: ink,
      error: const Color(0xFFC94B4B),
      onError: Colors.white,
      outline: line,
    );

    final textTheme = const TextTheme(
      displayLarge: TextStyle(
        fontSize: 30,
        height: 34 / 30,
        fontWeight: FontWeight.bold,
        color: ink,
      ),
      headlineLarge: TextStyle(
        fontSize: 24,
        height: 29 / 24,
        fontWeight: FontWeight.bold,
        color: ink,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        height: 23 / 18,
        fontWeight: FontWeight.bold,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        height: 20 / 15,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyLarge: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        color: ink,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        color: muted,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 17 / 12,
        color: muted,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        height: 18 / 14,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      labelMedium: TextStyle(
        fontSize: 11,
        height: 14 / 11,
        fontWeight: FontWeight.w600,
        color: muted,
      ),
    );

    return MaterialApp(
      title: 'World Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: background,
        textTheme: textTheme,

        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: ink,
          elevation: 0,
          centerTitle: false,
        ),

        cardTheme: CardTheme(
          color: surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(
              color: line,
              width: 0.5,
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: line,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: line,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: primary,
              width: 1.5,
            ),
          ),
          hintStyle: const TextStyle(
            color: muted,
            fontSize: 14,
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            minimumSize: const Size.fromHeight(48),
            side: const BorderSide(
              color: line,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: surface,
          selectedColor: primary,
          disabledColor: background,
          side: const BorderSide(
            color: line,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: muted,
          ),
          secondaryLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),

        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surface,
          elevation: 0,
          height: 76,
          indicatorColor: const Color(0xFFDFF4F1),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: primary,
                );
              }

              return const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: muted,
              );
            },
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(
                  color: primary,
                  size: 24,
                );
              }

              return const IconThemeData(
                color: muted,
                size: 23,
              );
            },
          ),
        ),

        dividerTheme: const DividerThemeData(
          color: line,
          thickness: 1,
          space: 1,
        ),
      ),
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