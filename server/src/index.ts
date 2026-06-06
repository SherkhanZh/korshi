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
const notifyNeighborhoodAdmins = (nid: string, msg: PushMessage) =>
  notify(tokensWhere("user_type='admin' AND neighborhood_id=?", nid), msg);

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
  const { email, password } = req.body ?? {};
  const a = q('SELECT * FROM admins WHERE email=?').get(String(email || '').toLowerCase()) as any;
  if (!a || !bcrypt.compareSync(String(password || ''), a.password_hash)) {
    return res.status(401).json({ error: 'Неверный email или пароль' });
  }
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
  const phone = String(req.body?.phone ?? '');
  const secret = String(req.body?.secret ?? '').trim();
  if (!phone || !secret) return res.status(400).json({ error: 'phone and secret required' });
  const key = last10(phone);
  const all = q('SELECT * FROM residents').all() as any[];
  const r = all.find((x) => last10(x.phone) === key);
  if (!r) return res.status(404).json({ error: 'Житель не найден. Обратитесь к председателю.' });

  let ok = false;
  if (r.password_hash) ok = bcrypt.compareSync(secret, r.password_hash);
  if (!ok && r.invite_code) ok = secret.toUpperCase() === String(r.invite_code).toUpperCase();
  if (!ok) return res.status(401).json({ error: 'Неверный код или пароль' });

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
    options: [], households: 0, endsInDays: 0, voted: false, confidential: true, voters: [],
  };
  if (ap) {
    const voted = !!q('SELECT 1 FROM votes WHERE poll_id=? AND resident_id=?').get(ap.p.id, req.auth!.sub);
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
  const r = q('SELECT * FROM reports WHERE id=? AND resident_id=?').get(req.params.id, req.auth!.sub) as any;
  if (!r) return res.status(404).json({ error: 'not found' });
  res.json(reportDetail(r));
});

app.post('/api/reports', requireResident, reportUpload.single('image'), (req: AuthedRequest, res) => {
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
    location || '', new Date().toLocaleString('ru-RU'), desc,
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
  // Notify the resident when their report's status changes.
  if (status && status !== r.status && r.resident_id) {
    const labels: Record<string, string> = {
      waitingResponse: 'Ожидает ответа', inProgress: 'В работе', waitingCity: 'Ожидает город', resolved: 'Решено',
    };
    notifyResident(r.resident_id, {
      title: 'Статус заявки обновлён',
      body: `${r.title}: ${labels[status] || status}`,
      data: { type: 'report', id: r.id },
    });
  }
  res.json(reportDetail(q('SELECT * FROM reports WHERE id=?').get(r.id)));
});

app.post('/api/admin/reports/:id/update', requireAdmin, (req: AuthedRequest, res) => {
  const r = adminReport(req.params.id, req.auth!.nid!);
  if (!r) return res.status(404).json({ error: 'not found' });
  const body = String(req.body?.body || '').trim();
  if (!body) return res.status(400).json({ error: 'body required' });
  const updates = JSON.parse(r.updates_json || '[]');
  updates.push({ date: new Date().toLocaleDateString('ru-RU'), body });
  q('UPDATE reports SET updates_json=? WHERE id=?').run(JSON.stringify(updates), r.id);
  // Notify the resident of the chairman's message.
  if (r.resident_id) {
    notifyResident(r.resident_id, {
      title: 'Сообщение от председателя',
      body: body.length > 120 ? body.slice(0, 117) + '…' : body,
      data: { type: 'report', id: r.id },
    });
  }
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
    0, publishNow === false ? 'запланировано' : 'только что', 0, String(nowMs()));
  if (publishNow !== false) {
    notifyNeighborhoodResidents(req.auth!.nid!, {
      title: 'Новое объявление',
      body: title,
      data: { type: 'announcement', id },
    });
  }
  res.status(201).json({ id });
});
app.patch('/api/admin/announcements/:id', requireAdmin, (req: AuthedRequest, res) => {
  if (req.body?.pinned !== undefined)
    q('UPDATE announcements SET pinned=? WHERE id=? AND neighborhood_id=?').run(req.body.pinned ? 1 : 0, req.params.id, req.auth!.nid!);
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
  const residents = (q('SELECT * FROM residents WHERE neighborhood_id=? ORDER BY rowid').all(nid) as any[]).map((r) => ({
    id: r.id, name: r.name, phone: r.phone, address: r.address, street: r.street,
    status: r.status, inviteCode: r.invite_code,
    initials: (r.name && r.name !== '—' ? r.name.split(' ').map((w: string) => w[0]).slice(0, 2).join('') : '—'),
  }));
  const streets = (q('SELECT * FROM streets WHERE neighborhood_id=? ORDER BY ord').all(nid) as any[]).map((s) => ({
    id: s.id, name: s.name, connected: s.connected, total: s.total,
  }));
  const total = streets.reduce((s, x) => s + x.total, 0);
  const connected = streets.reduce((s, x) => s + x.connected, 0);
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

export { app };
if (process.env.KORSHI_NO_LISTEN !== '1') {
  app.listen(PORT, () => console.log(`[korshi-server] listening on :${PORT}`));
}
