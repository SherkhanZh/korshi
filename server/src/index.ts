import express from 'express';
import cors from 'cors';
import multer from 'multer';
import bcrypt from 'bcryptjs';
import path from 'path';
import fs from 'fs';
import { db, seed, setting } from './db';
import { signToken, requireAdmin, requireResident, type AuthedRequest } from './auth';

seed();

const app = express();
const PORT = Number(process.env.PORT) || 3000;
app.use(cors());
app.use(express.json());

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

function activePoll() {
  const p = q(`SELECT * FROM polls WHERE status='active' ORDER BY created_at DESC LIMIT 1`).get() as any;
  if (!p) return null;
  const opts = q('SELECT * FROM poll_options WHERE poll_id=? ORDER BY ord').all(p.id) as any[];
  const total = opts.reduce((s, o) => s + o.votes, 0);
  return { p, opts, total };
}

// ───────────────────────── health ─────────────────────────
app.get('/api/health', (_req, res) =>
  res.json({ status: 'ok', service: 'korshi-server', version: '0.2.0', time: new Date().toISOString() }));

// ───────────────────────── auth ─────────────────────────
app.post('/api/auth/admin/login', (req, res) => {
  const { email, password } = req.body ?? {};
  const a = q('SELECT * FROM admins WHERE email=?').get(String(email || '').toLowerCase()) as any;
  if (!a || !bcrypt.compareSync(String(password || ''), a.password_hash)) {
    return res.status(401).json({ error: 'Неверный email или пароль' });
  }
  res.json({ token: signToken({ sub: String(a.id), role: 'admin' }), email: a.email });
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
    token: signToken({ sub: r.id, role: 'resident' }),
    resident: { id: r.id, name: r.name, phone: r.phone, address: r.address },
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
  res.json({ ...r, neighborhood: setting('neighborhood') });
});

function feedItems(residentId?: string) {
  const reports = (q('SELECT * FROM reports ORDER BY created_at DESC LIMIT 4').all() as any[]).map((r) => ({
    title: r.title,
    subtitle: `${r.location} · недавно`,
    body: r.description,
    category: r.category,
    status: r.status,
    seenBy: 0,
    created: Number(r.created_at) || 0,
  }));
  const anns = (q('SELECT * FROM announcements ORDER BY created_at DESC').all() as any[]).map((a) => ({
    title: a.title,
    subtitle: a.date,
    body: a.message,
    category: annTypeCategory(a.type),
    status: annTypeStatus(a.type),
    seenBy: a.seen_by,
    created: Number(a.created_at) || 0,
  }));
  void residentId;
  return [...reports, ...anns].sort((x, y) => y.created - x.created);
}

app.get('/api/home', requireResident, (_req, res) => {
  const pinned = (q(`SELECT * FROM announcements ORDER BY pinned DESC, created_at DESC LIMIT 1`).get() as any) || {};
  const feed = feedItems().slice(0, 3).map(({ created, ...x }) => x);
  const ap = activePoll();
  let yesPct = 0, noPct = 0;
  if (ap && ap.total > 0) {
    const yes = ap.opts.find((o) => o.positive) || ap.opts[0];
    yesPct = Math.round((yes.votes / ap.total) * 100);
    noPct = 100 - yesPct;
  }
  const chair = q(`SELECT * FROM contacts WHERE badge='chairman' LIMIT 1`).get() as any;
  const svcs = q(`SELECT * FROM contacts WHERE kind='service' ORDER BY ord LIMIT 2`).all() as any[];
  const contacts = [chair, ...svcs].filter(Boolean).map((c) => ({
    name: c.name, role: c.role, category: c.category, phone: c.phone,
  }));
  const partner = q(`SELECT * FROM contacts WHERE kind='partner' ORDER BY ord LIMIT 1`).get() as any;
  res.json({
    neighborhood: setting('neighborhood'),
    announcement: { title: pinned.title || '', date: pinned.date || '', body: pinned.message || '' },
    today: feed,
    poll: { question: ap?.p.question || '', yesPct, noPct },
    contacts,
    partner: partner
      ? { title: partner.name, subtitle: partner.role, rating: '4.9', reviews: '128', phone: partner.phone }
      : { title: '', subtitle: '', rating: '0.0', reviews: '0', phone: '' },
  });
});

