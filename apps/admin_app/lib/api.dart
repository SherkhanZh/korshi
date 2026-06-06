import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Override with: flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://188.244.115.167/api',
  );
}

// ── session (admin JWT + identity) ──
final ValueNotifier<String?> adminToken = ValueNotifier<String?>(null);
final ValueNotifier<String?> adminEmail = ValueNotifier<String?>(null);
final ValueNotifier<String?> adminRole = ValueNotifier<String?>(null); // 'admin' | 'super'
final ValueNotifier<String?> neighborhoodName = ValueNotifier<String?>(null);
String? neighborhoodId;

/// Selected bottom-nav tab — lets a push tap jump to a screen.
final ValueNotifier<int> selectedTab = ValueNotifier<int>(0);

/// Section to auto-open from the dashboard (e.g. after a push tap).
/// 0 none · 1 reports · 2 announcements · 3 polls.
final ValueNotifier<int> pendingOpenSection = ValueNotifier<int>(0);

// ── UI language ('ru' | 'kk') ──
final ValueNotifier<String> adminLocale = ValueNotifier<String>('ru');

Future<void> loadLocale() async {
  final p = await SharedPreferences.getInstance();
  final code = p.getString('locale');
  if (code != null && code.isNotEmpty) adminLocale.value = code;
}

Future<void> setLocale(String code) async {
  adminLocale.value = code;
  final p = await SharedPreferences.getInstance();
  await p.setString('locale', code);
}

/// Picks Kazakh when the app is in Kazakh and a translation exists, else Russian.
String loc(String ru, [String? kk]) =>
    (adminLocale.value == 'kk' && kk != null && kk.isNotEmpty) ? kk : ru;

bool get isLoggedIn => adminToken.value != null;

Future<void> loadSession() async {
  final p = await SharedPreferences.getInstance();
  adminToken.value = p.getString('token');
  adminEmail.value = p.getString('email');
  adminRole.value = p.getString('role');
  neighborhoodName.value = p.getString('nbhd');
  neighborhoodId = p.getString('nid');
}

Future<void> saveSession({
  required String token,
  required String email,
  required String role,
  String? nbhd,
  String? nid,
}) async {
  final p = await SharedPreferences.getInstance();
  await p.setString('token', token);
  await p.setString('email', email);
  await p.setString('role', role);
  if (nbhd != null) await p.setString('nbhd', nbhd);
  if (nid != null) await p.setString('nid', nid);
  adminToken.value = token;
  adminEmail.value = email;
  adminRole.value = role;
  neighborhoodName.value = nbhd;
  neighborhoodId = nid;
}

Future<void> clearSession() async {
  final p = await SharedPreferences.getInstance();
  final locale = p.getString('locale');
  await p.clear();
  if (locale != null) await p.setString('locale', locale); // keep language choice
  adminToken.value = null;
  adminEmail.value = null;
  adminRole.value = null;
  neighborhoodName.value = null;
  neighborhoodId = null;
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class Api {
  Api({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const _timeout = Duration(seconds: 15);

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, String> _headers({bool json = false}) {
    final h = <String, String>{'Accept': 'application/json'};
    if (json) h['Content-Type'] = 'application/json';
    final t = adminToken.value;
    if (t != null) h['Authorization'] = 'Bearer $t';
    return h;
  }

  Never _fail(http.Response res, String method, String path) {
    var msg = 'Ошибка $method $path → ${res.statusCode}';
    try {
      final b = jsonDecode(utf8.decode(res.bodyBytes));
      if (b is Map && b['error'] is String) msg = b['error'] as String;
    } catch (_) {}
    throw ApiException(msg, statusCode: res.statusCode);
  }

  Future<dynamic> get(String path) async {
    final http.Response res;
    try {
      res = await _client.get(_uri(path), headers: _headers()).timeout(_timeout);
    } catch (_) {
      throw ApiException('Нет связи с сервером', statusCode: 0);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    _fail(res, 'GET', path);
  }

  Future<dynamic> send(String method, String path, [Map<String, dynamic>? body]) async {
    final http.Response res;
    try {
      final req = http.Request(method, _uri(path));
      req.headers.addAll(_headers(json: true));
      if (body != null) req.body = jsonEncode(body);
      final streamed = await _client.send(req).timeout(_timeout);
      res = await http.Response.fromStream(streamed);
    } catch (_) {
      throw ApiException('Нет связи с сервером', statusCode: 0);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.bodyBytes.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
    }
    _fail(res, method, path);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) => send('POST', path, body);
  Future<dynamic> patch(String path, Map<String, dynamic> body) => send('PATCH', path, body);
  Future<dynamic> delete(String path) => send('DELETE', path);

  /// Multipart upload (cover image).
  Future<void> uploadCover(String filePath) async {
    final req = http.MultipartRequest('POST', _uri('/neighborhood/cover'));
    req.headers.addAll(_headers());
    req.files.add(await http.MultipartFile.fromPath('image', filePath));
    final streamed = await req.send().timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res, 'POST', '/neighborhood/cover');
  }
}

final api = Api();
