import express, { type Request, type Response } from 'express';
import cors from 'cors';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { home, updates, polls, contacts, reports } from './data';

const app = express();
const PORT = Number(process.env.PORT) || 3000;

app.use(cors());
app.use(express.json());

// ─── Neighborhood cover image (uploaded from the admin panel) ───
const uploadsDir = path.join(process.cwd(), 'uploads');
fs.mkdirSync(uploadsDir, { recursive: true });

function findCover(): string | null {
  const f = fs.readdirSync(uploadsDir).find((n) => n.startsWith('cover.'));
  return f ? path.join(uploadsDir, f) : null;
}
let coverPath: string | null = findCover();

const upload = multer({
  storage: multer.diskStorage({
    destination: uploadsDir,
    filename: (_req, file, cb) => {
      const ext = path.extname(file.originalname) || '.jpg';
      cb(null, `cover${ext}`);
    },
  }),
  limits: { fileSize: 10 * 1024 * 1024 },
});

app.post('/api/neighborhood/cover', upload.single('image'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'image file required' });
  // Remove any older cover with a different extension.
  for (const n of fs.readdirSync(uploadsDir)) {
    const p = path.join(uploadsDir, n);
    if (n.startsWith('cover.') && p !== req.file.path) fs.unlinkSync(p);
  }
  coverPath = req.file.path;
  res.status(201).json({ ok: true, url: '/api/neighborhood/cover' });
});

app.get('/api/neighborhood/cover', (_req, res) => {
  const p = coverPath && fs.existsSync(coverPath) ? coverPath : null;
  if (!p) return res.status(404).json({ error: 'no cover set' });
  res.sendFile(p);
});

// ─── Health ───
app.get('/api/health', (_req: Request, res: Response) => {
  res.json({
    status: 'ok',
    service: 'korshi-server',
    version: '0.1.0',
    time: new Date().toISOString(),
  });
});

// ─── Reports submitted by residents (in-memory; newest first) ───
const created: any[] = [];

const categoryTitle: Record<string, string> = {
  water: 'Проблема с водой',
  roads: 'Проблема с дорогой',
  lights: 'Проблема с освещением',
  garbage: 'Проблема с мусором',
  safety: 'Вопрос безопасности',
  other: 'Обращение',
};

function nowLabel(): string {
  const d = new Date();
  const months = ['янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
  const hh = String(d.getHours()).padStart(2, '0');
  const mm = String(d.getMinutes()).padStart(2, '0');
  return `${d.getDate()} ${months[d.getMonth()]} ${d.getFullYear()} · ${hh}:${mm}`;
}

/** Created reports as feed items for Home/Updates. */
function createdAsFeed() {
  return created.map((r) => ({
    title: r.title,
    subtitle: `${r.location} · только что`,
    body: r.description,
    category: r.category,
    status: 'waitingResponse',
    seenBy: 0,
  }));
}

// ─── Resident client data ───
app.get('/api/home', (_req, res) =>
  res.json({ ...home, today: [...createdAsFeed(), ...home.today] }));
app.get('/api/updates', (_req, res) =>
  res.json({ ...updates, latest: [...createdAsFeed(), ...updates.latest] }));
app.get('/api/polls', (_req, res) => res.json(polls));
app.get('/api/contacts', (_req, res) => res.json(contacts));

app.get('/api/reports', (_req, res) => {
  // List view: omit heavy detail fields.
  res.json(
    [...created, ...reports].map(
      ({ detailSteps, chairmanUpdates, description, ...r }) => r,
    ),
  );
});

app.get('/api/reports/:id', (req, res) => {
  const report = [...created, ...reports].find((r) => r.id === req.params.id);
  if (!report) return res.status(404).json({ error: 'not found' });
  res.json(report);
});

app.post('/api/reports', (req, res) => {
  const { category, description, location } = req.body ?? {};
  if (!category) return res.status(400).json({ error: 'category is required' });
  const desc = (description ?? '').trim();
  const date = nowLabel();
  const report = {
    id: `c${Date.now()}`,
    title: desc.length > 0 ? desc : categoryTitle[category] ?? 'Обращение',
    category,
    status: 'waitingResponse',
    location: location ?? '',
    dateTime: date,
    updatedLabel: 'Обновлено только что',
    chairmanNote: 'Заявка получена. Ожидает рассмотрения председателем.',
    author: 'Шерхан Жантали',
    description: desc,
    steps: [
      { label: 'Отправлено', date: 'сейчас', state: 'done' },
      { label: 'Ожидает ответа', date: 'сейчас', state: 'current' },
      { label: 'Решено', date: null, state: 'pending' },
    ],
    detailSteps: [
      { label: 'Отправлено', date: 'сейчас', state: 'done' },
      { label: 'Рассмотрение', date: null, state: 'current' },
      { label: 'В работе', date: null, state: 'pending' },
      { label: 'Решено', date: null, state: 'pending' },
    ],
    chairmanUpdates: [
      { date: 'сейчас', body: 'Заявка получена.\nОжидает рассмотрения председателем.' },
    ],
  };
  created.unshift(report);
  res.status(201).json(report);
});

// Invite flow (used by the admin panel / future apps).
app.post('/api/residents/invite', (req, res) => {
  const { phone, address, name } = req.body ?? {};
  if (!phone || !address) {
    return res.status(400).json({ error: 'phone and address are required' });
  }
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let raw = '';
  for (let i = 0; i < 6; i++) raw += chars[Math.floor(Math.random() * chars.length)];
  const code = `${raw.slice(0, 4)}-${raw.slice(4)}`;
  res.status(201).json({
    resident: { phone, address, name: name ?? null, status: 'invited' },
    activationCode: code,
    expires: null,
  });
});

app.get('/', (_req, res) => res.json({ name: 'Korshi API', docs: '/api/health' }));

app.listen(PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`[korshi-server] listening on :${PORT}`);
});
