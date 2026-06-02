import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../app_state.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/launchers.dart';
import '../services/repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/common.dart';
import '../widgets/detail_sheet.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'report_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _quickCategories = [
    IssueCategory.water,
    IssueCategory.roads,
    IssueCategory.lights,
    IssueCategory.garbage,
    IssueCategory.safety,
  ];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    const headerHeight = 300.0;
    const sheetTop = 250.0;
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: headerHeight,
          child: _headerImage(context, l),
        ),
        Positioned.fill(
          child: ListView(
            padding: EdgeInsets.zero,
            // No bounce — keeps the header's bottom edge straight.
            physics: const ClampingScrollPhysics(),
            children: [
              const SizedBox(height: sheetTop),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.scaffold,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                child: Transform.translate(
                  offset: const Offset(0, -52),
                  child: AsyncView<HomeData>(
                    create: () => repository.home(),
                    refresh: dataVersion,
                    builder: (context, d) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _announcement(context, l, d),
                        const SizedBox(height: 20),
                        SectionHeader(
                            title: l.quickReport,
                            onSeeAll: () => _openReport(context)),
                        const SizedBox(height: 12),
                        _quickReportRow(context),
                        const SizedBox(height: 24),
                        Text(l.todayInNeighborhood, style: AppTheme.sectionTitle),
                        const SizedBox(height: 12),
                        _todayCard(context, d.today),
                        const SizedBox(height: 20),
                        _pollCard(context, l, d),
                        const SizedBox(height: 24),
                        SectionHeader(
                            title: l.trustedContacts,
                            onSeeAll: () => shellTab.value = 4),
                        const SizedBox(height: 12),
                        _contactsRow(context, d.contacts),
                        const SizedBox(height: 20),
                        _partnerCard(context, l, d),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          right: 16,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => showProfileSheet(context),
                child: const SizedBox(width: 40, height: 40),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
                child: const SizedBox(width: 40, height: 40),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerImage(BuildContext context, AppLocalizations l) {
    final topInset = MediaQuery.of(context).padding.top;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          ApiConfig.coverUrl,
          fit: BoxFit.cover,
          // Fall back to the bundled image until a cover is uploaded.
          errorBuilder: (_, __, ___) =>
              Image.asset('assets/login.png', fit: BoxFit.cover),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [Color(0x59000000), Color(0x00000000)],
            ),
          ),
        ),
        Positioned(
          top: topInset + 12,
          left: 20,
          right: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: _strokedText(
                            l.homeNeighborhood,
                            base: const TextStyle(
                              fontFamily: AppTheme.displayFont,
                              fontSize: 27,
                              fontWeight: FontWeight.w600,
                              height: 1.05,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.eco, color: Colors.white, size: 20),
                      ],
                    ),
                    const SizedBox(height: 2),
                    _strokedText(l.homeCity, base: const TextStyle(fontSize: 15)),
                  ],
                ),
              ),
              _circleIcon(Icons.person_rounded,
                  onTap: () => showProfileSheet(context)),
              const SizedBox(width: 8),
              _circleIcon(Icons.notifications_none_rounded, onTap: () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _strokedText(String text, {required TextStyle base, double stroke = 1}) {
    return Stack(
      children: [
        Text(text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: base.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = stroke
                ..strokeJoin = StrokeJoin.round
                ..color = Colors.black,
            )),
        Text(text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: base.copyWith(color: Colors.white)),
      ],
    );
  }

  Widget _circleIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  void _openReport(BuildContext context, [IssueCategory? category]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReportScreen(initialCategory: category)),
    );
  }

  void _openUpdate(
    BuildContext context, {
    required String title,
    required String date,
    required String body,
    required IssueCategory category,
    required AppStatus status,
  }) {
    showUpdateSheet(
      context,
      title: title,
      date: date,
      body: body,
      category: category,
      status: status,
    );
  }

  Widget _announcement(BuildContext context, AppLocalizations l, HomeData d) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.lights, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l.importantAnnouncement,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(d.announcementTitle,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(d.announcementDate,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(d.announcementBody,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _openUpdate(
                    context,
                    title: d.announcementTitle,
                    date: d.announcementDate,
                    body: d.announcementBody,
                    category: IssueCategory.roads,
                    status: AppStatus.upcoming,
                  ),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white54),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(l.viewDetails,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 88,
            height: 92,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.construction_rounded,
                color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _quickReportRow(BuildContext context) {
    final l = context.l10n;
    final tiles = <_QuickTile>[
      for (final c in _quickCategories)
        _QuickTile(c.icon, c.color, l.t(c.labelKey), c),
      _QuickTile(Icons.more_horiz_rounded, AppColors.textSecondary, l.catMore, null),
    ];
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tiles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final t = tiles[i];
          return GestureDetector(
            onTap: () => _openReport(context, t.category),
            child: Container(
              width: 76,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(t.icon, color: t.color, size: 26),
                  const SizedBox(height: 8),
                  Text(t.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _todayCard(BuildContext context, List<UpdateItem> today) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        children: [
          for (int i = 0; i < today.length; i++) ...[
            _todayRow(context, today[i]),
            if (i != today.length - 1)
              const Divider(height: 1, color: AppColors.divider),
          ],
        ],
      ),
    );
  }

  Widget _todayRow(BuildContext context, UpdateItem item) {
    return InkWell(
      onTap: () => _openUpdate(
        context,
        title: item.title,
        date: item.subtitle ?? '',
        body: item.body ?? item.subtitle ?? '',
        category: item.category,
        status: item.status,
      ),
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          IconChip(
            icon: item.category == IssueCategory.other
                ? Icons.calendar_today_rounded
                : item.category.icon,
            color: item.status == AppStatus.upcoming
                ? AppColors.lights
                : AppColors.primary,
            filled: item.status != AppStatus.upcoming,
            bgOpacity: 0.16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.cardTitle.copyWith(fontSize: 15)),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(item.subtitle!,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.subtle),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(status: item.status),
        ],
      ),
      ),
    );
  }

  Widget _pollCard(BuildContext context, AppLocalizations l, HomeData d) {
    return AppCard(
      color: AppColors.surfaceGreenTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.communityPoll, style: AppTheme.cardTitle),
          const SizedBox(height: 6),
          Text(d.pollQuestion, style: AppTheme.body),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: d.pollYesPct / 100,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${d.pollYesPct}% Да',
                  style: AppTheme.subtle.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
              Text('${d.pollNoPct}% Нет', style: AppTheme.subtle),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => shellTab.value = 3,
            style: FilledButton.styleFrom(
              minimumSize: const Size(120, 44),
              backgroundColor: AppColors.primary,
            ),
            child: Text(l.voteNow),
          ),
        ],
      ),
    );
  }

  Widget _contactsRow(BuildContext context, List<ContactItem> contacts) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: contacts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final c = contacts[i];
          return Container(
            width: 260,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: c.color.withOpacity(0.15),
                  child: Icon(c.icon, color: c.color, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(c.role,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.subtle.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CallWhatsAppRow(compact: true, phone: c.phone),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _partnerCard(BuildContext context, AppLocalizations l, HomeData d) {
    return AppCard(
      color: AppColors.surfaceGreenTint,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.trustedLocalPartner,
                    style: AppTheme.subtle.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(d.partnerTitle, style: AppTheme.cardTitle),
                const SizedBox(height: 4),
                Text(d.partnerSubtitle, style: AppTheme.subtle),
                const SizedBox(height: 8),
                RatingLine(rating: d.partnerRating, reviews: d.partnerReviews),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => callNumber(context, d.partnerPhone),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickTile {
  const _QuickTile(this.icon, this.color, this.label, this.category);
  final IconData icon;
  final Color color;
  final String label;
  final IssueCategory? category;
}
