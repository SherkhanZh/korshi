import 'dart:convert';
import 'package:http/http.dart' as http;

/// API configuration. Override the base URL at build/run time with:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://188.244.115.167/api',
  );

  /// Set once per app launch so the cover image is re-fetched on each start
  /// instead of being served from Flutter's stale image cache.
  static final int _launch = DateTime.now().millisecondsSinceEpoch;

  /// Neighborhood cover image (uploaded from the admin panel).
  static String get coverUrl => '$baseUrl/neighborhood/cover?v=$_launch';
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => 'ApiException: $message';
}

/// Thin HTTP client over the Korshi API.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;
  static const _timeout = Duration(seconds: 12);

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<dynamic> getJson(String path) async {
    try {
      final res = await _client
          .get(_uri(path), headers: {'Accept': 'application/json'})
          .timeout(_timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
      throw ApiException('GET $path → ${res.statusCode}');
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
    try {
      final res = await _client
          .post(
            _uri(path),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
      throw ApiException('POST $path → ${res.statusCode}');
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
