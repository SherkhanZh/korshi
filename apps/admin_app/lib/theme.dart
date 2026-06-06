import 'package:flutter/material.dart';

/// Korshi palette (shared visual language with the resident app).
class C {
  C._();
  static const primary = Color(0xFF1E6B4F);
  static const primaryDark = Color(0xFF15573E);
  static const scaffold = Color(0xFFF6F5F0);
  static const surface = Color(0xFFFFFFFF);
  static const muted = Color(0xFFF1F0EA);
  static const greenTint = Color(0xFFEDF2EC);
  static const ink = Color(0xFF1C1C1E);
  static const ink2 = Color(0xFF6E6E73);
  static const ink3 = Color(0xFF9A9A9F);
  static const border = Color(0xFFE6E5DF);
  static const shadow = Color(0x14000000);

  static const water = Color(0xFF3B9BE0);
  static const roads = Color(0xFF4A4A4F);
  static const lights = Color(0xFFF5B81E);
  static const garbage = Color(0xFF3FA45F);
  static const safety = Color(0xFF6C63C7);
  static const other = Color(0xFFB07A4A);

  static const danger = Color(0xFFC0492E);
  static const warn = Color(0xFFC9881C);
}

ThemeData korshiTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: C.primary, primary: C.primary),
    scaffoldBackgroundColor: C.scaffold,
    fontFamily: 'Roboto',
  );
  return base.copyWith(
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: C.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: C.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: C.primary, width: 1.5),
      ),
    ),
  );
}

/// A simple white card.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: C.shadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: card);
  }
}

/// Category visual metadata.
class Cat {
  static IconData icon(String c) => {
        'water': Icons.water_drop_rounded,
        'roads': Icons.add_road_rounded,
        'lights': Icons.lightbulb_rounded,
        'garbage': Icons.delete_rounded,
        'safety': Icons.shield_rounded,
      }[c] ??
      Icons.report_problem_rounded;

  static Color color(String c) => {
        'water': C.water,
        'roads': C.roads,
        'lights': C.lights,
        'garbage': C.garbage,
        'safety': C.safety,
      }[c] ??
      C.other;

  static String label(String c) => {
        'water': 'Вода',
        'roads': 'Дороги',
        'lights': 'Освещение',
        'garbage': 'Мусор',
        'safety': 'Безопасность',
        'other': 'Другое',
      }[c] ??
      'Другое';
}

/// Report status visuals (admin vocabulary).
class St {
  static String label(String s) => {
        'new': 'Новая',
        'waitingResponse': 'Новая',
        'inProgress': 'В работе',
        'waitingCity': 'Ожидает город',
        'resolved': 'Решено',
      }[s] ??
      s;

  static Color bg(String s) => {
        'resolved': const Color(0xFFE2F0E8),
        'inProgress': const Color(0xFFFBEFD6),
        'waitingCity': const Color(0xFFE3ECF8),
      }[s] ??
      const Color(0xFFFBE6E1);

  static Color fg(String s) => {
        'resolved': C.primary,
        'inProgress': C.warn,
        'waitingCity': const Color(0xFF3A6FB0),
      }[s] ??
      C.danger;
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, required this.bg, required this.fg});
  final String text;
  final Color bg;
  final Color fg;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
      );
}
