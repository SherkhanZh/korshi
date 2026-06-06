import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../repo.dart';
import '../theme.dart';
import '../widgets.dart';

const _contractors = ['Energo Service LLP', 'Water Pro KZ', 'Road Master', 'Clean City', 'Security Plus'];
const _tabs = [
  ['all', 'Все'],
  ['new', 'Новые'],
  ['inProgress', 'В работе'],
  ['waitingCity', 'Ожидает город'],
  ['resolved', 'Решено'],
];
const _quickUpdates = [
  ['Осмотрено', 'inProgress'],
  ['Ремонт запланирован', 'inProgress'],
  ['Ожидает город', 'waitingCity'],
  ['Назначен подрядчик', 'inProgress'],
  ['Решено', 'resolved'],
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
          const Header(title: 'Заявки', subtitle: 'Обращения жителей района'),
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
                            _chip(t[1], '${counts[t[0]] ?? 0}', _tab == t[0], () => setState(() => _tab = t[0])),
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
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: Text('Заявок нет', style: TextStyle(color: C.ink3))),
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
  bool _assigning = false;

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
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    height: 80, alignment: Alignment.center, color: C.muted,
                    child: const Text('Не удалось загрузить фото', style: TextStyle(color: C.ink3)),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 18),
            const Text('Сообщение жителю', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _reply,
              minLines: 2,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Ответ появится в истории заявки у жителя…'),
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
                label: const Text('Отправить'),
              ),
            ),

            const SizedBox(height: 18),
            const Text('Сменить статус', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final u in _quickUpdates)
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                              await repo.patchReport(r.id, status: u[1]);
                              return repo.addReportUpdate(r.id, u[0]);
                            }),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: C.ink2,
                      side: const BorderSide(color: C.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    child: Text(u[0]),
                  ),
              ],
            ),

            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => setState(() => _assigning = !_assigning),
              icon: const Icon(Icons.engineering_rounded, size: 18),
              label: Text(r.contractor != null ? 'Сменить подрядчика' : 'Назначить подрядчика'),
            ),
            if (r.contractor != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Подрядчик: ${r.contractor}', style: const TextStyle(color: C.ink2)),
              ),
            if (_assigning) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in _contractors)
                    ActionChip(
                      label: Text(c),
                      onPressed: _busy
                          ? null
                          : () async {
                              setState(() => _assigning = false);
                              await _run(() async {
                                await repo.patchReport(r.id, contractor: c);
                                return repo.addReportUpdate(r.id, 'Назначен подрядчик: $c');
                              });
                            },
                    ),
                ],
              ),
            ],

            const SizedBox(height: 18),
            const Text('Внутренняя заметка (только для администрации)', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              onEditingComplete: () => _run(() => repo.patchReport(r.id, internalNote: _note.text)),
              decoration: const InputDecoration(hintText: 'Например: ждём доступности подрядчика…'),
            ),

            const SizedBox(height: 8),
            if (r.updates.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('История', style: TextStyle(fontWeight: FontWeight.w700)),
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
              label: const Text('Отметить решённой'),
            ),
          ],
        ),
      ),
    );
  }
}
