import { useMemo, useState } from 'react';
import {
  UserPlus,
  Clock,
  QrCode,
  MapPin,
  Copy,
  MessageCircle,
  Phone,
  Home,
  Pencil,
  RefreshCw,
  UserX,
  KeyRound,
  FileText,
  BarChart3,
  Megaphone,
} from 'lucide-react';
import { PageHeader } from '../components/ui/PageHeader';
import { Badge } from '../components/ui/Badge';
import { Modal } from '../components/ui/Modal';
import { inviteMessage } from '../data/mockData';
import type { Resident, ResidentStatus } from '../types';
import { fetchResidents, inviteResident } from '../lib/api';
import { useAsync } from '../lib/useAsync';
import { useI18n } from '../lib/i18n';

type Tr = (ru: string, kk: string) => string;

function statusBadge(s: ResidentStatus, tr: Tr) {
  switch (s) {
    case 'active':
      return <Badge label={tr('Активен', 'Белсенді')} bg="#E2F0E8" fg="#1E6B4F" />;
    case 'invited':
      return <Badge label={tr('Приглашён', 'Шақырылды')} bg="#FBEFD6" fg="#C9881C" />;
    case 'notJoined':
      return <Badge label={tr('Не подключён', 'Қосылмаған')} bg="#F1F0EA" fg="#6E6E73" />;
  }
}

