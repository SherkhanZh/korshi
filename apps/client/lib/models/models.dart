import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Issue / service categories used across reporting, quick actions and icons.
enum IssueCategory { water, roads, lights, garbage, safety, other }

IssueCategory categoryFromCode(String? code) {
  switch (code) {
    case 'water':
      return IssueCategory.water;
    case 'roads':
      return IssueCategory.roads;
    case 'lights':
      return IssueCategory.lights;
    case 'garbage':
      return IssueCategory.garbage;
    case 'safety':
      return IssueCategory.safety;
    default:
      return IssueCategory.other;
  }
}

extension IssueCategoryX on IssueCategory {
  IconData get icon {
    switch (this) {
      case IssueCategory.water:
        return Icons.water_drop_rounded;
      case IssueCategory.roads:
        return Icons.add_road_rounded;
      case IssueCategory.lights:
        return Icons.lightbulb_rounded;
      case IssueCategory.garbage:
        return Icons.delete_rounded;
      case IssueCategory.safety:
        return Icons.verified_user_rounded;
      case IssueCategory.other:
        return Icons.home_rounded;
    }
  }

  Color get color {
    switch (this) {
      case IssueCategory.water:
        return AppColors.water;
      case IssueCategory.roads:
        return AppColors.roads;
      case IssueCategory.lights:
        return AppColors.lights;
      case IssueCategory.garbage:
        return AppColors.garbage;
      case IssueCategory.safety:
        return AppColors.safety;
      case IssueCategory.other:
        return AppColors.other;
    }
  }

  String get code => name;

  /// Localization key for the category label.
  String get labelKey {
    switch (this) {
      case IssueCategory.water:
        return 'catWater';
      case IssueCategory.roads:
        return 'catRoads';
      case IssueCategory.lights:
        return 'catLights';
      case IssueCategory.garbage:
        return 'catGarbage';
      case IssueCategory.safety:
        return 'catSafety';
      case IssueCategory.other:
        return 'catOther';
    }
  }
}

/// Visual status used by badges throughout the app.
enum AppStatus {
  resolved,
  upcoming,
  event,
  update,
  inProgress,
  waitingResponse,
  approved,
  rejected,
  emergency,
}

AppStatus statusFromCode(String? code) {
  switch (code) {
    case 'resolved':
      return AppStatus.resolved;
    case 'upcoming':
      return AppStatus.upcoming;
    case 'event':
      return AppStatus.event;
    case 'update':
      return AppStatus.update;
    case 'inProgress':
      return AppStatus.inProgress;
    case 'waitingResponse':
      return AppStatus.waitingResponse;
    case 'approved':
      return AppStatus.approved;
    case 'rejected':
      return AppStatus.rejected;
    case 'emergency':
      return AppStatus.emergency;
    default:
      return AppStatus.update;
  }
}

extension AppStatusX on AppStatus {
  String get labelKey {
    switch (this) {
      case AppStatus.resolved:
        return 'statusResolved';
      case AppStatus.upcoming:
        return 'statusUpcoming';
      case AppStatus.event:
        return 'statusEvent';
      case AppStatus.update:
        return 'statusUpdate';
      case AppStatus.inProgress:
        return 'statusInProgress';
      case AppStatus.waitingResponse:
        return 'statusWaitingResponse';
      case AppStatus.approved:
        return 'statusApproved';
      case AppStatus.rejected:
        return 'statusRejected';
      case AppStatus.emergency:
        return 'statusEmergency';
    }
  }

  Color get bg {
    switch (this) {
      case AppStatus.resolved:
      case AppStatus.approved:
        return AppColors.resolvedBg;
      case AppStatus.upcoming:
        return AppColors.upcomingBg;
      case AppStatus.event:
        return AppColors.eventBg;
      case AppStatus.update:
        return AppColors.updateBg;
      case AppStatus.inProgress:
        return AppColors.upcomingBg;
      case AppStatus.waitingResponse:
        return AppColors.waitingBg;
      case AppStatus.rejected:
        return AppColors.rejectedBg;
      case AppStatus.emergency:
        return AppColors.emergencyBg;
    }
  }

