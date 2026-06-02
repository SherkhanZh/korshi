import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class _Notif {
  const _Notif(this.icon, this.color, this.title, this.body, this.time, this.unread);
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String time;
  final bool unread;
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _items = [
    _Notif(Icons.warning_amber_rounded, AppColors.rejectedText, 'Обслуживание воды в субботу',
        'Водоснабжение приостановят с 09:00 до 13:00.', '2 ч назад', true),
    _Notif(Icons.build_rounded, AppColors.lights, 'Обновление по заявке',
        'Электрик назначен по вашей заявке «Не работает фонарь».', '5 ч назад', true),
    _Notif(Icons.bar_chart_rounded, AppColors.safety, 'Новый опрос',
        'Установить дополнительные фонари на улице Мереке?', 'вчера', false),
    _Notif(Icons.check_circle_rounded, AppColors.primary, 'Заявка решена',
        'Утечка воды у парка устранена. Спасибо!', '2 дня назад', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text('Уведомления', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final n = _items[i];
          return AppCard(
            color: n.unread ? AppColors.surfaceGreenTint : AppColors.surface,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconChip(icon: n.icon, color: n.color, size: 44, bgOpacity: 0.16),
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
                          if (n.unread)
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
                      Text(n.time, style: AppTheme.subtle.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
