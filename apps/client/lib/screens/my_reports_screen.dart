import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/common.dart';
import '../widgets/detail_sheet.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  ),
                ],
              ),
            ),
            ScreenHeader(title: l.myReportsTitle, subtitle: l.myReportsSubtitle),
            const SizedBox(height: 4),
            FilterChips(
              labels: [l.filterAll, l.filterInProgress, l.filterResolved],
              selected: _filter,
              onSelected: (i) => setState(() => _filter = i),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AsyncView<List<ReportItem>>(
                create: () => repository.reports(),
                refresh: dataVersion,
                builder: (context, reports) {
                  final items = reports.where((r) {
                    switch (_filter) {
                      case 1: // In progress
                        return r.status == AppStatus.inProgress ||
                            r.status == AppStatus.waitingResponse;
                      case 2: // Resolved
                        return r.status == AppStatus.resolved;
                      default:
                        return true;
                    }
                  }).toList();
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      for (final r in items) ...[
                        _reportCard(context, l, r),
                        const SizedBox(height: 16),
                      ],
                      _noReportsBanner(context, l),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportCard(BuildContext context, AppLocalizations l, ReportItem r) {
    return AppCard(
      onTap: () => showReportSheet(context, r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: r.category.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(r.category.icon, color: r.category.color, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconChip(
                          icon: r.category.icon,
                          color: r.category.color,
                          size: 30,
                          iconSize: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(r.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.cardTitle.copyWith(fontSize: 16)),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: r.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(r.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.subtle),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(r.dateTime,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.subtle),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StatusTimeline(steps: r.steps),
          const SizedBox(height: 14),
          _chairmanNote(l, r),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(r.updatedLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.subtle),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.viewDetails, style: AppTheme.seeAll),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.primary, size: 18),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chairmanNote(AppLocalizations l, ReportItem r) {
    final Color bg;
    switch (r.status) {
      case AppStatus.waitingResponse:
        bg = const Color(0xFFEFF3FA);
        break;
      case AppStatus.resolved:
        bg = AppColors.surfaceGreenTint;
        break;
      default:
        bg = const Color(0xFFFBF3E6);
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.account_circle_rounded,
              size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.chairmanUpdate,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(r.chairmanNote, style: AppTheme.body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noReportsBanner(BuildContext context, AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceGreenTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_outlined,
              color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.noReportsYet,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                Text(l.noReportsDesc, style: AppTheme.subtle),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(l.reportAnIssue, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

/// Horizontal 3-step status timeline used on report cards and details.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.steps});

  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _node(steps[i]),
          if (i != steps.length - 1) Expanded(child: _connector(i)),
        ],
      ],
    );
  }

  Widget _node(TimelineStep step) {
    final Color color;
    final Widget inner;
    switch (step.state) {
      case TimelineStepState.done:
        color = AppColors.primary;
        inner = const Icon(Icons.check_rounded, color: Colors.white, size: 16);
        break;
      case TimelineStepState.current:
        color = AppColors.lights;
        inner = Icon(step.icon ?? Icons.build_rounded, color: Colors.white, size: 14);
        break;
      case TimelineStepState.pending:
        color = AppColors.border;
        inner = const SizedBox.shrink();
        break;
    }
    return SizedBox(
      width: 76,
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: step.state == TimelineStepState.pending
                  ? AppColors.surface
                  : color,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(child: inner),
          ),
          const SizedBox(height: 6),
          Text(step.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          if (step.date != null)
            Text(step.date!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _connector(int index) {
    final done = steps[index].state == TimelineStepState.done &&
        steps[index + 1].state != TimelineStepState.pending;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Container(
        height: 2,
        color: done ? AppColors.primary : AppColors.border,
      ),
    );
  }
}
