import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../repo.dart';
import '../theme.dart';
import '../widgets.dart';

const _types = [
  ['water', 'Вода', Icons.water_drop_rounded],
  ['maintenance', 'Ремонт', Icons.handyman_rounded],
  ['electricity', 'Электр.', Icons.bolt_rounded],
  ['community', 'Сообщество', Icons.groups_rounded],
  ['important', 'Важное', Icons.priority_high_rounded],
  ['event', 'Событие', Icons.event_rounded],
];

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Loader<List<AdminAnnouncement>>(
        load: repo.announcements,
        builder: (context, items, reload) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Header(
              title: 'Объявления',
              subtitle: 'Информируйте жителей',
              action: FilledButton(
                onPressed: () => _create(context, reload),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 14)),
                child: const Icon(Icons.add, size: 20),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (items.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('Объявлений нет', style: TextStyle(color: C.ink3)))),
                  for (final a in items) ...[
                    _card(context, a, reload),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, AdminAnnouncement a, VoidCallback reload) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (a.pinned) const Icon(Icons.push_pin_rounded, size: 15, color: C.danger),
              if (a.pinned) const SizedBox(width: 4),
              Expanded(child: Text(a.audienceLabel, style: const TextStyle(color: C.ink3, fontSize: 12))),
              Text('${a.seenBy} просм.', style: const TextStyle(color: C.ink3, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          if (a.date.isNotEmpty) Text(a.date, style: const TextStyle(color: C.ink3, fontSize: 12)),
          const SizedBox(height: 6),
          Text(a.message, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.ink2)),
          const Divider(height: 22),
          Row(
            children: [
              TextButton.icon(
                onPressed: () async {
                  await repo.pinAnnouncement(a.id, !a.pinned);
                  reload();
                },
                icon: Icon(a.pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded, size: 16),
                label: Text(a.pinned ? 'Открепить' : 'Закрепить'),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  final ok = await _confirm(context, 'Удалить объявление?');
                  if (ok) {
                    await repo.deleteAnnouncement(a.id);
                    reload();
                  }
                },
                style: TextButton.styleFrom(foregroundColor: C.danger),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Удалить'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _create(BuildContext context, VoidCallback reload) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateAnnouncementSheet(onCreated: reload),
    );
  }
}

Future<bool> _confirm(BuildContext context, String message) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить', style: TextStyle(color: C.danger))),
      ],
    ),
  );
  return r ?? false;
}

class _CreateAnnouncementSheet extends StatefulWidget {
  const _CreateAnnouncementSheet({required this.onCreated});
  final VoidCallback onCreated;
  @override
  State<_CreateAnnouncementSheet> createState() => _CreateAnnouncementSheetState();
}

class _CreateAnnouncementSheetState extends State<_CreateAnnouncementSheet> {
  String _type = 'maintenance';
  final _titleRu = TextEditingController();
  final _titleKk = TextEditingController();
  final _msgRu = TextEditingController();
  final _msgKk = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _titleRu.dispose();
    _titleKk.dispose();
    _msgRu.dispose();
    _msgKk.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleRu.text.trim().isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await repo.createAnnouncement({
        'type': _type,
        'title': _titleRu.text.trim(),
        'titleKk': _titleKk.text.trim().isEmpty ? _titleRu.text.trim() : _titleKk.text.trim(),
        'message': _msgRu.text.trim(),
        'messageKk': _msgKk.text.trim().isEmpty ? _msgRu.text.trim() : _msgKk.text.trim(),
        'audience': 'all',
        'audienceLabel': 'Весь район',
        'publishNow': true,
      });
      if (mounted) Navigator.pop(context);
      widget.onCreated();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(color: C.scaffold, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const Text('Новое объявление', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            const Text('Тип', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in _types)
                  ChoiceChip(
                    selected: _type == t[0],
                    onSelected: (_) => setState(() => _type = t[0] as String),
                    avatar: Icon(t[2] as IconData, size: 16),
                    label: Text(t[1] as String),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Заголовок', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(controller: _titleRu, decoration: const InputDecoration(hintText: 'Русский')),
            const SizedBox(height: 8),
            TextField(controller: _titleKk, decoration: const InputDecoration(hintText: 'Қазақша')),
            const SizedBox(height: 16),
            const Text('Сообщение', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(controller: _msgRu, minLines: 2, maxLines: 4, decoration: const InputDecoration(hintText: 'Текст (рус)')),
            const SizedBox(height: 8),
            TextField(controller: _msgKk, minLines: 2, maxLines: 4, decoration: const InputDecoration(hintText: 'Мәтін (қаз)')),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : const Text('Опубликовать'),
            ),
          ],
        ),
      ),
    );
  }
}
