import { useMemo, useState, useEffect } from 'react';
import {
  MapPin,
  User,
  Clock,
  CheckCircle2,
  MessageSquare,
  HardHat,
} from 'lucide-react';
import { PageHeader } from '../components/ui/PageHeader';
import { Badge } from '../components/ui/Badge';
import { Modal } from '../components/ui/Modal';
import { contractors } from '../data/mockData';
import { categoryMeta, reportStatusMeta } from '../lib/meta';
import type { Category, Report, ReportStatus, ReportStage } from '../types';
import { fetchReports, patchReport, addReportUpdate } from '../lib/api';
import { useAsync } from '../lib/useAsync';

type TabKey = ReportStatus | 'all';
const TABS: { key: TabKey; label: string }[] = [
  { key: 'all', label: 'Все' },
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
  const { data, loading, error, setData } = useAsync(fetchReports, []);
  const [items, setItems] = useState<Report[]>([]);
  const [tab, setTab] = useState<TabKey>('all');
  const [cat, setCat] = useState<Category | null>(null);
  const [selected, setSelected] = useState<Report | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (data) setItems(data);
  }, [data]);

  const counts = useMemo(() => {
    const c: Record<TabKey, number> = { all: items.length, new: 0, inProgress: 0, waitingCity: 0, resolved: 0 };
    items.forEach((r) => (c[r.status] += 1));
    return c;
  }, [items]);

  const filtered = items.filter((r) => {
    if (tab !== 'all' && r.status !== tab) return false;
    if (cat) return r.category === cat;
    return true;
  });

  // Replace one report everywhere (list + open modal + cache).
  const apply = (r: Report) => {
    setItems((prev) => {
      const next = prev.map((x) => (x.id === r.id ? r : x));
      setData(next);
      return next;
    });
    setSelected((cur) => (cur && cur.id === r.id ? r : cur));
  };

  const run = async (p: Promise<Report>) => {
    setBusy(true);
    try {
      apply(await p);
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Не удалось обновить заявку');
    } finally {
      setBusy(false);
    }
  };

  const applyStage = (r: Report, u: (typeof QUICK_UPDATES)[number]) =>
    run(patchReport(r.id, { status: u.status }).then(() => addReportUpdate(r.id, u.label)));

  if (loading) return <div className="p-10 text-center text-ink3">Загрузка…</div>;
  if (error) return <div className="p-10 text-center text-[#C0492E]">{error}</div>;

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
      </div>

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
                </div>
                <p className="mt-0.5 font-semibold">{r.title}</p>
                <p className="text-xs text-ink3">
                  {r.location} · {r.resident} · {r.ago}
                </p>
              </div>
              <button
                className="btn-primary shrink-0"
                disabled={busy}
                onClick={(e) => {
                  e.stopPropagation();
                  if (r.status === 'new') run(patchReport(r.id, { status: 'inProgress' }));
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
        busy={busy}
        onClose={() => setSelected(null)}
        onStage={applyStage}
        onReply={(r, text) => run(addReportUpdate(r.id, text))}
        onAssign={(r, c) =>
          run(patchReport(r.id, { contractor: c }).then(() => addReportUpdate(r.id, `Назначен подрядчик: ${c}`)))
        }
        onNote={(r, note) => run(patchReport(r.id, { internalNote: note }))}
        onResolve={(r) =>
          run(patchReport(r.id, { status: 'resolved' }).then(() => addReportUpdate(r.id, 'Заявка решена')))
        }
      />
    </div>
  );
}

function ReportDetail({
  report,
  busy,
  onClose,
  onStage,
  onReply,
  onAssign,
  onNote,
  onResolve,
}: {
  report: Report | null;
  busy: boolean;
  onClose: () => void;
  onStage: (r: Report, u: (typeof QUICK_UPDATES)[number]) => void;
  onReply: (r: Report, text: string) => void;
  onAssign: (r: Report, c: string) => void;
  onNote: (r: Report, note: string) => void;
  onResolve: (r: Report) => void;
}) {
  const [assigning, setAssigning] = useState(false);
  const [note, setNote] = useState('');
  const [reply, setReply] = useState('');
  if (!report) return null;
  const m = categoryMeta[report.category];
  const st = reportStatusMeta[report.status];
  const Icon = m.icon;

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

      {report.description && (
        <p className="mt-3 rounded-xl bg-surface p-3 text-sm text-ink2">{report.description}</p>
      )}

      {/* Reply to resident — posts a visible update */}
      <div className="mt-4">
        <p className="label">Сообщение жителю</p>
        <textarea
          className="input min-h-[64px] resize-y"
          value={reply}
          onChange={(e) => setReply(e.target.value)}
          placeholder="Напишите ответ — он появится в истории заявки у жителя…"
        />
        <button
          className="btn-primary mt-2"
          disabled={busy || !reply.trim()}
          onClick={() => {
            onReply(report, reply.trim());
            setReply('');
          }}
        >
          <MessageSquare size={16} /> Отправить
        </button>
      </div>

      {/* Assign contractor toggle */}
      <button
        className="btn-ghost mt-4 w-full"
        onClick={() => setAssigning((v) => !v)}
      >
        <HardHat size={16} /> {report.contractor ? 'Сменить подрядчика' : 'Назначить подрядчика'}
      </button>
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
              disabled={busy}
              onClick={() => onStage(report, u)}
              className="rounded-full border border-line px-3 py-1.5 text-xs font-semibold text-ink2 transition hover:border-primary hover:text-primary disabled:opacity-50"
            >
              {u.label}
            </button>
          ))}
        </div>
      </div>

      {/* Timeline */}
      <div className="mt-5">
        <p className="mb-2 text-sm font-semibold">Хронология</p>
        {report.timeline.length === 0 ? (
          <p className="text-sm text-ink3">Пока нет обновлений.</p>
        ) : (
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
        )}
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

      {/* Resolve */}
      <div className="mt-4">
        <button
          onClick={() => onResolve(report)}
          className="btn-primary w-full"
          disabled={busy || report.status === 'resolved'}
        >
          <CheckCircle2 size={16} /> Отметить решённой
        </button>
      </div>
    </Modal>
  );
}
