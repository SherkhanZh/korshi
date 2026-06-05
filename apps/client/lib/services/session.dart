import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Resident auth session. The JWT is sent with every authenticated request and
/// persisted so the resident stays logged in across app launches.
final ValueNotifier<String?> authToken = ValueNotifier<String?>(null);
final ValueNotifier<String?> residentName = ValueNotifier<String?>(null);

/// The resident's neighborhood — used to scope the cover image and shown in UI.
final ValueNotifier<String?> neighborhoodName = ValueNotifier<String?>(null);
String? neighborhoodId;

/// Phone the resident typed on the welcome screen — kept in memory only,
/// used to complete login on the next onboarding step.
String? pendingPhone;

const _kToken = 'korshi_token';
const _kName = 'korshi_name';
const _kNid = 'korshi_nid';
const _kNbhd = 'korshi_nbhd';

bool get isLoggedIn => authToken.value != null;

Future<void> loadSession() async {
  final p = await SharedPreferences.getInstance();
  authToken.value = p.getString(_kToken);
  residentName.value = p.getString(_kName);
  neighborhoodId = p.getString(_kNid);
  neighborhoodName.value = p.getString(_kNbhd);
}

Future<void> saveSession(
  String token,
  String? name, {
  String? nid,
  String? nbhd,
}) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(_kToken, token);
  if (name != null && name.isNotEmpty) await p.setString(_kName, name);
  if (nid != null) await p.setString(_kNid, nid);
  if (nbhd != null) await p.setString(_kNbhd, nbhd);
  authToken.value = token;
  residentName.value = name;
  neighborhoodId = nid;
  neighborhoodName.value = nbhd;
}

Future<void> clearSession() async {
  final p = await SharedPreferences.getInstance();
  await p.remove(_kToken);
  await p.remove(_kName);
  await p.remove(_kNid);
  await p.remove(_kNbhd);
  authToken.value = null;
  residentName.value = null;
  neighborhoodId = null;
  neighborhoodName.value = null;
  pendingPhone = null;
}
