import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../app_state.dart';
import '../firebase_options.dart';
import 'repository.dart';
import 'session.dart';

/// Background message handler — the OS shows the notification automatically,
/// so there's nothing to do here, but a top-level handler must be registered.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {}

/// Push notifications via Firebase Cloud Messaging.
///
/// Everything is guarded: if Firebase isn't configured yet (no
/// google-services.json / GoogleService-Info.plist), [init] silently disables
/// push and the app keeps working.
class PushService {
  static bool _ready = false;
  static String? _token;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      _ready = true;
    } catch (_) {
      _ready = false; // Firebase not set up — push disabled.
      return;
    }
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (_) {}

    // Re-register if FCM rotates the token.
    FirebaseMessaging.instance.onTokenRefresh.listen((t) {
      _token = t;
      if (authToken.value != null) repository.registerPushToken(t);
    });

    // Tap handling (background → foreground, and cold start).
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleTap(initial);
  }

  /// Registers this device's token with the backend (call after login).
  static Future<void> registerIfPossible() async {
    if (!_ready || authToken.value == null) return;
    try {
      final t = await FirebaseMessaging.instance.getToken();
      if (t != null) {
        _token = t;
        await repository.registerPushToken(t);
      }
    } catch (_) {}
  }

  /// Removes this device's token (call on logout).
  static Future<void> unregister() async {
    if (!_ready || _token == null) return;
    try {
      await repository.unregisterPushToken(_token!);
    } catch (_) {}
  }

  static void _handleTap(RemoteMessage message) {
    final type = message.data['type'];
    if (type == 'poll') {
      shellTab.value = 3;
    } else {
      // report or announcement → Updates tab.
      shellTab.value = 1;
    }
  }
}
