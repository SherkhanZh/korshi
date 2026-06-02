import { useMemo, useState } from 'react';
import {
  MapPin,
  User,
  Clock,
  AlertTriangle,
  CheckCircle2,
  MessageSquare,
  HardHat,
  Phone,
  Camera,
  RefreshCw,
  Image as ImageIcon,
} from 'lucide-react';
import { PageHeader } from '../components/ui/PageHeader';
import { Badge } from '../components/ui/Badge';
import { Modal } from '../components/ui/Modal';
import { reports as seed, contractors } from '../data/mockData';
import { categoryMeta, reportStatusMeta } from '../lib/meta';
import type { Category, Report, ReportStatus, ReportStage } from '../types';

const TABS: { key: ReportStatus; label: string }[] = [
  { key: 'new', label: 'Новые' },
  { key: 'inProgress', label: 'В работе' },
  { key: 'waitingCity', label: 'Ожидает город' },
  { key: 'resolved', label: 'Решено' },
];

const QUICK_UPDATES: { stage: ReportStage; label: string; status: ReportStatus }[] = [
  { stage: 'inspected', label: 'Осмотрено', status: 'inProgress' },
  { stage: 'scheduledRepair', label: 'Ремонт запланирован', status: 'inProgress' },
  { stage: 'waitingCity', label: 'Ожидает город', status: 'waitingCity' },
  { stage: 'contractorAssigned', label: 'Назначен подрядчик', status: 'inProgress' },
  { stage: 'resolved', label: 'Решено', status: 'resolved' },
];

