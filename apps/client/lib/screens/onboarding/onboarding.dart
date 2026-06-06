import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../services/api_client.dart';
import '../../services/push.dart';
import '../../services/repository.dart';
import '../../services/session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../main_shell.dart';

// ─────────────────────────────────────────────────────────────────────────
// Onboarding / login flow (live resident auth).
//   Welcome (phone) → Invite code/password → Secure access → Connected → MainShell
// ─────────────────────────────────────────────────────────────────────────

const _phoneStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
  color: AppColors.textPrimary,
);

/// Fixed bottom action bar so the primary button sits at the screen bottom.
Widget _bottomBar(Widget button) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: button,
      ),
    );

Widget _headerImage(BuildContext context, {double height = 300, bool showBack = false}) {
  return SizedBox(
    height: height,
    width: double.infinity,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/login.png', fit: BoxFit.cover),
        // Fade into the white sheet.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors: [Color(0x00F6F5F0), AppColors.scaffold],
              stops: [0.55, 1.0],
            ),
          ),
        ),
        if (showBack)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
            ),
          ),
      ],
    ),
  );
}

// ─── 1. Welcome (phone) ───
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _continue() {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc('Введите номер телефона', 'Телефон нөмірін енгізіңіз'))),
      );
      return;
    }
    pendingPhone = '+7$digits';
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InviteCodeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _headerImage(context, height: 300),
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                children: [
                  Text(loc('Добро пожаловать\nв ваш район', 'Ауданыңызға\nқош келдіңіз'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontFamily: AppTheme.displayFont,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontSize: 34,
                          height: 1.08)),
                  const SizedBox(height: 10),
                  Text(loc('Введите номер телефона, чтобы продолжить',
                          'Жалғастыру үшін телефон нөмірін енгізіңіз'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                              loc('Доступ предоставляет председатель района',
                                  'Қолжетімділікті аудан төрағасы береді'),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text('🇰🇿', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 6),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        const Text('+7', style: _phoneStyle),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            style: _phoneStyle,
                            onSubmitted: (_) => _continue(),
                            decoration: InputDecoration.collapsed(
                              hintText: '(___) ___ __ __',
                              hintStyle:
                                  _phoneStyle.copyWith(color: AppColors.textTertiary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
            ),
          ),
          _bottomBar(FilledButton(
            onPressed: _continue,
            child: Text(loc('Продолжить', 'Жалғастыру')),
          )),
        ],
      ),
    );
  }
}

// ─── 2. Invite code ───
class InviteCodeScreen extends StatefulWidget {
  const InviteCodeScreen({super.key});

  @override
  State<InviteCodeScreen> createState() => _InviteCodeScreenState();
}

class _InviteCodeScreenState extends State<InviteCodeScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final secret = _code.text.trim();
    if (secret.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc('Введите код или пароль', 'Кодты немесе құпиясөзді енгізіңіз'))),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final hasPassword = await repository.residentLogin(phone: pendingPhone ?? '', secret: secret);
      PushService.registerIfPossible(); // register this device for push
      if (!mounted) return;
      if (hasPassword) {
        // Returning resident — go straight in, no password step.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      } else {
        // First-time resident — let them set a password.
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SecureAccessScreen()),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _headerImage(context, height: 230, showBack: true),
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded,
                            color: AppColors.primary, size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc('Номер подтверждён', 'Нөмір расталды'),
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              Text(pendingPhone ?? '—',
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18)),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.primary, size: 22),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(loc('Введите код или пароль', 'Кодты немесе құпиясөзді енгізіңіз'),
                      style: const TextStyle(
                          fontFamily: AppTheme.displayFont,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontSize: 30)),
                  const SizedBox(height: 8),
                  Text(
                      loc('Введите одноразовый код приглашения от председателя или свой пароль, если уже задавали его.',
                          'Төрағадан алған біржолғы шақыру кодын немесе бұрын орнатқан құпиясөзіңізді енгізіңіз.'),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.vpn_key_rounded,
                            color: AppColors.primary, size: 24),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc('Код или пароль', 'Код немесе құпиясөз'),
                                  style: const TextStyle(
                                      color: AppColors.textTertiary, fontSize: 13)),
                              const SizedBox(height: 2),
                              TextField(
                                controller: _code,
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20),
                                decoration: InputDecoration.collapsed(
                                  hintText: loc('Введите код или пароль', 'Кодты немесе құпиясөзді енгізіңіз'),
                                  hintStyle: const TextStyle(
                                      color: AppColors.textTertiary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.surfaceGreenTint,
                          child: Icon(Icons.home_rounded, color: AppColors.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.location_on_rounded,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(residentAddress ?? loc('Ваш адрес', 'Сіздің мекенжайыңыз'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                ),
                              ]),
                              const SizedBox(height: 2),
                              Row(children: [
                                const Icon(Icons.home_outlined, size: 16, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(neighborhoodName.value ?? loc('Ваш район', 'Сіздің ауданыңыз'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                ),
                              ]),
                              const SizedBox(height: 4),
                              Text(loc('Это приглашение создано для вашего адреса',
                                      'Бұл шақыру сіздің мекенжайыңызға жасалған'),
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
            ),
          ),
          _bottomBar(FilledButton(
            onPressed: _busy ? null : _login,
            child: _busy
                ? const SizedBox(
                    height: 22, width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : Text(loc('Продолжить', 'Жалғастыру')),
          )),
        ],
      ),
    );
  }
}

// ─── 3. Secure access ───
class SecureAccessScreen extends StatefulWidget {
  const SecureAccessScreen({super.key});

