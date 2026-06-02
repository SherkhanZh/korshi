import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/common.dart';

class PollsScreen extends StatefulWidget {
  const PollsScreen({super.key});

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen> {
  int _selectedOption = 0; // index of the option the resident voted for

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(title: l.pollsTitle, subtitle: l.pollsSubtitle),
          Expanded(
            child: AsyncView<PollsData>(
              create: () => repository.polls(),
              builder: (context, d) => ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _participationBanner(l, d.participationPct),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _activePoll(context, l, d.active),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SectionHeader(title: l.upcomingDecisions, onSeeAll: () => _soon(context)),
                  ),
                  const SizedBox(height: 12),
                  _decisionList(context, l, d.upcoming),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SectionHeader(title: l.previousDecisions, onSeeAll: () => _soon(context)),
                  ),
                  const SizedBox(height: 12),
                  _decisionList(context, l, d.previous),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _participationBanner(AppLocalizations l, int pct) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$pct% ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: l.t('householdsParticipated').replaceFirst('{p}% ', ''),
                    style: AppTheme.subtle,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activePoll(BuildContext context, AppLocalizations l, ActivePoll poll) {
    return AppCard(
      color: AppColors.surfaceGreenTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.primary, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(l.statusActivePoll,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(poll.question,
                        style: AppTheme.sectionTitle.copyWith(fontSize: 21)),
                    const SizedBox(height: 6),
                    Text(poll.description, style: AppTheme.subtle),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.lights.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.light_rounded,
                    color: AppColors.lights, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < poll.options.length; i++) ...[
            _pollOption(context, poll.options[i], i),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    const Icon(Icons.groups_rounded,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l.t('householdsVoted').replaceFirst('{n}', '${poll.households}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.subtle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(l.t('endsInDays').replaceFirst('{n}', '${poll.endsInDays}'),
                      style: AppTheme.subtle),
                ],
              ),
            ],
          ),
          if (poll.voted) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.border),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l.voteRecorded,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ),
                OutlinedButton(
                  onPressed: () => _voted(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(l.changeVote),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _voted(context),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
              child: Text(l.voteNow),
            ),
          ],
        ],
      ),
    );
  }

  void _voted(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ваш голос учтён')),
    );
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Скоро будет доступно')),
    );
  }

  Widget _pollOption(BuildContext context, PollOption opt, int index) {
    final selected = index == _selectedOption;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedOption = index);
        _voted(context);
      },
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor:
                    selected ? AppColors.primary : AppColors.border,
                child: Icon(
                  selected ? Icons.check_rounded : Icons.circle_outlined,
                  color: selected ? Colors.white : AppColors.textTertiary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(opt.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              Text('${opt.pct}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: opt.pct / 100,
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${opt.votes} голосов', style: AppTheme.subtle),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _decisionList(
      BuildContext context, AppLocalizations l, List<DecisionItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              _decisionRow(l, items[i]),
              if (i != items.length - 1)
                const Divider(height: 1, color: AppColors.divider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _decisionRow(AppLocalizations l, DecisionItem item) {
    final isPrevious = item.status != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          if (isPrevious)
            CircleAvatar(
              radius: 18,
              backgroundColor: item.status == AppStatus.approved
                  ? AppColors.primary
                  : AppColors.rejectedText,
              child: Icon(
                item.status == AppStatus.approved
                    ? Icons.check_rounded
                    : Icons.close_rounded,
                color: Colors.white,
                size: 18,
              ),
            )
          else
            IconChip(icon: item.category.icon, color: item.category.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.cardTitle.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(item.subtitle,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.subtle),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isPrevious)
                StatusBadge(status: item.status!)
              else
                Pill(
                  text: item.trailingTop,
                  bg: AppColors.upcomingBg,
                  fg: AppColors.upcomingText,
                  fontSize: 11.5,
                ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isPrevious) ...[
                    const Icon(Icons.calendar_today_rounded,
                        size: 12, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                  ],
                  Text(item.trailingBottom, style: AppTheme.subtle),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
