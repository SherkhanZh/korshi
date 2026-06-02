import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

String _digits(String phone) => phone.replaceAll(RegExp(r'[^0-9+]'), '');

Future<void> _launch(Uri uri, BuildContext context) async {
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) _toast(context, 'Не удалось открыть');
  } catch (_) {
    if (context.mounted) _toast(context, 'Не удалось открыть');
  }
}

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

/// Open the phone dialer for [phone].
Future<void> callNumber(BuildContext context, String phone) =>
    _launch(Uri(scheme: 'tel', path: _digits(phone)), context);

/// Open WhatsApp chat with [phone].
Future<void> openWhatsApp(BuildContext context, String phone) {
  final n = _digits(phone).replaceAll('+', '');
  return _launch(Uri.parse('https://wa.me/$n'), context);
}
