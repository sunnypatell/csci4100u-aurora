import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'journal_screen.dart';
import 'resources.dart';
import 'settings_screen.dart';

/// AuroraShell
/// Provides a persistent bottom navigation bar to switch between
/// primary application areas. Uses an IndexedStack to preserve state of
/// each tab (e.g. scroll position or in-progress form input).
class AuroraShell extends StatefulWidget {
  const AuroraShell({super.key});

  @override
  State<AuroraShell> createState() => _AuroraShellState();
}

class _AuroraShellState extends State<AuroraShell> {
  int _index = 0;

  final _pages = const [
    DashboardScreen(),
    JournalScreen(),
    ResourcesPage(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Outer scaffold only provides nav bar; inner pages manage their own AppBars.
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books_rounded),
            label: 'Resources',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
