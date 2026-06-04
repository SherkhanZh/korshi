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
import type { Resident, ResidentStatus, Street } from '../types';
import { fetchResidents, inviteResident } from '../lib/api';
import { useAsync } from '../lib/useAsync';

function statusBadge(s: ResidentStatus) {
  switch (s) {
    case 'active':
      return <Badge label="Активен" bg="#E2F0E8" fg="#1E6B4F" />;
    case 'invited':
      return <Badge label="Приглашён" bg="#FBEFD6" fg="#C9881C" />;
    case 'notJoined':
      return <Badge label="Не подключён" bg="#F1F0EA" fg="#6E6E73" />;
  }
}

export function Residents() {
  const { data, loading, error, reload } = useAsync(fetchResidents, []);
  const [query, setQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<ResidentStatus | 'all'>('all');
  const [selected, setSelected] = useState<Resident | null>(null);
  const [invite, setInvite] = useState(false);

  const items: Resident[] = data?.residents ?? [];
  const streets: Street[] = data?.streets ?? [];
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

  if (loading) return <div className="p-10 text-center text-ink3">Загрузка…</div>;
  if (error) return <div className="p-10 text-center text-[#C0492E]">{error}</div>;

  return (
    <div>
      <PageHeader
        title="Жители"
        subtitle="Управление сообществом района"
        action={
          <button className="btn-primary" onClick={() => setInvite(true)}>
            <UserPlus size={16} /> Пригласить жителя
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
                <p className="text-[10px] text-ink3">подключено</p>
              </div>
            </div>
          </div>
          <div>
            <p className="text-sm text-ink2">Прогресс сообщества</p>
            <p className="text-2xl font-bold">
              {community.connected} <span className="text-ink3">из</span> {community.total}
            </p>
            <p className="text-xs text-ink3">домов подключено</p>
          </div>
        </div>

        <div className="grid grid-cols-1 gap-4 sm:grid-cols-3 lg:col-span-2">
          <button onClick={() => setInvite(true)} className="card flex items-center gap-3 p-5 text-left transition hover:shadow-md">
            <div className="grid h-11 w-11 place-items-center rounded-xl bg-greentint text-primary">
              <UserPlus size={20} />
            </div>
            <div>
              <p className="font-semibold">Пригласить</p>
              <p className="text-xs text-ink3">Добавить жителя</p>
            </div>
          </button>
          <div className="card flex items-center gap-3 p-5">
            <div className="grid h-11 w-11 place-items-center rounded-xl bg-greentint text-primary">
              <QrCode size={20} />
            </div>
            <div>
              <p className="font-semibold">QR-приглашение</p>
              <p className="text-xs text-ink3">Сгенерировать QR</p>
            </div>
          </div>
          <div className="card flex items-center gap-3 p-5">
            <div className="grid h-11 w-11 place-items-center rounded-xl bg-[#E3ECF8] text-[#3A6FB0]">
              <BarChart3 size={20} />
            </div>
            <div>
              <p className="font-semibold">{pct}%</p>
              <p className="text-xs text-ink3">Участие</p>
            </div>
          </div>
        </div>
      </div>

      {/* Streets overview */}
      <h3 className="mb-3 mt-8 flex items-center gap-2 font-semibold">
        <MapPin size={16} className="text-primary" /> Обзор улиц
      </h3>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        {streets.map((s) => {
          const p = s.total ? Math.round((s.connected / s.total) * 100) : 0;
          return (
            <div key={s.id} className="card p-4">
              <div className="flex items-center justify-between">
                <p className="font-semibold">{s.name}</p>
                <span className="text-sm font-bold text-primary">{p}%</span>
              </div>
              <p className="mt-0.5 text-xs text-ink3">
                {s.connected} из {s.total} домов
              </p>
              <div className="mt-2 h-2 overflow-hidden rounded-full bg-line">
                <div className="h-full rounded-full bg-primary" style={{ width: `${p}%` }} />
              </div>
            </div>
          );
        })}
      </div>

      {/* Residents list */}
      <div className="mb-3 mt-8 flex items-center justify-between">
        <h3 className="font-semibold">Жители ({items.length})</h3>
        <div className="flex gap-2">
          <select
            className="input w-40"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as ResidentStatus | 'all')}
          >
            <option value="all">Все статусы</option>
            <option value="active">Активные</option>
            <option value="invited">Приглашённые</option>
            <option value="notJoined">Не подключены</option>
          </select>
          <input
            className="input w-56"
            placeholder="Поиск жителей…"
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
            {statusBadge(r.status)}
          </div>
        ))}
        {filtered.length === 0 && (
          <div className="px-5 py-8 text-center text-ink3">Жителей нет</div>
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
  const [phone, setPhone] = useState('');
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
      setCode(r.activationCode);
      onCreated();
    } catch (e) {
      setErr(e instanceof Error ? e.message : 'Не удалось создать приглашение');
    } finally {
      setBusy(false);
    }
  };

  return (
    <Modal open title="Пригласить жителя" onClose={onClose} width={480}>
      <div className="space-y-4">
        <div>
          <label className="label">Номер телефона *</label>
          <input className="input" value={phone} disabled={!!code} onChange={(e) => setPhone(e.target.value)} placeholder="+7 7__ ___ __ __" />
        </div>
        <div>
          <label className="label">Адрес *</label>
          <input className="input" value={address} disabled={!!code} onChange={(e) => setAddress(e.target.value)} placeholder="ул. Абая, 27" />
        </div>
        <div>
          <label className="label">Имя жителя (необязательно)</label>
          <input className="input" value={name} disabled={!!code} onChange={(e) => setName(e.target.value)} placeholder="Даулет С." />
        </div>

        {err && <p className="rounded-lg bg-[#FBE6E1] px-3 py-2 text-sm text-[#C0492E]">{err}</p>}

        {!code ? (
          <button className="btn-primary w-full" onClick={create} disabled={busy || !phone.trim() || !address.trim()}>
            <KeyRound size={16} /> {busy ? 'Создаём…' : 'Создать код активации'}
          </button>
        ) : (
          <>
            {/* Code */}
            <div className="flex items-center justify-between rounded-xl border border-line bg-greentint p-3">
              <div className="flex items-center gap-3">
                <div className="grid h-10 w-10 place-items-center rounded-lg bg-primary text-white">
                  <KeyRound size={18} />
                </div>
                <div>
                  <p className="text-xs text-ink2">Код активации (создан сервером)</p>
                  <p className="font-mono text-2xl font-bold tracking-widest text-primary">{code}</p>
                </div>
              </div>
              <div className="text-right">
                <p className="text-xs text-ink3">Код не истекает</p>
                <button onClick={() => copy(code)} className="mt-1 inline-flex items-center gap-1 text-sm font-semibold text-primary">
                  <Copy size={14} /> {copied ? 'Скопировано' : 'Копировать'}
                </button>
              </div>
            </div>

            {/* WhatsApp preview */}
            <div>
              <label className="label">Предпросмотр приглашения (WhatsApp)</label>
              <div className="rounded-xl bg-greentint p-3 text-sm text-ink2 whitespace-pre-line">{msg}</div>
            </div>

            <div className="space-y-2">
              <a
                href={`https://wa.me/?text=${encodeURIComponent(msg)}`}
                target="_blank"
                rel="noreferrer"
                className="btn-primary w-full !bg-[#25D366] hover:!bg-[#1eb958]"
              >
                <MessageCircle size={16} /> Отправить через WhatsApp
              </a>
              <button onClick={() => copy(msg)} className="btn-ghost w-full">
                <Copy size={16} /> Скопировать приглашение
              </button>
              <button onClick={onClose} className="btn-ghost w-full">Готово</button>
            </div>
          </>
        )}
      </div>
    </Modal>
  );
}

