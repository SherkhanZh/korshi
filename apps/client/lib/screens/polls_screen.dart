import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/api_client.dart';
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
  /// Index the resident has tapped this session. When null, the highlighted
  /// option is derived from their actual recorded vote (votedOptionId).
  int? _selectedOption;

  /// True while the resident is changing an already-cast vote. Options are only
  /// selectable when they haven't voted yet or are actively editing.
  bool _editing = false;

  /// Effective highlighted option index: the manual tap if any, else the
  /// option the resident actually voted for, else the first option.
  int _effectiveIndex(ActivePoll poll) {
    if (poll.options.isEmpty) return 0;
    if (_selectedOption != null) {
      return _selectedOption!.clamp(0, poll.options.length - 1).toInt();
    }
    final vi = poll.votedOptionId >= 0
        ? poll.options.indexWhere((o) => o.id == poll.votedOptionId)
        : -1;
    return vi >= 0 ? vi : 0;
  }

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
              refresh: dataVersion,
              create: () => repository.polls(),
              builder: (context, d) => RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  dataVersion.value++;
                  await Future<void>.delayed(const Duration(milliseconds: 500));
                },
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    if (d.active.exists) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _participationBanner(l, d.participationPct),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _activePoll(context, l, d.active),
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _noActivePoll(),
                      ),
                  ],
                ),
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
                    Text(loc(poll.question, poll.questionKk),
                        style: AppTheme.sectionTitle.copyWith(fontSize: 21)),
                    const SizedBox(height: 6),
                    Text(loc(poll.description, poll.descriptionKk), style: AppTheme.subtle),
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
            _pollOption(context, poll.options[i], i, _effectiveIndex(poll),
                !poll.voted || _editing),
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
          _visibility(poll),
          if (poll.voted && !_editing) ...[
            // Already voted: options are locked. "Change" unlocks re-selection.
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
                  onPressed: () => setState(() {
                    _editing = true;
                    _selectedOption = null; // start from the current choice
                  }),
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
            // Not voted yet, or changing the vote: pick an option then submit.
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _castVote(context, poll),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
              child: Text(l.voteNow),
            ),
            if (_editing) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() {
                  _editing = false;
                  _selectedOption = null;
                }),
                child: Text(loc('Отмена', 'Болдырмау'),
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _noActivePoll() {
    return AppCard(
      child: Column(
        children: [
          const Icon(Icons.how_to_vote_outlined,
              size: 40, color: AppColors.textTertiary),
          const SizedBox(height: 10),
          Text(loc('Сейчас нет активных опросов', 'Қазір белсенді сауалнамалар жоқ'),
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(loc('Здесь появятся новые опросы района.', 'Мұнда аудан сауалнамалары пайда болады.'),
              textAlign: TextAlign.center, style: AppTheme.subtle),
        ],
      ),
    );
  }

  /// Confidential note, or — for public polls — the list of who voted.
  Widget _visibility(ActivePoll poll) {
    if (poll.confidential) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(loc('Голосование конфиденциально', 'Дауыс беру құпия'),
                style: AppTheme.subtle),
          ],
        ),
      );
    }
    if (poll.voters.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            const Icon(Icons.public_rounded, size: 15, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(loc('Открытое голосование', 'Ашық дауыс беру'), style: AppTheme.subtle),
          ],
        ),
      );
    }
    String optLabel(int id) {
      for (final o in poll.options) {
        if (o.id == id) return loc(o.label, o.labelKk);
      }
      return '—';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.public_rounded, size: 15, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(loc('Как проголосовали:', 'Қалай дауыс берді:'),
                    style: AppTheme.subtle.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            for (final v in poll.voters)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('${v.name} — ${optLabel(v.optionId)}',
                    style: AppTheme.subtle),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _castVote(BuildContext context, ActivePoll poll) async {
    if (poll.id.isEmpty || poll.options.isEmpty) return;
    final idx = _effectiveIndex(poll);
    final option = poll.options[idx];
    try {
      await repository.vote(pollId: poll.id, optionId: option.id);
      dataVersion.value++; // re-fetch the poll with updated tallies + voted state
      if (!mounted) return;
      setState(() {
        _editing = false;
        _selectedOption = null; // highlight now follows the recorded vote
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc('Ваш голос учтён', 'Дауысыңыз есепке алынды'))),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Widget _pollOption(
      BuildContext context, PollOption opt, int index, int selectedIdx, bool enabled) {
    final selected = index == selectedIdx;
    return GestureDetector(
      onTap: enabled ? () => setState(() => _selectedOption = index) : null,
      child: Opacity(
        opacity: enabled || selected ? 1 : 0.55,
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
                child: Text(loc(opt.label, opt.labelKk),
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
              Text('${opt.votes} ${loc('голосов', 'дауыс')}', style: AppTheme.subtle),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }

}
