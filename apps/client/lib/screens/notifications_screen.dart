import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/models.dart';
import '../services/repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<NotificationsData> _future;

  @override
  void initState() {
    super.initState();
    _future = repository.notifications();
    // Once loaded, clear the unread badge (list still shows unread styling from
    // the data fetched just before marking).
    _future.then((_) {
      repository.markNotificationsRead();
      unreadNotifications.value = 0;
    }).catchError((_) {});
  }

  (IconData, Color) _meta(String type) {
    switch (type) {
      case 'report':
        return (Icons.assignment_rounded, AppColors.lights);
      case 'poll':
        return (Icons.bar_chart_rounded, AppColors.safety);
      default:
        return (Icons.campaign_rounded, AppColors.primary);
    }
  }

  void _open(NotificationItem n) {
    if (n.refId.isEmpty) return;
    Navigator.of(context).maybePop();
    openNotifTarget(n.type, n.refId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: Text(loc('Уведомления', 'Хабарламалар'),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: FutureBuilder<NotificationsData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          final items = snap.data?.items ?? const <NotificationItem>[];
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notifications_none_rounded,
                        size: 44, color: AppColors.textTertiary),
                    const SizedBox(height: 12),
                    Text(loc('Уведомлений пока нет', 'Әзірге хабарламалар жоқ'),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final n = items[i];
              final (icon, color) = _meta(n.type);
              return GestureDetector(
                onTap: () => _open(n),
                child: AppCard(
                  color: n.read ? AppColors.surface : AppColors.surfaceGreenTint,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconChip(icon: icon, color: color, size: 44, bgOpacity: 0.16),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(n.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.cardTitle.copyWith(fontSize: 15)),
                                ),
                                if (!n.read)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                        color: AppColors.primary, shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(n.body, style: AppTheme.body),
                            const SizedBox(height: 6),
                            Text(n.date, style: AppTheme.subtle.copyWith(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