  Color get fg {
    switch (this) {
      case AppStatus.resolved:
      case AppStatus.approved:
        return AppColors.resolvedText;
      case AppStatus.upcoming:
        return AppColors.upcomingText;
      case AppStatus.event:
        return AppColors.eventText;
      case AppStatus.update:
        return AppColors.updateText;
      case AppStatus.inProgress:
        return AppColors.upcomingText;
      case AppStatus.waitingResponse:
        return AppColors.waitingText;
      case AppStatus.rejected:
        return AppColors.rejectedText;
      case AppStatus.emergency:
        return AppColors.emergencyText;
    }
  }
}

/// A short item in the "Today" / "Latest updates" lists.
class UpdateItem {
  const UpdateItem({
    required this.id,
    required this.title,
    this.titleKk,
    this.subtitle,
    this.body,
    this.bodyKk,
    required this.category,
    required this.status,
    this.seenBy,
    this.kind = 'announcement',
    this.reportId = '',
  });

  final String id; // announcement id ('' for resident reports)
  final String title;
  final String? titleKk;
  final String? subtitle;
  final String? body;
  final String? bodyKk;
  final IssueCategory category;
  final AppStatus status;
  final int? seenBy;
  final String kind; // 'announcement' | 'report'
  final String reportId; // set when kind == 'report'

  bool get isReport => kind == 'report';

  factory UpdateItem.fromJson(Map<String, dynamic> j) => UpdateItem(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        titleKk: j['titleKk'] as String?,
        subtitle: j['subtitle'] as String?,
        body: j['body'] as String?,
        bodyKk: j['bodyKk'] as String?,
        category: categoryFromCode(j['category'] as String?),
        status: statusFromCode(j['status'] as String?),
        seenBy: j['seenBy'] as int?,
        kind: j['kind'] as String? ?? 'announcement',
        reportId: j['reportId'] as String? ?? '',
      );
}

/// A contact card (chairman, police, services, emergency, partners).
class ContactItem {
  const ContactItem({
    required this.name,
    required this.role,
    required this.category,
    this.subtitle,
    this.statusLine,
    this.badge,
    this.phone = '',
  });

  final String name;
  final String role;
  final IssueCategory category;
  final String? subtitle;
  final String? statusLine;
  final String? badge; // 'chairman' | 'police' | 'emergency' | null
  final String phone;

  IconData get icon {
    switch (badge) {
      case 'chairman':
        return Icons.person_rounded;
      case 'police':
        return Icons.local_police_rounded;
      case 'emergency':
        return category == IssueCategory.lights
            ? Icons.local_fire_department_rounded
            : Icons.emergency_rounded;
      default:
        switch (category) {
          case IssueCategory.water:
            return Icons.plumbing_rounded;
          case IssueCategory.lights:
            return Icons.electrical_services_rounded;
          case IssueCategory.safety:
            return Icons.videocam_rounded;
          default:
            return Icons.handyman_rounded;
        }
    }
  }

  Color get color {
    switch (badge) {
      case 'chairman':
        return AppColors.primary;
      case 'police':
        return AppColors.waitingText;
      case 'emergency':
        return category == IssueCategory.lights
            ? AppColors.lights
            : AppColors.emergencyText;
      default:
        return category.color;
    }
  }

  factory ContactItem.fromJson(Map<String, dynamic> j) => ContactItem(
        name: j['name'] as String? ?? '',
        role: (j['role'] ?? j['desc'] ?? '') as String,
        category: categoryFromCode(j['category'] as String?),
        subtitle: j['subtitle'] as String?,
        statusLine: j['statusLine'] as String?,
        badge: j['badge'] as String?,
        phone: j['phone'] as String? ?? '',
      );
}

