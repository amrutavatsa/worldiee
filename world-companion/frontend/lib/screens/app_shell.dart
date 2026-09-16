import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'explore_screens.dart';
import 'trip_screen.dart';
import 'stays_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const Color primary = Color(0xFF0E7774);
  static const Color deep = Color(0xFF123B43);
  static const Color aqua = Color(0xFFDFF4F1);
  static const Color surface = Color(0xFFFFFFFF);

  final List<Widget> _screens = const [
    HomeScreen(),
    ExploreScreen(),
    TripsScreen(),
    StaysScreen(),
    ProfileScreen(),
  ];

  void _onDestinationSelected(int index) {
    if (index == _selectedIndex) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        backgroundColor: surface,
        elevation: 0,
        height: 72,
        indicatorColor: aqua,
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
              color: deep,
            ),
            selectedIcon: Icon(
              Icons.home_rounded,
              color: primary,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.explore_outlined,
              color: deep,
            ),
            selectedIcon: Icon(
              Icons.explore_rounded,
              color: primary,
            ),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.map_outlined,
              color: deep,
            ),
            selectedIcon: Icon(
              Icons.map_rounded,
              color: primary,
            ),
            label: 'Trips',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.hotel_outlined,
              color: deep,
            ),
            selectedIcon: Icon(
              Icons.hotel_rounded,
              color: primary,
            ),
            label: 'Stay',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline_rounded,
              color: deep,
            ),
            selectedIcon: Icon(
              Icons.person_rounded,
              color: primary,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}