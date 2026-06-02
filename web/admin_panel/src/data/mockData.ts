import type {
  Report,
  Announcement,
  Poll,
  Resident,
  Street,
  ApprovalRequest,
} from '../types';
import { NEIGHBORHOOD } from '../lib/meta';

export const reports: Report[] = [
  {
    id: 'r1',
    title: 'Прорыв воды',
    category: 'water',
    status: 'new',
    urgent: true,
    location: 'ул. Абая, 12',
    resident: 'А. Нурмуханов',
    ago: '15 минут назад',
    date: '18 мая, 09:26',
    description: 'Из трубы у дома бьёт вода, заливает двор.',
    hasPhoto: true,
    timeline: [{ time: '09:26', title: 'Заявка получена', done: true }],
  },
  {
    id: 'r2',
    title: 'Яма на дороге',
    category: 'roads',
    status: 'new',
    urgent: false,
    location: 'ул. Жандосова, 88',
    resident: 'Б. Тлеуов',
    ago: '20 минут назад',
    date: '18 мая, 09:21',
    description: 'Большая яма у въезда, повреждает машины.',
    hasPhoto: true,
    timeline: [{ time: '09:21', title: 'Заявка получена', done: true }],
  },
  {
    id: 'r3',
    title: 'Переполнены баки',
    category: 'garbage',
    status: 'new',
    urgent: false,
    location: 'ул. Кок-Тобе, 54',
    resident: 'А. Ибраимова',
    ago: '35 минут назад',
    date: '18 мая, 09:06',
    description: 'Баки не вывозили неделю.',
    hasPhoto: true,
    needsUpdate: 'Житель ждёт 2 ч',
    timeline: [{ time: '09:06', title: 'Заявка получена', done: true }],
  },
  {
    id: 'r4',
    title: 'Не работает фонарь',
    category: 'lights',
    status: 'inProgress',
    urgent: false,
    location: 'ул. Абая, 27',
    resident: 'М. Абдрахманов',
    ago: '1 час назад',
    date: '16 мая, 21:30',
    description: 'Уличный фонарь у наших ворот не работает уже 3 дня.',
    contractor: 'Energo Service LLP',
    internalNote: 'Ждём доступности подрядчика. Видно только администрации.',
    hasPhoto: true,
    needsUpdate: 'Нет обновления 1 ч',
    timeline: [
      { time: '16 мая, 21:30', title: 'Заявка получена', body: 'Отправил Шерхан Жантали', done: true },
      { time: '16 мая, 22:10', title: 'Председатель осмотрел', body: 'Асхат отметил как осмотрено', done: true },
      { time: '17 мая, 09:15', title: 'Назначен электрик', body: 'Подрядчик: Energo Service LLP', done: true },
      { time: '18 мая, 10:00', title: 'Ремонт запланирован', body: 'Запланировано на 18 мая, 14:00', done: true },
      { time: '18 мая, 14:00', title: 'Ремонт выполняется', body: 'Ожидаем подтверждения', done: false },
    ],
  },
  {
    id: 'r5',
    title: 'Сломан шлагбаум',
    category: 'safety',
    status: 'waitingCity',
    urgent: false,
    location: 'въезд',
    resident: 'О. Нурлан',
    ago: '2 дня назад',
    date: '16 мая, 12:00',
    description: 'Шлагбаум не закрывается.',
    hasPhoto: false,
    timeline: [
      { time: '16 мая', title: 'Заявка получена', done: true },
      { time: '17 мая', title: 'Запрос в акимат', done: true },
    ],
  },
  {
    id: 'r6',
    title: 'Утечка воды у парка',
    category: 'water',
    status: 'resolved',
    urgent: false,
    location: 'ул. Парковая, 5',
    resident: 'Д. Молдабеков',
    ago: '6 дней назад',
    date: '10 мая, 11:30',
    description: 'Прорвало трубу рядом с площадкой.',
    hasPhoto: true,
    timeline: [
      { time: '10 мая', title: 'Заявка получена', done: true },
      { time: '12 мая', title: 'Решено', body: 'Утечка устранена', done: true },
    ],
  },
];

export const announcements: Announcement[] = [
  {
    id: 'a1',
    type: 'water',
    title: 'Обслуживание воды в субботу',
    message:
      'Уважаемые жители, водоснабжение будет приостановлено в субботу, 18 мая, с 10:00 до 14:00.',
    publishNow: true,
    audience: 'all',
    audienceLabel: 'Весь район',
    date: '18 мая, 10:00 – 14:00',
    seenBy: 64,
    pinned: true,
  },
  {
    id: 'a2',
    type: 'maintenance',
    title: 'Ремонт дороги завтра',
    message: 'Пожалуйста, не оставляйте автомобили на улице во время работ.',
    publishNow: true,
    audience: 'street',
    audienceLabel: 'ул. Абая',
    date: '18 мая, 08:00 – 16:00',
    seenBy: 37,
    pinned: false,
  },
  {
    id: 'a3',
    type: 'event',
    title: 'Субботник в это воскресенье',
    message: 'Давайте сохраним наш район чистым и красивым!',
    publishNow: true,
    audience: 'all',
    audienceLabel: 'Весь район',
    date: '18 мая, 10:00',
    seenBy: 52,
    pinned: false,
  },
];

