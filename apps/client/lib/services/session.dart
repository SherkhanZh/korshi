import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Resident auth session. The JWT is sent with every authenticated request and
/// persisted so the resident stays logged in across app launches.
final ValueNotifier<String?> authToken = ValueNotifier<String?>(null);
final ValueNotifier<String?> residentName = ValueNotifier<String?>(null);

/// Phone the resident typed on the welcome screen — kept in memory only,
/// used to complete login on the next onboarding step.
String? pendingPhone;

const _kToken = 'korshi_token';
const _kName = 'korshi_name';

bool get isLoggedIn => authToken.value != null;

Future<void> loadSession() async {
  final p = await SharedPreferences.getInstance();
  authToken.value = p.getString(_kToken);
  residentName.value = p.getString(_kName);
}

Future<void> saveSession(String token, String? name) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(_kToken, token);
  if (name != null && name.isNotEmpty) await p.setString(_kName, name);
  authToken.value = token;
  residentName.value = name;
}

Future<void> clearSession() async {
  final p = await SharedPreferences.getInstance();
  await p.remove(_kToken);
  await p.remove(_kName);
  authToken.value = null;
  residentName.value = null;
  pendingPhone = null;
}
