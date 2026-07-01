// Live API client for the Korshi admin panel.
// In production nginx serves this SPA and reverse-proxies /api → backend.
import type {
  Report,
  ReportStatus,
  Announcement,
  Poll,
  Resident,
  Street,
} from '../types';

const BASE = ((import.meta as { env?: Record<string, string> }).env?.VITE_API_BASE) || '/api';
const TOKEN_KEY = 'korshi_admin_token';

export function getToken(): string | null {
  return localStorage.getItem(TOKEN_KEY);
}
export function setToken(t: string | null) {
  if (t) localStorage.setItem(TOKEN_KEY, t);
  else localStorage.removeItem(TOKEN_KEY);
}

export class ApiError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

async function request<T>(path: string, opts: RequestInit = {}): Promise<T> {
  const headers: Record<string, string> = { ...(opts.headers as Record<string, string>) };
  const token = getToken();
  if (token) headers.Authorization = `Bearer ${token}`;
  if (opts.body && !(opts.body instanceof FormData)) headers['Content-Type'] = 'application/json';

  // Abort hung requests so a stuck connection can't freeze a modal/spinner.
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), 15000);
  let res: Response;
  try {
    res = await fetch(`${BASE}${path}`, { ...opts, headers, signal: ctrl.signal });
  } catch {
    throw new ApiError(0, ctrl.signal.aborted ? 'Превышено время ожидания сервера' : 'Не удалось связаться с сервером');
  } finally {
    clearTimeout(timer);
  }
  if (res.status === 401) {
    setToken(null);
    throw new ApiError(401, 'Сессия истекла. Войдите снова.');
  }
  if (!res.ok) {
    let msg = `Ошибка ${res.status}`;
    try {
      const j = await res.json();
      if (j?.error) msg = j.error;
    } catch { /* ignore */ }
    throw new ApiError(res.status, msg);
  }
  if (res.status === 204) return undefined as T;
  return (await res.json()) as T;
}

// ── status mapping (server uses the resident-app vocabulary) ──
const SRV_TO_ADMIN: Record<string, ReportStatus> = {
  waitingResponse: 'new',
  new: 'new',
  inProgress: 'inProgress',
  waitingCity: 'waitingCity',
  resolved: 'resolved',
};
const ADMIN_TO_SRV: Record<ReportStatus, string> = {
  new: 'waitingResponse',
  inProgress: 'inProgress',
  waitingCity: 'waitingCity',
  resolved: 'resolved',
};

interface SrvReport {
  id: string;
  title: string;
  category: string;
  status: string;
  location: string;
  dateTime: string;
  author: string;
  description: string;
  contractor: string | null;
  internalNote: string | null;
  chairmanUpdates: { date: string; body: string }[];
  resident?: string;
  hasPhoto?: boolean;
}

function adaptReport(r: SrvReport): Report {
  return {
    id: r.id,
    title: r.title,
    category: (r.category as Report['category']) || 'other',
    status: SRV_TO_ADMIN[r.status] || 'new',
    urgent: false,
    location: r.location || '',
    resident: r.resident || r.author || '—',
    ago: r.dateTime || '',
    date: r.dateTime || '',
    description: r.description || '',
    contractor: r.contractor || undefined,
    internalNote: r.internalNote || undefined,
    hasPhoto: !!r.hasPhoto,
    timeline: (r.chairmanUpdates || []).map((u) => ({
      time: u.date,
      title: u.body,
      done: true,
    })),
  };
}

// ── auth ──
export type AdminRole = 'super' | 'admin';
export interface LoginResult {
  token: string;
  email: string;
  role: AdminRole;
  neighborhood: { id: string; name: string } | null;
}
export async function adminLogin(email: string, password: string): Promise<LoginResult> {
  const r = await request<LoginResult>('/auth/admin/login', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  });
  setToken(r.token);
  return r;
}

