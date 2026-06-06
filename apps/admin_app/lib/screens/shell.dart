import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import 'announcements.dart';
import 'dashboard.dart';
import 'polls.dart';
import 'reports.dart';
import 'residents.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _tab = 0;

  static const _pages = [
    DashboardScreen(),
    ReportsScreen(),
    AnnouncementsScreen(),
    PollsScreen(),
    ResidentsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Lets a push-notification tap jump to a tab.
    selectedTab.addListener(_onTabSignal);
  }

  @override
  void dispose() {
    selectedTab.removeListener(_onTabSignal);
    super.dispose();
  }

  void _onTabSignal() {
    if (mounted) setState(() => _tab = selectedTab.value);
  }

  @override
  Widget build(BuildContext context) {
    // The chairman app is for neighborhood admins; super admins use the web panel.
    if (adminRole.value == 'super') {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings_rounded, size: 48, color: C.ink3),
                const SizedBox(height: 12),
                const Text('Это приложение для председателей района.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text('Супер-админ управляет районами в веб-панели.',
                    textAlign: TextAlign.center, style: TextStyle(color: C.ink2)),
                const SizedBox(height: 20),
                FilledButton(onPressed: clearSession, child: const Text('Выйти')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _tab, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          selectedTab.value = i; // keep the push signal in sync
          setState(() => _tab = i);
        },
        backgroundColor: C.surface,
        indicatorColor: C.greenTint,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Обзор'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment_rounded), label: 'Заявки'),
          NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign_rounded), label: 'Объявл.'),
          NavigationDestination(icon: Icon(Icons.how_to_vote_outlined), selectedIcon: Icon(Icons.how_to_vote_rounded), label: 'Опросы'),
          NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: 'Жители'),
        ],
      ),
    );
  }
}
