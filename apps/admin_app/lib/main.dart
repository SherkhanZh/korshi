import 'package:flutter/material.dart';

import 'api.dart';
import 'push.dart';
import 'screens/login.dart';
import 'screens/shell.dart';
import 'splash.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadLocale();
  await loadSession();
  await PushService.init();
  if (isLoggedIn) PushService.registerIfPossible();
  runApp(const KorshiAdminApp());
}

class KorshiAdminApp extends StatelessWidget {
  const KorshiAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild the whole app when the language changes so loc() re-evaluates.
    // The screens are const widgets, so an ancestor rebuild alone won't refresh
    // them — keying the subtree by locale forces a full rebuild on switch.
    return ValueListenableBuilder<String>(
      valueListenable: adminLocale,
      builder: (context, lang, __) => MaterialApp(
        title: 'Korshi — Председатель',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: adminMessengerKey,
        theme: korshiTheme(),
        // Tap anywhere outside a text field to dismiss the keyboard.
        builder: (context, child) => GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        ),
        home: SplashGate(
          child: ValueListenableBuilder<String?>(
            valueListenable: adminToken,
            builder: (context, token, _) => KeyedSubtree(
              key: ValueKey('lang-$lang'),
              child: token == null ? const LoginScreen() : const AdminShell(),
            ),
          ),
        ),
      ),
    );
  }
}
