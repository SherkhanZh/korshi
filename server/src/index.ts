import express from 'express';
import cors from 'cors';
import multer from 'multer';
import bcrypt from 'bcryptjs';
import path from 'path';
import fs from 'fs';
import { db, seed, neighborhoodName, createNeighborhood } from './db';
import jwt from 'jsonwebtoken';
import { signToken, requireAdmin, requireSuper, requireResident, requireUser, type AuthedRequest, type TokenPayload } from './auth';
import { sendToTokens, type PushMessage } from './push';

seed();

const app = express();
const PORT = Number(process.env.PORT) || 3000;
app.use(cors());
app.use(express.json());

// Uploaded files (cover images + report photos) live here.
const uploadsDir = path.join(process.cwd(), 'data', 'uploads');
fs.mkdirSync(uploadsDir, { recursive: true });

// Report photos are received in memory, then written with the new report id.
const reportUpload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 12 * 1024 * 1024 } });

const q = (sql: string) => db.prepare(sql);
const digits = (s: string) => (s || '').replace(/\D/g, '');
const last10 = (s: string) => digits(s).slice(-10);
const nowMs = () => Date.now();

// ── In-memory rate limiting (single-process server) ──
const _rl = new Map<string, { count: number; reset: number }>();
/** Increments the counter for [key] within [windowMs]; returns the new count. */
function rlBump(key: string, windowMs: number): number {
  const now = nowMs();
  const b = _rl.get(key);
  if (!b || now > b.reset) { _rl.set(key, { count: 1, reset: now + windowMs }); return 1; }
  b.count++;
  return b.count;
}
function rlPeek(key: string): number {
  const b = _rl.get(key);
  return b && nowMs() <= b.reset ? b.count : 0;
}
function rlClear(key: string): void { _rl.delete(key); }
function clientIp(req: any): string {
  const fwd = (req.headers?.['x-forwarded-for'] as string | undefined)?.split(',')[0];
  return (fwd || req.socket?.remoteAddress || 'unknown').trim();
}

// All human-readable timestamps are rendered in the neighborhood's timezone.
const TZ = process.env.TZ || 'Asia/Almaty';
function nowDateTime(): string {
  const d = new Date();
  const date = d.toLocaleDateString('ru-RU', { timeZone: TZ, day: 'numeric', month: 'long', year: 'numeric' });
  const time = d.toLocaleTimeString('ru-RU', { timeZone: TZ, hour: '2-digit', minute: '2-digit' });
  return `${date} · ${time}`;
}
function nowDateShort(): string {
  return new Date().toLocaleDateString('ru-RU', { timeZone: TZ, day: 'numeric', month: 'long' });
}

// ───────────────────────── helpers / mappers ─────────────────────────
function annTypeCategory(t: string): string {
  return { water: 'water', electricity: 'lights', maintenance: 'roads', community: 'other', important: 'other', event: 'other' }[t] || 'other';
}
function annTypeStatus(t: string): string {
  if (t === 'event') return 'event';
  if (t === 'important') return 'upcoming';
  return 'update';
}

function reportRow(r: any) {
  const updates = JSON.parse(r.updates_json || '[]');
  const last = updates[updates.length - 1];
  return {
    id: r.id,
    title: r.title,
    category: r.category,
    status: r.status,
    location: r.location,
    dateTime: r.date_time,
    author: r.author,
    chairmanNote: last ? last.body : 'Заявка получена.',
    updatedLabel: last ? `Обновлено: ${last.date}` : 'Обновлено недавно',
    steps: JSON.parse(r.steps_json || '[]'),
    hasPhoto: !!r.photo,
  };
}
function reportDetail(r: any) {
  return {
    ...reportRow(r),
    description: r.description,
    contractor: r.contractor || null,
    internalNote: r.internal_note || null,
    detailSteps: JSON.parse(r.detail_steps_json || '[]'),
    chairmanUpdates: JSON.parse(r.updates_json || '[]'),
  };
}

function activePoll(nid: string) {
  const p = q(`SELECT * FROM polls WHERE status='active' AND neighborhood_id=? ORDER BY created_at DESC LIMIT 1`).get(nid) as any;
  if (!p) return null;
  const opts = q('SELECT * FROM poll_options WHERE poll_id=? ORDER BY ord').all(p.id) as any[];
  const total = opts.reduce((s, o) => s + o.votes, 0);
  return { p, opts, total };
}

/** Real unique-resident view count for an announcement. */
function seenCount(annId: string): number {
  return (q('SELECT COUNT(*) n FROM announcement_views WHERE announcement_id=?').get(annId) as any).n;
}

/** Who voted for what — exposed only for public (non-confidential) polls. */
function pollVoters(pollId: string) {
  return (q(
    `SELECT r.name AS name, v.option_id AS optionId
     FROM votes v JOIN residents r ON r.id = v.resident_id
     WHERE v.poll_id = ? ORDER BY r.name`,
  ).all(pollId) as any[]).map((x) => ({ name: x.name && x.name !== '—' ? x.name : 'Житель', optionId: x.optionId }));
}

// ───────────────────────── push notifications ─────────────────────────
function tokensWhere(sql: string, ...params: unknown[]): string[] {
  return (q(`SELECT token FROM device_tokens WHERE ${sql}`).all(...params) as any[]).map((r) => r.token);
}
function pruneTokens(dead: string[]) {
  if (!dead.length) return;
  const del = q('DELETE FROM device_tokens WHERE token=?');
  for (const t of dead) del.run(t);
}
/** Fire-and-forget push to a set of tokens; prunes dead tokens afterwards. */
function notify(tokens: string[], msg: PushMessage) {
  if (tokens.length === 0) return;
  sendToTokens(tokens, msg).then(pruneTokens).catch((e) => console.warn('[push] notify error', e?.message));
}
const notifyResident = (residentId: string, msg: PushMessage) =>
  notify(tokensWhere("user_type='resident' AND user_id=?", residentId), msg);
const notifyNeighborhoodResidents = (nid: string, msg: PushMessage) =>
  notify(tokensWhere("user_type='resident' AND neighborhood_id=?", nid), msg);
const notifyNeighborhoodResidentsExcept = (nid: string, exceptResidentId: string, msg: PushMessage) =>
  notify(tokensWhere("user_type='resident' AND neighborhood_id=? AND user_id<>?", nid, exceptResidentId), msg);
const notifyNeighborhoodAdmins = (nid: string, msg: PushMessage) =>
  notify(tokensWhere("user_type='admin' AND neighborhood_id=?", nid), msg);

// ─── In-app notification inbox (fan-out one row per resident) ───
type NotifKind = 'report' | 'announcement' | 'poll';
let notifSeq = 0;
function recordResidentNotif(
  nid: string,
  residentId: string,
  n: { type: NotifKind; refId: string; title: string; body: string },
) {
  q(`INSERT INTO notifications (id,neighborhood_id,resident_id,type,ref_id,title,body,read,created_at)
     VALUES (?,?,?,?,?,?,?,0,?)`).run(
    `n${nowMs()}_${++notifSeq}`, nid, residentId, n.type, n.refId, n.title, n.body, String(nowMs()),
  );
}
function recordNeighborhoodNotif(
  nid: string,
  except: string | null,
  n: { type: NotifKind; refId: string; title: string; body: string },
) {
  const residents = q('SELECT id FROM residents WHERE neighborhood_id=?').all(nid) as any[];
  for (const r of residents) {
    if (except && r.id === except) continue;
    recordResidentNotif(nid, r.id, n);
  }
}

