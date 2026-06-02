import 'package:flutter/material.dart';

import 'strings_en.dart';
import 'strings_kk.dart';
import 'strings_ru.dart';

/// Lightweight, codegen-free localization layer.
///
/// English is the source of truth. Kazakh (kk) and Russian (ru) maps can be
/// filled incrementally — any missing key falls back to English, so the app
/// always renders. Access strings via `context.l10n.<key>` or
/// `context.l10n.t('key')`.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('kk'),
    Locale('ru'),
  ];

  static const Map<String, Map<String, String>> _all = {
    'en': stringsEn,
    'kk': stringsKk,
    'ru': stringsRu,
  };

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  Map<String, String> get _map => _all[locale.languageCode] ?? stringsEn;

  /// Key-based lookup with English fallback.
  String t(String key) => _map[key] ?? stringsEn[key] ?? key;

  // --- Auto-generated named getters for every key in strings_en.dart -----
  String get appName => t('appName');
  String get navHome => t('navHome');
  String get navUpdates => t('navUpdates');
  String get navReport => t('navReport');
  String get navPolls => t('navPolls');
  String get navContacts => t('navContacts');
  String get viewDetails => t('viewDetails');
  String get seeAll => t('seeAll');
  String get voteNow => t('voteNow');
  String get call => t('call');
  String get whatsApp => t('whatsApp');
  String get partner => t('partner');
  String get changeVote => t('changeVote');
  String get sendReport => t('sendReport');
  String get contactChairman => t('contactChairman');
  String get reportAnIssue => t('reportAnIssue');
  String get homeNeighborhood => t('homeNeighborhood');
  String get homeCity => t('homeCity');
  String get importantAnnouncement => t('importantAnnouncement');
  String get homeAnnounceTitle => t('homeAnnounceTitle');
  String get homeAnnounceDate => t('homeAnnounceDate');
  String get homeAnnounceBody => t('homeAnnounceBody');
  String get quickReport => t('quickReport');
  String get catWater => t('catWater');
  String get catRoads => t('catRoads');
  String get catLights => t('catLights');
  String get catGarbage => t('catGarbage');
  String get catSafety => t('catSafety');
  String get catMore => t('catMore');
  String get catOther => t('catOther');
  String get todayInNeighborhood => t('todayInNeighborhood');
  String get communityPoll => t('communityPoll');
  String get pollStreetLightsQ => t('pollStreetLightsQ');
  String get trustedContacts => t('trustedContacts');
  String get trustedLocalPartner => t('trustedLocalPartner');
  String get reliablePlumbing => t('reliablePlumbing');
  String get recommendedForNeighborhood => t('recommendedForNeighborhood');
  String get statusResolved => t('statusResolved');
  String get statusUpcoming => t('statusUpcoming');
  String get statusEvent => t('statusEvent');
  String get statusUpdate => t('statusUpdate');
  String get statusInProgress => t('statusInProgress');
  String get statusWaitingResponse => t('statusWaitingResponse');
  String get statusApproved => t('statusApproved');
  String get statusRejected => t('statusRejected');
  String get statusEmergency => t('statusEmergency');
  String get statusActivePoll => t('statusActivePoll');
  String get waterServiceRestored => t('waterServiceRestored');
  String get roadMaintenanceTomorrow => t('roadMaintenanceTomorrow');
  String get communityCleanupSunday => t('communityCleanupSunday');
  String get updatesTitle => t('updatesTitle');
  String get updatesSubtitle => t('updatesSubtitle');
  String get filterAll => t('filterAll');
  String get filterImportant => t('filterImportant');
  String get filterUpdates => t('filterUpdates');
  String get filterEvents => t('filterEvents');
  String get pinned => t('pinned');
  String get waterMaintenanceSaturday => t('waterMaintenanceSaturday');
  String get waterMaintenanceBody => t('waterMaintenanceBody');
  String get seenByResidents => t('seenByResidents');
  String get seenBy => t('seenBy');
  String get latestUpdates => t('latestUpdates');
  String get helpful => t('helpful');
  String get waterRestoredBody => t('waterRestoredBody');
  String get roadMaintenanceBody => t('roadMaintenanceBody');
  String get cleanupBody => t('cleanupBody');
  String get newStreetLightsInstalled => t('newStreetLightsInstalled');
  String get newStreetLightsBody => t('newStreetLightsBody');
  String get fenceRepairService => t('fenceRepairService');
  String get recommendedForResidents => t('recommendedForResidents');
  String get reportSubtitle => t('reportSubtitle');
  String get selectCategory => t('selectCategory');
  String get addPhotoOptional => t('addPhotoOptional');
  String get addPhoto => t('addPhoto');
  String get cameraOrGallery => t('cameraOrGallery');
  String get location => t('location');
  String get describeIssue => t('describeIssue');
  String get describeHint => t('describeHint');
  String get chairmanNotified => t('chairmanNotified');
  String get pollsTitle => t('pollsTitle');
  String get pollsSubtitle => t('pollsSubtitle');
  String get householdsParticipated => t('householdsParticipated');
  String get activePollQ => t('activePollQ');
  String get activePollDesc => t('activePollDesc');
  String get yesSupport => t('yesSupport');
  String get notNow => t('notNow');
  String get householdsVoted => t('householdsVoted');
  String get endsInDays => t('endsInDays');
  String get voteRecorded => t('voteRecorded');
  String get upcomingDecisions => t('upcomingDecisions');
  String get cctvProposal => t('cctvProposal');
  String get cctvDesc => t('cctvDesc');
  String get snowRemovalBudget => t('snowRemovalBudget');
  String get snowRemovalDesc => t('snowRemovalDesc');
  String get gateProposal => t('gateProposal');
  String get gateDesc => t('gateDesc');
  String get opensTomorrow => t('opensTomorrow');
  String get opensInDays => t('opensInDays');
  String get opensIn3Days => t('opensIn3Days');
  String get opensIn5Days => t('opensIn5Days');
  String get previousDecisions => t('previousDecisions');
  String get improvedSafetyAbay => t('improvedSafetyAbay');
  String get securityGateProposal => t('securityGateProposal');
  String get notEnoughSupport => t('notEnoughSupport');
  String get contactsTitle => t('contactsTitle');
  String get contactsSubtitle => t('contactsSubtitle');
  String get tabNeighborhood => t('tabNeighborhood');
  String get tabServices => t('tabServices');
  String get tabEmergency => t('tabEmergency');
  String get importantContacts => t('importantContacts');
  String get roleChairman => t('roleChairman');
  String get rolePolice => t('rolePolice');
  String get neighborhoodChairman => t('neighborhoodChairman');
  String get medeuPolice => t('medeuPolice');
  String get respondsQuickly => t('respondsQuickly');
  String get available => t('available');
  String get emergencyService => t('emergencyService');
  String get gasElectricityEmergency => t('gasElectricityEmergency');
  String get localServices => t('localServices');
  String get plumber => t('plumber');
  String get electrician => t('electrician');
  String get gateRepair => t('gateRepair');
  String get waterTechnician => t('waterTechnician');
  String get recommendedByNeighborhood => t('recommendedByNeighborhood');
  String get trustedLocalPartners => t('trustedLocalPartners');
  String get fenceRepair => t('fenceRepair');
  String get fenceRepairDesc => t('fenceRepairDesc');
  String get waterDelivery => t('waterDelivery');
  String get waterDeliveryDesc => t('waterDeliveryDesc');
  String get securityCameras => t('securityCameras');
  String get securityCamerasDesc => t('securityCamerasDesc');
  String get profileResident => t('profileResident');
  String get profileAddress => t('profileAddress');
  String get sectionLanguage => t('sectionLanguage');
  String get langKazakh => t('langKazakh');
  String get langRussian => t('langRussian');
  String get langEnglish => t('langEnglish');
  String get sectionNotifications => t('sectionNotifications');
  String get notifEmergency => t('notifEmergency');
  String get notifEmergencyDesc => t('notifEmergencyDesc');
  String get notifUpdates => t('notifUpdates');
  String get notifUpdatesDesc => t('notifUpdatesDesc');
  String get notifPolls => t('notifPolls');
  String get notifPollsDesc => t('notifPollsDesc');
  String get notifService => t('notifService');
  String get notifServiceDesc => t('notifServiceDesc');
  String get sectionMyRequests => t('sectionMyRequests');
  String get myReports => t('myReports');
  String get myReportsDesc => t('myReportsDesc');
  String get sectionHelp => t('sectionHelp');
  String get contactChairmanDesc => t('contactChairmanDesc');
  String get faqHelp => t('faqHelp');
  String get faqHelpDesc => t('faqHelpDesc');
  String get sectionAccount => t('sectionAccount');
  String get privacyPolicy => t('privacyPolicy');
  String get privacyPolicyDesc => t('privacyPolicyDesc');
  String get termsConditions => t('termsConditions');
  String get termsConditionsDesc => t('termsConditionsDesc');
  String get logout => t('logout');
  String get logoutDesc => t('logoutDesc');
  String get profileFooterThanks => t('profileFooterThanks');
  String get profileFooterTogether => t('profileFooterTogether');
  String get myReportsTitle => t('myReportsTitle');
  String get myReportsSubtitle => t('myReportsSubtitle');
  String get filterInProgress => t('filterInProgress');
  String get filterResolved => t('filterResolved');
  String get stepSubmitted => t('stepSubmitted');
  String get stepInProgress => t('stepInProgress');
  String get stepResolved => t('stepResolved');
  String get stepWaitingResponse => t('stepWaitingResponse');
  String get chairmanUpdate => t('chairmanUpdate');
  String get updatedAgo => t('updatedAgo');
  String get noteStreetLight => t('noteStreetLight');
  String get notePothole => t('notePothole');
  String get noteWaterLeak => t('noteWaterLeak');
  String get updated2hAgo => t('updated2hAgo');
  String get updated1dAgo => t('updated1dAgo');
  String get updatedMay12 => t('updatedMay12');
  String get streetLightNotWorking => t('streetLightNotWorking');
  String get potholeOnRoad => t('potholeOnRoad');
  String get waterLeakNearPark => t('waterLeakNearPark');
  String get noReportsYet => t('noReportsYet');
  String get noReportsDesc => t('noReportsDesc');
  String get requestDetails => t('requestDetails');
  String get statusProgress => t('statusProgress');
  String get stepChairmanReviewed => t('stepChairmanReviewed');
  String get stepScheduledRepair => t('stepScheduledRepair');
  String get inProgressKeepUpdated => t('inProgressKeepUpdated');
  String get chairmanUpdates => t('chairmanUpdates');
  String get originalReport => t('originalReport');
  String get descriptionLabel => t('descriptionLabel');
  String get locationLabel => t('locationLabel');
  String get photosLabel => t('photosLabel');
  String get needHelp => t('needHelp');
  String get needHelpDesc => t('needHelpDesc');
  String get expectedCompletion => t('expectedCompletion');
  String get expectedCompletionDesc => t('expectedCompletionDesc');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations._all.containsKey(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
