import 'package:flutter/foundation.dart';

import '../app_state.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'session.dart';

/// Typed access to the Korshi API. Screens depend on this, not on raw HTTP.
class Repository {
  Repository({ApiClient? client}) : _api = client ?? ApiClient();

  final ApiClient _api;

  // ── auth ──

  /// Logs the resident in with their phone + invite code (or password) and
  /// stores the JWT in the session. Returns whether they already have a
  /// personal password set (so onboarding can skip the "set password" step).
  Future<bool> residentLogin({required String phone, required String secret}) async {
    final res = (await _api.postJson('/auth/resident/login', {
      'phone': phone,
      'secret': secret,
    }) as Map)
        .cast<String, dynamic>();
    final token = res['token'] as String;
    final resident = (res['resident'] as Map?)?.cast<String, dynamic>();
    final nbhd = (res['neighborhood'] as Map?)?.cast<String, dynamic>();
    await saveSession(
      token,
      resident?['name'] as String?,
      nid: nbhd?['id'] as String?,
      nbhd: nbhd?['name'] as String?,
      address: resident?['address'] as String?,
    );
    return res['hasPassword'] as bool? ?? false;
  }

  /// Sets a personal password for the logged-in resident.
  Future<void> setPassword(String password) async {
    await _api.postJson('/auth/resident/password', {'password': password});
  }

  /// Records the resident's vote for [optionId] in poll [pollId].
  Future<void> vote({required String pollId, required int optionId}) async {
    await _api.postJson('/polls/$pollId/vote', {'optionId': optionId});
  }

  /// Registers this device's FCM token for push notifications.
  Future<void> registerPushToken(String token) async {
    try {
      await _api.postJson('/push/register', {
        'token': token,
        'platform': defaultTargetPlatform.name,
      });
    } catch (_) {
      // Best-effort; ignore failures.
    }
  }

  /// Removes this device's FCM token (on logout).
  Future<void> unregisterPushToken(String token) async {
    try {
      await _api.postJson('/push/unregister', {'token': token});
    } catch (_) {}
  }

  /// Marks an announcement as seen by the resident (for real view counts).
  Future<void> markAnnouncementSeen(String id) async {
    if (id.isEmpty) return;
    try {
      await _api.postJson('/announcements/$id/seen', {});
    } catch (_) {
      // View tracking is best-effort; ignore failures.
    }
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

  /// A single announcement as an update item (used when opening one from a push).
  Future<UpdateItem> announcementItem(String id) async => UpdateItem.fromJson(
      (await _api.getJson('/announcements/$id') as Map).cast<String, dynamic>());

  Future<NotificationsData> notifications() async => NotificationsData.fromJson(
      (await _api.getJson('/notifications') as Map).cast<String, dynamic>());

  Future<void> markNotificationsRead() async {
    try {
      await _api.postJson('/notifications/read', {});
    } catch (_) {
      // Best-effort.
    }
  }

  /// Refreshes the global unread badge count.
  Future<void> refreshUnread() async {
    try {
      final d = await notifications();
      unreadNotifications.value = d.unread;
    } catch (_) {}
  }

  Future<void> submitReport({
    required String category,
    required String description,
    required String location,
    String? photoPath,
  }) async {
    final fields = {
      'category': category,
      'description': description,
      'location': location,
    };
    if (photoPath != null) {
      await _api.postMultipart('/reports', fields, filePath: photoPath);
    } else {
      await _api.postJson('/reports', fields);
    }
  }
}

/// Single shared instance for the app.
final repository = Repository();
