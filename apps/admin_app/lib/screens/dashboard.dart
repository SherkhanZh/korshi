import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api.dart';
import '../models.dart';
import '../push.dart';
import '../repo.dart';
import '../theme.dart';
import '../widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _uploading = false;

  Future<void> _uploadCover() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2000, imageQuality: 85);
    if (x == null) return;
    setState(() => _uploading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repo.uploadCover(x.path);
      messenger.showSnackBar(const SnackBar(content: Text('Обложка района обновлена')));
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
                      const Text('Обзор', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                      Text(neighborhoodName.value ?? 'Район', style: const TextStyle(color: C.ink2)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Выйти',
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
                      _stat('Новые заявки', s.n('reportsNew'), Icons.assignment_late_rounded, C.warn),
                      _stat('В работе', s.n('reportsInProgress'), Icons.handyman_rounded, C.primary),
                      _stat('Объявления', s.n('announcements'), Icons.campaign_rounded, C.water),
                      _stat('Активные опросы', s.n('activePolls'), Icons.how_to_vote_rounded, C.safety),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Сводка района', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 12),
                        _row('Жителей', s.n('residents')),
                        _row('Заявок решено', s.n('reportsResolved')),
                        _row('Всего заявок', s.n('reportsTotal')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _uploading ? null : _uploadCover,
                    icon: _uploading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                        : const Icon(Icons.image_rounded, size: 18),
                    label: const Text('Обновить обложку района'),
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
}