app.get('/api/updates', requireResident, (_req, res) => {
  const pinned = (q(`SELECT * FROM announcements ORDER BY pinned DESC, created_at DESC LIMIT 1`).get() as any) || {};
  const latest = feedItems().map(({ created, ...x }) => x);
  res.json({
    pinned: { title: pinned.title || '', date: pinned.date || '', body: pinned.message || '', seenBy: pinned.seen_by || 0 },
    latest,
  });
});

app.get('/api/contacts', requireResident, (_req, res) => res.json(contactsPayload()));
function contactsPayload() {
  const map = (c: any) => ({
    name: c.name, role: c.role, subtitle: c.subtitle, statusLine: c.status_line,
    category: c.category, badge: c.badge, phone: c.phone, desc: c.role,
  });
  return {
    important: (q(`SELECT * FROM contacts WHERE kind='important' ORDER BY ord`).all() as any[]).map(map),
    services: (q(`SELECT * FROM contacts WHERE kind='service' ORDER BY ord`).all() as any[]).map(map),
    partners: (q(`SELECT * FROM contacts WHERE kind='partner' ORDER BY ord`).all() as any[]).map(map),
  };
}

app.get('/api/polls', requireResident, (req: AuthedRequest, res) => {
  const ap = activePoll();
  let active: any = { question: '', description: '', options: [], households: 0, endsInDays: 0, voted: false };
  if (ap) {
    const voted = !!q('SELECT 1 FROM votes WHERE poll_id=? AND resident_id=?').get(ap.p.id, req.auth!.sub);
    active = {
      id: ap.p.id,
      question: ap.p.question,
      description: ap.p.description,
      households: ap.total,
      endsInDays: ap.p.duration_days,
      voted,
      options: ap.opts.map((o) => ({
        id: o.id,
        label: o.label, votes: o.votes, positive: !!o.positive,
        pct: ap.total ? Math.round((o.votes / ap.total) * 100) : 0,
      })),
    };
  }
  const upcoming = (q(`SELECT * FROM decisions WHERE kind='upcoming' ORDER BY ord`).all() as any[]).map((d) => ({
    title: d.title, subtitle: d.subtitle, category: d.category, opensLabel: d.opens_label, date: d.date,
  }));
  const previous = (q(`SELECT * FROM decisions WHERE kind='previous' ORDER BY ord`).all() as any[]).map((d) => ({
    title: d.title, subtitle: d.subtitle, status: d.status, date: d.date,
  }));
  const residents = (q('SELECT COUNT(*) n FROM residents').get() as any).n || 1;
  const voters = ap ? (q('SELECT COUNT(*) n FROM votes WHERE poll_id=?').get(ap.p.id) as any).n : 0;
  res.json({ participationPct: Math.min(100, Math.round((voters / residents) * 100)), active, upcoming, previous });
});

app.post('/api/polls/:id/vote', requireResident, (req: AuthedRequest, res) => {
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
  const rows = q('SELECT * FROM reports WHERE resident_id=? ORDER BY created_at DESC').all(req.auth!.sub) as any[];
  res.json(rows.map(reportRow));
});

app.get('/api/reports/:id', requireResident, (req: AuthedRequest, res) => {
  const r = q('SELECT * FROM reports WHERE id=? AND resident_id=?').get(req.params.id, req.auth!.sub) as any;
  if (!r) return res.status(404).json({ error: 'not found' });
  res.json(reportDetail(r));
});

