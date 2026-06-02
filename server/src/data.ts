// Seed content for the resident client (Russian). This is the source of truth
// the client fetches live. Replace with a database later.

export const home = {
  neighborhood: 'с/т Щедрость',
  city: 'Алматы',
  announcement: {
    title: 'Ремонт дороги в субботу',
    date: '18 мая, 09:00 – 13:00',
    body: 'Улица Мереке будет частично перекрыта.',
  },
  today: [
    { title: 'Водоснабжение восстановлено', subtitle: 'ул. Абая · 2 ч назад', category: 'water', status: 'resolved' },
    { title: 'Ремонт дороги завтра', subtitle: '18 мая, 08:00 – 16:00', category: 'roads', status: 'upcoming' },
    { title: 'Субботник в это воскресенье', subtitle: '18 мая, 10:00', category: 'other', status: 'event' },
  ],
  poll: { question: 'Установить больше уличных фонарей?', yesPct: 72, noPct: 28 },
  contacts: [
    { name: 'Асхат С.', role: 'Председатель КСК', category: 'other', phone: '+7 701 000 00 01' },
    { name: 'Мурат', role: 'Сантехник', category: 'water', phone: '+7 701 000 00 03' },
    { name: 'Ильяс', role: 'Электрик', category: 'lights', phone: '+7 701 000 00 04' },
  ],
  partner: {
    title: 'Надёжные сантехнические услуги',
    subtitle: 'Рекомендовано для нашего района',
    rating: '4.9',
    reviews: '128',
    phone: '+7 701 000 00 20',
  },
};

export const updates = {
  pinned: {
    title: 'Обслуживание воды в субботу',
    date: '18 мая, 09:00 – 13:00',
    body: 'Водоснабжение будет временно приостановлено на части улицы Мереке.',
    seenBy: 64,
  },
  latest: [
    { id: 'u1', title: 'Водоснабжение восстановлено', subtitle: 'ул. Абая · 2 часа назад', body: 'Давление воды восстановлено. Спасибо за ваше терпение!', category: 'water', status: 'resolved', seenBy: 48 },
    { id: 'u2', title: 'Ремонт дороги завтра', subtitle: '18 мая, 08:00 – 16:00', body: 'Пожалуйста, не оставляйте автомобили на улице во время работ.', category: 'roads', status: 'upcoming', seenBy: 37 },
    { id: 'u3', title: 'Субботник в это воскресенье', subtitle: '18 мая, 10:00', body: 'Давайте сохраним наш район чистым и красивым!', category: 'other', status: 'event', seenBy: 52 },
    { id: 'u4', title: 'Установлены новые фонари', subtitle: 'ул. Абая · вчера', body: 'Мы установили новые LED-фонари на улице Мереке для безопасности.', category: 'lights', status: 'update', seenBy: 41 },
  ],
};

export const polls = {
  participationPct: 72,
  active: {
    question: 'Установить дополнительные фонари на улице Мереке?',
    description: 'Повысить безопасность и видимость по вечерам.',
    options: [
      { label: 'Да, поддерживаю', pct: 82, votes: 61, positive: true },
      { label: 'Не сейчас', pct: 18, votes: 17, positive: false },
    ],
    households: 78,
    endsInDays: 2,
    voted: true,
  },
  upcoming: [
    { title: 'Установка видеонаблюдения', subtitle: 'Повысить безопасность района', category: 'safety', opensLabel: 'Откроется завтра', date: '20 мая' },
    { title: 'Бюджет на уборку снега', subtitle: 'Подготовка к зимнему сезону', category: 'water', opensLabel: 'Откроется через 3 дня', date: '22 мая' },
    { title: 'Установка шлагбаума', subtitle: 'Контролируемый доступ для жителей', category: 'other', opensLabel: 'Откроется через 5 дней', date: '24 мая' },
  ],
  previous: [
    { title: 'Установлены новые фонари', subtitle: 'Повышена безопасность на улице Мереке', status: 'approved', date: '28 апр 2025' },
    { title: 'Предложение о шлагбауме', subtitle: 'Недостаточно поддержки от жителей', status: 'rejected', date: '12 апр 2025' },
  ],
};

