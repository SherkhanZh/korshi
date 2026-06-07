import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_state.dart';
import 'l10n/app_localizations.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding/onboarding.dart';
import 'services/push.dart';
import 'services/session.dart';
import 'splash.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadLocale();
  await loadSession();
  await PushService.init();
  if (isLoggedIn) PushService.registerIfPossible();
  runApp(const KorshiApp());
}

class KorshiApp extends StatefulWidget {
  const KorshiApp({super.key});

  @override
  State<KorshiApp> createState() => _KorshiAppState();
}

class _KorshiAppState extends State<KorshiApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back to the app (e.g. after tapping a notification or switching
    // away) re-fetches open screens so statuses and new items are current.
    if (state == AppLifecycleState.resumed) dataVersion.value++;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Korshi',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: scaffoldMessengerKey,
          theme: AppTheme.light(),
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Tap anywhere outside a text field to dismiss the keyboard.
          builder: (context, child) => GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child,
          ),
          home: SplashGate(child: isLoggedIn ? const MainShell() : const WelcomeScreen()),
        );
      },
    );
  }
}
