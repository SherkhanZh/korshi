import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide UI language. Changing this rebuilds MaterialApp's locale.
final ValueNotifier<Locale> appLocale = ValueNotifier<Locale>(const Locale('ru'));

const _kLocale = 'korshi_locale';

/// Restores the saved language (call at startup, before runApp).
Future<void> loadLocale() async {
  final p = await SharedPreferences.getInstance();
  final code = p.getString(_kLocale);
  if (code != null && code.isNotEmpty) appLocale.value = Locale(code);
}

/// Persists and applies a language choice.
Future<void> setLocale(String code) async {
  appLocale.value = Locale(code);
  final p = await SharedPreferences.getInstance();
  await p.setString(_kLocale, code);
}

/// Currently selected bottom-nav tab (0 Home, 1 Updates, 3 Polls, 4 Contacts).
/// Lets any screen jump to another tab.
final ValueNotifier<int> shellTab = ValueNotifier<int>(0);

/// Local path of the user's chosen profile avatar (null = default icon).
final ValueNotifier<String?> avatarPath = ValueNotifier<String?>(null);

/// Bumped whenever resident data changes (e.g. a new report submitted) so
/// open screens re-fetch instead of needing an app restart.
final ValueNotifier<int> dataVersion = ValueNotifier<int>(0);

/// Number of unread notifications — drives the red dot on the home bell.
final ValueNotifier<int> unreadNotifications = ValueNotifier<int>(0);

/// A notification target to open once the shell is ready (deep-link from a push
/// tap or from the notifications list).
class NotifTarget {
  const NotifTarget(this.type, this.id);
  final String type; // 'report' | 'announcement' | 'poll'
  final String id;
}

final ValueNotifier<NotifTarget?> pendingNav = ValueNotifier<NotifTarget?>(null);

/// Switches to the right tab and queues the detail to open (handled by MainShell).
void openNotifTarget(String type, String id) {
  shellTab.value = type == 'poll' ? 3 : 1; // poll → Polls tab, else Updates tab
  if (id.isNotEmpty) pendingNav.value = NotifTarget(type, id);
}

/// Global messenger so push notifications can surface an in-app banner while
/// the app is in the foreground (FCM doesn't show the tray notification then).
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Fallback chairman contact (used by "Contact chairman" actions).
const String kChairmanPhone = '+77010000001';

/// Picks the Kazakh text when the app is in Kazakh and a translation exists,
/// otherwise falls back to the Russian text.
String loc(String ru, String? kk) {
  if (appLocale.value.languageCode == 'kk' && kk != null && kk.isNotEmpty) return kk;
  return ru;
}
