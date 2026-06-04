import { DatabaseSync } from 'node:sqlite';
import bcrypt from 'bcryptjs';
import path from 'path';
import fs from 'fs';

const dataDir = process.env.DB_DIR || path.join(process.cwd(), 'data');
fs.mkdirSync(dataDir, { recursive: true });
const dbPath = path.join(dataDir, 'korshi.db');

export const db = new DatabaseSync(dbPath);
try {
  db.exec('PRAGMA journal_mode = WAL;');
} catch {
  // Some filesystems (network/overlay mounts) reject WAL — fall back to the default journal.
}
db.exec('PRAGMA foreign_keys = ON;');

// ─── Schema ───
db.exec(`
CREATE TABLE IF NOT EXISTS admins (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS residents (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '—',
  phone TEXT UNIQUE NOT NULL,
  address TEXT NOT NULL,
  street TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'invited',
  invite_code TEXT,
  password_hash TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS reports (
  id TEXT PRIMARY KEY,
  resident_id TEXT,
  author TEXT NOT NULL DEFAULT '',
  title TEXT NOT NULL,
  category TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'waitingResponse',
  location TEXT NOT NULL DEFAULT '',
  date_time TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  contractor TEXT,
  internal_note TEXT,
  steps_json TEXT NOT NULL DEFAULT '[]',
  detail_steps_json TEXT NOT NULL DEFAULT '[]',
  updates_json TEXT NOT NULL DEFAULT '[]',
  created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS announcements (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL DEFAULT '',
  audience TEXT NOT NULL DEFAULT 'all',
  audience_label TEXT NOT NULL DEFAULT 'Весь район',
  pinned INTEGER NOT NULL DEFAULT 0,
  date TEXT NOT NULL DEFAULT '',
  seen_by INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS polls (
  id TEXT PRIMARY KEY,
  category TEXT,
  question TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'active',
  duration_days INTEGER NOT NULL DEFAULT 7,
  audience_label TEXT NOT NULL DEFAULT 'Весь район',
  ends_at TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS poll_options (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  poll_id TEXT NOT NULL,
  label TEXT NOT NULL,
  votes INTEGER NOT NULL DEFAULT 0,
  positive INTEGER NOT NULL DEFAULT 0,
  ord INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS votes (
  poll_id TEXT NOT NULL,
  resident_id TEXT NOT NULL,
  option_id INTEGER NOT NULL,
  PRIMARY KEY (poll_id, resident_id)
);
CREATE TABLE IF NOT EXISTS decisions (
  id TEXT PRIMARY KEY,
  kind TEXT NOT NULL,
  title TEXT NOT NULL,
  subtitle TEXT NOT NULL DEFAULT '',
  category TEXT,
  opens_label TEXT,
  date TEXT,
  status TEXT,
  ord INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS contacts (
  id TEXT PRIMARY KEY,
  kind TEXT NOT NULL,
  name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT '',
  subtitle TEXT,
  status_line TEXT,
  category TEXT,
  badge TEXT,
  phone TEXT NOT NULL DEFAULT '',
  ord INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS streets (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  connected INTEGER NOT NULL DEFAULT 0,
  total INTEGER NOT NULL DEFAULT 0,
  ord INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
`);

function count(table: string): number {
  return (db.prepare(`SELECT COUNT(*) AS n FROM ${table}`).get() as any).n;
}