export function Reports() {
  const [items, setItems] = useState<Report[]>(seed);
  const [tab, setTab] = useState<ReportStatus>('new');
  const [cat, setCat] = useState<Category | 'urgent' | null>(null);
  const [selected, setSelected] = useState<Report | null>(null);

  const counts = useMemo(() => {
    const c: Record<ReportStatus, number> = { new: 0, inProgress: 0, waitingCity: 0, resolved: 0 };
    items.forEach((r) => (c[r.status] += 1));
    return c;
  }, [items]);

  const urgent = items.find((r) => r.urgent && r.status !== 'resolved');

  const filtered = items.filter((r) => {
    if (r.status !== tab) return false;
    if (cat === 'urgent') return r.urgent;
    if (cat) return r.category === cat;
    return true;
  });

  const patch = (id: string, fn: (r: Report) => Report) => {
    setItems((prev) => prev.map((r) => (r.id === id ? fn(r) : r)));
    setSelected((cur) => (cur && cur.id === id ? fn(cur) : cur));
  };

  const applyStage = (r: Report, u: (typeof QUICK_UPDATES)[number]) =>
    patch(r.id, (x) => ({
      ...x,
      status: u.status,
      timeline: [...x.timeline, { time: 'только что', title: u.label, done: u.status === 'resolved' }],
    }));

  return (
    <div>
      <PageHeader title="Заявки" subtitle="Обращения жителей района" />

      {/* Tabs */}
      <div className="mb-4 flex flex-wrap gap-2">
        {TABS.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            className={`flex items-center gap-2 rounded-full px-4 py-2 text-sm font-medium transition ${
              tab === t.key ? 'bg-primary text-white' : 'bg-muted text-ink2 hover:bg-line'
            }`}
          >
            {t.label}
            <span
              className={`rounded-full px-1.5 text-xs ${
                tab === t.key ? 'bg-white/25' : 'bg-surface'
              }`}
            >
              {counts[t.key]}
            </span>
          </button>
        ))}
      </div>

      {/* Category filters */}
      <div className="mb-5 flex flex-wrap gap-2">
        {(['water', 'roads', 'lights'] as Category[]).map((c) => {
          const m = categoryMeta[c];
          const active = cat === c;
          return (
            <button
              key={c}
              onClick={() => setCat(active ? null : c)}
              className="flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-sm font-medium transition"
              style={{
                borderColor: active ? m.color : '#E6E5DF',
                color: active ? m.color : '#6E6E73',
                backgroundColor: active ? `${m.color}14` : '#fff',
              }}
            >
              <m.icon size={14} /> {m.label}
            </button>
          );
        })}
        <button
          onClick={() => setCat(cat === 'urgent' ? null : 'urgent')}
          className="flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-sm font-medium transition"
          style={{
            borderColor: cat === 'urgent' ? '#C0492E' : '#E6E5DF',
            color: cat === 'urgent' ? '#C0492E' : '#6E6E73',
            backgroundColor: cat === 'urgent' ? '#FBE6E1' : '#fff',
          }}
        >
          <AlertTriangle size={14} /> Срочные
        </button>
      </div>

      {/* Urgent highlight */}
      {urgent && tab === 'new' && !cat && (
        <div
          className="mb-5 flex cursor-pointer items-center gap-4 rounded-2xl border border-[#F3DDD3] bg-[#FBEFE9] p-4"
          onClick={() => setSelected(urgent)}
        >
          <div className="grid h-12 w-12 shrink-0 place-items-center rounded-xl bg-[#FBE6E1] text-[#C0492E]">
            <AlertTriangle size={22} />
          </div>
          <div className="min-w-0 flex-1">
            <span className="text-xs font-bold text-[#C0492E]">СРОЧНО</span>
            <p className="font-bold">{urgent.title}</p>
            <p className="text-xs text-ink3">
              {urgent.location} · {urgent.resident} · {urgent.ago}
            </p>
          </div>
          <button className="btn-primary !bg-[#C0492E] hover:!bg-[#a83e26]">Ответить</button>
        </div>
      )}

      {/* Queue */}
      <div className="space-y-3">
        {filtered.map((r) => {
          const m = categoryMeta[r.category];
          const st = reportStatusMeta[r.status];
          const Icon = m.icon;
          return (
            <div
              key={r.id}
              onClick={() => setSelected(r)}
              className="card flex cursor-pointer items-center gap-4 p-4 transition hover:shadow-md"
            >
              <div
                className="grid h-12 w-12 shrink-0 place-items-center rounded-xl"
                style={{ backgroundColor: `${m.color}22`, color: m.color }}
              >
                <Icon size={20} />
              </div>
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2">
                  <span className="text-xs font-medium" style={{ color: m.color }}>
                    {m.label}
                  </span>
                  <Badge label={st.label} bg={st.bg} fg={st.fg} />
                  {r.urgent && (
                    <span className="text-xs font-bold text-[#C0492E]">СРОЧНО</span>
                  )}
                </div>
                <p className="mt-0.5 font-semibold">{r.title}</p>
                <p className="text-xs text-ink3">
                  {r.location} · {r.resident} · {r.ago}
                </p>
                {r.needsUpdate && (
                  <p className="mt-1 flex items-center gap-1 text-xs font-medium text-[#C9881C]">
                    <Clock size={12} /> {r.needsUpdate}
                  </p>
                )}
              </div>
              <button
                className="btn-primary shrink-0"
                onClick={(e) => {
                  e.stopPropagation();
                  if (r.status === 'new')
                    patch(r.id, (x) => ({ ...x, status: 'inProgress' }));
                  else setSelected(r);
                }}
              >
                {r.status === 'new' ? 'В работу' : 'Обновить'}
              </button>
            </div>
          );
        })}
        {filtered.length === 0 && (
          <div className="card p-10 text-center text-ink3">Заявок нет</div>
        )}
      </div>

      <ReportDetail
        report={selected}
        onClose={() => setSelected(null)}
        onStage={applyStage}
        onAssign={(r, c) =>
          patch(r.id, (x) => ({
            ...x,
            contractor: c,
            timeline: [...x.timeline, { time: 'только что', title: 'Назначен подрядчик', body: c, done: true }],
          }))
        }
        onNote={(r, note) => patch(r.id, (x) => ({ ...x, internalNote: note }))}
        onPhoto={(r) => patch(r.id, (x) => ({ ...x, hasPhoto: true }))}
        onResolve={(r) =>
          patch(r.id, (x) => ({
            ...x,
            status: 'resolved',
            timeline: [...x.timeline, { time: 'только что', title: 'Решено', done: true }],
          }))
        }
      />
    </div>
  );
}