  @override
  State<SecureAccessScreen> createState() => _SecureAccessScreenState();
}

class _SecureAccessScreenState extends State<SecureAccessScreen> {
  final _pw1 = TextEditingController();
  final _pw2 = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _busy = false;

  @override
  void dispose() {
    _pw1.dispose();
    _pw2.dispose();
    super.dispose();
  }

  void _toConnected() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ConnectedScreen()),
    );
  }

  Future<void> _activate() async {
    final pw = _pw1.text;
    // Password is optional — the invite code keeps working as a password.
    if (pw.isEmpty) {
      _toConnected();
      return;
    }
    if (pw.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc('Пароль должен быть не короче 4 символов',
            'Құпиясөз кемінде 4 таңбадан болуы керек'))),
      );
      return;
    }
    if (pw != _pw2.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc('Пароли не совпадают', 'Құпиясөздер сәйкес келмейді'))),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await repository.setPassword(pw);
      if (mounted) _toConnected();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _headerImage(context, height: 210, showBack: true),
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                children: [
                  Text(loc('Шаг 3 из 4', '4-тен 3-қадам'),
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  _stepper(),
                  const SizedBox(height: 12),
                  Text(loc('Защитите доступ', 'Қолжетімділікті қорғаңыз'),
                      style: const TextStyle(
                          fontFamily: AppTheme.displayFont,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontSize: 32)),
                  const SizedBox(height: 6),
                  Text(loc('Создайте пароль для входа', 'Кіру үшін құпиясөз жасаңыз'),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                  const SizedBox(height: 20),
                  _passwordField(_pw1, loc('Пароль', 'Құпиясөз'),
                      loc('Введите пароль', 'Құпиясөзді енгізіңіз'), _obscure1,
                      () => setState(() => _obscure1 = !_obscure1)),
                  const SizedBox(height: 12),
                  _passwordField(_pw2, loc('Повторите пароль', 'Құпиясөзді қайталаңыз'),
                      loc('Введите пароль ещё раз', 'Құпиясөзді қайта енгізіңіз'), _obscure2,
                      () => setState(() => _obscure2 = !_obscure2)),
                  const SizedBox(height: 10),
                  Text(
                      loc('Пароль можно не задавать — код приглашения продолжит работать как пароль.',
                          'Құпиясөзді орнатпауға болады — шақыру коды құпиясөз ретінде жұмыс істей береді.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
            ),
          ),
          _bottomBar(FilledButton.icon(
            onPressed: _busy ? null : _activate,
            icon: _busy
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : const Icon(Icons.shield_rounded, size: 20),
            label: Text(loc('Активировать доступ', 'Қолжетімділікті іске қосу')),
          )),
        ],
      ),
    );
  }

  Widget _stepper() {
    Widget node(String label, {bool done = false, bool current = false}) {
      final filled = done || current;
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.border,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: done
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
            : Text(label,
                style: TextStyle(
                    color: current ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
      );
    }

    Widget bar(bool active) =>
        Expanded(child: Container(height: 3, color: active ? AppColors.primary : AppColors.border));

    return Row(
      children: [
        node('1', done: true),
        bar(true),
        node('2', done: true),
        bar(true),
        node('3', current: true),
        bar(false),
        node('4'),
      ],
    );
  }

  Widget _passwordField(
      TextEditingController controller, String label, String hint, bool obscure, VoidCallback toggle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                TextField(
                  controller: controller,
                  obscureText: obscure,
                  decoration: InputDecoration.collapsed(hintText: hint),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: toggle,
            child: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ─── 4. Connected ───
class ConnectedScreen extends StatelessWidget {
  const ConnectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      (Icons.description_rounded, loc('Новости района', 'Аудан жаңалықтары'),
          loc('Будьте в курсе важных событий', 'Маңызды оқиғалардан хабардар болыңыз')),
      (Icons.build_rounded, loc('Заявки', 'Өтініштер'),
          loc('Сообщайте о проблемах района', 'Аудан мәселелері туралы хабарлаңыз')),
      (Icons.groups_rounded, loc('Опросы', 'Сауалнамалар'),
          loc('Голосуйте и делитесь мнением', 'Дауыс беріп, пікір білдіріңіз')),
      (Icons.call_rounded, loc('Контакты', 'Байланыстар'),
          loc('Председатель и полезные службы', 'Төраға және пайдалы қызметтер')),
    ];
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _headerImage(context, height: 190),
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGreenTint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.home_rounded, color: AppColors.primary, size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc('Успешно подключено', 'Сәтті қосылды'),
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                              Text(loc('Вы теперь часть сообщества района.',
                                      'Енді сіз аудан қауымдастығының бөлігісіз.'),
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.check_rounded, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                      '${loc('Добро пожаловать в', 'Қош келдіңіз')}\n${neighborhoodName.value ?? loc('ваш район', 'ауданыңыз')}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontFamily: AppTheme.displayFont,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontSize: 28,
                          height: 1.3)),
                  const SizedBox(height: 12),
                  Text(loc('Вы подключены к приватному сообществу района',
                          'Сіз ауданның жабық қауымдастығына қосылдыңыз'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      for (final f in features)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                  color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.surfaceGreenTint,
                                child: Icon(f.$1, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(height: 8),
                              Text(f.$2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(f.$3,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
            ),
          ),
          _bottomBar(FilledButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainShell()),
              (route) => false,
            ),
            child: Text(loc('Перейти в район  →', 'Ауданға өту  →')),
          )),
        ],
      ),
    );
  }
}
