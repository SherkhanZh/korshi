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

class RequestDetailsScreen extends StatelessWidget {
  const RequestDetailsScreen({super.key, required this.report});

  final ReportItem report;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _appBar(context, l),
            Expanded(
              child: AsyncView<ReportDetail>(
                create: () => repository.reportDetail(report.id),
                builder: (context, d) => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _hero(l),
                    const SizedBox(height: 16),
                    if (d.detailSteps.isNotEmpty) ...[
                      _statusProgress(context, l, d.detailSteps),
                      const SizedBox(height: 16),
                    ],
                    if (d.chairmanUpdates.isNotEmpty) ...[
                      _chairmanUpdates(l, d.chairmanUpdates),
                      const SizedBox(height: 16),
                    ],
                    _originalReport(l, d.description),
                    const SizedBox(height: 16),
                    _needHelp(context, l),
                    const SizedBox(height: 16),
                    _expectedCompletion(l),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appBar(BuildContext context, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
            ),
          ),
          Text(l.requestDetails,
              style: AppTheme.displayTitle.copyWith(fontSize: 22)),
        ],
      ),
    );
  }

  Widget _hero(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF1EA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 90,
            height: 110,
            decoration: BoxDecoration(
              color: report.category.color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(report.category.icon,
                color: report.category.color, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(report.category.icon,
                        color: report.category.color, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(l.t(report.category.labelKey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(report.title,
                    style: AppTheme.sectionTitle.copyWith(fontSize: 21)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(report.location,
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
                      child: Text(report.dateTime,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.subtle),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: report.status.fg),
                    const SizedBox(width: 6),
                    Text(l.t(report.status.labelKey),
                        style: TextStyle(
                            color: report.status.fg,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusProgress(
      BuildContext context, AppLocalizations l, List<TimelineStep> steps) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.statusProgress, style: AppTheme.cardTitle.copyWith(fontSize: 17)),
          const SizedBox(height: 16),
          _FourStepTimeline(steps: steps),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceGreenTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l.inProgressKeepUpdated, style: AppTheme.body),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chairmanUpdates(AppLocalizations l, List<ChairmanUpdate> updates) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.chairmanUpdates,
              style: AppTheme.cardTitle.copyWith(fontSize: 17)),
          const SizedBox(height: 14),
          for (int i = 0; i < updates.length; i++)
            _updateRow(updates[i],
                isLast: i == updates.length - 1,
                current: i == updates.length - 1),
        ],
      ),
    );
  }

  Widget _updateRow(ChairmanUpdate u, {required bool isLast, required bool current}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(u.date,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: current ? AppColors.lights : AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: AppColors.border)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_circle_rounded,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text('Сообщение председателя',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(u.body, style: AppTheme.body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _originalReport(AppLocalizations l, String description) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.originalReport, style: AppTheme.cardTitle.copyWith(fontSize: 17)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _labelRow(Icons.chat_bubble_outline_rounded, l.descriptionLabel),
                    const SizedBox(height: 4),
                    Text(description, style: AppTheme.body),
                    const SizedBox(height: 12),
                    _labelRow(Icons.location_on_outlined, l.locationLabel),
                    const SizedBox(height: 4),
                    Text(report.location, style: AppTheme.body),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.photosLabel,
                      style: AppTheme.subtle.copyWith(
                          color: AppColors.primary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _photoBox(),
                      const SizedBox(width: 8),
                      _photoBox(),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _labelRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ),
      ],
    );
  }

  Widget _photoBox() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: report.category.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(report.category.icon, color: report.category.color, size: 22),
    );
  }

  Widget _needHelp(BuildContext context, AppLocalizations l) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.needHelp, style: AppTheme.cardTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(l.needHelpDesc, style: AppTheme.subtle),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () => openWhatsApp(context, kChairmanPhone),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            icon: const Icon(Icons.chat_rounded, size: 18),
            label: Text(l.contactChairman, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _expectedCompletion(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceGreenTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.expectedCompletion,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                Text(l.expectedCompletionDesc, style: AppTheme.subtle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Four-step horizontal timeline for the request details progress section.
class _FourStepTimeline extends StatelessWidget {
  const _FourStepTimeline({required this.steps});

  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          Expanded(child: _node(steps[i])),
          if (i != steps.length - 1)
            SizedBox(
              width: 20,
              child: Padding(
                padding: const EdgeInsets.only(top: 13),
                child: Container(
                  height: 2,
                  color: steps[i].state == TimelineStepState.done &&
                          steps[i + 1].state != TimelineStepState.pending
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
            ),
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
        inner = const Icon(Icons.check_rounded, color: Colors.white, size: 15);
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
    return Column(
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
    );
  }
}
