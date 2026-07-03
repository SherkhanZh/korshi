import 'package:flutter/foundation.dart';

import 'api.dart';
import 'models.dart';

/// Typed access to the Korshi admin API.
class Repo {
  // ── auth ──
  Future<void> login(String email, String password) async {
    final r = (await api.post('/auth/admin/login', {'email': email, 'password': password}) as Map)
        .cast<String, dynamic>();
    final nbhd = (r['neighborhood'] as Map?)?.cast<String, dynamic>();
    await saveSession(
      token: r['token'] as String,
      email: r['email'] as String,
      role: r['role'] as String? ?? 'admin',
      nbhd: nbhd?['name'] as String?,
      nid: nbhd?['id'] as String?,
    );
  }

  // ── dashboard ──
  Future<Stats> stats() async =>
      Stats((await api.get('/admin/stats') as Map).cast<String, dynamic>());

  // ── reports ──
  Future<List<AdminReport>> reports() async {
    final list = await api.get('/admin/reports') as List;
    return list.map((e) => AdminReport((e as Map).cast<String, dynamic>())).toList();
  }

  Future<AdminReport> patchReport(String id, {String? status, String? contractor, String? internalNote}) async {
    final body = <String, dynamic>{};
    if (status != null) body['status'] = AdminReport.toServer(status);
    if (contractor != null) body['contractor'] = contractor;
    if (internalNote != null) body['internalNote'] = internalNote;
    return AdminReport((await api.patch('/admin/reports/$id', body) as Map).cast<String, dynamic>());
  }

  Future<void> deleteReport(String id) => api.delete('/admin/reports/$id');
  Future<AdminReport> addReportUpdate(String id, String text) async =>
      AdminReport((await api.post('/admin/reports/$id/update', {'body': text}) as Map).cast<String, dynamic>());

  // No token in the URL — the photo is fetched with an Authorization header
  // (see reports.dart) so the JWT never lands in proxy logs or the image cache.
  String reportPhotoUrl(String id) => '${ApiConfig.baseUrl}/reports/$id/photo';

  // ── announcements ──
  Future<List<AdminAnnouncement>> announcements() async {
    final list = await api.get('/admin/announcements') as List;
    return list.map((e) => AdminAnnouncement((e as Map).cast<String, dynamic>())).toList();
  }

  Future<void> createAnnouncement(Map<String, dynamic> body) => api.post('/admin/announcements', body);
  Future<void> updateAnnouncement(String id, Map<String, dynamic> body) => api.patch('/admin/announcements/$id', body);
  Future<void> pinAnnouncement(String id, bool pinned) => api.patch('/admin/announcements/$id', {'pinned': pinned});
  Future<void> deleteAnnouncement(String id) => api.delete('/admin/announcements/$id');

  // ── polls ──
  Future<List<AdminPoll>> polls() async {
    final list = await api.get('/admin/polls') as List;
    return list.map((e) => AdminPoll((e as Map).cast<String, dynamic>())).toList();
  }

  Future<void> createPoll(Map<String, dynamic> body) => api.post('/admin/polls', body);
  Future<void> deletePoll(String id) => api.delete('/admin/polls/$id');

  // ── residents ──
  Future<ResidentsData> residents() async =>
      ResidentsData((await api.get('/admin/residents') as Map).cast<String, dynamic>());

  Future<String> invite({required String phone, required String address, String? name}) async {
    final r = (await api.post('/admin/residents/invite', {
      'phone': phone,
      'address': address,
      if (name != null && name.isNotEmpty) 'name': name,
    }) as Map)
        .cast<String, dynamic>();
    return r['activationCode'] as String? ?? '';
  }

  Future<void> deleteResident(String id) => api.delete('/admin/residents/$id');

  // ── contacts (important; chairman-managed) ──
  Future<List<AdminContact>> contacts() async {
    final list = await api.get('/admin/contacts') as List;
    return list.map((e) => AdminContact((e as Map).cast<String, dynamic>())).toList();
  }
  Future<void> createContact(Map<String, dynamic> body) => api.post('/admin/contacts', body);
  Future<void> updateContact(String id, Map<String, dynamic> body) => api.patch('/admin/contacts/$id', body);
  Future<void> deleteContact(String id) => api.delete('/admin/contacts/$id');

  // ── cover ──
  Future<void> uploadCover(String filePath) => api.uploadCover(filePath);

  // ── push ──
  Future<void> registerPushToken(String token) async {
    try {
      await api.post('/push/register', {'token': token, 'platform': defaultTargetPlatform.name});
    } catch (_) {}
  }

  Future<void> unregisterPushToken(String token) async {
    try {
      await api.post('/push/unregister', {'token': token});
    } catch (_) {}
  }
}

final repo = Repo();
