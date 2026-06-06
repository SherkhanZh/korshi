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

/** The neighborhood that holds the original demo data + the default admin. */
export const DEFAULT_NID = 'n1';

// ─── Schema (fresh installs get the full multi-tenant shape) ───
db.exec(`
CREATE TABLE IF NOT EXISTS neighborhoods (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS admins (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'admin',
  neighborhood_id TEXT
);
CREATE TABLE IF NOT EXISTS residents (
  id TEXT PRIMARY KEY,
  neighborhood_id TEXT NOT NULL,
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
  neighborhood_id TEXT NOT NULL,
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
  photo TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS announcements (
  id TEXT PRIMARY KEY,
  neighborhood_id TEXT NOT NULL,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  title_kk TEXT NOT NULL DEFAULT '',
  message TEXT NOT NULL DEFAULT '',
  message_kk TEXT NOT NULL DEFAULT '',
  audience TEXT NOT NULL DEFAULT 'all',
  audience_label TEXT NOT NULL DEFAULT 'Весь район',
  pinned INTEGER NOT NULL DEFAULT 0,
  date TEXT NOT NULL DEFAULT '',
  seen_by INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS announcement_views (
  announcement_id TEXT NOT NULL,
  resident_id TEXT NOT NULL,
  PRIMARY KEY (announcement_id, resident_id)
);
CREATE TABLE IF NOT EXISTS polls (
  id TEXT PRIMARY KEY,
  neighborhood_id TEXT NOT NULL,
  category TEXT,
  question TEXT NOT NULL,
  question_kk TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  description_kk TEXT NOT NULL DEFAULT '',
  confidential INTEGER NOT NULL DEFAULT 1,
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
  label_kk TEXT NOT NULL DEFAULT '',
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
  neighborhood_id TEXT NOT NULL,
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
  neighborhood_id TEXT NOT NULL,
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
  neighborhood_id TEXT NOT NULL,
  name TEXT NOT NULL,
  connected INTEGER NOT NULL DEFAULT 0,
  total INTEGER NOT NULL DEFAULT 0,
  ord INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS device_tokens (
  token TEXT PRIMARY KEY,
  user_type TEXT NOT NULL,      -- 'resident' | 'admin'
  user_id TEXT NOT NULL,
  neighborhood_id TEXT NOT NULL,
  app TEXT NOT NULL,            -- 'client' | 'admin'
  platform TEXT,
  created_at TEXT NOT NULL
);
`);

// ─── Migration: upgrade legacy single-tenant databases in place ───
function columns(table: string): string[] {
  return (db.prepare(`PRAGMA table_info(${table})`).all() as any[]).map((c) => c.name);
}
function ensureColumn(table: string, col: string, decl: string) {
  if (!columns(table).includes(col)) {
    db.exec(`ALTER TABLE ${table} ADD COLUMN ${col} ${decl}`);
  }
}
function migrate() {
  // Older admins table had no role / neighborhood_id.
  ensureColumn('admins', 'role', "TEXT NOT NULL DEFAULT 'admin'");
  ensureColumn('admins', 'neighborhood_id', 'TEXT');
  for (const t of ['residents', 'reports', 'announcements', 'polls', 'decisions', 'contacts', 'streets']) {
    ensureColumn(t, 'neighborhood_id', 'TEXT');
  }
  // Backfill any rows that predate multi-tenancy onto the default neighborhood.
  db.exec(`UPDATE admins SET neighborhood_id = '${DEFAULT_NID}' WHERE role = 'admin' AND neighborhood_id IS NULL`);
  for (const t of ['residents', 'reports', 'announcements', 'polls', 'decisions', 'contacts', 'streets']) {
    db.exec(`UPDATE ${t} SET neighborhood_id = '${DEFAULT_NID}' WHERE neighborhood_id IS NULL`);
  }
  // Bilingual content columns + poll visibility (added later).
  ensureColumn('announcements', 'title_kk', "TEXT NOT NULL DEFAULT ''");
  ensureColumn('announcements', 'message_kk', "TEXT NOT NULL DEFAULT ''");
  ensureColumn('polls', 'question_kk', "TEXT NOT NULL DEFAULT ''");
  ensureColumn('polls', 'description_kk', "TEXT NOT NULL DEFAULT ''");
  ensureColumn('polls', 'confidential', 'INTEGER NOT NULL DEFAULT 1');
  ensureColumn('poll_options', 'label_kk', "TEXT NOT NULL DEFAULT ''");
  ensureColumn('reports', 'photo', 'TEXT');
  // Backfill KK = RU for pre-existing rows so the app always has a fallback.
  db.exec(`UPDATE announcements SET title_kk = title WHERE title_kk = ''`);
  db.exec(`UPDATE announcements SET message_kk = message WHERE message_kk = ''`);
  db.exec(`UPDATE polls SET question_kk = question WHERE question_kk = ''`);
  db.exec(`UPDATE polls SET description_kk = description WHERE description_kk = ''`);
  db.exec(`UPDATE poll_options SET label_kk = label WHERE label_kk = ''`);
}
migrate();

