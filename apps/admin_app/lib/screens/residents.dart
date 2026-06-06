import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../models.dart';
import '../repo.dart';
import '../theme.dart';
import '../widgets.dart';

class ResidentsScreen extends StatelessWidget {
  const ResidentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Loader<ResidentsData>(
        load: repo.residents,
        builder: (context, d, reload) {
          final pct = d.total == 0 ? 0 : (d.connected * 100 / d.total).round();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Header(
                title: 'Жители',
                subtitle: 'Сообщество района',
                action: FilledButton.icon(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _InviteSheet(onInvited: reload),
                  ),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 12)),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text('Пригласить'),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Panel(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Прогресс сообщества', style: TextStyle(color: C.ink2, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text('${d.connected} из ${d.total}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                                const Text('домов подключено', style: TextStyle(color: C.ink3, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text('$pct%', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: C.primary)),
                        ],
                      ),
                    ),
                    if (d.streets.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Обзор улиц', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      for (final s in d.streets)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Panel(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text('${s.total == 0 ? 0 : (s.connected * 100 / s.total).round()}%',
                                        style: const TextStyle(color: C.primary, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: s.total == 0 ? 0 : s.connected / s.total,
                                    minHeight: 6,
                                    backgroundColor: C.border,
                                    valueColor: const AlwaysStoppedAnimation(C.primary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 16),
                    Text('Жители (${d.residents.length})', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    for (final r in d.residents) ...[
                      _residentTile(r),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _residentTile(AdminResident r) {
    return Panel(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(radius: 20, backgroundColor: C.greenTint, child: Text(r.initials, style: const TextStyle(color: C.primary, fontWeight: FontWeight.w700, fontSize: 13))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${r.address} · ${r.phone}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.ink3, fontSize: 12)),
              ],
            ),
          ),
          if (r.inviteCode != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: C.muted, borderRadius: BorderRadius.circular(8)),
              child: Text(r.inviteCode!, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
            )
          else
            _statusBadge(r.status),
        ],
      ),
    );
  }

  Widget _statusBadge(String s) {
    switch (s) {
      case 'active':
        return const Pill('Активен', bg: Color(0xFFE2F0E8), fg: C.primary);
      case 'invited':
        return const Pill('Приглашён', bg: Color(0xFFFBEFD6), fg: C.warn);
      default:
        return const Pill('Не подключён', bg: C.muted, fg: C.ink2);
    }
  }
}

class _InviteSheet extends StatefulWidget {
  const _InviteSheet({required this.onInvited});
  final VoidCallback onInvited;
  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _name = TextEditingController();
  bool _busy = false;
  String? _code;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _address.dispose();
    _name.dispose();
    super.dispose();
  }

  String get _message =>
      'Здравствуйте!\nВас подключили к приложению района ${neighborhoodName.value ?? ''}.\n'
      'Адрес: ${_address.text.trim()}\nКод активации: ${_code ?? ''}\n'
      'Скачайте приложение и установите пароль при первом входе.';

  Future<void> _create() async {
    if (_phone.text.trim().isEmpty || _address.text.trim().isEmpty || _busy) {
      setState(() => _error = 'Укажите телефон и адрес');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final code = await repo.invite(phone: _phone.text.trim(), address: _address.text.trim(), name: _name.text.trim());
      setState(() => _code = code);
      widget.onInvited();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(color: C.scaffold, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const Text('Пригласить жителя', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: _phone, enabled: _code == null, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Телефон *', hintText: '+7 7__ ___ __ __')),
            const SizedBox(height: 12),
            TextField(controller: _address, enabled: _code == null, decoration: const InputDecoration(labelText: 'Адрес *', hintText: 'ул. Абая, 27')),
            const SizedBox(height: 12),
            TextField(controller: _name, enabled: _code == null, decoration: const InputDecoration(labelText: 'Имя (необязательно)')),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: C.danger)),
            ],
            const SizedBox(height: 16),
            if (_code == null)
              FilledButton(
                onPressed: _busy ? null : _create,
                child: _busy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                    : const Text('Создать код активации'),
              )
            else ...[
              Panel(
                child: Column(
                  children: [
                    const Text('Код активации', style: TextStyle(color: C.ink2, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(_code!, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: 6, color: C.primary)),
                    const SizedBox(height: 4),
                    const Text('Код не истекает', style: TextStyle(color: C.ink3, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(_message)}');
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                icon: const Icon(Icons.chat_rounded, size: 18),
                label: const Text('Отправить через WhatsApp'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _message));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Скопировано')));
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Скопировать приглашение'),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Готово')),
            ],
          ],
        ),
      ),
    );
  }
}