export function Residents() {
  const { t: tr } = useI18n();
  const { data, loading, error, reload } = useAsync(fetchResidents, []);
  const [query, setQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<ResidentStatus | 'all'>('all');
  const [selected, setSelected] = useState<Resident | null>(null);
  const [invite, setInvite] = useState(false);

  const items: Resident[] = data?.residents ?? [];
  const community = data?.community ?? { connected: 0, total: 0 };
  const pct = community.total ? Math.round((community.connected / community.total) * 100) : 0;

  const filtered = useMemo(
    () =>
      items.filter((r) => {
        const okS = statusFilter === 'all' || r.status === statusFilter;
        const okQ =
          !query ||
          [r.name, r.phone, r.address].join(' ').toLowerCase().includes(query.toLowerCase());
        return okS && okQ;
      }),
    [items, query, statusFilter],
  );

  if (loading) return <div className="p-10 text-center text-ink3">{tr('Загрузка…', 'Жүктелуде…')}</div>;
  if (error) return <div className="p-10 text-center text-[#C0492E]">{error}</div>;

  return (
    <div>
      <PageHeader
        title={tr('Жители', 'Тұрғындар')}
        subtitle={tr('Управление сообществом района', 'Аудан қауымдастығын басқару')}
        action={
          <button className="btn-primary" onClick={() => setInvite(true)}>
            <UserPlus size={16} /> {tr('Пригласить жителя', 'Тұрғынды шақыру')}
          </button>
        }
      />

      {/* Community progress + action tiles */}
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
        <div className="card flex items-center gap-5 p-5 lg:col-span-1">
          <div
            className="grid h-24 w-24 shrink-0 place-items-center rounded-full"
            style={{
              background: `conic-gradient(#1E6B4F ${pct * 3.6}deg, #E6E5DF 0)`,
            }}
          >
            <div className="grid h-[76px] w-[76px] place-items-center rounded-full bg-surface text-center">
              <div>
                <p className="text-lg font-bold leading-none">{pct}%</p>
                <p className="text-[10px] text-ink3">{tr('подключено', 'қосылған')}</p>
              </div>
            </div>
          </div>
          <div>
            <p className="text-sm text-ink2">{tr('Прогресс сообщества', 'Қауымдастық прогресі')}</p>
            <p className="text-2xl font-bold">
              {community.connected} <span className="text-ink3">{tr('из', 'ішінен')}</span> {community.total}
            </p>
            <p className="text-xs text-ink3">{tr('домов подключено', 'үй қосылған')}</p>
          </div>
        </div>

        <div className="grid grid-cols-1 gap-4 sm:grid-cols-3 lg:col-span-2">
          <button onClick={() => setInvite(true)} className="card flex items-center gap-3 p-5 text-left transition hover:shadow-md">
            <div className="grid h-11 w-11 place-items-center rounded-xl bg-greentint text-primary">
              <UserPlus size={20} />
            </div>
            <div>
              <p className="font-semibold">{tr('Пригласить', 'Шақыру')}</p>
              <p className="text-xs text-ink3">{tr('Добавить жителя', 'Тұрғын қосу')}</p>
            </div>
          </button>
          <div className="card flex items-center gap-3 p-5">
            <div className="grid h-11 w-11 place-items-center rounded-xl bg-greentint text-primary">
              <QrCode size={20} />
            </div>
            <div>
              <p className="font-semibold">{tr('QR-приглашение', 'QR-шақыру')}</p>
              <p className="text-xs text-ink3">{tr('Сгенерировать QR', 'QR жасау')}</p>
            </div>
          </div>
          <div className="card flex items-center gap-3 p-5">
            <div className="grid h-11 w-11 place-items-center rounded-xl bg-[#E3ECF8] text-[#3A6FB0]">
              <BarChart3 size={20} />
            </div>
            <div>
              <p className="font-semibold">{pct}%</p>
              <p className="text-xs text-ink3">{tr('Участие', 'Қатысу')}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Residents list */}
      <div className="mb-3 mt-8 flex items-center justify-between">
        <h3 className="font-semibold">{tr('Жители', 'Тұрғындар')} ({items.length})</h3>
        <div className="flex gap-2">
          <select
            className="input w-40"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as ResidentStatus | 'all')}
          >
            <option value="all">{tr('Все статусы', 'Барлық статус')}</option>
            <option value="active">{tr('Активные', 'Белсенді')}</option>
            <option value="invited">{tr('Приглашённые', 'Шақырылған')}</option>
            <option value="notJoined">{tr('Не подключены', 'Қосылмаған')}</option>
          </select>
          <input
            className="input w-56"
            placeholder={tr('Поиск жителей…', 'Тұрғындарды іздеу…')}
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </div>
      </div>
      <div className="card divide-y divide-line/60">
        {filtered.map((r) => (
          <div
            key={r.id}
            onClick={() => setSelected(r)}
            className="flex cursor-pointer items-center gap-3 px-5 py-3.5 transition hover:bg-muted/50"
          >
            <div className="grid h-10 w-10 place-items-center rounded-full bg-greentint text-sm font-semibold text-primary">
              {r.initials}
            </div>
            <div className="min-w-0 flex-1">
              <p className="font-medium">{r.name}</p>
              <p className="text-xs text-ink3">
                {r.address} · {r.phone}
              </p>
            </div>
            {r.inviteCode && (
              <span className="rounded-lg bg-muted px-2 py-1 font-mono text-xs font-semibold tracking-widest">
                {r.inviteCode}
              </span>
            )}
            {statusBadge(r.status, tr)}
          </div>
        ))}
        {filtered.length === 0 && (
          <div className="px-5 py-8 text-center text-ink3">{tr('Жителей нет', 'Тұрғындар жоқ')}</div>
        )}
      </div>

      {invite && (
        <InviteModal
          onClose={() => setInvite(false)}
          onCreated={reload}
        />
      )}
      <ResidentDetail resident={selected} onClose={() => setSelected(null)} />
    </div>
  );
}

