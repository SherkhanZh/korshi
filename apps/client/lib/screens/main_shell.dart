import 'package:flutter/material.dart';

import '../app_state.dart';
import '../widgets/bottom_nav.dart';
import 'home_screen.dart';
import 'updates_screen.dart';
import 'polls_screen.dart';
import 'contacts_screen.dart';
import 'report_screen.dart';

/// Root scaffold holding the four primary tabs + the central Report action.
/// The selected tab is driven by the shared [shellTab] notifier so any screen
/// can jump to another tab.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _stackOrder = [0, 1, 3, 4];

  void _openReport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReportScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: shellTab,
      builder: (context, index, _) {
        final stackIndex = _stackOrder.indexOf(index).clamp(0, 3);
        return Scaffold(
          body: IndexedStack(
            index: stackIndex,
            children: const [
              HomeScreen(),
              UpdatesScreen(),
              PollsScreen(),
              ContactsScreen(),
            ],
          ),
          bottomNavigationBar: AppBottomNav(
            currentIndex: index,
            onTap: (i) => shellTab.value = i,
            onReport: () => _openReport(context),
          ),
        );
      },
    );
  }
}