function count(sql: string, ...params: unknown[]): number {
  return (db.prepare(sql).get(...params) as any).n;
}

/** Standard emergency contacts every new neighborhood starts with. */
export function seedEmergencyContacts(nid: string) {
  const c = db.prepare(
    'INSERT INTO contacts (id,neighborhood_id,kind,name,role,subtitle,status_line,category,badge,phone,ord) VALUES (?,?,?,?,?,?,?,?,?,?,?)',
  );
  c.run(`${nid}-e1`, nid, 'important', 'Экстренная служба', 'Экстренный', '24/7', null, 'safety', 'emergency', '112', 0);
  c.run(`${nid}-e2`, nid, 'important', 'Авария газа / электр.', 'Экстренный', '24/7', null, 'lights', 'emergency', '104', 1);
}

/** Creates a neighborhood and its admin in one transaction. Returns the new id. */
export function createNeighborhood(name: string, adminEmail: string, adminPassword: string): string {
  const id = `n${Date.now()}`;
  db.prepare('INSERT INTO neighborhoods (id,name,created_at) VALUES (?,?,?)').run(id, name, new Date().toISOString());
  db.prepare('INSERT INTO admins (email,password_hash,role,neighborhood_id) VALUES (?,?,?,?)').run(
    adminEmail.toLowerCase(),
    bcrypt.hashSync(adminPassword, 10),
    'admin',
    id,
  );
  seedEmergencyContacts(id);
  return id;
}