// ─── Invite modal ───
function InviteModal({
  onClose,
  onCreated,
}: {
  onClose: () => void;
  onCreated: () => void;
}) {
  const { t: tr } = useI18n();
  const [phone, setPhone] = useState('+7 ');
  const [address, setAddress] = useState('');
  const [name, setName] = useState('');
  const [code, setCode] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState('');
  const [copied, setCopied] = useState(false);

  const msg = inviteMessage(address || '—', code || '••••-••');

  const copy = (text: string) => {
    navigator.clipboard?.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  };

  const create = async () => {
    if (!phone.trim() || !address.trim() || busy) return;
    setBusy(true);
    setErr('');
    try {
      const r = await inviteResident({ phone: phone.trim(), address: address.trim(), name: name.trim() || undefined });
      // Show the code popup first; refreshing the list now would unmount this
      // modal via the page's loading guard. Reload happens on close instead.
      setCode(r.activationCode);
    } catch (e) {
      setErr(e instanceof Error ? e.message : tr('Не удалось создать приглашение', 'Шақыру жасау мүмкін болмады'));
    } finally {
      setBusy(false);
    }
  };

  // Closing the success popup refreshes the resident list.
  const finish = () => {
    onCreated();
    onClose();
  };

  // Once a code exists, show ONLY the result (no form to scroll past).
  if (code) {
    return (
      <Modal open title={tr('Житель приглашён', 'Тұрғын шақырылды')} onClose={finish} width={480}>
        <div className="space-y-4">
          <div className="rounded-xl border border-line bg-greentint p-4 text-center">
            <p className="text-xs text-ink2">{tr('Код активации', 'Белсендіру коды')}</p>
            <p className="font-mono text-4xl font-extrabold tracking-[0.3em] text-primary">{code}</p>
            <p className="mt-1 text-xs text-ink3">{tr('Код не истекает и работает как пароль до смены', 'Код мерзімі бітпейді және ауыстырылғанға дейін құпиясөз ретінде жұмыс істейді')}</p>
            <button onClick={() => copy(code)} className="mt-2 inline-flex items-center gap-1 text-sm font-semibold text-primary">
              <Copy size={14} /> {copied ? tr('Скопировано', 'Көшірілді') : tr('Копировать код', 'Кодты көшіру')}
            </button>
          </div>

          <div>
            <label className="label">{tr('Приглашение для жителя', 'Тұрғынға арналған шақыру')}</label>
            <div className="rounded-xl bg-muted p-3 text-sm text-ink2 whitespace-pre-line">{msg}</div>
          </div>

          <div className="space-y-2">
            <a
              href={`https://wa.me/?text=${encodeURIComponent(msg)}`}
              target="_blank"
              rel="noreferrer"
              className="btn-primary w-full !bg-[#25D366] hover:!bg-[#1eb958]"
            >
              <MessageCircle size={16} /> {tr('Отправить через WhatsApp', 'WhatsApp арқылы жіберу')}
            </a>
            <button onClick={() => copy(msg)} className="btn-ghost w-full">
              <Copy size={16} /> {tr('Скопировать приглашение', 'Шақыруды көшіру')}
            </button>
            <button onClick={finish} className="btn-primary w-full">{tr('Готово', 'Дайын')}</button>
          </div>
        </div>
      </Modal>
    );
  }

  return (
    <Modal open title={tr('Пригласить жителя', 'Тұрғынды шақыру')} onClose={onClose} width={480}>
      <div className="space-y-4">
        <div>
          <label className="label">{tr('Номер телефона *', 'Телефон нөмірі *')}</label>
          <input className="input" value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="+7 7__ ___ __ __" />
        </div>
        <div>
          <label className="label">{tr('Адрес *', 'Мекенжай *')}</label>
          <input className="input" value={address} onChange={(e) => setAddress(e.target.value)} placeholder="ул. Абая, 27" />
        </div>
        <div>
          <label className="label">{tr('Имя жителя (необязательно)', 'Тұрғын аты (міндетті емес)')}</label>
          <input className="input" value={name} onChange={(e) => setName(e.target.value)} placeholder="Даулет С." />
        </div>

        {err && <p className="rounded-lg bg-[#FBE6E1] px-3 py-2 text-sm text-[#C0492E]">{err}</p>}

        <button className="btn-primary w-full" onClick={create} disabled={busy || !phone.trim() || !address.trim()}>
          <KeyRound size={16} /> {busy ? tr('Создаём…', 'Құрылуда…') : tr('Создать код активации', 'Белсендіру кодын жасау')}
        </button>
      </div>
    </Modal>
  );
}

