import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import 'contacts.dart';
import 'dashboard.dart';
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
    ResidentsScreen(),
    ContactsScreen(),
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
                Text(loc('Это приложение для председателей района.', 'Бұл қосымша аудан төрағаларына арналған.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(loc('Супер-админ управляет районами в веб-панели.', 'Супер-әкімші аудандарды веб-панельде басқарады.'),
                    textAlign: TextAlign.center, style: const TextStyle(color: C.ink2)),
                const SizedBox(height: 20),
                FilledButton(onPressed: clearSession, child: Text(loc('Выйти', 'Шығу'))),
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
        destinations: [
          NavigationDestination(icon: const Icon(Icons.dashboard_outlined), selectedIcon: const Icon(Icons.dashboard_rounded), label: loc('Обзор', 'Шолу')),
          NavigationDestination(icon: const Icon(Icons.people_outline_rounded), selectedIcon: const Icon(Icons.people_rounded), label: loc('Жители', 'Тұрғындар')),
          NavigationDestination(icon: const Icon(Icons.contacts_outlined), selectedIcon: const Icon(Icons.contacts_rounded), label: loc('Контакты', 'Контактілер')),
        ],
      ),
    );
  }
}
