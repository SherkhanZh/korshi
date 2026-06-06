import 'package:flutter/material.dart';

import 'api.dart';
import 'push.dart';
import 'screens/login.dart';
import 'screens/shell.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadSession();
  await PushService.init();
  if (isLoggedIn) PushService.registerIfPossible();
  runApp(const KorshiAdminApp());
}

class KorshiAdminApp extends StatelessWidget {
  const KorshiAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Korshi — Председатель',
      debugShowCheckedModeBanner: false,
      theme: korshiTheme(),
      home: ValueListenableBuilder<String?>(
        valueListenable: adminToken,
        builder: (context, token, _) => token == null ? const LoginScreen() : const AdminShell(),
      ),
    );
  }
}
