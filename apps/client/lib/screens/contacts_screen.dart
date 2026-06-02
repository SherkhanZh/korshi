import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/common.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(title: l.contactsTitle, subtitle: l.contactsSubtitle),
          const SizedBox(height: 4),
          FilterChips(
            labels: [l.filterAll, l.tabNeighborhood, l.tabServices, l.tabEmergency],
            selected: _filter,
            onSelected: (i) => setState(() => _filter = i),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AsyncView<ContactsData>(
              create: () => repository.contacts(),
              builder: (context, d) {
                // 0 All, 1 Neighborhood, 2 Services, 3 Emergency
                final showImportant = _filter == 0 || _filter == 1 || _filter == 3;
                final showServices = _filter == 0 || _filter == 2;
                final showPartners = _filter == 0 || _filter == 2;
                final important = _filter == 1
                    ? d.important.where((c) => c.badge != 'emergency').toList()
                    : _filter == 3
                        ? d.important.where((c) => c.badge == 'emergency').toList()
                        : d.important;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    if (showImportant) ...[
                      MiniSectionLabel(
                          text: l.importantContacts, icon: Icons.groups_rounded),
                      const SizedBox(height: 12),
                      _importantGrid(l, important),
                      const SizedBox(height: 24),
                    ],
                    if (showServices) ...[
                      MiniSectionLabel(
                          text: l.localServices, icon: Icons.handyman_rounded),
                      const SizedBox(height: 12),
                      _servicesRow(l, d.services),
                      const SizedBox(height: 24),
                    ],
                    if (showPartners) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          MiniSectionLabel(
                              text: l.trustedLocalPartners,
                              icon: Icons.star_rounded),
                          Text(l.seeAll, style: AppTheme.seeAll),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _partnersRow(l, d.partners),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  ({String label, Color bg, Color fg})? _badge(AppLocalizations l, ContactItem c) {
    switch (c.badge) {
      case 'chairman':
        return (label: l.roleChairman, bg: AppColors.resolvedBg, fg: AppColors.resolvedText);
      case 'police':
        return (label: l.rolePolice, bg: AppColors.waitingBg, fg: AppColors.waitingText);
      case 'emergency':
        final amber = c.category == IssueCategory.lights;
        return (
          label: l.statusEmergency,
          bg: amber ? AppColors.upcomingBg : AppColors.emergencyBg,
          fg: amber ? AppColors.upcomingText : AppColors.emergencyText,
        );
      default:
        return null;
    }
  }

  Widget _importantGrid(AppLocalizations l, List<ContactItem> items) {
    return Column(
      children: [
        for (final c in items) ...[
          _importantCard(l, c),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _importantCard(AppLocalizations l, ContactItem c) {
    final badge = _badge(l, c);
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: c.color.withOpacity(0.15),
                child: Icon(c.icon, color: c.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(c.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Pill(text: badge.label, bg: badge.bg, fg: badge.fg, fontSize: 10),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(c.statusLine ?? c.subtitle ?? '24/7',
                        style: AppTheme.subtle.copyWith(fontSize: 12.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: CallWhatsAppRow(compact: true, phone: c.phone),
          ),
        ],
      ),
    );
  }

  Widget _servicesRow(AppLocalizations l, List<ContactItem> items) {
    return SizedBox(
      height: 192,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final c = items[i];
          return Container(
            width: 150,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: c.color.withOpacity(0.15),
                  child: Icon(c.icon, color: c.color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(c.role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(c.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.subtle),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_rounded,
                        size: 13, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(l.recommendedByNeighborhood,
                          style: AppTheme.subtle.copyWith(fontSize: 10.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const Spacer(),
                CallWhatsAppRow(compact: true, phone: c.phone),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _partnersRow(AppLocalizations l, List<ContactItem> items) {
    return SizedBox(
      height: 234,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final c = items[i];
          return Container(
            width: 168,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 84,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: c.color.withOpacity(0.15),
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Center(child: Icon(c.icon, color: c.color, size: 34)),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Pill(
                        text: l.partner,
                        bg: AppColors.partnerBadge,
                        fg: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(c.role,
                          style: AppTheme.subtle.copyWith(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 10),
                      CallWhatsAppRow(compact: true, phone: c.phone),
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