app.post('/api/push/register', requireUser, (req: AuthedRequest, res) => {
  const token = String(req.body?.token || '').trim();
  if (!token) return res.status(400).json({ error: 'token required' });
  const role = req.auth!.role; // 'resident' | 'admin'
  q(`INSERT INTO device_tokens (token,user_type,user_id,neighborhood_id,app,platform,created_at)
     VALUES (?,?,?,?,?,?,?)
     ON CONFLICT(token) DO UPDATE SET user_type=excluded.user_type, user_id=excluded.user_id,
       neighborhood_id=excluded.neighborhood_id, app=excluded.app, platform=excluded.platform`).run(
    token, role, req.auth!.sub, req.auth!.nid!, role === 'admin' ? 'admin' : 'client',
    String(req.body?.platform || ''), new Date().toISOString());
  res.json({ ok: true });
});

app.post('/api/push/unregister', requireUser, (req: AuthedRequest, res) => {
  const token = String(req.body?.token || '').trim();
  if (token) q('DELETE FROM device_tokens WHERE token=?').run(token);
  res.json({ ok: true });
});

// ───────────────────────── health ─────────────────────────
app.get('/api/health', (_req, res) =>
  res.json({ status: 'ok', service: 'korshi-server', version: '0.4.0', time: new Date().toISOString() }));

// ───────────────────────── auth ─────────────────────────
app.post('/api/auth/admin/login', (req, res) => {
  const ip = clientIp(req);
  if (rlPeek(`adminlogin:${ip}`) > 15) {
    return res.status(429).json({ error: 'Слишком много попыток. Попробуйте позже.' });
  }
  const { email, password } = req.body ?? {};
  const a = q('SELECT * FROM admins WHERE email=?').get(String(email || '').toLowerCase()) as any;
  if (!a || !bcrypt.compareSync(String(password || ''), a.password_hash)) {
    rlBump(`adminlogin:${ip}`, 15 * 60 * 1000);
    return res.status(401).json({ error: 'Неверный email или пароль' });
  }
  rlClear(`adminlogin:${ip}`);
  res.json({
    token: signToken({ sub: String(a.id), role: a.role, nid: a.neighborhood_id || undefined }),
    email: a.email,
    role: a.role,
    neighborhood: a.neighborhood_id
      ? { id: a.neighborhood_id, name: neighborhoodName(a.neighborhood_id) }
      : null,
  });
});

app.post('/api/auth/resident/login', (req, res) => {
  // Brute-force protection: cap failed attempts per IP and per phone.
  const ip = clientIp(req);
  const phoneKey = last10(String(req.body?.phone ?? ''));
  if (rlPeek(`login:ip:${ip}`) > 20 || rlPeek(`login:ph:${phoneKey}`) > 8) {
    return res.status(429).json({ error: 'Слишком много попыток. Попробуйте позже.' });
  }
  const fail = (status: number, error: string) => {
    rlBump(`login:ip:${ip}`, 15 * 60 * 1000);
    rlBump(`login:ph:${phoneKey}`, 15 * 60 * 1000);
    return res.status(status).json({ error });
  };

  const phone = String(req.body?.phone ?? '');
  const secret = String(req.body?.secret ?? '').trim();
  if (!phone || !secret) return res.status(400).json({ error: 'phone and secret required' });
  const key = last10(phone);
  const all = q('SELECT * FROM residents').all() as any[];
  const r = all.find((x) => last10(x.phone) === key);
  if (!r) return fail(404, 'Житель не найден. Обратитесь к председателю.');

  let ok = false;
  if (r.password_hash) ok = bcrypt.compareSync(secret, r.password_hash);
  if (!ok && r.invite_code) ok = secret.toUpperCase() === String(r.invite_code).toUpperCase();
  if (!ok) return fail(401, 'Неверный код или пароль');

  rlClear(`login:ip:${ip}`);
  rlClear(`login:ph:${phoneKey}`);

  if (r.status === 'invited' || r.status === 'notJoined') {
    q("UPDATE residents SET status='active' WHERE id=?").run(r.id);
  }
  res.json({
    token: signToken({ sub: r.id, role: 'resident', nid: r.neighborhood_id }),
    resident: { id: r.id, name: r.name, phone: r.phone, address: r.address },
    neighborhood: { id: r.neighborhood_id, name: neighborhoodName(r.neighborhood_id) },
    hasPassword: !!r.password_hash,
  });
});

app.post('/api/auth/resident/password', requireResident, (req: AuthedRequest, res) => {
  const pw = String(req.body?.password ?? '');
  if (pw.length < 4) return res.status(400).json({ error: 'Пароль слишком короткий' });
  q('UPDATE residents SET password_hash=? WHERE id=?').run(bcrypt.hashSync(pw, 10), req.auth!.sub);
  res.json({ ok: true });
});

// ───────────────────────── resident data ─────────────────────────
app.get('/api/me', requireResident, (req: AuthedRequest, res) => {
  const r = q('SELECT id,name,phone,address,street,status FROM residents WHERE id=?').get(req.auth!.sub) as any;
  res.json({ ...r, neighborhood: neighborhoodName(req.auth!.nid) });
});

function feedItems(nid: string, residentId: string) {
  // Only the resident's own reports appear in their feed (and stay openable).
  const reports = (q('SELECT * FROM reports WHERE neighborhood_id=? AND resident_id=? ORDER BY created_at DESC LIMIT 6')
    .all(nid, residentId) as any[]).map((r) => ({
    title: r.title,
    subtitle: `${r.location} · недавно`,
    body: r.description,
    category: r.category,
    status: r.status,
    seenBy: 0,
    kind: 'report',
    reportId: r.id,
    created: Number(r.created_at) || 0,
  }));
  const anns = (q('SELECT * FROM announcements WHERE neighborhood_id=? ORDER BY created_at DESC').all(nid) as any[]).map((a) => ({
    id: a.id,
    title: a.title,
    titleKk: a.title_kk || a.title,
    subtitle: a.date,
    body: a.message,
    bodyKk: a.message_kk || a.message,
    category: annTypeCategory(a.type),
    status: annTypeStatus(a.type),
    seenBy: seenCount(a.id),
    kind: 'announcement',
    created: Number(a.created_at) || 0,
  }));
  return [...reports, ...anns].sort((x, y) => y.created - x.created);
}

/** Pinned banner — only when something is actually pinned. */
function pinnedAnnouncement(nid: string): any | null {
  return (q(`SELECT * FROM announcements WHERE neighborhood_id=? AND pinned=1 ORDER BY created_at DESC LIMIT 1`).get(nid) as any) || null;
}