/// A poll option (active poll).
class PollOption {
  const PollOption({
    required this.id,
    required this.label,
    this.labelKk,
    required this.pct,
    required this.votes,
    required this.positive,
  });

  final int id;
  final String label;
  final String? labelKk;
  final int pct;
  final int votes;
  final bool positive;

  factory PollOption.fromJson(Map<String, dynamic> j) => PollOption(
        id: (j['id'] as num?)?.toInt() ?? 0,
        label: j['label'] as String? ?? '',
        labelKk: j['labelKk'] as String?,
        pct: j['pct'] as int? ?? 0,
        votes: j['votes'] as int? ?? 0,
        positive: j['positive'] as bool? ?? false,
      );
}

class PollVoter {
  const PollVoter({required this.name, required this.optionId});
  final String name;
  final int optionId;

  factory PollVoter.fromJson(Map<String, dynamic> j) => PollVoter(
        name: j['name'] as String? ?? '',
        optionId: (j['optionId'] as num?)?.toInt() ?? 0,
      );
}

class ActivePoll {
  const ActivePoll({
    required this.id,
    required this.question,
    required this.questionKk,
    required this.description,
    required this.descriptionKk,
    required this.options,
    required this.households,
    required this.endsInDays,
    required this.voted,
    required this.confidential,
    required this.voters,
  });

  final String id;
  final String question;
  final String questionKk;
  final String description;
  final String descriptionKk;
  final List<PollOption> options;
  final int households;
  final int endsInDays;
  final bool voted;
  final bool confidential;
  final List<PollVoter> voters;

  /// True when there's an active poll to display.
  bool get exists => id.isNotEmpty;

