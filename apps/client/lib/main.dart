import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_state.dart';
import 'l10n/app_localizations.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding/onboarding.dart';
import 'services/push.dart';
import 'services/session.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadSession();
  await PushService.init();
  if (isLoggedIn) PushService.registerIfPossible();
  runApp(const KorshiApp());
}

class KorshiApp extends StatelessWidget {
  const KorshiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Korshi',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: isLoggedIn ? const MainShell() : const WelcomeScreen(),
        );
      },
    );
  }
}
