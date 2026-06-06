import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'api.dart';
import 'firebase_options.dart';
import 'repo.dart';

/// Background message handler — the OS displays the notification; nothing to do.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {}

/// Push notifications for the chairman app (FCM).
///
/// Guarded: if Firebase isn't configured yet (run `flutterfire configure`),
/// [init] disables push silently and the app keeps working.
class PushService {
  static bool _ready = false;
  static String? _token;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      _ready = true;
    } catch (_) {
      _ready = false;
      return;
    }
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (_) {}
    FirebaseMessaging.instance.onTokenRefresh.listen((t) {
      _token = t;
      if (adminToken.value != null) repo.registerPushToken(t);
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleTap(initial);
  }

  static Future<void> registerIfPossible() async {
    if (!_ready || adminToken.value == null) return;
    try {
      final t = await FirebaseMessaging.instance.getToken();
      if (t != null) {
        _token = t;
        await repo.registerPushToken(t);
      }
    } catch (_) {}
  }

  static Future<void> unregister() async {
    if (!_ready || _token == null) return;
    try {
      await repo.unregisterPushToken(_token!);
    } catch (_) {}
  }

  static void _handleTap(RemoteMessage message) {
    // New reports are the chairman's main push → open the Reports tab.
    selectedTab.value = 1;
  }
}
