class Stats {
  Stats(this.j);
  final Map<String, dynamic> j;
  int n(String k) => (j[k] as num?)?.toInt() ?? 0;
  String get neighborhood => j['neighborhood'] as String? ?? '';
}

class ReportUpdate {
  ReportUpdate(this.date, this.body);
  final String date;
  final String body;
  factory ReportUpdate.from(Map j) =>
      ReportUpdate(j['date'] as String? ?? '', j['body'] as String? ?? '');
}

class AdminReport {
  AdminReport(Map<String, dynamic> j)
      : id = j['id'] as String? ?? '',
        title = j['title'] as String? ?? '',
        category = j['category'] as String? ?? 'other',
        status = j['status'] as String? ?? 'waitingResponse',
        location = j['location'] as String? ?? '',
        dateTime = j['dateTime'] as String? ?? '',
        resident = j['resident'] as String? ?? j['author'] as String? ?? '—',
        description = j['description'] as String? ?? '',
        contractor = j['contractor'] as String?,
        internalNote = j['internalNote'] as String?,
        hasPhoto = j['hasPhoto'] as bool? ?? false,
        updates = ((j['chairmanUpdates'] as List?) ?? [])
            .map((e) => ReportUpdate.from(e as Map))
            .toList();

  final String id, title, category, status, location, dateTime, resident, description;
  final String? contractor, internalNote;
  final bool hasPhoto;
  final List<ReportUpdate> updates;

  /// Server (resident-app) status code for a panel tab key.
  static String toServer(String tab) => {
        'new': 'waitingResponse',
        'inProgress': 'inProgress',
        'waitingCity': 'waitingCity',
        'resolved': 'resolved',
      }[tab] ??
      tab;

  /// Panel tab key for a server status.
  static String toTab(String s) => {
        'waitingResponse': 'new',
        'new': 'new',
        'inProgress': 'inProgress',
        'waitingCity': 'waitingCity',
        'resolved': 'resolved',
      }[s] ??
      'new';
}

class AdminContact {
  AdminContact(Map<String, dynamic> j)
      : id = j['id'] as String? ?? '',
        kind = j['kind'] as String? ?? 'important',
        name = j['name'] as String? ?? '',
        role = j['role'] as String? ?? '',
        subtitle = j['subtitle'] as String? ?? '',
        category = j['category'] as String? ?? 'other',
        badge = j['badge'] as String?,
        phone = j['phone'] as String? ?? '';
  final String id, kind, name, role, subtitle, category, phone;
  final String? badge;
}

class AdminAnnouncement {
  AdminAnnouncement(Map<String, dynamic> j)
      : id = j['id'] as String? ?? '',
        type = j['type'] as String? ?? 'update',
        title = j['title'] as String? ?? '',
        titleKk = j['titleKk'] as String? ?? '',
        message = j['message'] as String? ?? '',
        messageKk = j['messageKk'] as String? ?? '',
        audienceLabel = j['audienceLabel'] as String? ?? '',
        date = j['date'] as String? ?? '',
        seenBy = (j['seenBy'] as num?)?.toInt() ?? 0,
        pinned = j['pinned'] as bool? ?? false;
  final String id, type, title, titleKk, message, messageKk, audienceLabel, date;
  final int seenBy;
  final bool pinned;
}

class PollOption {
  PollOption(this.id, this.label, this.votes);
  final int id;
  final String label;
  final int votes;
  factory PollOption.from(Map j) =>
      PollOption((j['id'] as num?)?.toInt() ?? 0, j['label'] as String? ?? '', (j['votes'] as num?)?.toInt() ?? 0);
}

class PollVoter {
  PollVoter(this.name, this.optionId);
  final String name;
  final int optionId;
  factory PollVoter.from(Map j) =>
      PollVoter(j['name'] as String? ?? '', (j['optionId'] as num?)?.toInt() ?? 0);
}

class AdminPoll {
  AdminPoll(Map<String, dynamic> j)
      : id = j['id'] as String? ?? '',
        question = j['question'] as String? ?? '',
        status = j['status'] as String? ?? 'active',
        category = j['category'] as String?,
        audienceLabel = j['audienceLabel'] as String? ?? '',
        endsAt = j['endsAt'] as String? ?? '',
        households = (j['households'] as num?)?.toInt() ?? 0,
        confidential = j['confidential'] as bool? ?? true,
        options = ((j['options'] as List?) ?? []).map((e) => PollOption.from(e as Map)).toList(),
        voters = ((j['voters'] as List?) ?? []).map((e) => PollVoter.from(e as Map)).toList();
  final String id, question, status, audienceLabel, endsAt;
  final String? category;
  final int households;
  final bool confidential;
  final List<PollOption> options;
  final List<PollVoter> voters;
  int get totalVotes => options.fold(0, (s, o) => s + o.votes);
}

class AdminResident {
  AdminResident(Map<String, dynamic> j)
      : id = j['id'] as String? ?? '',
        name = j['name'] as String? ?? '—',
        initials = j['initials'] as String? ?? '—',
        phone = j['phone'] as String? ?? '',
        address = j['address'] as String? ?? '',
        status = j['status'] as String? ?? 'invited',
        inviteCode = j['inviteCode'] as String?;
  final String id, name, initials, phone, address, status;
  final String? inviteCode;
}

class Street {
  Street(Map<String, dynamic> j)
      : name = j['name'] as String? ?? '',
        connected = (j['connected'] as num?)?.toInt() ?? 0,
        total = (j['total'] as num?)?.toInt() ?? 0;
  final String name;
  final int connected, total;
}

class ResidentsData {
  ResidentsData(Map<String, dynamic> j)
      : residents = ((j['residents'] as List?) ?? [])
            .map((e) => AdminResident((e as Map).cast<String, dynamic>()))
            .toList(),
        streets = ((j['streets'] as List?) ?? [])
            .map((e) => Street((e as Map).cast<String, dynamic>()))
            .toList(),
        connected = ((j['community'] as Map?)?['connected'] as num?)?.toInt() ?? 0,
        total = ((j['community'] as Map?)?['total'] as num?)?.toInt() ?? 0;
  final List<AdminResident> residents;
  final List<Street> streets;
  final int connected, total;
}