function ReportDetail({
  report,
  onClose,
  onStage,
  onAssign,
  onNote,
  onPhoto,
  onResolve,
}: {
  report: Report | null;
  onClose: () => void;
  onStage: (r: Report, u: (typeof QUICK_UPDATES)[number]) => void;
  onAssign: (r: Report, c: string) => void;
  onNote: (r: Report, note: string) => void;
  onPhoto: (r: Report) => void;
  onResolve: (r: Report) => void;
}) {
  const [assigning, setAssigning] = useState(false);
  const [note, setNote] = useState('');
  if (!report) return null;
  const m = categoryMeta[report.category];
  const st = reportStatusMeta[report.status];
  const Icon = m.icon;

  const fastActions = [
    { label: 'Ответить', icon: MessageSquare },
    { label: 'Сменить статус', icon: RefreshCw },
    { label: 'Подрядчик', icon: HardHat, onClick: () => setAssigning((v) => !v) },
    { label: 'Позвонить', icon: Phone },
  ];

  return (
    <Modal open title="Детали заявки" onClose={onClose} width={560}>
      {/* Hero */}
      <div className="flex items-start gap-3 rounded-2xl bg-muted p-4">
        <div
          className="grid h-12 w-12 shrink-0 place-items-center rounded-xl"
          style={{ backgroundColor: `${m.color}22`, color: m.color }}
        >
          <Icon size={22} />
        </div>
        <div className="min-w-0 flex-1">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold" style={{ color: m.color }}>
              {m.label}
            </span>
            <Badge label={st.label} bg={st.bg} fg={st.fg} />
          </div>
          <h3 className="mt-0.5 text-lg font-bold">{report.title}</h3>
          <div className="mt-1 space-y-0.5 text-sm text-ink2">
            <p className="flex items-center gap-1.5"><MapPin size={13} /> {report.location}</p>
            <p className="flex items-center gap-1.5"><User size={13} /> {report.resident}</p>
            <p className="flex items-center gap-1.5"><Clock size={13} /> {report.date}</p>
          </div>
        </div>
      </div>

      {/* Fast actions */}
      <div className="mt-4 grid grid-cols-4 gap-2">
        {fastActions.map((a) => (
          <button
            key={a.label}
            onClick={a.onClick}
            className="flex flex-col items-center gap-1.5 rounded-xl bg-greentint py-3 text-xs font-medium text-primary transition hover:bg-[#e0ebe1]"
          >
            <a.icon size={18} />
            {a.label}
          </button>
        ))}
      </div>

      {/* Assign contractor */}
      {assigning && (
        <div className="mt-3 rounded-xl border border-line p-3">
          <p className="label">Назначить подрядчика</p>
          <div className="flex flex-wrap gap-2">
            {contractors.map((c) => (
              <button
                key={c}
                onClick={() => {
                  onAssign(report, c);
                  setAssigning(false);
                }}
                className="rounded-full bg-muted px-3 py-1.5 text-xs font-medium hover:bg-line"
              >
                {c}
              </button>
            ))}
          </div>
        </div>
      )}
      {report.contractor && (
        <p className="mt-2 text-sm text-ink2">
          Подрядчик: <span className="font-semibold text-ink">{report.contractor}</span>
        </p>
      )}

      {/* Quick update */}
      <div className="mt-4">
        <p className="label">Быстрое обновление статуса</p>
        <div className="flex flex-wrap gap-2">
          {QUICK_UPDATES.map((u) => (
            <button
              key={u.stage}
              onClick={() => onStage(report, u)}
              className="rounded-full border border-line px-3 py-1.5 text-xs font-semibold text-ink2 transition hover:border-primary hover:text-primary"
            >
              {u.label}
            </button>
          ))}
        </div>
      </div>

      {/* Timeline */}
      <div className="mt-5">
        <p className="mb-2 text-sm font-semibold">Хронология</p>
        <div className="space-y-0">
          {report.timeline.map((t, i) => (
            <div key={i} className="flex gap-3">
              <div className="flex flex-col items-center">
                <span
                  className={`mt-1 grid h-4 w-4 place-items-center rounded-full ${
                    t.done ? 'bg-primary text-white' : 'border-2 border-line bg-white'
                  }`}
                >
                  {t.done && <CheckCircle2 size={10} />}
                </span>
                {i < report.timeline.length - 1 && (
                  <span className="w-0.5 flex-1 bg-line" style={{ minHeight: 24 }} />
                )}
              </div>
              <div className="pb-3">
                <p className="text-xs text-ink3">{t.time}</p>
                <p className="text-sm font-medium">{t.title}</p>
                {t.body && <p className="text-xs text-ink2">{t.body}</p>}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Internal note */}
      <div className="mt-3">
        <p className="label">Внутренняя заметка (видна только администрации)</p>
        <textarea
          className="input min-h-[64px] resize-y"
          defaultValue={report.internalNote ?? ''}
          onChange={(e) => setNote(e.target.value)}
          onBlur={() => onNote(report, note || report.internalNote || '')}
          placeholder="Например: ждём доступности подрядчика…"
        />
      </div>

      {/* Photo + resolve */}
      <div className="mt-4 flex items-center gap-2">
        <button onClick={() => onPhoto(report)} className="btn-ghost flex-1">
          {report.hasPhoto ? <ImageIcon size={16} /> : <Camera size={16} />}
          {report.hasPhoto ? 'Фото добавлено' : 'Загрузить фото ремонта'}
        </button>
        <button
          onClick={() => onResolve(report)}
          className="btn-primary flex-1"
          disabled={report.status === 'resolved'}
        >
          <CheckCircle2 size={16} /> Отметить решённой
        </button>
      </div>
    </Modal>
  );
}
