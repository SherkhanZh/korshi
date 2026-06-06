import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../repo.dart';
import '../theme.dart';
import '../widgets.dart';

const _cats = ['water', 'roads', 'lights', 'garbage', 'safety', 'other'];
// [code, ru, kk]
const _badges = [
  [null, 'Нет', 'Жоқ'],
  ['chairman', 'Председатель', 'Төраға'],
  ['police', 'Участковый', 'Учаскелік'],
  ['emergency', 'Экстренный', 'Жедел'],
];

String _badgeLabel(String? b) => {
      'chairman': loc('Председатель', 'Төраға'),
      'police': loc('Участковый', 'Учаскелік'),
      'emergency': loc('Экстренный', 'Жедел'),
    }[b] ?? '';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Loader<List<AdminContact>>(
        load: repo.contacts,
        builder: (context, items, reload) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Header(
              title: loc('Контакты', 'Контактілер'),
              subtitle: loc('Важные контакты района', 'Аудан маңызды контактілері'),
              action: FilledButton(
                onPressed: () => _edit(context, reload, null),
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
                    Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Center(child: Text(loc('Контактов нет', 'Контактілер жоқ'), style: const TextStyle(color: C.ink3)))),
                  for (final c in items) ...[
                    _card(context, c, reload),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, AdminContact c, VoidCallback reload) {
    return Panel(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: Cat.color(c.category).withOpacity(0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(Cat.icon(c.category), color: Cat.color(c.category)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
                    if (c.badge != null) ...[
                      const SizedBox(width: 8),
                      Pill(_badgeLabel(c.badge), bg: C.greenTint, fg: C.primary),
                    ],
                  ],
                ),
                Text([c.role, c.subtitle].where((s) => s.isNotEmpty).join(' · '),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.ink3, fontSize: 12)),
                if (c.phone.isNotEmpty) Text(c.phone, style: const TextStyle(color: C.ink2, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: C.ink3),
            onPressed: () => _edit(context, reload, c),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: C.ink3),
            onPressed: () async {
              final ok = await _confirm(context, loc('Удалить контакт?', 'Контактіні жою керек пе?'));
              if (ok) {
                await repo.deleteContact(c.id);
                reload();
              }
            },
          ),
        ],
      ),
    );
  }

  void _edit(BuildContext context, VoidCallback reload, AdminContact? editing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContactSheet(onSaved: reload, editing: editing),
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

class _ContactSheet extends StatefulWidget {
  const _ContactSheet({required this.onSaved, this.editing});
  final VoidCallback onSaved;
  final AdminContact? editing;
  @override
  State<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends State<_ContactSheet> {
  late final _name = TextEditingController(text: widget.editing?.name ?? '');
  late final _role = TextEditingController(text: widget.editing?.role ?? '');
  late final _subtitle = TextEditingController(text: widget.editing?.subtitle ?? '');
  late final _phone = TextEditingController(text: widget.editing?.phone ?? '');
  late String _category = widget.editing?.category ?? 'other';
  late String? _badge = widget.editing?.badge;
  bool _busy = false;

  bool get _isEdit => widget.editing != null;

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _subtitle.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final body = {
        'name': _name.text.trim(),
        'role': _role.text.trim(),
        'subtitle': _subtitle.text.trim(),
        'category': _category,
        'badge': _badge,
        'phone': _phone.text.trim(),
      };
      if (_isEdit) {
        await repo.updateContact(widget.editing!.id, body);
      } else {
        await repo.createContact(body);
      }
      if (mounted) Navigator.pop(context);
      widget.onSaved();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(color: C.scaffold, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Text(_isEdit ? loc('Изменить контакт', 'Контактіні өзгерту') : loc('Новый контакт', 'Жаңа контакт'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: InputDecoration(labelText: loc('Имя / название *', 'Аты / атауы *'), hintText: loc('Напр.: Асхат С.', 'Мыс.: Асхат С.'))),
            const SizedBox(height: 12),
            TextField(controller: _role, decoration: InputDecoration(labelText: loc('Роль / описание', 'Рөлі / сипаттамасы'), hintText: loc('Напр.: Председатель', 'Мыс.: Төраға'))),
            const SizedBox(height: 12),
            TextField(controller: _subtitle, decoration: InputDecoration(labelText: loc('Подпись', 'Жазба'), hintText: loc('Напр.: Обычно отвечает быстро', 'Мыс.: Әдетте тез жауап береді'))),
            const SizedBox(height: 16),
            Text(loc('Метка', 'Белгі'), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final b in _badges)
                  ChoiceChip(
                    selected: _badge == b[0],
                    onSelected: (_) => setState(() => _badge = b[0] as String?),
                    label: Text(loc(b[1] as String, b[2] as String)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(loc('Категория (цвет иконки)', 'Санат (белгіше түсі)'), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in _cats)
                  ChoiceChip(
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                    avatar: Icon(Cat.icon(c), size: 16, color: Cat.color(c)),
                    label: Text(Cat.label(c)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: loc('Телефон', 'Телефон'), hintText: '+7 701 000 00 00')),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : Text(_isEdit ? loc('Сохранить', 'Сақтау') : loc('Добавить', 'Қосу')),
            ),
          ],
        ),
      ),
    );
  }
}
