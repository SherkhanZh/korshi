import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../services/launchers.dart';
import '../services/push.dart';
import '../services/session.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'info_screen.dart';
import 'my_reports_screen.dart';
import 'onboarding/onboarding.dart';

/// Presents the profile / settings panel as a draggable bottom sheet,
/// matching the overlay design in the mockups.
void showProfileSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ProfileScreen(scrollController: controller),
      ),
    ),
  );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 0 KK, 1 RU — initialised from the current app locale.
  int _lang = appLocale.value.languageCode == 'kk' ? 0 : 1;
  final Map<String, bool> _notif = {
    'emergency': true,
    'updates': true,
    'polls': true,
    'service': true,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _profileHeader(l),
        const SizedBox(height: 24),
        _label(l.sectionLanguage),
        const SizedBox(height: 10),
        _languageSelector(l),
        const SizedBox(height: 24),
        _label(l.sectionNotifications),
        const SizedBox(height: 10),
        _notifications(l),
        const SizedBox(height: 24),
        _label(l.sectionMyRequests),
        const SizedBox(height: 10),
        _tile(
          icon: Icons.assignment_rounded,
          title: l.myReports,
          subtitle: l.myReportsDesc,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyReportsScreen()),
            );
          },
        ),
        const SizedBox(height: 24),
        _label(l.sectionHelp),
        const SizedBox(height: 10),
        _tile(
          icon: Icons.headset_mic_rounded,
          title: l.contactChairman,
          subtitle: l.contactChairmanDesc,
          onTap: () => callNumber(context, kChairmanPhone),
        ),
        const SizedBox(height: 10),
        _tile(
          icon: Icons.help_outline_rounded,
          title: l.faqHelp,
          subtitle: l.faqHelpDesc,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => InfoScreen.faq()),
          ),
        ),
        const SizedBox(height: 24),
        _label(l.sectionAccount),
        const SizedBox(height: 10),
        _tile(
          icon: Icons.shield_outlined,
          title: l.privacyPolicy,
          subtitle: l.privacyPolicyDesc,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => InfoScreen.privacy()),
          ),
        ),
        const SizedBox(height: 10),
        _tile(
          icon: Icons.description_outlined,
          title: l.termsConditions,
          subtitle: l.termsConditionsDesc,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => InfoScreen.terms()),
          ),
        ),
        const SizedBox(height: 10),
        _tile(
          icon: Icons.logout_rounded,
          title: l.logout,
          subtitle: l.logoutDesc,
          danger: true,
          onTap: () async {
            final nav = Navigator.of(context);
            await PushService.unregister();
            await clearSession();
            nav.pop(); // close the profile sheet
            nav.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false,
            );
          },
        ),
        const SizedBox(height: 20),
        _footer(l),
      ],
    );
  }

  Future<void> _pickAvatar() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        imageQuality: 85,
      );
      if (picked != null) avatarPath.value = picked.path;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось выбрать фото')),
        );
      }
    }
  }

  Widget _profileHeader(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F2EA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickAvatar,
            child: ValueListenableBuilder<String?>(
              valueListenable: avatarPath,
              builder: (context, path, _) => Stack(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.surfaceGreenTint,
                    backgroundImage:
                        path != null ? FileImage(File(path)) : null,
                    child: path == null
                        ? const Icon(Icons.person_rounded,
                            size: 38, color: AppColors.primary)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(residentName.value?.isNotEmpty == true ? residentName.value! : 'Sherkhan',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(l.profileAddress, style: AppTheme.subtle),
                Text(l.homeNeighborhood, style: AppTheme.subtle),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.home_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(l.profileResident,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: AppColors.primary),
      );

  Widget _languageSelector(AppLocalizations l) {
    final langs = [l.langKazakh, l.langRussian];
    final codes = ['kk', 'ru'];
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < langs.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _lang = i);
                  setLocale(codes[i]);
                },
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _lang == i ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    langs[i],
                    style: TextStyle(
                      color: _lang == i ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _notifications(AppLocalizations l) {
    final rows = [
      ['emergency', Icons.campaign_rounded, l.notifEmergency, l.notifEmergencyDesc],
      ['updates', Icons.notifications_rounded, l.notifUpdates, l.notifUpdatesDesc],
      ['polls', Icons.bar_chart_rounded, l.notifPolls, l.notifPollsDesc],
      ['service', Icons.assignment_rounded, l.notifService, l.notifServiceDesc],
    ];
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _notifRow(rows[i][0] as String, rows[i][1] as IconData,
                rows[i][2] as String, rows[i][3] as String),
            if (i != rows.length - 1)
              const Divider(height: 1, color: AppColors.divider),
          ],
        ],
      ),
    );
  }

  Widget _notifRow(String key, IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          IconChip(icon: icon, color: AppColors.primary, bgOpacity: 0.12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                Text(desc, style: AppTheme.subtle.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: _notif[key]!,
            activeColor: Colors.white,
            activeTrackColor: AppColors.primary,
            onChanged: (v) => setState(() => _notif[key] = v),
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool danger = false,
  }) {
    final color = danger ? AppColors.logout : AppColors.textPrimary;
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          IconChip(
            icon: icon,
            color: danger ? AppColors.logout : AppColors.primary,
            bgOpacity: 0.12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15, color: color)),
                Text(subtitle, style: AppTheme.subtle.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: danger ? AppColors.logout : AppColors.textTertiary),
        ],
      ),
    );
  }

  Widget _footer(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceGreenTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco, color: AppColors.primaryLight, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(l.profileFooterThanks, style: AppTheme.subtle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l.profileFooterTogether,
              style: AppTheme.subtle.copyWith(
                  fontStyle: FontStyle.italic, color: AppColors.primary),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