export const polls: Poll[] = [
  {
    id: 'p1',
    category: 'infrastructure',
    question: 'Установить дополнительные фонари на ул. Абая?',
    options: [
      { label: 'Да, поддерживаю', votes: 61 },
      { label: 'Не сейчас', votes: 17 },
    ],
    status: 'active',
    durationDays: 7,
    audienceLabel: 'Весь район',
    households: 78,
    endsAt: '24 мая 2025',
  },
  {
    id: 'p2',
    category: 'safety',
    question: 'Установка видеонаблюдения',
    options: [
      { label: 'Да', votes: 0 },
      { label: 'Нет', votes: 0 },
    ],
    status: 'upcoming',
    durationDays: 7,
    audienceLabel: 'Весь район',
    households: 0,
    endsAt: '26 мая 2025',
  },
  {
    id: 'p3',
    category: 'budget',
    question: 'Бюджет на уборку снега',
    options: [
      { label: 'Одобрить', votes: 88 },
      { label: 'Отклонить', votes: 12 },
    ],
    status: 'closed',
    durationDays: 14,
    audienceLabel: 'Весь район',
    households: 100,
    endsAt: '28 апр 2025',
  },
];

export const quickPollTemplates: { label: string; question: string }[] = [
  { label: 'Фонари', question: 'Установить дополнительные уличные фонари?' },
  { label: 'Видеокамеры', question: 'Установить камеры видеонаблюдения?' },
  { label: 'Ремонт дороги', question: 'Отремонтировать дорогу в этом сезоне?' },
  { label: 'Шлагбаум', question: 'Установить шлагбаум на въезде?' },
  { label: 'Субботник', question: 'Провести общий субботник в выходные?' },
];

export const contractors = [
  'Energo Service LLP',
  'Water Pro KZ',
  'Road Master',
  'Clean City',
  'Security Plus',
];

export const streets: Street[] = [
  { id: 's1', name: 'ул. Абая', connected: 18, total: 24 },
  { id: 's2', name: 'ул. Кок-Тобе', connected: 9, total: 14 },
  { id: 's3', name: 'ул. Таргын', connected: 7, total: 12 },
];

export const community = { connected: 67, total: 98 };

export const approvals: ApprovalRequest[] = [
  { id: 'ap1', name: 'Шерхан Жантали', initials: 'ШЖ', address: 'ул. Абая, 12', joinedAgo: '10 мин назад' },
  { id: 'ap2', name: 'Айгерим Ибраимова', initials: 'АИ', address: 'ул. Кок-Тобе, 35', joinedAgo: '25 мин назад' },
  { id: 'ap3', name: 'Бахтияр Мукашев', initials: 'БМ', address: 'ул. Таргын, 8', joinedAgo: '1 час назад' },
];

export const residents: Resident[] = [
  {
    id: 'res1',
    name: 'Асхат Садвакасов',
    initials: 'АС',
    phone: '+7 777 123 45 67',
    address: 'ул. Абая, 5',
    street: 'ул. Абая',
    status: 'active',
    adminNote: 'Обычно отвечает быстро. Очень активный житель.',
    metrics: {
      reports: 3,
      polls: 7,
      pollsTotal: 9,
      announcementsRead: 82,
      lastActive: 'сегодня, 18:43',
      firstLogin: '14 мая 2025',
      participation: 'Высокая',
    },
  },
  {
    id: 'res2',
    name: 'Гульнара Нургалиева',
    initials: 'ГН',
    phone: '+7 701 234 56 78',
    address: 'ул. Абая, 8',
    street: 'ул. Абая',
    status: 'active',
    metrics: {
      reports: 1,
      polls: 5,
      pollsTotal: 9,
      announcementsRead: 70,
      lastActive: 'вчера, 20:10',
      firstLogin: '12 мая 2025',
      participation: 'Средняя',
    },
  },
  {
    id: 'res3',
    name: 'Даулет Толеген',
    initials: 'ДТ',
    phone: '+7 777 987 65 43',
    address: 'ул. Кок-Тобе, 12',
    street: 'ул. Кок-Тобе',
    status: 'notJoined',
  },
  {
    id: 'res4',
    name: '—',
    initials: '—',
    phone: '+7 705 111 22 33',
    address: 'ул. Таргын, 8',
    street: 'ул. Таргын',
    status: 'invited',
    inviteCode: 'AB12-48',
  },
];

/** Mock of the server-side activation code (6 chars, grouped 4-2, never expires). */
export function generateInviteCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let out = '';
  for (let i = 0; i < 6; i++) out += chars[Math.floor(Math.random() * chars.length)];
  return `${out.slice(0, 4)}-${out.slice(4)}`;
}

export function inviteMessage(address: string, code: string): string {
  return [
    'Здравствуйте!',
    `Вас подключили к приложению района ${NEIGHBORHOOD}.`,
    `Адрес: ${address}`,
    `Код активации: ${code}`,
    'Скачайте приложение и установите пароль при первом входе.',
  ].join('\n');
}