app.post('/api/reports', requireResident, (req: AuthedRequest, res) => {
  const { category, description, location } = req.body ?? {};
  if (!category) return res.status(400).json({ error: 'category required' });
  const resident = q('SELECT name FROM residents WHERE id=?').get(req.auth!.sub) as any;
  const titles: Record<string, string> = {
    water: 'Проблема с водой', roads: 'Проблема с дорогой', lights: 'Проблема с освещением',
    garbage: 'Проблема с мусором', safety: 'Вопрос безопасности', other: 'Обращение',
  };
  const desc = String(description || '').trim();
  const id = `c${nowMs()}`;
  q(`INSERT INTO reports (id,resident_id,author,title,category,status,location,date_time,description,steps_json,detail_steps_json,updates_json,created_at)
     VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)`).run(
    id, req.auth!.sub, resident?.name || '', desc || titles[category] || 'Обращение', category, 'waitingResponse',
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
    String(nowMs()),
  );
  res.status(201).json(reportDetail(q('SELECT * FROM reports WHERE id=?').get(id)));
});

// ───────────────────────── admin: reports ─────────────────────────
app.get('/api/admin/reports', requireAdmin, (_req, res) => {
  const rows = q('SELECT * FROM reports ORDER BY created_at DESC').all() as any[];
  res.json(rows.map((r) => ({ ...reportDetail(r), resident: r.author })));
});

app.patch('/api/admin/reports/:id', requireAdmin, (req, res) => {
  const r = q('SELECT * FROM reports WHERE id=?').get(req.params.id) as any;
  if (!r) return res.status(404).json({ error: 'not found' });
  const { status, contractor, internalNote } = req.body ?? {};
  if (status) q('UPDATE reports SET status=? WHERE id=?').run(status, r.id);
  if (contractor !== undefined) q('UPDATE reports SET contractor=? WHERE id=?').run(contractor, r.id);
  if (internalNote !== undefined) q('UPDATE reports SET internal_note=? WHERE id=?').run(internalNote, r.id);
  res.json(reportDetail(q('SELECT * FROM reports WHERE id=?').get(r.id)));
});

app.post('/api/admin/reports/:id/update', requireAdmin, (req, res) => {
  const r = q('SELECT * FROM reports WHERE id=?').get(req.params.id) as any;
  if (!r) return res.status(404).json({ error: 'not found' });
  const body = String(req.body?.body || '').trim();
  if (!body) return res.status(400).json({ error: 'body required' });
  const updates = JSON.parse(r.updates_json || '[]');
  updates.push({ date: new Date().toLocaleDateString('ru-RU'), body });
  q('UPDATE reports SET updates_json=? WHERE id=?').run(JSON.stringify(updates), r.id);
  res.json(reportDetail(q('SELECT * FROM reports WHERE id=?').get(r.id)));
});

// ───────────────────────── admin: announcements ─────────────────────────
app.get('/api/admin/announcements', requireAdmin, (_req, res) => {
  res.json((q('SELECT * FROM announcements ORDER BY created_at DESC').all() as any[]).map((a) => ({
    id: a.id, type: a.type, title: a.title, message: a.message, audience: a.audience,
    audienceLabel: a.audience_label, pinned: !!a.pinned, date: a.date, seenBy: a.seen_by,
  })));
});
app.post('/api/admin/announcements', requireAdmin, (req, res) => {
  const { type, title, message, audience, audienceLabel, publishNow } = req.body ?? {};
  if (!title) return res.status(400).json({ error: 'title required' });
  const id = `a${nowMs()}`;
  q(`INSERT INTO announcements (id,type,title,message,audience,audience_label,pinned,date,seen_by,created_at)
     VALUES (?,?,?,?,?,?,?,?,?,?)`).run(
    id, type || 'update', title, message || '', audience || 'all', audienceLabel || 'Весь район',
    0, publishNow === false ? 'запланировано' : 'только что', 0, String(nowMs()));
  res.status(201).json({ id });
});
app.patch('/api/admin/announcements/:id', requireAdmin, (req, res) => {
  if (req.body?.pinned !== undefined)
    q('UPDATE announcements SET pinned=? WHERE id=?').run(req.body.pinned ? 1 : 0, req.params.id);
  res.json({ ok: true });
});
app.delete('/api/admin/announcements/:id', requireAdmin, (req, res) => {
  q('DELETE FROM announcements WHERE id=?').run(req.params.id);
  res.json({ ok: true });
});