// ─── Resident detail ───
function ResidentDetail({ resident, onClose }: { resident: Resident | null; onClose: () => void }) {
  const { t: tr } = useI18n();
  if (!resident) return null;
  const m = resident.metrics;

  const quickActions = [
    { label: tr('Написать', 'Жазу'), icon: MessageCircle },
    { label: tr('Позвонить', 'Қоңырау шалу'), icon: Phone },
    { label: tr('Сменить адрес', 'Мекенжайды ауыстыру'), icon: Home },
    { label: tr('Редактировать', 'Өңдеу'), icon: Pencil },
    { label: tr('Перевыпустить код', 'Кодты қайта шығару'), icon: RefreshCw },
    { label: tr('Деактивировать', 'Өшіру'), icon: UserX, danger: true },
  ];

  return (
    <Modal open title={tr('Профиль жителя', 'Тұрғын профилі')} onClose={onClose} width={520}>
      {/* Header */}
      <div className="flex items-center gap-4 rounded-2xl bg-muted p-4">
        <div className="grid h-16 w-16 place-items-center rounded-full bg-greentint text-xl font-bold text-primary">
          {resident.initials}
        </div>
        <div>
          <h3 className="text-xl font-bold">{resident.name}</h3>
          <div className="mt-1">{statusBadge(resident.status, tr)}</div>
          <p className="mt-1.5 flex items-center gap-1.5 text-sm text-ink2"><MapPin size={13} /> {resident.address}</p>
          <p className="flex items-center gap-1.5 text-sm text-ink2"><Phone size={13} /> {resident.phone}</p>
        </div>
      </div>

      {resident.inviteCode && (
        <div className="mt-3 flex items-center justify-between rounded-xl border border-line bg-greentint p-3 text-sm">
          <span className="text-ink2">{tr('Код активации (работает как пароль, пока не изменён)', 'Белсендіру коды (өзгертілгенге дейін құпиясөз ретінде жұмыс істейді)')}</span>
          <span className="font-mono text-lg font-bold tracking-widest text-primary">{resident.inviteCode}</span>
        </div>
      )}

      {/* Activity */}
      {m && (
        <>
          <div className="mt-4 grid grid-cols-4 gap-2">
            {[
              { icon: FileText, v: m.reports, l: tr('Заявок', 'Өтініш') },
              { icon: BarChart3, v: m.polls, l: tr('Опросов', 'Сауалнама') },
              { icon: Megaphone, v: `${m.announcementsRead}%`, l: tr('Прочитано', 'Оқылды') },
              { icon: Clock, v: m.lastActive.split(',')[0], l: tr('Активность', 'Белсенділік') },
            ].map((s) => (
              <div key={s.l} className="rounded-xl bg-muted p-3 text-center">
                <s.icon size={16} className="mx-auto text-primary" />
                <p className="mt-1 text-sm font-bold">{s.v}</p>
                <p className="text-[11px] text-ink3">{s.l}</p>
              </div>
            ))}
          </div>

          <div className="mt-3 rounded-xl border border-line p-4">
            <p className="mb-2 text-sm font-semibold">{tr('Участие', 'Қатысу')}</p>
            <div className="space-y-2 text-sm">
              <Bar label={`${tr('Опросы', 'Сауалнамалар')} — ${m.polls} ${tr('из', '/')} ${m.pollsTotal}`} pct={(m.polls / m.pollsTotal) * 100} />
              <Bar label={`${tr('Прочитано объявлений', 'Оқылған хабарландырулар')} — ${m.announcementsRead}%`} pct={m.announcementsRead} />
            </div>
            <p className="mt-2 text-xs text-ink3">
              {tr('Первый вход', 'Алғашқы кіру')}: {m.firstLogin} · {tr('Активность', 'Белсенділік')}: {m.participation}
            </p>
          </div>
        </>
      )}

      {/* Quick actions */}
      <div className="mt-4 grid grid-cols-3 gap-2">
        {quickActions.map((a) => (
          <button
            key={a.label}
            className={`flex flex-col items-center gap-1.5 rounded-xl border border-line py-3 text-xs font-medium transition hover:bg-muted ${
              a.danger ? 'text-[#C0492E]' : 'text-ink'
            }`}
          >
            <a.icon size={18} className={a.danger ? 'text-[#C0492E]' : 'text-primary'} />
            {a.label}
          </button>
        ))}
      </div>

      {resident.adminNote && (
        <div className="mt-4 rounded-xl bg-[#FBF3E6] p-3 text-sm">
          <p className="text-xs font-semibold text-[#C9881C]">{tr('Заметка администратора (приватно)', 'Әкімші ескертпесі (құпия)')}</p>
          <p className="mt-0.5 text-ink2">{resident.adminNote}</p>
        </div>
      )}
    </Modal>
  );
}

function Bar({ label, pct }: { label: string; pct: number }) {
  return (
    <div>
      <p className="mb-1 text-ink2">{label}</p>
      <div className="h-2 overflow-hidden rounded-full bg-line">
        <div className="h-full rounded-full bg-primary" style={{ width: `${Math.min(100, pct)}%` }} />
      </div>
    </div>
  );
}