// ─── Seed (only when empty) ───
export function seed() {
  if (count('admins') === 0) {
    db.prepare('INSERT INTO admins (email, password_hash) VALUES (?, ?)').run(
      'admin@korshi.kz',
      bcrypt.hashSync('admin123', 10),
    );
  }

  if (count('settings') === 0) {
    db.prepare('INSERT INTO settings (key, value) VALUES (?, ?)').run(
      'neighborhood',
      'мкр Кок-Тобе',
    );
  }

  if (count('residents') === 0) {
    const insR = db.prepare(
      `INSERT INTO residents (id, name, phone, address, street, status, invite_code, password_hash, created_at)
       VALUES (?,?,?,?,?,?,?,?,?)`,
    );
    const now = new Date().toISOString();
    insR.run('res1', 'Шерхан Жантали', '+77771234567', 'ул. Мереке, 12', 'ул. Мереке', 'active', 'AB12-48', null, now);
    insR.run('res2', 'Айгерим Ибраимова', '+77071112233', 'ул. Кок-Тобе, 35', 'ул. Кок-Тобе', 'active', 'CD34-90', null, now);
    insR.run('res3', '—', '+77059876543', 'ул. Парковая, 5', 'ул. Парковая', 'invited', 'EF56-12', null, now);
  }

  if (count('streets') === 0) {
    const s = db.prepare('INSERT INTO streets (id,name,connected,total,ord) VALUES (?,?,?,?,?)');
    s.run('s1', 'ул. Абая', 18, 24, 0);
    s.run('s2', 'ул. Кок-Тобе', 9, 14, 1);
    s.run('s3', 'ул. Таргын', 7, 12, 2);
  }

  if (count('reports') === 0) {
    const insRep = db.prepare(
      `INSERT INTO reports (id, resident_id, author, title, category, status, location, date_time, description, contractor, internal_note, steps_json, detail_steps_json, updates_json, created_at)
       VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
    );
    const now = Date.now();
    insRep.run('r1', 'res1', 'Шерхан Жантали', 'Не работает уличный фонарь', 'lights', 'inProgress',
      'ул. Мереке, 12', '16 мая 2025 · 09:15', 'Уличный фонарь у наших ворот не работает уже 3 дня.',
      'Energo Service LLP', 'Ждём доступности подрядчика.',
      JSON.stringify([
        { label: 'Отправлено', date: '16 мая', state: 'done' },
        { label: 'В работе', date: '16 мая', state: 'current' },
        { label: 'Решено', date: null, state: 'pending' },
      ]),
      JSON.stringify([
        { label: 'Отправлено', date: '16 мая', state: 'done' },
        { label: 'Рассмотрено', date: '16 мая', state: 'done' },
        { label: 'Ремонт запланирован', date: '17 мая', state: 'current' },
        { label: 'Решено', date: null, state: 'pending' },
      ]),
      JSON.stringify([
        { date: '16 мая', body: 'Мы осмотрели проблему.\nУличный фонарь не работает.' },
        { date: '17 мая', body: 'Ремонт запланирован на эту пятницу (19 мая).' },
      ]),
      String(now - 3000));
    insRep.run('r2', 'res1', 'Шерхан Жантали', 'Яма на дороге', 'roads', 'waitingResponse',
      'ул. Мереке, 12', '14 мая 2025 · 18:40', 'Большая яма у въезда, повреждает машины.',
      null, null,
      JSON.stringify([
        { label: 'Отправлено', date: '14 мая', state: 'done' },
        { label: 'Ожидает ответа', date: '14 мая', state: 'current' },
        { label: 'Решено', date: null, state: 'pending' },
      ]),
      JSON.stringify([]),
      JSON.stringify([{ date: '14 мая', body: 'Заявка направлена в городскую службу.' }]),
      String(now - 2000));
    insRep.run('r3', 'res1', 'Шерхан Жантали', 'Утечка воды у парка', 'water', 'resolved',
      'ул. Парковая, 5', '10 мая 2025 · 11:30', 'Прорвало трубу рядом с площадкой.',
      null, null,
      JSON.stringify([
        { label: 'Отправлено', date: '10 мая', state: 'done' },
        { label: 'В работе', date: '11 мая', state: 'done' },
        { label: 'Решено', date: '12 мая', state: 'done' },
      ]),
      JSON.stringify([]),
      JSON.stringify([{ date: '12 мая', body: 'Утечка устранена. Спасибо за сообщение!' }]),
      String(now - 1000));
  }

  if (count('announcements') === 0) {
    const a = db.prepare(
      `INSERT INTO announcements (id,type,title,message,audience,audience_label,pinned,date,seen_by,created_at)
       VALUES (?,?,?,?,?,?,?,?,?,?)`,
    );
    const now = Date.now();
    a.run('a1', 'water', 'Обслуживание воды в субботу',
      'Водоснабжение будет приостановлено в субботу, 18 мая, с 10:00 до 14:00.',
      'all', 'Весь район', 1, '18 мая, 10:00 – 14:00', 64, String(now - 3000));
    a.run('a2', 'maintenance', 'Ремонт дороги завтра',
      'Пожалуйста, не оставляйте автомобили на улице во время работ.',
      'street', 'ул. Абая', 0, '18 мая, 08:00 – 16:00', 37, String(now - 2000));
    a.run('a3', 'event', 'Субботник в это воскресенье',
      'Давайте сохраним наш район чистым и красивым!',
      'all', 'Весь район', 0, '18 мая, 10:00', 52, String(now - 1000));
  }

  if (count('polls') === 0) {
    const now = Date.now();
    db.prepare(
      `INSERT INTO polls (id,category,question,description,status,duration_days,audience_label,ends_at,created_at)
       VALUES (?,?,?,?,?,?,?,?,?)`,
    ).run('p1', 'infrastructure', 'Установить дополнительные фонари на улице Мереке?',
      'Повысить безопасность и видимость по вечерам.', 'active', 7, 'Весь район', 'через 2 дн.', String(now));
    const o = db.prepare('INSERT INTO poll_options (poll_id,label,votes,positive,ord) VALUES (?,?,?,?,?)');
    o.run('p1', 'Да, поддерживаю', 61, 1, 0);
    o.run('p1', 'Не сейчас', 17, 0, 1);
  }

  if (count('decisions') === 0) {
    const d = db.prepare(
      'INSERT INTO decisions (id,kind,title,subtitle,category,opens_label,date,status,ord) VALUES (?,?,?,?,?,?,?,?,?)',
    );
    d.run('d1', 'upcoming', 'Установка видеонаблюдения', 'Повысить безопасность района', 'safety', 'Откроется завтра', '20 мая', null, 0);
    d.run('d2', 'upcoming', 'Бюджет на уборку снега', 'Подготовка к зимнему сезону', 'water', 'Откроется через 3 дня', '22 мая', null, 1);
    d.run('d3', 'previous', 'Установлены новые фонари', 'Повышена безопасность на улице Мереке', null, null, '28 апр 2025', 'approved', 0);
    d.run('d4', 'previous', 'Предложение о шлагбауме', 'Недостаточно поддержки от жителей', null, null, '12 апр 2025', 'rejected', 1);
  }

  if (count('contacts') === 0) {
    const c = db.prepare(
      'INSERT INTO contacts (id,kind,name,role,subtitle,status_line,category,badge,phone,ord) VALUES (?,?,?,?,?,?,?,?,?,?)',
    );
    c.run('c1', 'important', 'Асхат С.', 'Председатель', 'Председатель КСК', 'Обычно отвечает быстро', 'other', 'chairman', '+7 701 000 00 01', 0);
    c.run('c2', 'important', 'Данияр Т.', 'Участковый', 'Полиция Медеуского района', 'Доступен', 'safety', 'police', '+7 701 000 00 02', 1);
    c.run('c3', 'important', 'Экстренная служба', 'Экстренный', '24/7', null, 'safety', 'emergency', '112', 2);
    c.run('c4', 'important', 'Авария газа / электр.', 'Экстренный', '24/7', null, 'lights', 'emergency', '104', 3);
    c.run('s1', 'service', 'Мурат', 'Сантехник', null, null, 'water', null, '+7 701 000 00 03', 0);
    c.run('s2', 'service', 'Ильяс', 'Электрик', null, null, 'lights', null, '+7 701 000 00 04', 1);
    c.run('s3', 'service', 'Руслан', 'Ремонт ворот', null, null, 'other', null, '+7 701 000 00 05', 2);
    c.run('s4', 'service', 'Айдос', 'Мастер по воде', null, null, 'water', null, '+7 701 000 00 06', 3);
    c.run('pt1', 'partner', 'Ремонт заборов', 'Качественные материалы и монтаж', null, null, 'other', null, '+7 701 000 00 10', 0);
    c.run('pt2', 'partner', 'Доставка воды', 'Чистая вода с доставкой на дом', null, null, 'water', null, '+7 701 000 00 11', 1);
    c.run('pt3', 'partner', 'Камеры наблюдения', 'Установка и обслуживание', null, null, 'safety', null, '+7 701 000 00 12', 2);
  }
}

export function setting(key: string, fallback = ''): string {
  const row = db.prepare('SELECT value FROM settings WHERE key = ?').get(key) as any;
  return row ? row.value : fallback;
}
