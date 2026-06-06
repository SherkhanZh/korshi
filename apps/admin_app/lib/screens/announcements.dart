import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../repo.dart';
import '../theme.dart';
import '../widgets.dart';

// [key, ru, icon, kk]
const _types = [
  ['water', 'Вода', Icons.water_drop_rounded, 'Су'],
  ['maintenance', 'Ремонт', Icons.handyman_rounded, 'Жөндеу'],
  ['electricity', 'Электр.', Icons.bolt_rounded, 'Электр'],
  ['community', 'Сообщество', Icons.groups_rounded, 'Қауымдастық'],
  ['important', 'Важное', Icons.priority_high_rounded, 'Маңызды'],
  ['event', 'Событие', Icons.event_rounded, 'Іс-шара'],
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
              title: loc('Объявления', 'Хабарландырулар'),
              subtitle: loc('Информируйте жителей', 'Тұрғындарды хабардар етіңіз'),
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
                    Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Center(child: Text(loc('Объявлений нет', 'Хабарландырулар жоқ'), style: const TextStyle(color: C.ink3)))),
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
              Text('${a.seenBy} ${loc('просм.', 'қаралым')}', style: const TextStyle(color: C.ink3, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          if (a.date.isNotEmpty) Text(a.date, style: const TextStyle(color: C.ink3, fontSize: 12)),
          const SizedBox(height: 6),
          Text(a.message, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.ink2)),
          const Divider(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _cardAction(
                icon: a.pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                label: a.pinned ? loc('Открепить', 'Босату') : loc('Закрепить', 'Бекіту'),
                color: C.primary,
                onPressed: () async {
                  await repo.pinAnnouncement(a.id, !a.pinned);
                  reload();
                },
              ),
              _cardAction(
                icon: Icons.edit_outlined,
                label: loc('Изменить', 'Өзгерту'),
                color: C.ink2,
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _CreateAnnouncementSheet(onCreated: reload, editing: a),
                ),
              ),
              _cardAction(
                icon: Icons.delete_outline_rounded,
                label: loc('Удалить', 'Жою'),
                color: C.danger,
                onPressed: () async {
                  final ok = await _confirm(context, loc('Удалить объявление?', 'Хабарландыруды жою керек пе?'));
                  if (ok) {
                    await repo.deleteAnnouncement(a.id);
                    reload();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Compact card action that won't overflow on narrow phones.
  Widget _cardAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      icon: Icon(icon, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 13)),
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
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc('Отмена', 'Болдырмау'))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc('Удалить', 'Жою'), style: const TextStyle(color: C.danger))),
      ],
    ),
  );
  return r ?? false;
}

class _CreateAnnouncementSheet extends StatefulWidget {
  const _CreateAnnouncementSheet({required this.onCreated, this.editing});
  final VoidCallback onCreated;
  final AdminAnnouncement? editing;
  @override
  State<_CreateAnnouncementSheet> createState() => _CreateAnnouncementSheetState();
}

class _CreateAnnouncementSheetState extends State<_CreateAnnouncementSheet> {
  late String _type = widget.editing?.type ?? 'maintenance';
  late final _titleRu = TextEditingController(text: widget.editing?.title ?? '');
  late final _titleKk = TextEditingController(text: widget.editing?.titleKk ?? '');
  late final _msgRu = TextEditingController(text: widget.editing?.message ?? '');
  late final _msgKk = TextEditingController(text: widget.editing?.messageKk ?? '');
  bool _busy = false;

  bool get _isEdit => widget.editing != null;

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
      final body = {
        'type': _type,
        'title': _titleRu.text.trim(),
        'titleKk': _titleKk.text.trim().isEmpty ? _titleRu.text.trim() : _titleKk.text.trim(),
        'message': _msgRu.text.trim(),
        'messageKk': _msgKk.text.trim().isEmpty ? _msgRu.text.trim() : _msgKk.text.trim(),
      };
      if (_isEdit) {
        await repo.updateAnnouncement(widget.editing!.id, body);
      } else {
        await repo.createAnnouncement({
          ...body,
          'audience': 'all',
          'audienceLabel': 'Весь район',
          'publishNow': true,
        });
      }
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
            Text(_isEdit ? loc('Изменить объявление', 'Хабарландыруды өзгерту') : loc('Новое объявление', 'Жаңа хабарландыру'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Text(loc('Тип', 'Түрі'), style: const TextStyle(fontWeight: FontWeight.w600)),
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
                    label: Text(loc(t[1] as String, t[3] as String)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(loc('Заголовок', 'Тақырып'), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(controller: _titleKk, decoration: const InputDecoration(hintText: 'Қазақша')),
            const SizedBox(height: 8),
            TextField(controller: _titleRu, decoration: const InputDecoration(hintText: 'Русский')),
            const SizedBox(height: 16),
            Text(loc('Сообщение', 'Хабарлама'), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(controller: _msgKk, minLines: 2, maxLines: 4, decoration: const InputDecoration(hintText: 'Мәтін (қаз)')),
            const SizedBox(height: 8),
            TextField(controller: _msgRu, minLines: 2, maxLines: 4, decoration: const InputDecoration(hintText: 'Текст (рус)')),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : Text(_isEdit ? loc('Сохранить', 'Сақтау') : loc('Опубликовать', 'Жариялау')),
            ),
          ],
        ),
      ),
    );
  }
}
