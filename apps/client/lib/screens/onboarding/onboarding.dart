import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../main_shell.dart';

// ─────────────────────────────────────────────────────────────────────────
// Mock onboarding / login flow (no real auth yet — visual only).
//   Welcome (phone) → Invite code → Secure access → Connected → MainShell
// ─────────────────────────────────────────────────────────────────────────

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

Widget _chairmanFooter(BuildContext context, String question) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
          child: const Icon(Icons.headset_mic_rounded, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(question, style: AppTheme.body),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Связаться с председателем',
                      style: TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w700)),
                  Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 18),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ─── 1. Welcome (phone) ───
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _headerImage(context, height: 300),
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  const Text('Добро пожаловать\nв ваш район',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: AppTheme.displayFont,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontSize: 34,
                          height: 1.08)),
                  const SizedBox(height: 10),
                  const Text('Введите номер телефона, чтобы продолжить',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text('Доступ предоставляет председатель района',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
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
                        const Text('🇰🇿', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 6),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        const Text('+7',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration.collapsed(
                              hintText: '(___) ___ __ __',
                              hintStyle: TextStyle(
                                  fontSize: 20, color: AppColors.textTertiary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const InviteCodeScreen()),
                    ),
                    child: const Text('Продолжить'),
                  ),
                  const SizedBox(height: 24),
                  _chairmanFooter(context, 'Не получается войти в район?'),
                ],
              ),
            ),
          ),
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
  final _code = TextEditingController(text: 'AB12-48');

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _headerImage(context, height: 230, showBack: true),
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
                            children: const [
                              Text('Номер подтверждён',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              Text('+7 777 123 45 67',
                                  style: TextStyle(
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
                  const Text('Введите код приглашения',
                      style: TextStyle(
                          fontFamily: AppTheme.displayFont,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontSize: 30)),
                  const SizedBox(height: 8),
                  const Text('Председатель района отправил вам код приглашения',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
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
                        const Icon(Icons.confirmation_number_outlined,
                            color: AppColors.primary, size: 26),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Введите код приглашения',
                                  style: TextStyle(
                                      color: AppColors.textTertiary, fontSize: 13)),
                              TextField(
                                controller: _code,
                                textCapitalization: TextCapitalization.characters,
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 28,
                                    letterSpacing: 2),
                                decoration: const InputDecoration.collapsed(
                                  hintText: 'AB12-48',
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
                            children: const [
                              Row(children: [
                                Icon(Icons.location_on_rounded,
                                    size: 16, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text('Abay St. 27',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                              ]),
                              SizedBox(height: 2),
                              Row(children: [
                                Icon(Icons.home_outlined, size: 16, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text('Kok-Tobe Neighborhood',
                                    style: TextStyle(fontWeight: FontWeight.w600)),
                              ]),
                              SizedBox(height: 4),
                              Text('Это приглашение создано для вашего адреса',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SecureAccessScreen()),
                    ),
                    child: const Text('Продолжить'),
                  ),
                  const SizedBox(height: 20),
                  _chairmanFooter(context, 'Не получили код приглашения?'),
                ],
              ),
            ),
          ),
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
  bool _faceId = true;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _headerImage(context, height: 210, showBack: true),
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  const Text('Шаг 3 из 4',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  _stepper(),
                  const SizedBox(height: 12),
                  const Text('Защитите доступ',
                      style: TextStyle(
                          fontFamily: AppTheme.displayFont,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontSize: 32)),
                  const SizedBox(height: 6),
                  const Text('Создайте пароль для входа',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                  const SizedBox(height: 20),
                  _passwordField('Пароль', 'Введите пароль', _obscure1,
                      () => setState(() => _obscure1 = !_obscure1)),
                  const SizedBox(height: 12),
                  _passwordField('Повторите пароль', 'Введите пароль ещё раз', _obscure2,
                      () => setState(() => _obscure2 = !_obscure2)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGreenTint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_rounded, color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Ваш доступ приватен и защищён',
                                  style: TextStyle(
                                      color: AppColors.primary, fontWeight: FontWeight.w700)),
                              Text('Присоединиться могут только жители района.',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
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
                        const Icon(Icons.face_retouching_natural_rounded,
                            color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Включить Face ID',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              Text('Для быстрого и удобного входа',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _faceId,
                          activeColor: Colors.white,
                          activeTrackColor: AppColors.primary,
                          onChanged: (v) => setState(() => _faceId = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ConnectedScreen()),
                    ),
                    icon: const Icon(Icons.shield_rounded, size: 20),
                    label: const Text('Активировать доступ'),
                  ),
                  const SizedBox(height: 20),
                  _chairmanFooter(context, 'Нужна помощь со входом?'),
                ],
              ),
            ),
          ),
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

  Widget _passwordField(String label, String hint, bool obscure, VoidCallback toggle) {
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
      (Icons.description_rounded, 'Новости района', 'Будьте в курсе важных событий'),
      (Icons.build_rounded, 'Заявки', 'Сообщайте о проблемах района'),
      (Icons.groups_rounded, 'Опросы', 'Голосуйте и делитесь мнением'),
      (Icons.call_rounded, 'Контакты', 'Председатель и полезные службы'),
    ];
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _headerImage(context, height: 250),
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
                            children: const [
                              Text('Успешно подключено',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                              Text('Вы теперь часть сообщества района.',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
                  const SizedBox(height: 20),
                  const Text('Добро пожаловать в\nKok-Tobe Neighborhood',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: AppTheme.displayFont,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontSize: 28,
                          height: 1.1)),
                  const SizedBox(height: 8),
                  const Text('Вы подключены к приватному сообществу района',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.45,
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
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MainShell()),
                      (route) => false,
                    ),
                    child: const Text('Перейти в район  →'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
