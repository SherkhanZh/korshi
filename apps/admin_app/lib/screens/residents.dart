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
                title: loc('Жители', 'Тұрғындар'),
                subtitle: loc('Сообщество района', 'Аудан қауымдастығы'),
                action: FilledButton.icon(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _InviteSheet(onInvited: reload),
                  ),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 12)),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: Text(loc('Пригласить', 'Шақыру')),
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
                                Text(loc('Прогресс сообщества', 'Қауымдастық прогресі'), style: const TextStyle(color: C.ink2, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text('${d.connected} ${loc('из', '/')} ${d.total}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                                Text(loc('домов подключено', 'үй қосылған'), style: const TextStyle(color: C.ink3, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text('$pct%', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: C.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('${loc('Жители', 'Тұрғындар')} (${d.residents.length})', style: const TextStyle(fontWeight: FontWeight.w700)),
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
        return Pill(loc('Активен', 'Белсенді'), bg: const Color(0xFFE2F0E8), fg: C.primary);
      case 'invited':
        return Pill(loc('Приглашён', 'Шақырылды'), bg: const Color(0xFFFBEFD6), fg: C.warn);
      default:
        return Pill(loc('Не подключён', 'Қосылмаған'), bg: C.muted, fg: C.ink2);
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
      setState(() => _error = loc('Укажите телефон и адрес', 'Телефон мен мекенжайды көрсетіңіз'));
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
            Text(loc('Пригласить жителя', 'Тұрғынды шақыру'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: _phone, enabled: _code == null, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: loc('Телефон *', 'Телефон *'), hintText: '+7 7__ ___ __ __')),
            const SizedBox(height: 12),
            TextField(controller: _address, enabled: _code == null, decoration: InputDecoration(labelText: loc('Адрес *', 'Мекенжай *'), hintText: 'ул. Абая, 27')),
            const SizedBox(height: 12),
            TextField(controller: _name, enabled: _code == null, decoration: InputDecoration(labelText: loc('Имя (необязательно)', 'Аты (міндетті емес)'))),
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
                    : Text(loc('Создать код активации', 'Белсендіру кодын жасау')),
              )
            else ...[
              Panel(
                child: Column(
                  children: [
                    Text(loc('Код активации', 'Белсендіру коды'), style: const TextStyle(color: C.ink2, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(_code!, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: 6, color: C.primary)),
                    const SizedBox(height: 4),
                    Text(loc('Код не истекает', 'Кодтың мерзімі бітпейді'), style: const TextStyle(color: C.ink3, fontSize: 12)),
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
                label: Text(loc('Отправить через WhatsApp', 'WhatsApp арқылы жіберу')),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _message));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc('Скопировано', 'Көшірілді'))));
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text(loc('Скопировать приглашение', 'Шақыруды көшіру')),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: () => Navigator.pop(context), child: Text(loc('Готово', 'Дайын'))),
            ],
          ],
        ),
      ),
    );
  }
}