// ───────────────────────── admin: polls ─────────────────────────
app.get('/api/admin/polls', requireAdmin, (_req, res) => {
  const polls = q('SELECT * FROM polls ORDER BY created_at DESC').all() as any[];
  res.json(polls.map((p) => {
    const opts = q('SELECT * FROM poll_options WHERE poll_id=? ORDER BY ord').all(p.id) as any[];
    return {
      id: p.id, category: p.category, question: p.question, status: p.status,
      durationDays: p.duration_days, audienceLabel: p.audience_label,
      households: opts.reduce((s, o) => s + o.votes, 0), endsAt: p.ends_at,
      options: opts.map((o) => ({ label: o.label, votes: o.votes })),
    };
  }));
});
app.post('/api/admin/polls', requireAdmin, (req, res) => {
  const { category, question, options, durationDays, audienceLabel } = req.body ?? {};
  if (!question || !Array.isArray(options) || options.length < 2) return res.status(400).json({ error: 'invalid' });
  const id = `p${nowMs()}`;
  q(`INSERT INTO polls (id,category,question,description,status,duration_days,audience_label,ends_at,created_at)
     VALUES (?,?,?,?,?,?,?,?,?)`).run(
    id, category || null, question, '', 'active', durationDays || 7, audienceLabel || 'Весь район',
    `через ${durationDays || 7} дн.`, String(nowMs()));
  const ins = q('INSERT INTO poll_options (poll_id,label,votes,positive,ord) VALUES (?,?,?,?,?)');
  (options as string[]).filter((o) => o.trim()).forEach((label, i) => ins.run(id, label, 0, i === 0 ? 1 : 0, i));
  res.status(201).json({ id });
});
app.delete('/api/admin/polls/:id', requireAdmin, (req, res) => {
  q('DELETE FROM poll_options WHERE poll_id=?').run(req.params.id);
  q('DELETE FROM votes WHERE poll_id=?').run(req.params.id);
  q('DELETE FROM polls WHERE id=?').run(req.params.id);
  res.json({ ok: true });
});

// ───────────────────────── admin: residents ─────────────────────────
app.get('/api/admin/residents', requireAdmin, (_req, res) => {
  const residents = (q('SELECT * FROM residents ORDER BY rowid').all() as any[]).map((r) => ({
    id: r.id, name: r.name, phone: r.phone, address: r.address, street: r.street,
    status: r.status, inviteCode: r.invite_code,
    initials: (r.name && r.name !== '—' ? r.name.split(' ').map((w: string) => w[0]).slice(0, 2).join('') : '—'),
  }));
  const streets = (q('SELECT * FROM streets ORDER BY ord').all() as any[]).map((s) => ({
    id: s.id, name: s.name, connected: s.connected, total: s.total,
  }));
  const total = streets.reduce((s, x) => s + x.total, 0);
  const connected = streets.reduce((s, x) => s + x.connected, 0);
  res.json({ residents, streets, community: { connected, total } });
});

app.post('/api/admin/residents/invite', requireAdmin, (req, res) => {
  const { phone, address, name } = req.body ?? {};
  if (!phone || !address) return res.status(400).json({ error: 'phone and address required' });
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let raw = '';
  for (let i = 0; i < 6; i++) raw += chars[Math.floor(Math.random() * chars.length)];
  const code = `${raw.slice(0, 4)}-${raw.slice(4)}`;
  const id = `res${nowMs()}`;
  q(`INSERT INTO residents (id,name,phone,address,street,status,invite_code,password_hash,created_at)
     VALUES (?,?,?,?,?,?,?,?,?)`).run(
    id, name || '—', phone, address, String(address).split(',')[0] || '', 'invited', code, null, new Date().toISOString());
  res.status(201).json({ id, activationCode: code, expires: null });
});

