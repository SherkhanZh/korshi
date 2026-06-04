import '../models/models.dart';
import 'api_client.dart';
import 'session.dart';

/// Typed access to the Korshi API. Screens depend on this, not on raw HTTP.
class Repository {
  Repository({ApiClient? client}) : _api = client ?? ApiClient();

  final ApiClient _api;

  // ── auth ──

  /// Logs the resident in with their phone + invite code (or password) and
  /// stores the JWT in the session on success.
  Future<void> residentLogin({required String phone, required String secret}) async {
    final res = (await _api.postJson('/auth/resident/login', {
      'phone': phone,
      'secret': secret,
    }) as Map)
        .cast<String, dynamic>();
    final token = res['token'] as String;
    final resident = (res['resident'] as Map?)?.cast<String, dynamic>();
    await saveSession(token, resident?['name'] as String?);
  }

  /// Sets a personal password for the logged-in resident.
  Future<void> setPassword(String password) async {
    await _api.postJson('/auth/resident/password', {'password': password});
  }

  /// Records the resident's vote for [optionId] in poll [pollId].
  Future<void> vote({required String pollId, required int optionId}) async {
    await _api.postJson('/polls/$pollId/vote', {'optionId': optionId});
  }

  Future<HomeData> home() async =>
      HomeData.fromJson((await _api.getJson('/home') as Map).cast<String, dynamic>());

  Future<UpdatesData> updates() async =>
      UpdatesData.fromJson((await _api.getJson('/updates') as Map).cast<String, dynamic>());

  Future<PollsData> polls() async =>
      PollsData.fromJson((await _api.getJson('/polls') as Map).cast<String, dynamic>());

  Future<ContactsData> contacts() async =>
      ContactsData.fromJson((await _api.getJson('/contacts') as Map).cast<String, dynamic>());

  Future<List<ReportItem>> reports() async {
    final list = await _api.getJson('/reports') as List;
    return list
        .map((e) => ReportItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<ReportDetail> reportDetail(String id) async => ReportDetail.fromJson(
      (await _api.getJson('/reports/$id') as Map).cast<String, dynamic>());

  Future<void> submitReport({
    required String category,
    required String description,
    required String location,
  }) async {
    await _api.postJson('/reports', {
      'category': category,
      'description': description,
      'location': location,
    });
  }
}

/// Single shared instance for the app.
final repository = Repository();
