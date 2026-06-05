export type Category = 'water' | 'roads' | 'lights' | 'garbage' | 'safety' | 'other';

// Coarse status (matches the Reports tabs in the chairman app).
export type ReportStatus = 'new' | 'inProgress' | 'waitingCity' | 'resolved';

// Granular stage set by the "Quick update" chips.
export type ReportStage =
  | 'inspected'
  | 'scheduledRepair'
  | 'waitingCity'
  | 'contractorAssigned'
  | 'resolved';

export interface TimelineEntry {
  time: string;
  title: string;
  body?: string;
  done: boolean;
}

export interface Report {
  id: string;
  title: string;
  category: Category;
  status: ReportStatus;
  urgent: boolean;
  location: string;
  resident: string;
  ago: string; // "15 минут назад"
  date: string; // "16 мая, 21:30"
  description: string;
  contractor?: string;
  internalNote?: string;
  hasPhoto: boolean;
  timeline: TimelineEntry[];
  needsUpdate?: string; // SLA hint, e.g. "Житель ждёт 2 ч"
}

export type AnnouncementType =
  | 'maintenance'
  | 'water'
  | 'electricity'
  | 'community'
  | 'important'
  | 'event';

export type Audience = 'all' | 'street' | 'zone';

export interface Announcement {
  id: string;
  type: AnnouncementType;
  title: string;
  titleKk: string;
  message: string;
  messageKk: string;
  publishNow: boolean;
  audience: Audience;
  audienceLabel: string;
  date: string;
  seenBy: number;
  pinned: boolean;
}

export type PollCategory = 'infrastructure' | 'safety' | 'budget' | 'community' | 'event';

export type PollStatus = 'active' | 'upcoming' | 'closed';

export interface PollOption {
  id?: number;
  label: string;
  votes: number;
}

export interface PollVoter {
  name: string;
  optionId: number;
}

export interface Poll {
  id: string;
  category?: PollCategory;
  question: string;
  questionKk: string;
  options: PollOption[];
  status: PollStatus;
  durationDays: number;
  audienceLabel: string;
  households: number;
  endsAt: string;
  confidential: boolean;
  voters: PollVoter[];
}

export type ResidentStatus = 'active' | 'invited' | 'notJoined';

export interface ResidentMetrics {
  reports: number;
  polls: number;
  pollsTotal: number;
  announcementsRead: number; // percent
  lastActive: string;
  firstLogin: string;
  participation: 'Высокая' | 'Средняя' | 'Низкая';
}

export interface Resident {
  id: string;
  name: string;
  initials: string;
  phone: string;
  address: string;
  street: string;
  status: ResidentStatus;
  inviteCode?: string; // works as a password until changed; never expires
  metrics?: ResidentMetrics;
  adminNote?: string;
}

export interface Street {
  id: string;
  name: string;
  connected: number;
  total: number;
}

export interface ApprovalRequest {
  id: string;
  name: string;
  initials: string;
  address: string;
  joinedAgo: string;
}