// ───────────────────────── admin: contacts ─────────────────────────
app.get('/api/admin/contacts', requireAdmin, (_req, res) => res.json(contactsPayload()));
app.post('/api/admin/contacts', requireAdmin, (req, res) => {
  const { kind, name, role, subtitle, statusLine, category, badge, phone } = req.body ?? {};
  if (!kind || !name) return res.status(400).json({ error: 'kind and name required' });
  const id = `ct${nowMs()}`;
  const ord = (q('SELECT COALESCE(MAX(ord),-1)+1 n FROM contacts WHERE kind=?').get(kind) as any).n;
  q(`INSERT INTO contacts (id,kind,name,role,subtitle,status_line,category,badge,phone,ord)
     VALUES (?,?,?,?,?,?,?,?,?,?)`).run(
    id, kind, name, role || '', subtitle || null, statusLine || null, category || null, badge || null, phone || '', ord);
  res.status(201).json({ id });
});
app.delete('/api/admin/contacts/:id', requireAdmin, (req, res) => {
  q('DELETE FROM contacts WHERE id=?').run(req.params.id);
  res.json({ ok: true });
});

// ───────────────────────── admin: stats ─────────────────────────
app.get('/api/admin/stats', requireAdmin, (_req, res) => {
  const byStatus = (s: string) => (q('SELECT COUNT(*) n FROM reports WHERE status=?').get(s) as any).n;
  res.json({
    reportsNew: byStatus('new') + byStatus('waitingResponse'),
    reportsInProgress: byStatus('inProgress'),
    reportsResolved: byStatus('resolved'),
    reportsTotal: (q('SELECT COUNT(*) n FROM reports').get() as any).n,
    announcements: (q('SELECT COUNT(*) n FROM announcements').get() as any).n,
    activePolls: (q(`SELECT COUNT(*) n FROM polls WHERE status='active'`).get() as any).n,
    residents: (q('SELECT COUNT(*) n FROM residents').get() as any).n,
  });
});

// ───────────────────────── cover image ─────────────────────────
const uploadsDir = path.join(process.cwd(), 'data', 'uploads');
fs.mkdirSync(uploadsDir, { recursive: true });
function findCover(): string | null {
  const f = fs.readdirSync(uploadsDir).find((n) => n.startsWith('cover.'));
  return f ? path.join(uploadsDir, f) : null;
}
let coverPath = findCover();
const upload = multer({
  storage: multer.diskStorage({
    destination: uploadsDir,
    filename: (_req, file, cb) => cb(null, `cover${path.extname(file.originalname) || '.jpg'}`),
  }),
  limits: { fileSize: 12 * 1024 * 1024 },
});
app.post('/api/neighborhood/cover', requireAdmin, upload.single('image'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'image required' });
  for (const n of fs.readdirSync(uploadsDir)) {
    const p = path.join(uploadsDir, n);
    if (n.startsWith('cover.') && p !== req.file.path) fs.unlinkSync(p);
  }
  coverPath = req.file.path;
  res.status(201).json({ ok: true });
});
app.get('/api/neighborhood/cover', (_req, res) => {
  const p = coverPath && fs.existsSync(coverPath) ? coverPath : null;
  if (!p) return res.status(404).json({ error: 'no cover' });
  res.sendFile(p);
});

app.get('/', (_req, res) => res.json({ name: 'Korshi API', docs: '/api/health' }));

export { app };
if (process.env.KORSHI_NO_LISTEN !== '1') {
  app.listen(PORT, () => console.log(`[korshi-server] listening on :${PORT}`));
}