app.get('/api/home', requireResident, (req: AuthedRequest, res) => {
  const nid = req.auth!.nid!;
  const pinned = pinnedAnnouncement(nid);
  const feed = feedItems(nid, req.auth!.sub).slice(0, 3).map(({ created, ...x }) => x);
  const ap = activePoll(nid);
  let yesPct = 0, noPct = 0;
  if (ap && ap.total > 0) {
    const yes = ap.opts.find((o) => o.positive) || ap.opts[0];
    yesPct = Math.round((yes.votes / ap.total) * 100);
    noPct = 100 - yesPct;
  }
  const chair = q(`SELECT * FROM contacts WHERE neighborhood_id=? AND badge='chairman' LIMIT 1`).get(nid) as any;
  const svcs = q(`SELECT * FROM contacts WHERE neighborhood_id=? AND kind='service' ORDER BY ord LIMIT 2`).all(nid) as any[];
  const contacts = [chair, ...svcs].filter(Boolean).map((c) => ({
    name: c.name, role: c.role, category: c.category, phone: c.phone,
  }));
  const partner = q(`SELECT * FROM contacts WHERE neighborhood_id=? AND kind='partner' ORDER BY ord LIMIT 1`).get(nid) as any;
  res.json({
    neighborhood: neighborhoodName(nid),
    announcement: pinned
      ? {
          id: pinned.id,
          title: pinned.title,
          titleKk: pinned.title_kk || pinned.title,
          date: pinned.date,
          body: pinned.message,
          bodyKk: pinned.message_kk || pinned.message,
        }
      : { id: '', title: '', titleKk: '', date: '', body: '', bodyKk: '' },
    today: feed,
    poll: {
      question: ap?.p.question || '',
      questionKk: ap?.p.question_kk || ap?.p.question || '',
      yesPct,
      noPct,
    },
    contacts,
    partner: partner
      ? { title: partner.name, subtitle: partner.role, rating: '4.9', reviews: '128', phone: partner.phone }
      : { title: '', subtitle: '', rating: '0.0', reviews: '0', phone: '' },
  });
});

app.get('/api/updates', requireResident, (req: AuthedRequest, res) => {
  const nid = req.auth!.nid!;
  const pinned = pinnedAnnouncement(nid);
  const latest = feedItems(nid, req.auth!.sub).map(({ created, ...x }) => x);
  res.json({
    pinned: pinned
      ? {
          id: pinned.id,
          title: pinned.title,
          titleKk: pinned.title_kk || pinned.title,
          date: pinned.date,
          body: pinned.message,
          bodyKk: pinned.message_kk || pinned.message,
          seenBy: seenCount(pinned.id),
        }
      : { id: '', title: '', titleKk: '', date: '', body: '', bodyKk: '', seenBy: 0 },
    latest,
  });
});

// Mark an announcement as seen by the logged-in resident (idempotent).
app.post('/api/announcements/:id/seen', requireResident, (req: AuthedRequest, res) => {
  const ann = q('SELECT id FROM announcements WHERE id=? AND neighborhood_id=?').get(req.params.id, req.auth!.nid!) as any;
  if (!ann) return res.status(404).json({ error: 'not found' });
  q('INSERT OR IGNORE INTO announcement_views (announcement_id, resident_id) VALUES (?,?)').run(ann.id, req.auth!.sub);
  res.json({ seenBy: seenCount(ann.id) });
});

app.get('/api/contacts', requireResident, (req: AuthedRequest, res) => res.json(contactsPayload(req.auth!.nid!)));

// Admin-facing contact shape (id + editable fields).
function contactOut(c: any) {
  return {
    id: c.id, kind: c.kind, name: c.name, role: c.role,
    subtitle: c.subtitle, statusLine: c.status_line,
    category: c.category, badge: c.badge, phone: c.phone, ord: c.ord,
  };
}
function nextContactOrd(nid: string, kind: string): number {
  const r = q('SELECT COALESCE(MAX(ord),-1)+1 n FROM contacts WHERE neighborhood_id=? AND kind=?').get(nid, kind) as any;
  return r?.n ?? 0;
}
const CATEGORIES = ['water', 'roads', 'lights', 'garbage', 'safety', 'other'];

// ── Chairman: important contacts for their own neighborhood ──
app.get('/api/admin/contacts', requireAdmin, (req: AuthedRequest, res) => {
  const rows = q("SELECT * FROM contacts WHERE neighborhood_id=? AND kind='important' ORDER BY ord, name").all(req.auth!.nid!) as any[];
  res.json(rows.map(contactOut));
});
app.post('/api/admin/contacts', requireAdmin, (req: AuthedRequest, res) => {
  const nid = req.auth!.nid!;
  const { name, role, subtitle, category, badge, phone } = req.body ?? {};
  if (!name || !String(name).trim()) return res.status(400).json({ error: 'Имя обязательно' });
  const cat = CATEGORIES.includes(category) ? category : 'other';
  const bd = ['chairman', 'police', 'emergency'].includes(badge) ? badge : null;
  const id = `ct${nowMs()}`;
  const sub = subtitle ? String(subtitle) : null;
  q(`INSERT INTO contacts (id,neighborhood_id,kind,name,role,subtitle,status_line,category,badge,phone,ord)
     VALUES (?,?,?,?,?,?,?,?,?,?,?)`).run(
    id, nid, 'important', String(name).trim(), String(role || ''), sub, sub, cat, bd, String(phone || ''),
    nextContactOrd(nid, 'important'));
  res.status(201).json({ id });
});
app.patch('/api/admin/contacts/:id', requireAdmin, (req: AuthedRequest, res) => {
  const c = q("SELECT * FROM contacts WHERE id=? AND neighborhood_id=? AND kind='important'").get(req.params.id, req.auth!.nid!) as any;
  if (!c) return res.status(404).json({ error: 'not found' });
  applyContactPatch(c.id, req.body ?? {}, true);
  res.json({ ok: true });
});
app.delete('/api/admin/contacts/:id', requireAdmin, (req: AuthedRequest, res) => {
  const c = q("SELECT id FROM contacts WHERE id=? AND neighborhood_id=? AND kind='important'").get(req.params.id, req.auth!.nid!) as any;
  if (!c) return res.status(404).json({ error: 'not found' });
  q('DELETE FROM contacts WHERE id=?').run(c.id);
  res.json({ ok: true });
});

// ── Super-admin: services + partners for any neighborhood ──
app.get('/api/super/neighborhoods/:nid/contacts', requireSuper, (req, res) => {
  const rows = q("SELECT * FROM contacts WHERE neighborhood_id=? AND kind IN ('service','partner') ORDER BY kind, ord, name").all(req.params.nid) as any[];
  res.json(rows.map(contactOut));
});
app.post('/api/super/neighborhoods/:nid/contacts', requireSuper, (req, res) => {
  const nid = req.params.nid;
  if (!q('SELECT id FROM neighborhoods WHERE id=?').get(nid)) return res.status(404).json({ error: 'neighborhood not found' });
  const { kind, name, role, subtitle, category, phone } = req.body ?? {};
  if (!['service', 'partner'].includes(kind)) return res.status(400).json({ error: 'kind must be service|partner' });
  if (!name || !String(name).trim()) return res.status(400).json({ error: 'Имя обязательно' });
  const cat = CATEGORIES.includes(category) ? category : 'other';
  const id = `ct${nowMs()}`;
  const sub = subtitle ? String(subtitle) : null;
  q(`INSERT INTO contacts (id,neighborhood_id,kind,name,role,subtitle,status_line,category,badge,phone,ord)
     VALUES (?,?,?,?,?,?,?,?,?,?,?)`).run(
    id, nid, kind, String(name).trim(), String(role || ''), sub, sub, cat, null, String(phone || ''),
    nextContactOrd(nid, kind));
  res.status(201).json({ id });
});
app.patch('/api/super/contacts/:id', requireSuper, (req, res) => {
  const c = q("SELECT * FROM contacts WHERE id=? AND kind IN ('service','partner')").get(req.params.id) as any;
  if (!c) return res.status(404).json({ error: 'not found' });
  applyContactPatch(c.id, req.body ?? {}, false);
  res.json({ ok: true });
});
app.delete('/api/super/contacts/:id', requireSuper, (req, res) => {
  const c = q("SELECT id FROM contacts WHERE id=? AND kind IN ('service','partner')").get(req.params.id) as any;
  if (!c) return res.status(404).json({ error: 'not found' });
  q('DELETE FROM contacts WHERE id=?').run(c.id);
  res.json({ ok: true });
});

