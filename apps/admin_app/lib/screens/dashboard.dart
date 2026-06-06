import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api.dart';
import '../models.dart';
import '../push.dart';
import '../repo.dart';
import '../theme.dart';
import '../widgets.dart';
import 'announcements.dart';
import 'polls.dart';
import 'reports.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    pendingOpenSection.addListener(_handlePending);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handlePending());
  }

  @override
  void dispose() {
    pendingOpenSection.removeListener(_handlePending);
    super.dispose();
  }

  void _handlePending() {
    final s = pendingOpenSection.value;
    if (s == 0 || !mounted) return;
    pendingOpenSection.value = 0;
    final page = s == 1
        ? const ReportsScreen()
        : s == 2
            ? const AnnouncementsScreen()
            : const PollsScreen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _open(page);
    });
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _SectionPage(child: screen)));
  }

  Future<void> _uploadCover() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2000, imageQuality: 85);
    if (x == null) return;
    setState(() => _uploading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repo.uploadCover(x.path);
      messenger.showSnackBar(SnackBar(content: Text(loc('Обложка района обновлена', 'Аудан мұқабасы жаңартылды'))));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc('Обзор', 'Шолу'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                      Text(neighborhoodName.value ?? loc('Район', 'Аудан'), style: const TextStyle(color: C.ink2)),
                    ],
                  ),
                ),
                const _LangToggle(),
                IconButton(
                  tooltip: loc('Выйти', 'Шығу'),
                  onPressed: () async {
                    await PushService.unregister();
                    await clearSession();
                  },
                  icon: const Icon(Icons.logout_rounded, color: C.danger),
                ),
              ],
            ),
          ),
          Expanded(
            child: Loader<Stats>(
              load: repo.stats,
              builder: (context, s, reload) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _stat(loc('Новые заявки', 'Жаңа өтініштер'), s.n('reportsNew'), Icons.assignment_late_rounded, C.warn),
                      _stat(loc('В работе', 'Жұмыста'), s.n('reportsInProgress'), Icons.handyman_rounded, C.primary),
                      _stat(loc('Объявления', 'Хабарландырулар'), s.n('announcements'), Icons.campaign_rounded, C.water),
                      _stat(loc('Активные опросы', 'Белсенді сауалнамалар'), s.n('activePolls'), Icons.how_to_vote_rounded, C.safety),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _quickAction(loc('Заявки', 'Өтініштер'), Icons.assignment_rounded, C.warn, () => _open(const ReportsScreen())),
                      _quickAction(loc('Объявления', 'Хабарлар'), Icons.campaign_rounded, C.water, () => _open(const AnnouncementsScreen())),
                      _quickAction(loc('Опросы', 'Сауалнамалар'), Icons.how_to_vote_rounded, C.safety, () => _open(const PollsScreen())),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc('Сводка района', 'Аудан қорытындысы'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 12),
                        _row(loc('Жителей', 'Тұрғындар'), s.n('residents')),
                        _row(loc('Заявок решено', 'Шешілген өтініштер'), s.n('reportsResolved')),
                        _row(loc('Всего заявок', 'Барлық өтініштер'), s.n('reportsTotal')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _uploading ? null : _uploadCover,
                    icon: _uploading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                        : const Icon(Icons.image_rounded, size: 18),
                    label: Text(loc('Обновить обложку района', 'Аудан мұқабасын жаңарту')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int value, IconData icon, Color tint) {
    return Panel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: tint.withOpacity(0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: tint, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1)),
                const SizedBox(height: 2),
                Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.ink2, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, int value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: C.ink2)),
            Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );

  /// Circle icon button with a label below — opens a section as a full page.
  Widget _quickAction(String label, IconData icon, Color tint, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(color: tint.withOpacity(0.14), shape: BoxShape.circle),
              child: Icon(icon, color: tint, size: 26),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.ink2)),
          ],
        ),
      ),
    );
  }
}

/// Wraps a tab-style screen in a scaffold with a back button for pushed routes.
class _SectionPage extends StatelessWidget {
  const _SectionPage({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.scaffold,
      appBar: AppBar(
        backgroundColor: C.scaffold,
        foregroundColor: C.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: child,
    );
  }
}

/// KZ / RU language switch pill.
class _LangToggle extends StatelessWidget {
  const _LangToggle();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: adminLocale,
      builder: (context, lang, _) {
        Widget btn(String code, String label) {
          final active = lang == code;
          return GestureDetector(
            onTap: () => setLocale(code),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: active ? C.primary : C.surface,
              child: Text(label,
                  style: TextStyle(
                      color: active ? Colors.white : C.ink2,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            border: Border.all(color: C.border),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(mainAxisSize: MainAxisSize.min, children: [btn('kk', 'KZ'), btn('ru', 'RU')]),
        );
      },
    );
  }
}
