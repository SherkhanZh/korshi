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
            labels: [
              l.filterAll,
              loc('Объявления', 'Хабарландырулар'),
              loc('Заявки', 'Өтініштер'),
            ],
            selected: _filter,
            onSelected: (i) => setState(() => _filter = i),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AsyncView<UpdatesData>(
              create: () => repository.updates(),
              refresh: dataVersion,
              builder: (context, d) {
                final items = _filter == 1
                    ? d.announcements
                    : _filter == 2
                        ? d.reports
                        : d.latest;
                final showPinned = d.hasPinned && _filter != 2;
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    dataVersion.value++;
                    await Future<void>.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    if (showPinned) ...[
                      _pinnedCard(context, l, d),
                      const SizedBox(height: 20),
                    ],
                    Text(
                      _filter == 2 ? loc('Мои заявки', 'Менің өтініштерім') : l.latestUpdates,
                      style: AppTheme.cardTitle,
                    ),
                    const SizedBox(height: 12),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(loc('Здесь пока пусто', 'Әзірге бос'),
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, UpdateItem item) {
    // Resident reports open the full report detail (real author + status history).
    if (item.isReport && item.reportId.isNotEmpty) {
      showReportSheetById(context, item.reportId);
      return;
    }
    // Count an announcement view when the resident actually opens it.
    if (item.id.isNotEmpty) {
      repository.markAnnouncementSeen(item.id).then((_) => dataVersion.value++);
    }
    showUpdateSheet(
      context,
      title: loc(item.title, item.titleKk),
      date: item.subtitle ?? '',
      body: loc(item.body ?? item.subtitle ?? '', item.bodyKk),
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
                          child: Text(loc(d.pinnedTitle, d.pinnedTitleKk),
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
                    Text(loc(d.pinnedBody, d.pinnedBodyKk), style: AppTheme.body),
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
                onPressed: () {
                  if (d.pinnedId.isNotEmpty) {
                    repository.markAnnouncementSeen(d.pinnedId).then((_) => dataVersion.value++);
                  }
                  showUpdateSheet(
                    context,
                    title: loc(d.pinnedTitle, d.pinnedTitleKk),
                    date: d.pinnedDate,
                    body: loc(d.pinnedBody, d.pinnedBodyKk),
                    category: IssueCategory.water,
                    status: AppStatus.upcoming,
                  );
                },
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
                      child: Text(loc(item.title, item.titleKk),
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
                  Text(loc(item.body!, item.bodyKk), style: AppTheme.body),
                ],
                if (!item.isReport) ...[
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