// ── reports ──
export async function fetchReports(): Promise<Report[]> {
  const rows = await request<SrvReport[]>('/admin/reports');
  return rows.map(adaptReport);
}
export async function patchReport(
  id: string,
  body: { status?: ReportStatus; contractor?: string; internalNote?: string },
) {
  const payload: Record<string, unknown> = {};
  if (body.status) payload.status = ADMIN_TO_SRV[body.status];
  if (body.contractor !== undefined) payload.contractor = body.contractor;
  if (body.internalNote !== undefined) payload.internalNote = body.internalNote;
  return adaptReport(await request<SrvReport>(`/admin/reports/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(payload),
  }));
}
export async function deleteReport(id: string) {
  return request(`/admin/reports/${id}`, { method: 'DELETE' });
}
export async function addReportUpdate(id: string, text: string) {
  return adaptReport(await request<SrvReport>(`/admin/reports/${id}/update`, {
    method: 'POST',
    body: JSON.stringify({ body: text }),
  }));
}
/** Report photo URL (token in query so a plain <img> can load it). */
export function reportPhotoUrl(id: string): string {
  return `${BASE}/reports/${id}/photo?token=${getToken() ?? ''}`;
}

// ── stats ──
export interface AdminStats {
  neighborhood: string;
  reportsNew: number;
  reportsInProgress: number;
  reportsResolved: number;
  reportsTotal: number;
  announcements: number;
  activePolls: number;
  residents: number;
}
export async function fetchStats(): Promise<AdminStats> {
  return request<AdminStats>('/admin/stats');
}

// ── announcements ──
export async function fetchAnnouncements(): Promise<Announcement[]> {
  const rows = await request<any[]>('/admin/announcements');
  return rows.map((a) => ({
    id: a.id, type: a.type, title: a.title, titleKk: a.titleKk ?? '',
    message: a.message, messageKk: a.messageKk ?? '',
    publishNow: true, audience: a.audience, audienceLabel: a.audienceLabel,
    date: a.date, seenBy: a.seenBy, pinned: a.pinned,
  }));
}
export async function createAnnouncement(body: {
  type: string; title: string; titleKk: string; message: string; messageKk: string;
  audience: string; audienceLabel: string; publishNow: boolean;
}) {
  return request<{ id: string }>('/admin/announcements', { method: 'POST', body: JSON.stringify(body) });
}
export async function pinAnnouncement(id: string, pinned: boolean) {
  return request(`/admin/announcements/${id}`, { method: 'PATCH', body: JSON.stringify({ pinned }) });
}
export async function updateAnnouncement(id: string, body: {
  type: string; title: string; titleKk: string; message: string; messageKk: string;
}) {
  return request(`/admin/announcements/${id}`, { method: 'PATCH', body: JSON.stringify(body) });
}
export async function deleteAnnouncement(id: string) {
  return request(`/admin/announcements/${id}`, { method: 'DELETE' });
}

// ── polls ──
export async function fetchPolls(): Promise<Poll[]> {
  const rows = await request<any[]>('/admin/polls');
  return rows.map((p) => ({
    id: p.id, category: p.category || undefined, question: p.question, questionKk: p.questionKk ?? '',
    options: p.options, status: p.status, durationDays: p.durationDays,
    audienceLabel: p.audienceLabel, households: p.households, endsAt: p.endsAt,
    confidential: !!p.confidential,
    voters: (p.voters ?? []) as { name: string; optionId: number }[],
  }));
}
export async function createPoll(body: {
  category?: string;
  question: string;
  questionKk: string;
  description?: string;
  descriptionKk?: string;
  options: string[];
  optionsKk: string[];
  durationDays: number;
  audienceLabel: string;
  confidential: boolean;
}) {
  return request<{ id: string }>('/admin/polls', { method: 'POST', body: JSON.stringify(body) });
}
export async function deletePoll(id: string) {
  return request(`/admin/polls/${id}`, { method: 'DELETE' });
}

// ── residents ──
export async function fetchResidents(): Promise<{
  residents: Resident[];
  streets: Street[];
  community: { connected: number; total: number };
}> {
  const r = await request<any>('/admin/residents');
  return {
    residents: r.residents.map((x: any) => ({
      id: x.id, name: x.name, initials: x.initials, phone: x.phone,
      address: x.address, street: x.street, status: x.status, inviteCode: x.inviteCode || undefined,
    })),
    streets: r.streets,
    community: r.community,
  };
}
export async function inviteResident(body: { phone: string; address: string; name?: string }) {
  return request<{ id: string; activationCode: string }>('/admin/residents/invite', {
    method: 'POST',
    body: JSON.stringify(body),
  });
}
export async function deleteResident(id: string) {
  return request(`/admin/residents/${id}`, { method: 'DELETE' });
}

// ── cover ──
export async function uploadCover(file: File) {
  const fd = new FormData();
  fd.append('image', file);
  return request('/neighborhood/cover', { method: 'POST', body: fd });
}

// ── super admin: neighborhoods ──
export interface NeighborhoodRow {
  id: string;
  name: string;
  adminEmail: string | null;
  residents: number;
  reports: number;
  createdAt: string;
}
export async function listNeighborhoods(): Promise<NeighborhoodRow[]> {
  return request<NeighborhoodRow[]>('/super/neighborhoods');
}
export async function createNeighborhood(body: {
  name: string;
  adminEmail: string;
  adminPassword: string;
}) {
  return request<{ id: string }>('/super/neighborhoods', {
    method: 'POST',
    body: JSON.stringify(body),
  });
}
export async function updateNeighborhood(
  id: string,
  body: { name?: string; adminEmail?: string; adminPassword?: string },
) {
  return request(`/super/neighborhoods/${id}`, { method: 'PATCH', body: JSON.stringify(body) });
}
export async function deleteNeighborhood(id: string) {
  return request(`/super/neighborhoods/${id}`, { method: 'DELETE' });
}

// ── contacts ──
export type ContactKind = 'important' | 'service' | 'partner';
export type ContactCategory = 'water' | 'roads' | 'lights' | 'garbage' | 'safety' | 'other';
export type ContactBadge = 'chairman' | 'police' | 'emergency' | null;
export interface ContactRow {
  id: string;
  kind: ContactKind;
  name: string;
  role: string;
  subtitle: string | null;
  statusLine: string | null;
  category: ContactCategory;
  badge: ContactBadge;
  phone: string;
  ord: number;
}
export interface ContactInput {
  kind?: ContactKind; // required for super create (service|partner)
  name: string;
  role?: string;
  subtitle?: string;
  category?: ContactCategory;
  badge?: ContactBadge;
  phone?: string;
}

// Chairman — important contacts for their own neighborhood.
export async function fetchImportantContacts(): Promise<ContactRow[]> {
  return request<ContactRow[]>('/admin/contacts');
}
export async function createImportantContact(body: ContactInput) {
  return request<{ id: string }>('/admin/contacts', { method: 'POST', body: JSON.stringify(body) });
}
export async function updateImportantContact(id: string, body: Partial<ContactInput>) {
  return request(`/admin/contacts/${id}`, { method: 'PATCH', body: JSON.stringify(body) });
}
export async function deleteImportantContact(id: string) {
  return request(`/admin/contacts/${id}`, { method: 'DELETE' });
}

// Super-admin — services + partners for a chosen neighborhood.
export async function fetchNeighborhoodContacts(nid: string): Promise<ContactRow[]> {
  return request<ContactRow[]>(`/super/neighborhoods/${nid}/contacts`);
}
export async function createNeighborhoodContact(nid: string, body: ContactInput) {
  return request<{ id: string }>(`/super/neighborhoods/${nid}/contacts`, {
    method: 'POST',
    body: JSON.stringify(body),
  });
}
export async function updateNeighborhoodContact(id: string, body: Partial<ContactInput>) {
  return request(`/super/contacts/${id}`, { method: 'PATCH', body: JSON.stringify(body) });
}
export async function deleteNeighborhoodContact(id: string) {
  return request(`/super/contacts/${id}`, { method: 'DELETE' });
}
