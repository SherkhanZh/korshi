import 'dart:convert';
import 'package:http/http.dart' as http;

import 'session.dart';

/// API configuration. Override the base URL at build/run time with:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://korshiapp.kz/api',
  );

  /// Set once per app launch so the cover image is re-fetched on each start
  /// instead of being served from Flutter's stale image cache.
  static final int _launch = DateTime.now().millisecondsSinceEpoch;

  /// Neighborhood cover image (uploaded from the admin panel), scoped to the
  /// logged-in resident's neighborhood.
  static String get coverUrl =>
      '$baseUrl/neighborhood/cover?nid=${neighborhoodId ?? ''}&v=$_launch';
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'ApiException: $message';
}

/// Thin HTTP client over the Korshi API. Attaches the resident JWT when present.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;
  static const _timeout = Duration(seconds: 12);

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Map<String, String> _headers({bool json = false}) {
    final h = <String, String>{'Accept': 'application/json'};
    if (json) h['Content-Type'] = 'application/json';
    final t = authToken.value;
    if (t != null) h['Authorization'] = 'Bearer $t';
    return h;
  }

  /// Pulls the server's `{ "error": "..." }` message out of a failed response.
  Never _fail(http.Response res, String method, String path) {
    // Expired/invalid session on an authenticated request: clear it so the app
    // returns to onboarding (main.dart watches authToken).
    if (res.statusCode == 401 && authToken.value != null) {
      clearSession();
      throw ApiException('Сессия истекла. Войдите снова.', statusCode: 401);
    }
    String msg = 'Ошибка $method $path → ${res.statusCode}';
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body is Map && body['error'] is String) msg = body['error'] as String;
    } catch (_) {}
    throw ApiException(msg, statusCode: res.statusCode);
  }

  Future<dynamic> getJson(String path) async {
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

  Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
    final http.Response res;
    try {
      res = await _client
          .post(_uri(path), headers: _headers(json: true), body: jsonEncode(body))
          .timeout(_timeout);
    } catch (_) {
      throw ApiException('Нет связи с сервером', statusCode: 0);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.bodyBytes.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
    }
    _fail(res, 'POST', path);
  }

  /// Multipart POST with optional file upload (e.g. a report photo).
  Future<dynamic> postMultipart(
    String path,
    Map<String, String> fields, {
    String? filePath,
    String fileField = 'image',
  }) async {
    final http.Response res;
    try {
      final req = http.MultipartRequest('POST', _uri(path));
      req.headers.addAll(_headers()); // Accept + Authorization (no JSON content-type)
      req.fields.addAll(fields);
      if (filePath != null) {
        req.files.add(await http.MultipartFile.fromPath(fileField, filePath));
      }
      final streamed = await req.send().timeout(const Duration(seconds: 30));
      res = await http.Response.fromStream(streamed);
    } catch (_) {
      throw ApiException('Не удалось отправить фото', statusCode: 0);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.bodyBytes.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
    }
    _fail(res, 'POST', path);
  }
}
