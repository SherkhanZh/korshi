import '../models/models.dart';
import 'api_client.dart';

/// Typed access to the Korshi API. Screens depend on this, not on raw HTTP.
class Repository {
  Repository({ApiClient? client}) : _api = client ?? ApiClient();

  final ApiClient _api;

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
