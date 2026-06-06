import 'package:flutter/material.dart';

import '../app_state.dart';
import '../services/repository.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/detail_sheet.dart';
import 'home_screen.dart';
import 'updates_screen.dart';
import 'polls_screen.dart';
import 'contacts_screen.dart';
import 'report_screen.dart';

/// Root scaffold holding the four primary tabs + the central Report action.
/// The selected tab is driven by the shared [shellTab] notifier so any screen
/// can jump to another tab.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _stackOrder = [0, 1, 3, 4];

  @override
  void initState() {
    super.initState();
    pendingNav.addListener(_handlePending);
    dataVersion.addListener(_refreshUnread);
    // Process a cold-start deep link + load the unread badge after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUnread();
      _handlePending();
    });
  }

  @override
  void dispose() {
    pendingNav.removeListener(_handlePending);
    dataVersion.removeListener(_refreshUnread);
    super.dispose();
  }

  void _refreshUnread() {
    repository.refreshUnread();
  }

  void _handlePending() {
    final target = pendingNav.value;
    if (target == null) return;
    pendingNav.value = null; // consume
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (target.type == 'report') {
        showReportSheetById(context, target.id);
      } else if (target.type == 'announcement') {
        try {
          final item = await repository.announcementItem(target.id);
          repository.markAnnouncementSeen(item.id).then((_) => dataVersion.value++);
          if (!mounted) return;
          showUpdateSheet(
            context,
            title: loc(item.title, item.titleKk),
            date: item.subtitle ?? '',
            body: loc(item.body ?? item.subtitle ?? '', item.bodyKk),
            category: item.category,
            status: item.status,
          );
        } catch (_) {
          // If it can't be loaded, the Updates tab (already selected) still shows it.
        }
      }
      // poll → the Polls tab is already selected; the active poll is shown there.
    });
  }

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