// ─── Seed (only when empty) ───
export function seed() {
  const N = DEFAULT_NID;

  if (count('SELECT COUNT(*) AS n FROM neighborhoods') === 0) {
    db.prepare('INSERT INTO neighborhoods (id,name,created_at) VALUES (?,?,?)').run(N, 'мкр Кок-Тобе', new Date().toISOString());
  }

  // Super admin (manages neighborhoods; not tied to one).
  if (count("SELECT COUNT(*) AS n FROM admins WHERE role='super'") === 0) {
    db.prepare('INSERT INTO admins (email,password_hash,role,neighborhood_id) VALUES (?,?,?,?)').run(
      'superadmin@korshi.kz', bcrypt.hashSync('super123', 10), 'super', null,
    );
  }
  // Default neighborhood admin.
  if (count("SELECT COUNT(*) AS n FROM admins WHERE email='admin@korshi.kz'") === 0) {
    db.prepare('INSERT INTO admins (email,password_hash,role,neighborhood_id) VALUES (?,?,?,?)').run(
      'admin@korshi.kz', bcrypt.hashSync('admin123', 10), 'admin', N,
    );
  }

  if (count('SELECT COUNT(*) AS n FROM residents') === 0) {
    const insR = db.prepare(
      `INSERT INTO residents (id, neighborhood_id, name, phone, address, street, status, invite_code, password_hash, created_at)
       VALUES (?,?,?,?,?,?,?,?,?,?)`,
    );
    const now = new Date().toISOString();
    insR.run('res1', N, 'Шерхан Жантали', '+77771234567', 'ул. Мереке, 12', 'ул. Мереке', 'active', '4812', null, now);
    insR.run('res2', N, 'Айгерим Ибраимова', '+77071112233', 'ул. Кок-Тобе, 35', 'ул. Кок-Тобе', 'active', '3490', null, now);
    insR.run('res3', N, '—', '+77059876543', 'ул. Парковая, 5', 'ул. Парковая', 'invited', '5612', null, now);
  }

  if (count('SELECT COUNT(*) AS n FROM streets') === 0) {
    const s = db.prepare('INSERT INTO streets (id,neighborhood_id,name,connected,total,ord) VALUES (?,?,?,?,?,?)');
    s.run('s1', N, 'ул. Абая', 18, 24, 0);
    s.run('s2', N, 'ул. Кок-Тобе', 9, 14, 1);
    s.run('s3', N, 'ул. Таргын', 7, 12, 2);
  }

  if (count('SELECT COUNT(*) AS n FROM reports') === 0) {
    const insRep = db.prepare(
      `INSERT INTO reports (id, neighborhood_id, resident_id, author, title, category, status, location, date_time, description, contractor, internal_note, steps_json, detail_steps_json, updates_json, created_at)
       VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
    );
    const now = Date.now();
    insRep.run('r1', N, 'res1', 'Шерхан Жантали', 'Не работает уличный фонарь', 'lights', 'inProgress',
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
    insRep.run('r2', N, 'res1', 'Шерхан Жантали', 'Яма на дороге', 'roads', 'waitingResponse',
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
    insRep.run('r3', N, 'res1', 'Шерхан Жантали', 'Утечка воды у парка', 'water', 'resolved',
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

  if (count('SELECT COUNT(*) AS n FROM announcements') === 0) {
    const a = db.prepare(
      `INSERT INTO announcements (id,neighborhood_id,type,title,title_kk,message,message_kk,audience,audience_label,pinned,date,seen_by,created_at)
       VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)`,
    );
    const now = Date.now();
    a.run('a1', N, 'water', 'Обслуживание воды в субботу', 'Сенбіде су жөндеу жұмыстары',
      'Водоснабжение будет приостановлено в субботу, 18 мая, с 10:00 до 14:00.',
      'Сенбіде, 18 мамырда, 10:00-ден 14:00-ге дейін су жабылады.',
      'all', 'Весь район', 1, '18 мая, 10:00 – 14:00', 0, String(now - 3000));
    a.run('a2', N, 'maintenance', 'Ремонт дороги завтра', 'Ертең жол жөндеу',
      'Пожалуйста, не оставляйте автомобили на улице во время работ.',
      'Жұмыс кезінде көліктеріңізді көшеде қалдырмаңыз.',
      'street', 'ул. Абая', 0, '18 мая, 08:00 – 16:00', 0, String(now - 2000));
    a.run('a3', N, 'event', 'Субботник в это воскресенье', 'Осы жексенбіде сенбілік',
      'Давайте сохраним наш район чистым и красивым!',
      'Ауданымызды таза әрі әдемі сақтайық!',
      'all', 'Весь район', 0, '18 мая, 10:00', 0, String(now - 1000));
  }

  if (count('SELECT COUNT(*) AS n FROM polls') === 0) {
    const now = Date.now();
    db.prepare(
      `INSERT INTO polls (id,neighborhood_id,category,question,question_kk,description,description_kk,confidential,status,duration_days,audience_label,ends_at,created_at)
       VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)`,
    ).run('p1', N, 'infrastructure',
      'Установить дополнительные фонари на улице Мереке?',
      'Мереке көшесіне қосымша шамдар орнату керек пе?',
      'Повысить безопасность и видимость по вечерам.',
      'Кешкі уақытта қауіпсіздік пен көрінуді арттыру.',
      0, 'active', 7, 'Весь район', 'через 2 дн.', String(now));
    const o = db.prepare('INSERT INTO poll_options (poll_id,label,label_kk,votes,positive,ord) VALUES (?,?,?,?,?,?)');
    o.run('p1', 'Да, поддерживаю', 'Иә, қолдаймын', 61, 1, 0);
    o.run('p1', 'Не сейчас', 'Әзірге жоқ', 17, 0, 1);
  }

  if (count('SELECT COUNT(*) AS n FROM decisions') === 0) {
    const d = db.prepare(
      'INSERT INTO decisions (id,neighborhood_id,kind,title,subtitle,category,opens_label,date,status,ord) VALUES (?,?,?,?,?,?,?,?,?,?)',
    );
    d.run('d1', N, 'upcoming', 'Установка видеонаблюдения', 'Повысить безопасность района', 'safety', 'Откроется завтра', '20 мая', null, 0);
    d.run('d2', N, 'upcoming', 'Бюджет на уборку снега', 'Подготовка к зимнему сезону', 'water', 'Откроется через 3 дня', '22 мая', null, 1);
    d.run('d3', N, 'previous', 'Установлены новые фонари', 'Повышена безопасность на улице Мереке', null, null, '28 апр 2025', 'approved', 0);
    d.run('d4', N, 'previous', 'Предложение о шлагбауме', 'Недостаточно поддержки от жителей', null, null, '12 апр 2025', 'rejected', 1);
  }

  if (count('SELECT COUNT(*) AS n FROM contacts') === 0) {
    const c = db.prepare(
      'INSERT INTO contacts (id,neighborhood_id,kind,name,role,subtitle,status_line,category,badge,phone,ord) VALUES (?,?,?,?,?,?,?,?,?,?,?)',
    );
    c.run('c1', N, 'important', 'Асхат С.', 'Председатель', 'Председатель КСК', 'Обычно отвечает быстро', 'other', 'chairman', '+7 701 000 00 01', 0);
    c.run('c2', N, 'important', 'Данияр Т.', 'Участковый', 'Полиция Медеуского района', 'Доступен', 'safety', 'police', '+7 701 000 00 02', 1);
    c.run('c3', N, 'important', 'Экстренная служба', 'Экстренный', '24/7', null, 'safety', 'emergency', '112', 2);
    c.run('c4', N, 'important', 'Авария газа / электр.', 'Экстренный', '24/7', null, 'lights', 'emergency', '104', 3);
    c.run('s1', N, 'service', 'Мурат', 'Сантехник', null, null, 'water', null, '+7 701 000 00 03', 0);
    c.run('s2', N, 'service', 'Ильяс', 'Электрик', null, null, 'lights', null, '+7 701 000 00 04', 1);
    c.run('s3', N, 'service', 'Руслан', 'Ремонт ворот', null, null, 'other', null, '+7 701 000 00 05', 2);
    c.run('s4', N, 'service', 'Айдос', 'Мастер по воде', null, null, 'water', null, '+7 701 000 00 06', 3);
    c.run('pt1', N, 'partner', 'Ремонт заборов', 'Качественные материалы и монтаж', null, null, 'other', null, '+7 701 000 00 10', 0);
    c.run('pt2', N, 'partner', 'Доставка воды', 'Чистая вода с доставкой на дом', null, null, 'water', null, '+7 701 000 00 11', 1);
    c.run('pt3', N, 'partner', 'Камеры наблюдения', 'Установка и обслуживание', null, null, 'safety', null, '+7 701 000 00 12', 2);
  }
}

export function neighborhoodName(nid: string | null | undefined): string {
  if (!nid) return '';
  const row = db.prepare('SELECT name FROM neighborhoods WHERE id = ?').get(nid) as any;
  return row ? row.name : '';
}
