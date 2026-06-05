import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'async_view.dart';
import 'common.dart';

/// Opens the detail sheet for a submitted report (My reports), loading the full
/// detail (author, history, chairman updates) by id.
void showReportSheet(BuildContext context, ReportItem report) {
  _show(
    context,
    AsyncView<ReportDetail>(
      create: () => repository.reportDetail(report.id),
      builder: (context, d) {
        final history = d.detailSteps.isNotEmpty ? d.detailSteps : report.steps;
        return _DetailBody(
          category: report.category,
          status: report.status,
          title: report.title,
          date: report.dateTime,
          author: report.author.isEmpty ? '—' : report.author,
          body: d.description.isEmpty ? report.chairmanNote : d.description,
          history: history,
          updates: d.chairmanUpdates,
        );
      },
    ),
  );
}

/// Opens the report detail sheet by id (used when a report appears in a feed),
/// loading the full author + status history + chairman updates.
void showReportSheetById(BuildContext context, String id) {
  _show(
    context,
    AsyncView<ReportDetail>(
      create: () => repository.reportDetail(id),
      builder: (context, d) => _DetailBody(
        category: d.report.category,
        status: d.report.status,
        title: d.report.title,
        date: d.report.dateTime,
        author: d.report.author.isEmpty ? '—' : d.report.author,
        body: d.description.isEmpty ? d.report.chairmanNote : d.description,
        history: d.detailSteps.isNotEmpty ? d.detailSteps : d.report.steps,
        updates: d.chairmanUpdates,
      ),
    ),
  );
}

/// Opens the detail sheet for a feed item (Today / Updates).
void showUpdateSheet(
  BuildContext context, {
  required String title,
  required String date,
  required String body,
  required IssueCategory category,
  required AppStatus status,
  String? author,
}) {
  // Hardcoded history for feed items (no per-item timeline from the API yet).
  final history = <TimelineStep>[
    TimelineStep(label: 'Опубликовано', date: date, state: TimelineStepState.done),
    if (status == AppStatus.resolved)
      const TimelineStep(label: 'Решено', date: null, state: TimelineStepState.done)
    else
      const TimelineStep(label: 'Актуально', date: null, state: TimelineStepState.current),
  ];
  _show(
    context,
    _DetailBody(
      category: category,
      status: status,
      title: title,
      date: date,
      author: author ?? 'Администрация района',
      body: body,
      history: history,
      updates: const [],
    ),
  );
}

void _show(BuildContext context, Widget child) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
        child: PrimaryScrollController(
          controller: controller,
          child: child,
        ),
      ),
    ),
  );
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.category,
    required this.status,
    required this.title,
    required this.date,
    required this.author,
    required this.body,
    required this.history,
    required this.updates,
  });

  final IssueCategory category;
  final AppStatus status;
  final String title;
  final String date;
  final String author;
  final String body;
  final List<TimelineStep> history;
  final List<ChairmanUpdate> updates;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      controller: PrimaryScrollController.of(context),
      padding: EdgeInsets.zero,
      children: [
        // Status-colored header.
        Container(
          width: double.infinity,
          color: status.bg,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: status.fg.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  IconChip(icon: category.icon, color: status.fg, size: 44, bgOpacity: 0.18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.t(category.labelKey),
                            style: TextStyle(
                                color: status.fg,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        Text(l.t(status.labelKey),
                            style: TextStyle(
                                color: status.fg,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: status.fg),
                  const SizedBox(width: 6),
                  Text(date, style: TextStyle(color: status.fg, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author
              AppCard(
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.surfaceGreenTint,
                      child: Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Автор',
                            style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                        Text(author,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                      ],
                    ),
                  ],
                ),
              ),
              if (body.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Описание', style: AppTheme.cardTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 8),
                AppCard(child: Text(body, style: AppTheme.body.copyWith(height: 1.5))),
              ],
              const SizedBox(height: 16),
              Text('История статусов', style: AppTheme.cardTitle.copyWith(fontSize: 16)),
              const SizedBox(height: 10),
              AppCard(child: _History(history: history)),
              if (updates.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Сообщения председателя',
                    style: AppTheme.cardTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 10),
                for (final u in updates) ...[
                  AppCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 52,
                          child: Text(u.date,
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ),
                        Expanded(child: Text(u.body, style: AppTheme.body)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.history});
  final List<TimelineStep> history;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < history.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    _dot(history[i].state),
                    if (i != history.length - 1)
                      Expanded(child: Container(width: 2, color: AppColors.border)),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: i == history.length - 1 ? 0 : 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(history[i].label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        if (history[i].date != null)
                          Text(history[i].date!,
                              style: const TextStyle(
                                  color: AppColors.textTertiary, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _dot(TimelineStepState state) {
    switch (state) {
      case TimelineStepState.done:
        return const CircleAvatar(
          radius: 9,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.check_rounded, color: Colors.white, size: 12),
        );
      case TimelineStepState.current:
        return const CircleAvatar(radius: 9, backgroundColor: AppColors.lights);
      case TimelineStepState.pending:
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 2),
          ),
        );
    }
  }
}
