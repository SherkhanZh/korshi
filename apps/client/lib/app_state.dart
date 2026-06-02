import 'package:flutter/material.dart';

/// App-wide UI language. Changing this rebuilds MaterialApp's locale.
final ValueNotifier<Locale> appLocale = ValueNotifier<Locale>(const Locale('ru'));

/// Currently selected bottom-nav tab (0 Home, 1 Updates, 3 Polls, 4 Contacts).
/// Lets any screen jump to another tab.
final ValueNotifier<int> shellTab = ValueNotifier<int>(0);

/// Local path of the user's chosen profile avatar (null = default icon).
final ValueNotifier<String?> avatarPath = ValueNotifier<String?>(null);

/// Bumped whenever resident data changes (e.g. a new report submitted) so
/// open screens re-fetch instead of needing an app restart.
final ValueNotifier<int> dataVersion = ValueNotifier<int>(0);

/// Fallback chairman contact (used by "Contact chairman" actions).
const String kChairmanPhone = '+77010000001';