  factory ActivePoll.fromJson(Map<String, dynamic> j) => ActivePoll(
        id: j['id'] as String? ?? '',
        question: j['question'] as String? ?? '',
        questionKk: j['questionKk'] as String? ?? '',
        description: j['description'] as String? ?? '',
        descriptionKk: j['descriptionKk'] as String? ?? '',
        options: ((j['options'] as List?) ?? [])
            .map((e) => PollOption.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        households: j['households'] as int? ?? 0,
        endsInDays: j['endsInDays'] as int? ?? 0,
        voted: j['voted'] as bool? ?? false,
        confidential: j['confidential'] as bool? ?? true,
        voters: ((j['voters'] as List?) ?? [])
            .map((e) => PollVoter.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

/// Upcoming / previous decision rows on the Polls screen.
class DecisionItem {
  const DecisionItem({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.trailingTop,
    required this.trailingBottom,
    this.status,
  });

  final String title;
  final String subtitle;
  final IssueCategory category;
  final String trailingTop;
  final String trailingBottom;
  final AppStatus? status;

  factory DecisionItem.fromJson(Map<String, dynamic> j, {required bool previous}) =>
      DecisionItem(
        title: j['title'] as String? ?? '',
        subtitle: j['subtitle'] as String? ?? '',
        category: categoryFromCode(j['category'] as String?),
        trailingTop: j['opensLabel'] as String? ?? '',
        trailingBottom: j['date'] as String? ?? '',
        status: previous ? statusFromCode(j['status'] as String?) : null,
      );
}

/// Status timeline step state.
enum TimelineStepState { done, current, pending }

TimelineStepState stepStateFromCode(String? code) {
  switch (code) {
    case 'done':
      return TimelineStepState.done;
    case 'current':
      return TimelineStepState.current;
    default:
      return TimelineStepState.pending;
  }
}

class TimelineStep {
  const TimelineStep({
    required this.label,
    this.date,
    required this.state,
    this.icon,
  });

  final String label;
  final String? date;
  final TimelineStepState state;
  final IconData? icon;

  factory TimelineStep.fromJson(Map<String, dynamic> j) {
    final state = stepStateFromCode(j['state'] as String?);
    return TimelineStep(
      label: j['label'] as String? ?? '',
      date: j['date'] as String?,
      state: state,
      icon: state == TimelineStepState.current ? Icons.build_rounded : null,
    );
  }
}

/// A submitted report (My reports / Request details).
class ReportItem {
  const ReportItem({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.dateTime,
    required this.status,
    required this.steps,
    required this.chairmanNote,
    required this.updatedLabel,
    this.author = '',
  });

  final String id;
  final String title;
  final IssueCategory category;
  final String location;
  final String dateTime;
  final AppStatus status;
  final List<TimelineStep> steps;
  final String chairmanNote;
  final String updatedLabel;
  final String author;

  factory ReportItem.fromJson(Map<String, dynamic> j) => ReportItem(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        category: categoryFromCode(j['category'] as String?),
        location: j['location'] as String? ?? '',
        dateTime: j['dateTime'] as String? ?? '',
        status: statusFromCode(j['status'] as String?),
        steps: ((j['steps'] as List?) ?? [])
            .map((e) => TimelineStep.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        chairmanNote: j['chairmanNote'] as String? ?? '',
        updatedLabel: j['updatedLabel'] as String? ?? '',
        author: j['author'] as String? ?? '',
      );
}

class ChairmanUpdate {
  const ChairmanUpdate({required this.date, required this.body});
  final String date;
  final String body;
  factory ChairmanUpdate.fromJson(Map<String, dynamic> j) =>
      ChairmanUpdate(date: j['date'] as String? ?? '', body: j['body'] as String? ?? '');
}

class ReportDetail {
  const ReportDetail({
    required this.report,
    required this.description,
    required this.detailSteps,
    required this.chairmanUpdates,
  });

  final ReportItem report;
  final String description;
  final List<TimelineStep> detailSteps;
  final List<ChairmanUpdate> chairmanUpdates;

  factory ReportDetail.fromJson(Map<String, dynamic> j) => ReportDetail(
        report: ReportItem.fromJson(j),
        description: j['description'] as String? ?? '',
        detailSteps: ((j['detailSteps'] as List?) ?? [])
            .map((e) => TimelineStep.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        chairmanUpdates: ((j['chairmanUpdates'] as List?) ?? [])
            .map((e) => ChairmanUpdate.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

// ─── Aggregate payloads ───

class HomeData {
  const HomeData({
    required this.announcementTitle,
    required this.announcementTitleKk,
    required this.announcementDate,
    required this.announcementBody,
    required this.announcementBodyKk,
    required this.today,
    required this.pollQuestion,
    required this.pollQuestionKk,
    required this.pollYesPct,
    required this.pollNoPct,
    required this.contacts,
    required this.partnerTitle,
    required this.partnerSubtitle,
    required this.partnerRating,
    required this.partnerReviews,
    required this.partnerPhone,
  });

  final String announcementTitle;
  final String announcementTitleKk;
  final String announcementDate;
  final String announcementBody;
  final String announcementBodyKk;
  final List<UpdateItem> today;
  final String pollQuestion;
  final String pollQuestionKk;
  final int pollYesPct;
  final int pollNoPct;
  final List<ContactItem> contacts;
  final String partnerTitle;
  final String partnerSubtitle;
  final String partnerRating;
  final String partnerReviews;
  final String partnerPhone;

  /// True when the chairman has actually pinned an announcement.
  bool get hasAnnouncement => announcementTitle.trim().isNotEmpty;

  /// True when there's an active poll to show.
  bool get hasPoll => pollQuestion.trim().isNotEmpty;

  factory HomeData.fromJson(Map<String, dynamic> j) {
    final a = ((j['announcement'] as Map?) ?? {}).cast<String, dynamic>();
    final p = ((j['poll'] as Map?) ?? {}).cast<String, dynamic>();
    final pa = ((j['partner'] as Map?) ?? {}).cast<String, dynamic>();
    return HomeData(
      announcementTitle: a['title'] as String? ?? '',
      announcementTitleKk: a['titleKk'] as String? ?? '',
      announcementDate: a['date'] as String? ?? '',
      announcementBody: a['body'] as String? ?? '',
      announcementBodyKk: a['bodyKk'] as String? ?? '',
      today: ((j['today'] as List?) ?? [])
          .map((e) => UpdateItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      pollQuestion: p['question'] as String? ?? '',
      pollQuestionKk: p['questionKk'] as String? ?? '',
      pollYesPct: p['yesPct'] as int? ?? 0,
      pollNoPct: p['noPct'] as int? ?? 0,
      contacts: ((j['contacts'] as List?) ?? [])
          .map((e) => ContactItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      partnerTitle: pa['title'] as String? ?? '',
      partnerSubtitle: pa['subtitle'] as String? ?? '',
      partnerRating: pa['rating'] as String? ?? '0.0',
      partnerReviews: pa['reviews'] as String? ?? '0',
      partnerPhone: pa['phone'] as String? ?? '',
    );
  }
}

class UpdatesData {
  const UpdatesData({
    required this.pinnedId,
    required this.pinnedTitle,
    required this.pinnedTitleKk,
    required this.pinnedDate,
    required this.pinnedBody,
    required this.pinnedBodyKk,
    required this.pinnedSeenBy,
    required this.latest,
  });

  final String pinnedId;
  final String pinnedTitle;
  final String pinnedTitleKk;
  final String pinnedDate;
  final String pinnedBody;
  final String pinnedBodyKk;
  final int pinnedSeenBy;
  final List<UpdateItem> latest;

  bool get hasPinned => pinnedTitle.trim().isNotEmpty;

  /// Resident reports surfaced in the feed (the "Requests" tab).
  List<UpdateItem> get reports => latest.where((u) => u.isReport).toList();

  /// Announcements only (the "Announcements" tab).
  List<UpdateItem> get announcements => latest.where((u) => !u.isReport).toList();

  factory UpdatesData.fromJson(Map<String, dynamic> j) {
    final p = ((j['pinned'] as Map?) ?? {}).cast<String, dynamic>();
    return UpdatesData(
      pinnedId: p['id'] as String? ?? '',
      pinnedTitle: p['title'] as String? ?? '',
      pinnedTitleKk: p['titleKk'] as String? ?? '',
      pinnedDate: p['date'] as String? ?? '',
      pinnedBody: p['body'] as String? ?? '',
      pinnedBodyKk: p['bodyKk'] as String? ?? '',
      pinnedSeenBy: p['seenBy'] as int? ?? 0,
      latest: ((j['latest'] as List?) ?? [])
          .map((e) => UpdateItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class PollsData {
  const PollsData({
    required this.participationPct,
    required this.active,
    required this.upcoming,
    required this.previous,
  });

  final int participationPct;
  final ActivePoll active;
  final List<DecisionItem> upcoming;
  final List<DecisionItem> previous;

  factory PollsData.fromJson(Map<String, dynamic> j) => PollsData(
        participationPct: j['participationPct'] as int? ?? 0,
        active: ActivePoll.fromJson(((j['active'] as Map?) ?? {}).cast<String, dynamic>()),
        upcoming: ((j['upcoming'] as List?) ?? [])
            .map((e) => DecisionItem.fromJson((e as Map).cast<String, dynamic>(), previous: false))
            .toList(),
        previous: ((j['previous'] as List?) ?? [])
            .map((e) => DecisionItem.fromJson((e as Map).cast<String, dynamic>(), previous: true))
            .toList(),
      );
}

class ContactsData {
  const ContactsData({
    required this.important,
    required this.services,
    required this.partners,
  });

  final List<ContactItem> important;
  final List<ContactItem> services;
  final List<ContactItem> partners;

  factory ContactsData.fromJson(Map<String, dynamic> j) => ContactsData(
        important: ((j['important'] as List?) ?? [])
            .map((e) => ContactItem.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        services: ((j['services'] as List?) ?? [])
            .map((e) => ContactItem.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        partners: ((j['partners'] as List?) ?? [])
            .map((e) => ContactItem.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}