function applyContactPatch(id: string, b: any, allowBadge: boolean) {
  if (b.name !== undefined) q('UPDATE contacts SET name=? WHERE id=?').run(String(b.name).trim(), id);
  if (b.role !== undefined) q('UPDATE contacts SET role=? WHERE id=?').run(String(b.role || ''), id);
  if (b.subtitle !== undefined) {
    const sub = b.subtitle ? String(b.subtitle) : null;
    q('UPDATE contacts SET subtitle=?, status_line=? WHERE id=?').run(sub, sub, id);
  }
  if (b.category !== undefined) q('UPDATE contacts SET category=? WHERE id=?').run(CATEGORIES.includes(b.category) ? b.category : 'other', id);
  if (b.phone !== undefined) q('UPDATE contacts SET phone=? WHERE id=?').run(String(b.phone || ''), id);
  if (allowBadge && b.badge !== undefined) {
    q('UPDATE contacts SET badge=? WHERE id=?').run(['chairman', 'police', 'emergency'].includes(b.badge) ? b.badge : null, id);
  }
}
function contactsPayload(nid: string) {
  const map = (c: any) => ({
    name: c.name, role: c.role, subtitle: c.subtitle, statusLine: c.status_line,
    category: c.category, badge: c.badge, phone: c.phone, desc: c.role,
  });
  return {
    important: (q(`SELECT * FROM contacts WHERE neighborhood_id=? AND kind='important' ORDER BY ord`).all(nid) as any[]).map(map),
    services: (q(`SELECT * FROM contacts WHERE neighborhood_id=? AND kind='service' ORDER BY ord`).all(nid) as any[]).map(map),
    partners: (q(`SELECT * FROM contacts WHERE neighborhood_id=? AND kind='partner' ORDER BY ord`).all(nid) as any[]).map(map),
  };
}

app.get('/api/polls', requireResident, (req: AuthedRequest, res) => {
  const nid = req.auth!.nid!;
  const ap = activePoll(nid);
  let active: any = {
    id: '', question: '', questionKk: '', description: '', descriptionKk: '',
    options: [], households: 0, endsInDays: 0, voted: false, votedOptionId: -1, confidential: true, voters: [],
  };
  if (ap) {
    const myVote = q('SELECT option_id FROM votes WHERE poll_id=? AND resident_id=?').get(ap.p.id, req.auth!.sub) as any;
    const voted = !!myVote;
    const isConfidential = !!ap.p.confidential;
    active = {
      id: ap.p.id,
      question: ap.p.question,
      questionKk: ap.p.question_kk || ap.p.question,
      description: ap.p.description,
      descriptionKk: ap.p.description_kk || ap.p.description,
      households: ap.total,
      endsInDays: ap.p.duration_days,
      voted,
      votedOptionId: myVote ? Number(myVote.option_id) : -1,
      confidential: isConfidential,
      voters: isConfidential ? [] : pollVoters(ap.p.id),
      options: ap.opts.map((o) => ({
        id: o.id,
        label: o.label,
        labelKk: o.label_kk || o.label,
        votes: o.votes, positive: !!o.positive,
        pct: ap.total ? Math.round((o.votes / ap.total) * 100) : 0,
      })),
    };
  }
  const upcoming = (q(`SELECT * FROM decisions WHERE neighborhood_id=? AND kind='upcoming' ORDER BY ord`).all(nid) as any[]).map((d) => ({
    title: d.title, subtitle: d.subtitle, category: d.category, opensLabel: d.opens_label, date: d.date,
  }));
  const previous = (q(`SELECT * FROM decisions WHERE neighborhood_id=? AND kind='previous' ORDER BY ord`).all(nid) as any[]).map((d) => ({
    title: d.title, subtitle: d.subtitle, status: d.status, date: d.date,
  }));
  const residents = (q('SELECT COUNT(*) n FROM residents WHERE neighborhood_id=?').get(nid) as any).n || 1;
  const voters = ap ? (q('SELECT COUNT(*) n FROM votes WHERE poll_id=?').get(ap.p.id) as any).n : 0;
  res.json({ participationPct: Math.min(100, Math.round((voters / residents) * 100)), active, upcoming, previous });
});

app.post('/api/polls/:id/vote', requireResident, (req: AuthedRequest, res) => {
  const nid = req.auth!.nid!;
  const poll = q('SELECT * FROM polls WHERE id=? AND neighborhood_id=?').get(req.params.id, nid) as any;
  if (!poll) return res.status(404).json({ error: 'poll not found' });
  const optionId = Number(req.body?.optionId);
  const opt = q('SELECT * FROM poll_options WHERE id=? AND poll_id=?').get(optionId, req.params.id) as any;
  if (!opt) return res.status(400).json({ error: 'invalid option' });
  const prev = q('SELECT option_id FROM votes WHERE poll_id=? AND resident_id=?').get(req.params.id, req.auth!.sub) as any;
  if (prev) {
    if (prev.option_id === optionId) return res.json({ ok: true });
    q('UPDATE poll_options SET votes=votes-1 WHERE id=?').run(prev.option_id);
    q('UPDATE votes SET option_id=? WHERE poll_id=? AND resident_id=?').run(optionId, req.params.id, req.auth!.sub);
  } else {
    q('INSERT INTO votes (poll_id,resident_id,option_id) VALUES (?,?,?)').run(req.params.id, req.auth!.sub, optionId);
  }
  q('UPDATE poll_options SET votes=votes+1 WHERE id=?').run(optionId);
  res.json({ ok: true });
});

app.get('/api/reports', requireResident, (req: AuthedRequest, res) => {
  const rows = q('SELECT * FROM reports WHERE resident_id=? AND neighborhood_id=? ORDER BY created_at DESC')
    .all(req.auth!.sub, req.auth!.nid!) as any[];
  res.json(rows.map(reportRow));
});

app.get('/api/reports/:id', requireResident, (req: AuthedRequest, res) => {
  // Any resident in the neighborhood can open a report (e.g. from a push).
  const r = q('SELECT * FROM reports WHERE id=? AND neighborhood_id=?').get(req.params.id, req.auth!.nid!) as any;
  if (!r) return res.status(404).json({ error: 'not found' });
  res.json(reportDetail(r));
});

// Single announcement (used when opening one from a push notification).
app.get('/api/announcements/:id', requireResident, (req: AuthedRequest, res) => {
  const a = q('SELECT * FROM announcements WHERE id=? AND neighborhood_id=?').get(req.params.id, req.auth!.nid!) as any;
  if (!a) return res.status(404).json({ error: 'not found' });
  res.json({
    id: a.id,
    title: a.title,
    titleKk: a.title_kk || a.title,
    subtitle: a.date,
    body: a.message,
    bodyKk: a.message_kk || a.message,
    category: annTypeCategory(a.type),
    status: annTypeStatus(a.type),
    seenBy: seenCount(a.id),
    kind: 'announcement',
  });
});