// ─── Resident detail ───
function ResidentDetail({ resident, onClose }: { resident: Resident | null; onClose: () => void }) {
  if (!resident) return null;
  const m = resident.metrics;

  const quickActions = [
    { label: 'Написать', icon: MessageCircle },
    { label: 'Позвонить', icon: Phone },
    { label: 'Сменить адрес', icon: Home },
    { label: 'Редактировать', icon: Pencil },
    { label: 'Перевыпустить код', icon: RefreshCw },
    { label: 'Деактивировать', icon: UserX, danger: true },
  ];

  return (
    <Modal open title="Профиль жителя" onClose={onClose} width={520}>
      {/* Header */}
      <div className="flex items-center gap-4 rounded-2xl bg-muted p-4">
        <div className="grid h-16 w-16 place-items-center rounded-full bg-greentint text-xl font-bold text-primary">
          {resident.initials}
        </div>
        <div>
          <h3 className="text-xl font-bold">{resident.name}</h3>
          <div className="mt-1">{statusBadge(resident.status)}</div>
          <p className="mt-1.5 flex items-center gap-1.5 text-sm text-ink2"><MapPin size={13} /> {resident.address}</p>
          <p className="flex items-center gap-1.5 text-sm text-ink2"><Phone size={13} /> {resident.phone}</p>
        </div>
      </div>

      {resident.inviteCode && (
        <div className="mt-3 flex items-center justify-between rounded-xl border border-line bg-greentint p-3 text-sm">
          <span className="text-ink2">Код активации (работает как пароль, пока не изменён)</span>
          <span className="font-mono text-lg font-bold tracking-widest text-primary">{resident.inviteCode}</span>
        </div>
      )}

      {/* Activity */}
      {m && (
        <>
          <div className="mt-4 grid grid-cols-4 gap-2">
            {[
              { icon: FileText, v: m.reports, l: 'Заявок' },
              { icon: BarChart3, v: m.polls, l: 'Опросов' },
              { icon: Megaphone, v: `${m.announcementsRead}%`, l: 'Прочитано' },
              { icon: Clock, v: m.lastActive.split(',')[0], l: 'Активность' },
            ].map((s) => (
              <div key={s.l} className="rounded-xl bg-muted p-3 text-center">
                <s.icon size={16} className="mx-auto text-primary" />
                <p className="mt-1 text-sm font-bold">{s.v}</p>
                <p className="text-[11px] text-ink3">{s.l}</p>
              </div>
            ))}
          </div>

          <div className="mt-3 rounded-xl border border-line p-4">
            <p className="mb-2 text-sm font-semibold">Участие</p>
            <div className="space-y-2 text-sm">
              <Bar label={`Опросы — ${m.polls} из ${m.pollsTotal}`} pct={(m.polls / m.pollsTotal) * 100} />
              <Bar label={`Прочитано объявлений — ${m.announcementsRead}%`} pct={m.announcementsRead} />
            </div>
            <p className="mt-2 text-xs text-ink3">
              Первый вход: {m.firstLogin} · Активность: {m.participation}
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
          <p className="text-xs font-semibold text-[#C9881C]">Заметка администратора (приватно)</p>
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
