import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../repo.dart';
import '../theme.dart';
import '../widgets.dart';

// [key, ru, kk]
const _tabs = [
  ['all', 'Все', 'Барлығы'],
  ['new', 'Новые', 'Жаңа'],
  ['inProgress', 'В работе', 'Жұмыста'],
  ['waitingCity', 'Ожидает город', 'Қаланы күтуде'],
  ['resolved', 'Решено', 'Шешілді'],
];
// [ru-label (stored in history), status, kk-label]
const _quickUpdates = [
  ['Осмотрено', 'inProgress', 'Қаралды'],
  ['Ремонт запланирован', 'inProgress', 'Жөндеу жоспарланды'],
  ['Ожидает город', 'waitingCity', 'Қаланы күтуде'],
  ['Назначен подрядчик', 'inProgress', 'Мердігер тағайындалды'],
  ['Решено', 'resolved', 'Шешілді'],
];

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _tab = 'all';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Header(title: loc('Заявки', 'Өтініштер'), subtitle: loc('Обращения жителей района', 'Аудан тұрғындарының өтініштері')),
          Expanded(
            child: Loader<List<AdminReport>>(
              load: repo.reports,
              builder: (context, reports, reload) {
                final counts = <String, int>{'all': reports.length};
                for (final r in reports) {
                  final t = AdminReport.toTab(r.status);
                  counts[t] = (counts[t] ?? 0) + 1;
                }
                final items = _tab == 'all'
                    ? reports
                    : reports.where((r) => AdminReport.toTab(r.status) == _tab).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          for (final t in _tabs) ...[
                            _chip(loc(t[1], t[2]), '${counts[t[0]] ?? 0}', _tab == t[0], () => setState(() => _tab = t[0])),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          if (items.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: Text(loc('Заявок нет', 'Өтініштер жоқ'), style: const TextStyle(color: C.ink3))),
                            ),
                          for (final r in items) ...[
                            _card(context, r, reload),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String count, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? C.primary : C.muted,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: active ? Colors.white : C.ink2, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: active ? Colors.white24 : C.surface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(count, style: TextStyle(color: active ? Colors.white : C.ink2, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, AdminReport r, VoidCallback reload) {
    return Panel(
      onTap: () => _openDetail(context, r, reload),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: Cat.color(r.category).withOpacity(0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(Cat.icon(r.category), color: Cat.color(r.category)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(Cat.label(r.category), style: TextStyle(color: Cat.color(r.category), fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Pill(St.label(r.status), bg: St.bg(r.status), fg: St.fg(r.status)),
                    if (r.hasPhoto) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.photo_rounded, size: 14, color: C.ink3),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${r.location} · ${r.resident}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.ink3, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: C.ink3),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, AdminReport report, VoidCallback reload) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportDetailSheet(report: report, onChanged: reload),
    );
  }
}

class _ReportDetailSheet extends StatefulWidget {
  const _ReportDetailSheet({required this.report, required this.onChanged});
  final AdminReport report;
  final VoidCallback onChanged;
  @override
  State<_ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends State<_ReportDetailSheet> {
  late AdminReport r = widget.report;
  final _reply = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;
  // A quick-status selected but not yet confirmed: [label, status].
  List<String>? _staged;

  @override
  void initState() {
    super.initState();
    _note.text = r.internalNote ?? '';
  }

  @override
  void dispose() {
    _reply.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _run(Future<AdminReport> Function() action) async {
    setState(() => _busy = true);
    try {
      final updated = await action();
      setState(() => r = updated);
      widget.onChanged();
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
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: C.scaffold,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: Cat.color(r.category).withOpacity(0.14), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Cat.icon(r.category), color: Cat.color(r.category)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('${r.location} · ${r.resident}', style: const TextStyle(color: C.ink2, fontSize: 13)),
                      Text(r.dateTime, style: const TextStyle(color: C.ink3, fontSize: 12)),
                    ],
                  ),
                ),
                Pill(St.label(r.status), bg: St.bg(r.status), fg: St.fg(r.status)),
              ],
            ),
            if (r.description.isNotEmpty) ...[
              const SizedBox(height: 14),
              Panel(child: Text(r.description, style: const TextStyle(height: 1.4))),
            ],
            if (r.hasPhoto) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  repo.reportPhotoUrl(r.id),
                  headers: adminToken.value != null
                      ? {'Authorization': 'Bearer ${adminToken.value}'}
                      : null,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    height: 80, alignment: Alignment.center, color: C.muted,
                    child: Text(loc('Не удалось загрузить фото', 'Фотоны жүктеу мүмкін болмады'), style: const TextStyle(color: C.ink3)),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 18),
            Text(loc('Сообщение жителю', 'Тұрғынға хабарлама'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _reply,
              minLines: 2,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: loc('Ответ появится в истории заявки у жителя…', 'Жауап тұрғынның өтініш тарихында көрінеді…')),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _busy || _reply.text.trim().isEmpty
                    ? null
                    : () async {
                        final text = _reply.text.trim();
                        await _run(() => repo.addReportUpdate(r.id, text));
                        _reply.clear();
                      },
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(loc('Отправить', 'Жіберу')),
              ),
            ),

            const SizedBox(height: 18),
            Text(loc('Выберите новый статус', 'Жаңа статусты таңдаңыз'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final u in _quickUpdates)
                  Builder(builder: (_) {
                    final active = _staged != null && _staged![0] == u[0];
                    return OutlinedButton(
                      onPressed: _busy ? null : () => setState(() => _staged = active ? null : u),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: active ? C.primary : C.ink2,
                        backgroundColor: active ? C.greenTint : null,
                        side: BorderSide(color: active ? C.primary : C.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: Text(loc(u[0], u[2])),
                    );
                  }),
              ],
            ),
            if (_staged != null) ...[
              const SizedBox(height: 8),
              Text(loc('Изменение применится после нажатия «Подтвердить».', '«Растау» батырмасын басқаннан кейін өзгеріс қолданылады.'),
                  style: const TextStyle(color: C.ink3, fontSize: 12)),
            ],
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _busy || _staged == null
                  ? null
                  : () => _run(() async {
                        final u = _staged!;
                        await repo.patchReport(r.id, status: u[1]);
                        final res = await repo.addReportUpdate(r.id, u[0]);
                        if (mounted) setState(() => _staged = null);
                        return res;
                      }),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(loc('Подтвердить', 'Растау')),
            ),

            const SizedBox(height: 18),
            Text(loc('Внутренняя заметка (только для администрации)', 'Ішкі ескертпе (тек әкімшілікке)'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              onEditingComplete: () => _run(() => repo.patchReport(r.id, internalNote: _note.text)),
              decoration: InputDecoration(hintText: loc('Например: ждём доступности подрядчика…', 'Мысалы: мердігердің босауын күтудеміз…')),
            ),

            const SizedBox(height: 8),
            if (r.updates.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(loc('История', 'Тарих'), style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final u in r.updates)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Panel(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 56, child: Text(u.date, style: const TextStyle(color: C.primary, fontWeight: FontWeight.w600, fontSize: 12))),
                        Expanded(child: Text(u.body)),
                      ],
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy || r.status == 'resolved'
                  ? null
                  : () => _run(() async {
                        await repo.patchReport(r.id, status: 'resolved');
                        return repo.addReportUpdate(r.id, 'Заявка решена');
                      }),
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: Text(loc('Отметить решённой', 'Шешілді деп белгілеу')),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      final ok = await _confirmDelete(context,
                          loc('Удалить заявку (спам)? Действие необратимо.', 'Өтінішті жою (спам)? Әрекет қайтарылмайды.'));
                      if (!ok) return;
                      setState(() => _busy = true);
                      try {
                        await repo.deleteReport(r.id);
                        widget.onChanged();
                        if (mounted) Navigator.pop(context);
                      } on ApiException catch (e) {
                        if (mounted) {
                          setState(() => _busy = false);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                        }
                      }
                    },
              style: TextButton.styleFrom(foregroundColor: C.danger),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text(loc('Удалить заявку (спам)', 'Өтінішті жою (спам)')),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _confirmDelete(BuildContext context, String message) async {
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
