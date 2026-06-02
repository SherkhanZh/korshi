import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/launchers.dart';
import '../services/repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/common.dart';
import '../widgets/detail_sheet.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(title: l.updatesTitle, subtitle: l.updatesSubtitle),
          const SizedBox(height: 4),
          FilterChips(
            labels: [l.filterAll, l.filterImportant, l.filterUpdates, l.filterEvents],
            selected: _filter,
            onSelected: (i) => setState(() => _filter = i),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AsyncView<UpdatesData>(
              create: () => repository.updates(),
              refresh: dataVersion,
              builder: (context, d) {
                final items = _applyFilter(d.latest);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    if (_filter == 0 || _filter == 1) ...[
                      _pinnedCard(context, l, d),
                      const SizedBox(height: 20),
                    ],
                    Text(l.latestUpdates, style: AppTheme.cardTitle),
                    const SizedBox(height: 12),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text('Здесь пока пусто',
                              style: AppTheme.subtle),
                        ),
                      ),
                    for (final item in items) ...[
                      _updateCard(context, l, item),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 4),
                    _partnerCard(context, l),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<UpdateItem> _applyFilter(List<UpdateItem> items) {
    switch (_filter) {
      case 1: // Important
        return items.where((i) => i.status == AppStatus.upcoming).toList();
      case 2: // Updates
        return items
            .where((i) =>
                i.status == AppStatus.update || i.status == AppStatus.resolved)
            .toList();
      case 3: // Events
        return items.where((i) => i.status == AppStatus.event).toList();
      default:
        return items;
    }
  }

  void _openDetail(BuildContext context, UpdateItem item) {
    showUpdateSheet(
      context,
      title: item.title,
      date: item.subtitle ?? '',
      body: item.body ?? item.subtitle ?? '',
      category: item.category,
      status: item.status,
    );
  }

  Widget _pinnedCard(BuildContext context, AppLocalizations l, UpdatesData d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBEFE9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF3DDD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.push_pin_rounded,
                  color: AppColors.rejectedText, size: 16),
              const SizedBox(width: 6),
              Text(l.pinned,
                  style: const TextStyle(
                      color: AppColors.rejectedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const IconChip(
                          icon: Icons.warning_amber_rounded,
                          color: AppColors.rejectedText,
                          size: 40,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(d.pinnedTitle,
                              style: AppTheme.sectionTitle.copyWith(fontSize: 20)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(d.pinnedDate,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.subtle),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(d.pinnedBody, style: AppTheme.body),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: AppColors.water.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_shipping_rounded,
                    color: AppColors.water, size: 30),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              FilledButton(
                onPressed: () => showUpdateSheet(
                  context,
                  title: d.pinnedTitle,
                  date: d.pinnedDate,
                  body: d.pinnedBody,
                  category: IssueCategory.water,
                  status: AppStatus.upcoming,
                ),
                style: FilledButton.styleFrom(minimumSize: const Size(130, 44)),
                child: Text(l.viewDetails),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  l.t('seenByResidents').replaceFirst('{n}', '${d.pinnedSeenBy}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.subtle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _updateCard(BuildContext context, AppLocalizations l, UpdateItem item) {
    return AppCard(
      onTap: () => _openDetail(context, item),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconChip(
            icon: item.category.icon,
            color: item.status == AppStatus.update
                ? AppColors.safety
                : item.status == AppStatus.upcoming
                    ? AppColors.lights
                    : item.status == AppStatus.event
                        ? AppColors.primary
                        : item.category.color,
            size: 46,
            bgOpacity: 0.16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(item.title,
                          style: AppTheme.cardTitle.copyWith(fontSize: 15)),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: item.status),
                  ],
                ),
                const SizedBox(height: 2),
                if (item.subtitle != null)
                  Text(item.subtitle!,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.subtle),
                if (item.body != null) ...[
                  const SizedBox(height: 6),
                  Text(item.body!, style: AppTheme.body),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        l.t('seenBy').replaceFirst('{n}', '${item.seenBy ?? 0}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.subtle,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.thumb_up_alt_outlined,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(l.helpful,
                            style: AppTheme.subtle.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _partnerCard(BuildContext context, AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const IconChip(icon: Icons.fence_rounded, color: AppColors.primary, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Pill(
                  text: l.partner.toUpperCase(),
                  bg: AppColors.partnerBadge,
                  fg: Colors.white,
                  fontSize: 10,
                ),
                const SizedBox(height: 6),
                Text(l.fenceRepairService, style: AppTheme.cardTitle),
                Text(l.recommendedForResidents, style: AppTheme.subtle),
                const SizedBox(height: 6),
                const RatingLine(),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => callNumber(context, '+7 701 000 00 10'),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.call_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