export const contacts = {
  important: [
    { name: 'Асхат С.', role: 'Председатель', subtitle: 'Председатель КСК', statusLine: 'Обычно отвечает быстро', category: 'other', badge: 'chairman', phone: '+7 701 000 00 01' },
    { name: 'Данияр Т.', role: 'Участковый', subtitle: 'Полиция Медеуского района', statusLine: 'Доступен', category: 'safety', badge: 'police', phone: '+7 701 000 00 02' },
    { name: 'Экстренная служба', role: 'Экстренный', subtitle: '24/7', statusLine: null, category: 'safety', badge: 'emergency', phone: '112' },
    { name: 'Авария газа / электр.', role: 'Экстренный', subtitle: '24/7', statusLine: null, category: 'lights', badge: 'emergency', phone: '104' },
  ],
  services: [
    { name: 'Мурат', role: 'Сантехник', category: 'water', phone: '+7 701 000 00 03' },
    { name: 'Ильяс', role: 'Электрик', category: 'lights', phone: '+7 701 000 00 04' },
    { name: 'Руслан', role: 'Ремонт ворот', category: 'other', phone: '+7 701 000 00 05' },
    { name: 'Айдос', role: 'Мастер по воде', category: 'water', phone: '+7 701 000 00 06' },
  ],
  partners: [
    { name: 'Ремонт заборов', desc: 'Качественные материалы и монтаж', category: 'other', phone: '+7 701 000 00 10' },
    { name: 'Доставка воды', desc: 'Чистая вода с доставкой на дом', category: 'water', phone: '+7 701 000 00 11' },
    { name: 'Камеры наблюдения', desc: 'Установка и обслуживание', category: 'safety', phone: '+7 701 000 00 12' },
  ],
};

export const reports = [
  {
    id: 'r1',
    author: 'Шерхан Жантали',
    title: 'Не работает уличный фонарь',
    category: 'lights',
    status: 'inProgress',
    location: 'ул. Абая, 12',
    dateTime: '16 мая 2025 · 09:15',
    updatedLabel: 'Обновлено 2 часа назад',
    chairmanNote: 'Запланирован ремонт в эту пятницу.\nМы сообщим, когда работы будут завершены.',
    description: 'Уличный фонарь у наших ворот не работает уже 3 дня.',
    steps: [
      { label: 'Отправлено', date: '16 мая', state: 'done' },
      { label: 'В работе', date: '16 мая', state: 'current' },
      { label: 'Решено', date: null, state: 'pending' },
    ],
    detailSteps: [
      { label: 'Отправлено', date: '16 мая', state: 'done' },
      { label: 'Рассмотрено', date: '16 мая', state: 'done' },
      { label: 'Ремонт запланирован', date: '17 мая', state: 'current' },
      { label: 'Решено', date: null, state: 'pending' },
    ],
    chairmanUpdates: [
      { date: '16 мая', body: 'Мы осмотрели проблему.\nУличный фонарь не работает.' },
      { date: '17 мая', body: 'Ремонт запланирован на эту пятницу (19 мая).\nМы ожидаем бригаду электриков.' },
      { date: '18 мая', body: 'Электрик назначен.\nРаботы выполняются.' },
    ],
  },
  {
    id: 'r2',
    author: 'Шерхан Жантали',
    title: 'Яма на дороге',
    category: 'roads',
    status: 'waitingResponse',
    location: 'ул. Абая, 12',
    dateTime: '14 мая 2025 · 18:40',
    updatedLabel: 'Обновлено 1 день назад',
    chairmanNote: 'Заявка направлена в городскую службу.\nОжидаем их ответа.',
    description: 'Большая яма у въезда, повреждает машины.',
    steps: [
      { label: 'Отправлено', date: '14 мая', state: 'done' },
      { label: 'Ожидает ответа', date: '14 мая', state: 'current' },
      { label: 'Решено', date: null, state: 'pending' },
    ],
    detailSteps: [],
    chairmanUpdates: [],
  },
  {
    id: 'r3',
    author: 'Шерхан Жантали',
    title: 'Утечка воды у парка',
    category: 'water',
    status: 'resolved',
    location: 'ул. Парковая, 5',
    dateTime: '10 мая 2025 · 11:30',
    updatedLabel: 'Обновлено 12 мая 2025',
    chairmanNote: 'Утечка устранена.\nСпасибо за сообщение!',
    description: 'Прорвало трубу рядом с площадкой.',
    steps: [
      { label: 'Отправлено', date: '10 мая', state: 'done' },
      { label: 'В работе', date: '11 мая', state: 'done' },
      { label: 'Решено', date: '12 мая', state: 'done' },
    ],
    detailSteps: [],
    chairmanUpdates: [],
  },
];
