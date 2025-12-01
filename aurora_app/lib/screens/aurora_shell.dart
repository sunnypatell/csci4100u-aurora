import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'journal_screen.dart';
import 'resources.dart';
import 'help_near_me.dart';
import 'ai_chat.dart';
import 'settings_screen.dart';

/// AuroraShell
/// Provides a persistent bottom navigation bar to switch between
/// primary application areas. Uses an IndexedStack to preserve state of
/// each tab (e.g. scroll position or in-progress form input).
class AuroraShell extends StatefulWidget {
  const AuroraShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AuroraShell> createState() => _AuroraShellState();
}

class _AuroraShellState extends State<AuroraShell> {
  late int _index;

  final _pages = const [
    DashboardScreen(),
    JournalScreen(),
    ResourcesPage(),
    HelpNearMePage(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Outer scaffold only provides nav bar; inner pages manage their own AppBars.
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          // Destination indices: 0=Home,1=Journal,2=Resources,3=HelpNearby,4=Chat,5=Settings
          // Our internal pages omit Chat, so map taps to pages and handle Chat as a standalone route.
          if (i == 4) {
            // Open Chat as a standalone screen (outside the shell) so the navbar there omits Chat.
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiChatScreen()));
            return;
          }

          final pageIndex = i < 4 ? i : i - 1; // shift indices after Chat
          setState(() => _index = pageIndex);
        },
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
            icon: Icon(Icons.place_outlined),
            selectedIcon: Icon(Icons.place_rounded),
            label: 'Help Nearby',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_alt_outlined),
            selectedIcon: Icon(Icons.psychology_alt_rounded),
            label: 'Chat',
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
