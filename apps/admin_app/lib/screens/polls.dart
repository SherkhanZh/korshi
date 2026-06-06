import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../repo.dart';
import '../theme.dart';
import '../widgets.dart';

const _pollCats = [
  ['infrastructure', 'Инфраструктура'],
  ['safety', 'Безопасность'],
  ['budget', 'Бюджет'],
  ['community', 'Сообщество'],
  ['event', 'Событие'],
];

class PollsScreen extends StatelessWidget {
  const PollsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Loader<List<AdminPoll>>(
        load: repo.polls,
        builder: (context, items, reload) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Header(
              title: 'Опросы',
              subtitle: 'Мнение жителей',
              action: FilledButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _CreatePollSheet(onCreated: reload),
                ),
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
                    const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('Опросов нет', style: TextStyle(color: C.ink3)))),
                  for (final p in items) ...[
                    _card(context, p, reload),
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

  Widget _card(BuildContext context, AdminPoll p, VoidCallback reload) {
    final total = p.totalVotes;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: p.confidential ? C.muted : C.greenTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(p.confidential ? Icons.lock_outline_rounded : Icons.public_rounded, size: 12, color: p.confidential ? C.ink2 : C.primary),
                    const SizedBox(width: 4),
                    Text(p.confidential ? 'Конфиденциально' : 'Открытый',
                        style: TextStyle(fontSize: 11, color: p.confidential ? C.ink2 : C.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: C.ink3),
                onPressed: () async {
                  final ok = await _confirm(context, 'Удалить опрос?');
                  if (ok) {
                    await repo.deletePoll(p.id);
                    reload();
                  }
                },
              ),
            ],
          ),
          Text(p.question, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 10),
          for (final o in p.options) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(o.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                Text('${total == 0 ? 0 : (o.votes * 100 / total).round()}% · ${o.votes}', style: const TextStyle(color: C.ink2, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : o.votes / total,
                minHeight: 6,
                backgroundColor: C.border,
                valueColor: const AlwaysStoppedAnimation(C.primary),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (!p.confidential && p.voters.isNotEmpty) ...[
            const Divider(height: 8),
            const SizedBox(height: 6),
            const Text('Как проголосовали:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 4),
            for (final v in p.voters)
              Text('${v.name} — ${p.options.firstWhere((o) => o.id == v.optionId, orElse: () => PollOption(0, '—', 0)).label}',
                  style: const TextStyle(color: C.ink2, fontSize: 13)),
          ],
          const SizedBox(height: 4),
          Text('${p.households} домохозяйств · до ${p.endsAt}', style: const TextStyle(color: C.ink3, fontSize: 12)),
        ],
      ),
    );
  }
}

class _CreatePollSheet extends StatefulWidget {
  const _CreatePollSheet({required this.onCreated});
  final VoidCallback onCreated;
  @override
  State<_CreatePollSheet> createState() => _CreatePollSheetState();
}

class _CreatePollSheetState extends State<_CreatePollSheet> {
  String? _category;
  final _qRu = TextEditingController();
  final _qKk = TextEditingController();
  final _optsRu = [TextEditingController(text: 'Да'), TextEditingController(text: 'Нет')];
  final _optsKk = [TextEditingController(text: 'Иә'), TextEditingController(text: 'Жоқ')];
  bool _confidential = true;
  int _duration = 7;
  bool _busy = false;

  @override
  void dispose() {
    _qRu.dispose();
    _qKk.dispose();
    for (final c in _optsRu) c.dispose();
    for (final c in _optsKk) c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final opts = _optsRu.map((c) => c.text.trim()).toList();
    if (_busy || _qRu.text.trim().isEmpty || opts.where((o) => o.isNotEmpty).length < 2) return;
    setState(() => _busy = true);
    try {
      await repo.createPoll({
        if (_category != null) 'category': _category,
        'question': _qRu.text.trim(),
        'questionKk': _qKk.text.trim().isEmpty ? _qRu.text.trim() : _qKk.text.trim(),
        'options': opts,
        'optionsKk': List.generate(opts.length, (i) => _optsKk[i].text.trim().isEmpty ? opts[i] : _optsKk[i].text.trim()),
        'durationDays': _duration,
        'audienceLabel': 'Весь район',
        'confidential': _confidential,
      });
      if (mounted) Navigator.pop(context);
      widget.onCreated();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _addOption() {
    setState(() {
      _optsRu.add(TextEditingController());
      _optsKk.add(TextEditingController());
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(color: C.scaffold, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const Text('Создать опрос', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            const Text('Категория (необязательно)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in _pollCats)
                  ChoiceChip(
                    selected: _category == c[0],
                    onSelected: (sel) => setState(() => _category = sel ? c[0] : null),
                    label: Text(c[1]),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Вопрос', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(controller: _qRu, decoration: const InputDecoration(hintText: 'Русский')),
            const SizedBox(height: 8),
            TextField(controller: _qKk, decoration: const InputDecoration(hintText: 'Қазақша')),
            const SizedBox(height: 16),
            const Text('Варианты (рус / қаз)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (int i = 0; i < _optsRu.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          TextField(controller: _optsRu[i], decoration: InputDecoration(hintText: 'Вариант ${i + 1} (рус)')),
                          const SizedBox(height: 6),
                          TextField(controller: _optsKk[i], decoration: InputDecoration(hintText: '${i + 1}-нұсқа (қаз)')),
                        ],
                      ),
                    ),
                    if (_optsRu.length > 2)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: C.ink3),
                        onPressed: () => setState(() {
                          _optsRu.removeAt(i).dispose();
                          _optsKk.removeAt(i).dispose();
                        }),
                      ),
                  ],
                ),
              ),
            TextButton.icon(onPressed: _addOption, icon: const Icon(Icons.add), label: const Text('Добавить вариант')),
            const SizedBox(height: 8),
            const Text('Видимость голосов', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _toggle('Конфиденциально', Icons.lock_outline_rounded, _confidential, () => setState(() => _confidential = true)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _toggle('Открытый', Icons.public_rounded, !_confidential, () => setState(() => _confidential = false)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Длительность', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final d in [3, 7, 14])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _toggle('$d дн.', null, _duration == d, () => setState(() => _duration = d)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : const Text('Запустить опрос'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggle(String label, IconData? icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? C.greenTint : C.surface,
          border: Border.all(color: active ? C.primary : C.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 15, color: active ? C.primary : C.ink2), const SizedBox(width: 6)],
            Text(label, style: TextStyle(color: active ? C.primary : C.ink2, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
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