// ─── Notification inbox ───
app.get('/api/notifications', requireResident, (req: AuthedRequest, res) => {
  const tz = process.env.TZ || 'Asia/Almaty';
  const when = (ms: number) =>
    new Date(ms).toLocaleString('ru-RU', { timeZone: tz, day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' });
  const rows = q('SELECT * FROM notifications WHERE resident_id=? ORDER BY created_at DESC LIMIT 50').all(req.auth!.sub) as any[];
  const unread = (q('SELECT COUNT(*) n FROM notifications WHERE resident_id=? AND read=0').get(req.auth!.sub) as any).n || 0;
  res.json({
    unread,
    items: rows.map((r) => ({
      id: r.id, type: r.type, refId: r.ref_id, title: r.title, body: r.body,
      read: !!r.read, date: when(Number(r.created_at) || Date.now()),
    })),
  });
});

app.post('/api/notifications/read', requireResident, (req: AuthedRequest, res) => {
  q('UPDATE notifications SET read=1 WHERE resident_id=? AND read=0').run(req.auth!.sub);
  res.json({ ok: true });
});

app.post('/api/reports', requireResident, reportUpload.single('image'), (req: AuthedRequest, res) => {
  // Anti-spam: cap how many reports one resident can file per window.
  if (rlBump(`report:${req.auth!.sub}`, 10 * 60 * 1000) > 5) {
    return res.status(429).json({ error: 'Слишком много заявок подряд. Подождите немного.' });
  }
  const { category, description, location } = req.body ?? {};
  if (!category) return res.status(400).json({ error: 'category required' });
  const resident = q('SELECT name FROM residents WHERE id=?').get(req.auth!.sub) as any;
  const titles: Record<string, string> = {
    water: 'Проблема с водой', roads: 'Проблема с дорогой', lights: 'Проблема с освещением',
    garbage: 'Проблема с мусором', safety: 'Вопрос безопасности', other: 'Обращение',
  };
  const desc = String(description || '').trim();
  const id = `c${nowMs()}`;
  const reportTitle = desc || titles[category] || 'Обращение';
  // Persist an attached photo (if any) as report_<id>.<ext>.
  let photo: string | null = null;
  if (req.file) {
    const ext = path.extname(req.file.originalname || '').toLowerCase() || '.jpg';
    photo = `report_${id}${ext}`;
    fs.writeFileSync(path.join(uploadsDir, photo), new Uint8Array(req.file.buffer));
  }
  q(`INSERT INTO reports (id,neighborhood_id,resident_id,author,title,category,status,location,date_time,description,steps_json,detail_steps_json,updates_json,photo,created_at)
     VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`).run(
    id, req.auth!.nid!, req.auth!.sub, resident?.name || '', reportTitle, category, 'waitingResponse',
    location || '', nowDateTime(), desc,
    JSON.stringify([
      { label: 'Отправлено', date: 'сейчас', state: 'done' },
      { label: 'Ожидает ответа', date: 'сейчас', state: 'current' },
      { label: 'Решено', date: null, state: 'pending' },
    ]),
    JSON.stringify([
      { label: 'Отправлено', date: 'сейчас', state: 'done' },
      { label: 'Рассмотрение', date: null, state: 'current' },
      { label: 'Решено', date: null, state: 'pending' },
    ]),
    JSON.stringify([{ date: 'сейчас', body: 'Заявка получена. Ожидает рассмотрения председателем.' }]),
    photo,
    String(nowMs()),
  );
  // Notify the neighborhood's chairman(s) of the new report.
  notifyNeighborhoodAdmins(req.auth!.nid!, {
    title: 'Новая заявка',
    body: `${reportTitle}${location ? ' · ' + location : ''}`,
    data: { type: 'report', id },
  });
  // Notify every other resident in the neighborhood (not the author).
  notifyNeighborhoodResidentsExcept(req.auth!.nid!, req.auth!.sub, {
    title: 'Новая заявка в районе',
    body: `${reportTitle}${location ? ' · ' + location : ''}`,
    data: { type: 'report', id },
  });
  recordNeighborhoodNotif(req.auth!.nid!, req.auth!.sub, {
    type: 'report', refId: id,
    title: 'Новая заявка в районе', body: `${reportTitle}${location ? ' · ' + location : ''}`,
  });
  res.status(201).json(reportDetail(q('SELECT * FROM reports WHERE id=?').get(id)));
});

// Report photo — token via Authorization header or ?token= (so <img> can load it).
// Resident sees their own report's photo; neighborhood admin sees any in their area.
app.get('/api/reports/:id/photo', (req, res) => {
  const h = req.headers.authorization || '';
  const raw = h.startsWith('Bearer ') ? h.slice(7) : String(req.query.token || '');
  let payload: TokenPayload | null = null;
  try {
    payload = jwt.verify(raw, process.env.JWT_SECRET || 'korshi-dev-secret-change-me') as TokenPayload;
  } catch {
    return res.status(401).json({ error: 'unauthorized' });
  }
  const r = q('SELECT * FROM reports WHERE id=?').get(req.params.id) as any;
  if (!r || !r.photo) return res.status(404).json({ error: 'no photo' });
  const allowed =
    (payload.role === 'resident' && r.resident_id === payload.sub) ||
    (payload.role === 'admin' && r.neighborhood_id === payload.nid);
  if (!allowed) return res.status(403).json({ error: 'forbidden' });
  const p = path.join(uploadsDir, r.photo);
  if (!fs.existsSync(p)) return res.status(404).json({ error: 'no photo' });
  res.sendFile(p);
});

// ───────────────────────── admin: reports ─────────────────────────
app.get('/api/admin/reports', requireAdmin, (req: AuthedRequest, res) => {
  const rows = q('SELECT * FROM reports WHERE neighborhood_id=? ORDER BY created_at DESC').all(req.auth!.nid!) as any[];
  res.json(rows.map((r) => ({ ...reportDetail(r), resident: r.author })));
});

function adminReport(id: string, nid: string) {
  return q('SELECT * FROM reports WHERE id=? AND neighborhood_id=?').get(id, nid) as any;
}

app.patch('/api/admin/reports/:id', requireAdmin, (req: AuthedRequest, res) => {
  const r = adminReport(req.params.id, req.auth!.nid!);
  if (!r) return res.status(404).json({ error: 'not found' });
  const { status, contractor, internalNote } = req.body ?? {};
  if (status) q('UPDATE reports SET status=? WHERE id=?').run(status, r.id);
  if (contractor !== undefined) q('UPDATE reports SET contractor=? WHERE id=?').run(contractor, r.id);
  if (internalNote !== undefined) q('UPDATE reports SET internal_note=? WHERE id=?').run(internalNote, r.id);
  // Notify the whole neighborhood when a report's status changes.
  if (status && status !== r.status) {
    const labels: Record<string, string> = {
      waitingResponse: 'Ожидает ответа', inProgress: 'В работе', waitingCity: 'Ожидает город', resolved: 'Решено',
    };
    notifyNeighborhoodResidents(req.auth!.nid!, {
      title: 'Статус заявки обновлён',
      body: `${r.title}: ${labels[status] || status}`,
      data: { type: 'report', id: r.id },
    });
    recordNeighborhoodNotif(req.auth!.nid!, null, {
      type: 'report', refId: r.id,
      title: 'Статус заявки обновлён', body: `${r.title}: ${labels[status] || status}`,
    });
  }
  res.json(reportDetail(q('SELECT * FROM reports WHERE id=?').get(r.id)));
});

// Delete a report (e.g. spam) — neighborhood-scoped, removes its photo too.
app.delete('/api/admin/reports/:id', requireAdmin, (req: AuthedRequest, res) => {
  const r = adminReport(req.params.id, req.auth!.nid!);
  if (!r) return res.status(404).json({ error: 'not found' });
  if (r.photo) {
    try { fs.unlinkSync(path.join(uploadsDir, r.photo)); } catch { /* ignore */ }
  }
  q('DELETE FROM notifications WHERE type=? AND ref_id=?').run('report', r.id);
  q('DELETE FROM reports WHERE id=?').run(r.id);
  res.json({ ok: true });
});

app.post('/api/admin/reports/:id/update', requireAdmin, (req: AuthedRequest, res) => {
  const r = adminReport(req.params.id, req.auth!.nid!);
  if (!r) return res.status(404).json({ error: 'not found' });
  const body = String(req.body?.body || '').trim();
  if (!body) return res.status(400).json({ error: 'body required' });
  const updates = JSON.parse(r.updates_json || '[]');
  updates.push({ date: nowDateShort(), body });
  q('UPDATE reports SET updates_json=? WHERE id=?').run(JSON.stringify(updates), r.id);
  // Notify the whole neighborhood of the chairman's message.
  const msgBody = body.length > 120 ? body.slice(0, 117) + '…' : body;
  notifyNeighborhoodResidents(req.auth!.nid!, {
    title: 'Сообщение от председателя',
    body: msgBody,
    data: { type: 'report', id: r.id },
  });
  recordNeighborhoodNotif(req.auth!.nid!, null, {
    type: 'report', refId: r.id, title: 'Сообщение от председателя', body: msgBody,
  });
  res.json(reportDetail(q('SELECT * FROM reports WHERE id=?').get(r.id)));
});

// ───────────────────────── admin: announcements ─────────────────────────
app.get('/api/admin/announcements', requireAdmin, (req: AuthedRequest, res) => {
  res.json((q('SELECT * FROM announcements WHERE neighborhood_id=? ORDER BY created_at DESC').all(req.auth!.nid!) as any[]).map((a) => ({
    id: a.id, type: a.type,
    title: a.title, titleKk: a.title_kk || '',
    message: a.message, messageKk: a.message_kk || '',
    audience: a.audience, audienceLabel: a.audience_label,
    pinned: !!a.pinned, date: a.date, seenBy: seenCount(a.id),
  })));
});
app.post('/api/admin/announcements', requireAdmin, (req: AuthedRequest, res) => {
  const { type, title, titleKk, message, messageKk, audience, audienceLabel, publishNow } = req.body ?? {};
  if (!title) return res.status(400).json({ error: 'title required' });
  const id = `a${nowMs()}`;
  q(`INSERT INTO announcements (id,neighborhood_id,type,title,title_kk,message,message_kk,audience,audience_label,pinned,date,seen_by,created_at)
     VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)`).run(
    id, req.auth!.nid!, type || 'update', title, titleKk || title, message || '', messageKk || message || '',
    audience || 'all', audienceLabel || 'Весь район',
    0, publishNow === false ? 'запланировано' : nowDateTime(), 0, String(nowMs()));
  if (publishNow !== false) {
    notifyNeighborhoodResidents(req.auth!.nid!, {
      title: 'Новое объявление',
      body: title,
      data: { type: 'announcement', id },
    });
    recordNeighborhoodNotif(req.auth!.nid!, null, {
      type: 'announcement', refId: id, title: 'Новое объявление', body: title,
    });
  }
  res.status(201).json({ id });
});
app.patch('/api/admin/announcements/:id', requireAdmin, (req: AuthedRequest, res) => {
  const nid = req.auth!.nid!;
  const a = q('SELECT * FROM announcements WHERE id=? AND neighborhood_id=?').get(req.params.id, nid) as any;
  if (!a) return res.status(404).json({ error: 'not found' });
  const b = req.body ?? {};
  if (b.pinned !== undefined) q('UPDATE announcements SET pinned=? WHERE id=?').run(b.pinned ? 1 : 0, a.id);
  if (b.type !== undefined) q('UPDATE announcements SET type=? WHERE id=?').run(String(b.type), a.id);
  if (b.title !== undefined) {
    const title = String(b.title).trim();
    if (!title) return res.status(400).json({ error: 'title required' });
    q('UPDATE announcements SET title=? WHERE id=?').run(title, a.id);
    if (b.titleKk === undefined) q('UPDATE announcements SET title_kk=? WHERE id=?').run(title, a.id);
  }
  if (b.titleKk !== undefined) {
    const tk = String(b.titleKk).trim();
    q('UPDATE announcements SET title_kk=? WHERE id=?').run(tk || a.title, a.id);
  }
  if (b.message !== undefined) {
    const msg = String(b.message);
    q('UPDATE announcements SET message=? WHERE id=?').run(msg, a.id);
    if (b.messageKk === undefined) q('UPDATE announcements SET message_kk=? WHERE id=?').run(msg, a.id);
  }
  if (b.messageKk !== undefined) {
    const mk = String(b.messageKk);
    q('UPDATE announcements SET message_kk=? WHERE id=?').run(mk || a.message, a.id);
  }
  if (b.audience !== undefined) q('UPDATE announcements SET audience=? WHERE id=?').run(String(b.audience), a.id);
  if (b.audienceLabel !== undefined) q('UPDATE announcements SET audience_label=? WHERE id=?').run(String(b.audienceLabel), a.id);
  res.json({ ok: true });
});
app.delete('/api/admin/announcements/:id', requireAdmin, (req: AuthedRequest, res) => {
  q('DELETE FROM announcements WHERE id=? AND neighborhood_id=?').run(req.params.id, req.auth!.nid!);
  res.json({ ok: true });
});

// ───────────────────────── admin: polls ─────────────────────────
app.get('/api/admin/polls', requireAdmin, (req: AuthedRequest, res) => {
  const polls = q('SELECT * FROM polls WHERE neighborhood_id=? ORDER BY created_at DESC').all(req.auth!.nid!) as any[];
  res.json(polls.map((p) => {
    const opts = q('SELECT * FROM poll_options WHERE poll_id=? ORDER BY ord').all(p.id) as any[];
    const confidential = !!p.confidential;
    return {
      id: p.id, category: p.category, question: p.question, questionKk: p.question_kk || '',
      status: p.status, confidential,
      durationDays: p.duration_days, audienceLabel: p.audience_label,
      households: opts.reduce((s, o) => s + o.votes, 0), endsAt: p.ends_at,
      options: opts.map((o) => ({ id: o.id, label: o.label, votes: o.votes })),
      voters: confidential ? [] : pollVoters(p.id),
    };
  }));
});
app.post('/api/admin/polls', requireAdmin, (req: AuthedRequest, res) => {
  const { category, question, questionKk, description, descriptionKk, options, optionsKk, durationDays, audienceLabel, confidential } = req.body ?? {};
  if (!question || !Array.isArray(options) || options.length < 2) return res.status(400).json({ error: 'invalid' });
  const id = `p${nowMs()}`;
  q(`INSERT INTO polls (id,neighborhood_id,category,question,question_kk,description,description_kk,confidential,status,duration_days,audience_label,ends_at,created_at)
     VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)`).run(
    id, req.auth!.nid!, category || null, question, questionKk || question, description || '', descriptionKk || description || '',
    confidential === false ? 0 : 1, 'active', durationDays || 7, audienceLabel || 'Весь район',
    `через ${durationDays || 7} дн.`, String(nowMs()));
  const kkArr = Array.isArray(optionsKk) ? optionsKk : [];
  const ins = q('INSERT INTO poll_options (poll_id,label,label_kk,votes,positive,ord) VALUES (?,?,?,?,?,?)');
  (options as string[]).forEach((label, i) => {
    if (!label.trim()) return;
    ins.run(id, label, (kkArr[i] || label).toString(), 0, i === 0 ? 1 : 0, i);
  });
  notifyNeighborhoodResidents(req.auth!.nid!, {
    title: 'Новый опрос',
    body: question,
    data: { type: 'poll', id },
  });
  recordNeighborhoodNotif(req.auth!.nid!, null, {
    type: 'poll', refId: id, title: 'Новый опрос', body: question,
  });
  res.status(201).json({ id });
});
app.delete('/api/admin/polls/:id', requireAdmin, (req: AuthedRequest, res) => {
  const p = q('SELECT id FROM polls WHERE id=? AND neighborhood_id=?').get(req.params.id, req.auth!.nid!) as any;
  if (!p) return res.status(404).json({ error: 'not found' });
  q('DELETE FROM poll_options WHERE poll_id=?').run(req.params.id);
  q('DELETE FROM votes WHERE poll_id=?').run(req.params.id);
  q('DELETE FROM polls WHERE id=?').run(req.params.id);
  res.json({ ok: true });
});

// ───────────────────────── admin: residents ─────────────────────────
app.get('/api/admin/residents', requireAdmin, (req: AuthedRequest, res) => {
  const nid = req.auth!.nid!;
  const rows = q('SELECT * FROM residents WHERE neighborhood_id=? ORDER BY rowid').all(nid) as any[];
  const residents = rows.map((r) => ({
    id: r.id, name: r.name, phone: r.phone, address: r.address, street: r.street,
    status: r.status,
    // Show the activation code only while the resident hasn't joined yet.
    inviteCode: r.status === 'active' ? null : r.invite_code,
    initials: (r.name && r.name !== '—' ? r.name.split(' ').map((w: string) => w[0]).slice(0, 2).join('') : '—'),
  }));
  // Real street overview + community progress, derived from actual residents.
  const byStreet = new Map<string, { name: string; connected: number; total: number }>();
  for (const r of rows) {
    const name = (r.street && String(r.street).trim()) || 'Без улицы';
    const e = byStreet.get(name) || { name, connected: 0, total: 0 };
    e.total += 1;
    if (r.status === 'active') e.connected += 1;
    byStreet.set(name, e);
  }
  const streets = [...byStreet.values()]
    .sort((a, b) => a.name.localeCompare(b.name, 'ru'))
    .map((s, i) => ({ id: `st${i}`, ...s }));
  const connected = rows.filter((r) => r.status === 'active').length;
  const total = rows.length;
  res.json({ residents, streets, community: { connected, total } });
});

app.post('/api/admin/residents/invite', requireAdmin, (req: AuthedRequest, res) => {
  const { phone, address, name } = req.body ?? {};
  if (!phone || !address) return res.status(400).json({ error: 'phone and address required' });
  const exists = (q('SELECT * FROM residents').all() as any[]).some((r) => last10(r.phone) === last10(phone));
  if (exists) return res.status(409).json({ error: 'Этот номер уже зарегистрирован' });
  // 4-digit numeric activation code (easy for elderly residents to type).
  const code = String(Math.floor(1000 + Math.random() * 9000));
  const id = `res${nowMs()}`;
  q(`INSERT INTO residents (id,neighborhood_id,name,phone,address,street,status,invite_code,password_hash,created_at)
     VALUES (?,?,?,?,?,?,?,?,?,?)`).run(
    id, req.auth!.nid!, name || '—', phone, address, String(address).split(',')[0] || '', 'invited', code, null, new Date().toISOString());
  res.status(201).json({ id, activationCode: code, expires: null });
});

// Delete a resident or a pending invitation (and their auth/activity traces).
app.delete('/api/admin/residents/:id', requireAdmin, (req: AuthedRequest, res) => {
  const r = q('SELECT * FROM residents WHERE id=? AND neighborhood_id=?').get(req.params.id, req.auth!.nid!) as any;
  if (!r) return res.status(404).json({ error: 'not found' });
  q('DELETE FROM device_tokens WHERE user_type=? AND user_id=?').run('resident', r.id);
  q('DELETE FROM notifications WHERE resident_id=?').run(r.id);
  q('DELETE FROM votes WHERE resident_id=?').run(r.id);
  q('DELETE FROM announcement_views WHERE resident_id=?').run(r.id);
  q('DELETE FROM residents WHERE id=?').run(r.id);
  res.json({ ok: true });
});

// ───────────────────────── admin: contacts ─────────────────────────
app.get('/api/admin/contacts', requireAdmin, (req: AuthedRequest, res) => res.json(contactsPayload(req.auth!.nid!)));
app.post('/api/admin/contacts', requireAdmin, (req: AuthedRequest, res) => {
  const { kind, name, role, subtitle, statusLine, category, badge, phone } = req.body ?? {};
  if (!kind || !name) return res.status(400).json({ error: 'kind and name required' });
  const id = `ct${nowMs()}`;
  const ord = (q('SELECT COALESCE(MAX(ord),-1)+1 n FROM contacts WHERE neighborhood_id=? AND kind=?').get(req.auth!.nid!, kind) as any).n;
  q(`INSERT INTO contacts (id,neighborhood_id,kind,name,role,subtitle,status_line,category,badge,phone,ord)
     VALUES (?,?,?,?,?,?,?,?,?,?,?)`).run(
    id, req.auth!.nid!, kind, name, role || '', subtitle || null, statusLine || null, category || null, badge || null, phone || '', ord);
  res.status(201).json({ id });
});
app.delete('/api/admin/contacts/:id', requireAdmin, (req: AuthedRequest, res) => {
  q('DELETE FROM contacts WHERE id=? AND neighborhood_id=?').run(req.params.id, req.auth!.nid!);
  res.json({ ok: true });
});

// ───────────────────────── admin: stats ─────────────────────────
app.get('/api/admin/stats', requireAdmin, (req: AuthedRequest, res) => {
  const nid = req.auth!.nid!;
  const byStatus = (s: string) => (q('SELECT COUNT(*) n FROM reports WHERE neighborhood_id=? AND status=?').get(nid, s) as any).n;
  res.json({
    neighborhood: neighborhoodName(nid),
    reportsNew: byStatus('new') + byStatus('waitingResponse'),
    reportsInProgress: byStatus('inProgress'),
    reportsResolved: byStatus('resolved'),
    reportsTotal: (q('SELECT COUNT(*) n FROM reports WHERE neighborhood_id=?').get(nid) as any).n,
    announcements: (q('SELECT COUNT(*) n FROM announcements WHERE neighborhood_id=?').get(nid) as any).n,
    activePolls: (q(`SELECT COUNT(*) n FROM polls WHERE neighborhood_id=? AND status='active'`).get(nid) as any).n,
    residents: (q('SELECT COUNT(*) n FROM residents WHERE neighborhood_id=?').get(nid) as any).n,
  });
});

// ───────────────────────── super admin: neighborhoods ─────────────────────────
app.get('/api/super/neighborhoods', requireSuper, (_req, res) => {
  const list = q('SELECT * FROM neighborhoods ORDER BY created_at').all() as any[];
  res.json(list.map((n) => {
    const admin = q(`SELECT email FROM admins WHERE role='admin' AND neighborhood_id=? ORDER BY id LIMIT 1`).get(n.id) as any;
    return {
      id: n.id,
      name: n.name,
      adminEmail: admin?.email || null,
      residents: (q('SELECT COUNT(*) c FROM residents WHERE neighborhood_id=?').get(n.id) as any).c,
      reports: (q('SELECT COUNT(*) c FROM reports WHERE neighborhood_id=?').get(n.id) as any).c,
      createdAt: n.created_at,
    };
  }));
});

app.post('/api/super/neighborhoods', requireSuper, (req, res) => {
  const name = String(req.body?.name || '').trim();
  const adminEmail = String(req.body?.adminEmail || '').trim().toLowerCase();
  const adminPassword = String(req.body?.adminPassword || '');
  if (!name || !adminEmail || adminPassword.length < 6) {
    return res.status(400).json({ error: 'Укажите название, email и пароль (от 6 символов)' });
  }
  if (q('SELECT 1 FROM admins WHERE email=?').get(adminEmail)) {
    return res.status(409).json({ error: 'Этот email уже используется' });
  }
  const id = createNeighborhood(name, adminEmail, adminPassword);
  res.status(201).json({ id, name, adminEmail });
});

app.patch('/api/super/neighborhoods/:id', requireSuper, (req, res) => {
  const id = req.params.id;
  const n = q('SELECT * FROM neighborhoods WHERE id=?').get(id) as any;
  if (!n) return res.status(404).json({ error: 'not found' });
  const name = req.body?.name !== undefined ? String(req.body.name).trim() : undefined;
  const adminEmail = req.body?.adminEmail !== undefined ? String(req.body.adminEmail).trim().toLowerCase() : undefined;
  const adminPassword = req.body?.adminPassword !== undefined ? String(req.body.adminPassword) : undefined;

  if (name !== undefined) {
    if (!name) return res.status(400).json({ error: 'Название не может быть пустым' });
    q('UPDATE neighborhoods SET name=? WHERE id=?').run(name, id);
  }

  const admin = q(`SELECT * FROM admins WHERE role='admin' AND neighborhood_id=? ORDER BY id LIMIT 1`).get(id) as any;
  if (adminEmail !== undefined) {
    if (!adminEmail) return res.status(400).json({ error: 'Email не может быть пустым' });
    const clash = q('SELECT id FROM admins WHERE email=? AND id != ?').get(adminEmail, admin?.id ?? -1) as any;
    if (clash) return res.status(409).json({ error: 'Этот email уже используется' });
    if (admin) q('UPDATE admins SET email=? WHERE id=?').run(adminEmail, admin.id);
  }
  if (adminPassword !== undefined) {
    if (adminPassword.length < 6) return res.status(400).json({ error: 'Пароль должен быть от 6 символов' });
    if (admin) q('UPDATE admins SET password_hash=? WHERE id=?').run(bcrypt.hashSync(adminPassword, 10), admin.id);
  }
  res.json({ ok: true });
});

app.delete('/api/super/neighborhoods/:id', requireSuper, (req, res) => {
  const id = req.params.id;
  const n = q('SELECT id FROM neighborhoods WHERE id=?').get(id) as any;
  if (!n) return res.status(404).json({ error: 'not found' });
  // Remove the neighborhood's poll votes/options first (no neighborhood_id of their own).
  const pollIds = (q('SELECT id FROM polls WHERE neighborhood_id=?').all(id) as any[]).map((p) => p.id);
  for (const pid of pollIds) {
    q('DELETE FROM poll_options WHERE poll_id=?').run(pid);
    q('DELETE FROM votes WHERE poll_id=?').run(pid);
  }
  for (const t of ['residents', 'reports', 'announcements', 'polls', 'decisions', 'contacts', 'streets']) {
    q(`DELETE FROM ${t} WHERE neighborhood_id=?`).run(id);
  }
  q(`DELETE FROM admins WHERE role='admin' AND neighborhood_id=?`).run(id);
  q('DELETE FROM neighborhoods WHERE id=?').run(id);
  // Drop the neighborhood's cover file if present.
  for (const f of fs.readdirSync(uploadsDir)) {
    if (f.startsWith(`cover_${id}.`)) fs.unlinkSync(path.join(uploadsDir, f));
  }
  res.json({ ok: true });
});

// ───────────────────────── cover image (per neighborhood) ─────────────────────────
function coverFile(nid: string): string | null {
  const f = fs.readdirSync(uploadsDir).find((n) => n.startsWith(`cover_${nid}.`));
  return f ? path.join(uploadsDir, f) : null;
}
const upload = multer({
  storage: multer.diskStorage({
    destination: uploadsDir,
    filename: (req, file, cb) => {
      const nid = (req as AuthedRequest).auth!.nid!;
      cb(null, `cover_${nid}${path.extname(file.originalname) || '.jpg'}`);
    },
  }),
  limits: { fileSize: 12 * 1024 * 1024 },
});
app.post('/api/neighborhood/cover', requireAdmin, upload.single('image'), (req: AuthedRequest, res) => {
  if (!req.file) return res.status(400).json({ error: 'image required' });
  const nid = req.auth!.nid!;
  for (const n of fs.readdirSync(uploadsDir)) {
    const p = path.join(uploadsDir, n);
    if (n.startsWith(`cover_${nid}.`) && p !== req.file.path) fs.unlinkSync(p);
  }
  res.status(201).json({ ok: true });
});
app.get('/api/neighborhood/cover', (req, res) => {
  const nid = String(req.query.nid || '');
  const p = nid ? coverFile(nid) : null;
  if (!p || !fs.existsSync(p)) return res.status(404).json({ error: 'no cover' });
  res.sendFile(p);
});

app.get('/', (_req, res) => res.json({ name: 'Korshi API', docs: '/api/health' }));

// ───────────────────────── daily digest (chairman) ─────────────────────────
function neighborhoodDigest(nid: string) {
  const cutoff = nowMs() - 24 * 60 * 60 * 1000;
  const newReports = (q('SELECT created_at FROM reports WHERE neighborhood_id=?').all(nid) as any[])
    .filter((r) => (Number(r.created_at) || 0) >= cutoff).length;
  const openReports = (q("SELECT COUNT(*) n FROM reports WHERE neighborhood_id=? AND status!='resolved'").get(nid) as any).n || 0;
  const activePolls = (q("SELECT COUNT(*) n FROM polls WHERE neighborhood_id=? AND status='active'").get(nid) as any).n || 0;
  return { newReports, openReports, activePolls };
}

/** Sends the chairman a once-a-day summary — Kazakh and Russian as two pushes. */
function runDailyDigest() {
  try {
    const nids = (q('SELECT id FROM neighborhoods').all() as any[]).map((n) => n.id);
    for (const nid of nids) {
      const d = neighborhoodDigest(nid);
      if (d.newReports === 0) continue; // skip quiet days (nothing new)
      // Kazakh first…
      notifyNeighborhoodAdmins(nid, {
        title: 'Тәуліктік қорытынды',
        body: `Жаңа өтініштер: ${d.newReports} · Жұмыста: ${d.openReports} · Белсенді сауалнамалар: ${d.activePolls}`,
        data: { type: 'digest' },
      });
      // …then Russian.
      notifyNeighborhoodAdmins(nid, {
        title: 'Сводка за сутки',
        body: `Новых заявок: ${d.newReports} · В работе: ${d.openReports} · Активных опросов: ${d.activePolls}`,
        data: { type: 'digest' },
      });
    }
  } catch (e) {
    console.warn('[digest] error', (e as any)?.message);
  }
}

/** Schedules the digest for the next 09:00 (server TZ = Asia/Almaty), then daily. */
function scheduleDailyDigest() {
  const now = new Date();
  const next = new Date(now);
  next.setHours(9, 0, 0, 0);
  if (next.getTime() <= now.getTime()) next.setDate(next.getDate() + 1);
  setTimeout(() => {
    runDailyDigest();
    scheduleDailyDigest();
  }, next.getTime() - now.getTime());
  console.log(`[digest] next run ${next.toISOString()}`);
}

export { app };
if (process.env.KORSHI_NO_LISTEN !== '1') {
  app.listen(PORT, () => console.log(`[korshi-server] listening on :${PORT}`));
  scheduleDailyDigest();
}
