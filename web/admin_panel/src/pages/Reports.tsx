import { useMemo, useState, useEffect } from 'react';
import {
  MapPin,
  User,
  Clock,
  CheckCircle2,
  MessageSquare,
  ThumbsUp,
  Trash2,
} from 'lucide-react';
import { PageHeader } from '../components/ui/PageHeader';
import { Badge } from '../components/ui/Badge';
import { Modal } from '../components/ui/Modal';
import { categoryMeta, reportStatusMeta } from '../lib/meta';
import type { Category, Report, ReportStatus, ReportStage } from '../types';
import { fetchReports, patchReport, addReportUpdate, reportPhotoUrl, deleteReport } from '../lib/api';
import { useAsync } from '../lib/useAsync';
import { useI18n } from '../lib/i18n';

type TabKey = ReportStatus | 'all';
const TABS: { key: TabKey; label: string; labelKk: string }[] = [
  { key: 'all', label: 'Все', labelKk: 'Барлығы' },
  { key: 'new', label: 'Новые', labelKk: 'Жаңа' },
  { key: 'inProgress', label: 'В работе', labelKk: 'Жұмыста' },
  { key: 'waitingCity', label: 'Ожидает город', labelKk: 'Қаланы күтуде' },
  { key: 'resolved', label: 'Решено', labelKk: 'Шешілді' },
];

const QUICK_UPDATES: { stage: ReportStage; label: string; labelKk: string; status: ReportStatus }[] = [
  { stage: 'inspected', label: 'Осмотрено', labelKk: 'Қаралды', status: 'inProgress' },
  { stage: 'scheduledRepair', label: 'Ремонт запланирован', labelKk: 'Жөндеу жоспарланды', status: 'inProgress' },
  { stage: 'waitingCity', label: 'Ожидает город', labelKk: 'Қаланы күтуде', status: 'waitingCity' },
  { stage: 'contractorAssigned', label: 'Назначен подрядчик', labelKk: 'Мердігер тағайындалды', status: 'inProgress' },
  { stage: 'resolved', label: 'Решено', labelKk: 'Шешілді', status: 'resolved' },
];

export function Reports() {
  const { t: tr } = useI18n();
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
      alert(e instanceof Error ? e.message : tr('Не удалось обновить заявку', 'Өтінішті жаңарту мүмкін болмады'));
    } finally {
      setBusy(false);
    }
  };

  const applyStage = (r: Report, u: (typeof QUICK_UPDATES)[number]) =>
    run(patchReport(r.id, { status: u.status }).then(() => addReportUpdate(r.id, u.label)));

  if (loading) return <div className="p-10 text-center text-ink3">{tr('Загрузка…', 'Жүктелуде…')}</div>;
  if (error) return <div className="p-10 text-center text-[#C0492E]">{error}</div>;

  return (
    <div>
      <PageHeader title={tr('Заявки', 'Өтініштер')} subtitle={tr('Обращения жителей района', 'Аудан тұрғындарының өтініштері')} />

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
            {tr(t.label, t.labelKk)}
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
              <m.icon size={14} /> {tr(m.label, m.labelKk)}
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
                    {tr(m.label, m.labelKk)}
                  </span>
                  <Badge label={tr(st.label, st.labelKk)} bg={st.bg} fg={st.fg} />
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
                {r.status === 'new' ? tr('В работу', 'Жұмысқа') : tr('Обновить', 'Жаңарту')}
              </button>
            </div>
          );
        })}
        {filtered.length === 0 && (
          <div className="card p-10 text-center text-ink3">{tr('Заявок нет', 'Өтініштер жоқ')}</div>
        )}
      </div>

      <ReportDetail
        key={selected?.id ?? 'none'}
        report={selected}
        busy={busy}
        onClose={() => setSelected(null)}
        onCommit={applyStage}
        onReply={(r, text) => run(addReportUpdate(r.id, text))}
        onNote={(r, note) => run(patchReport(r.id, { internalNote: note }))}
        onResolve={(r) =>
          run(patchReport(r.id, { status: 'resolved' }).then(() => addReportUpdate(r.id, 'Заявка решена')))
        }
        onDelete={(r) => {
          if (!confirm(tr('Удалить эту заявку? Действие необратимо.', 'Бұл өтінішті жою керек пе? Әрекет қайтарылмайды.'))) return;
          setBusy(true);
          deleteReport(r.id)
            .then(() => {
              setItems((prev) => {
                const next = prev.filter((x) => x.id !== r.id);
                setData(next);
                return next;
              });
              setSelected(null);
            })
            .catch((e) => alert(e instanceof Error ? e.message : tr('Не удалось удалить', 'Жою мүмкін болмады')))
            .finally(() => setBusy(false));
        }}
        tr={tr}
      />
    </div>
  );
}

function ReportDetail({
  report,
  busy,
  onClose,
  onCommit,
  onReply,
  onNote,
  onResolve,
  onDelete,
  tr,
}: {
  report: Report | null;
  busy: boolean;
  onClose: () => void;
  onCommit: (r: Report, u: (typeof QUICK_UPDATES)[number]) => void;
  onReply: (r: Report, text: string) => void;
  onNote: (r: Report, note: string) => void;
  onResolve: (r: Report) => void;
  onDelete: (r: Report) => void;
  tr: (ru: string, kk: string) => string;
}) {
  const [note, setNote] = useState('');
  const [reply, setReply] = useState('');
  // A quick-status the chairman selected but hasn't confirmed yet. Nothing is
  // persisted until they press "Подтвердить".
  const [staged, setStaged] = useState<(typeof QUICK_UPDATES)[number] | null>(null);
  if (!report) return null;
  const m = categoryMeta[report.category];
  const st = reportStatusMeta[report.status];
  const Icon = m.icon;

  return (
    <Modal open title={tr('Детали заявки', 'Өтініш мәліметтері')} onClose={onClose} width={560}>
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
              {tr(m.label, m.labelKk)}
            </span>
            <Badge label={tr(st.label, st.labelKk)} bg={st.bg} fg={st.fg} />
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

      {report.hasPhoto && (
        <img
          src={reportPhotoUrl(report.id)}
          alt={tr('Фото заявки', 'Өтініш фотосы')}
          className="mt-3 max-h-72 w-full rounded-xl object-cover"
          onError={(e) => { (e.currentTarget as HTMLImageElement).style.display = 'none'; }}
        />
      )}

      {/* Reply to resident — posts a visible update */}
      <div className="mt-4">
        <p className="label">{tr('Сообщение жителю', 'Тұрғынға хабарлама')}</p>
        <textarea
          className="input min-h-[64px] resize-y"
          value={reply}
          onChange={(e) => setReply(e.target.value)}
          placeholder={tr('Напишите ответ — он появится в истории заявки у жителя…', 'Жауап жазыңыз — ол тұрғынның өтініш тарихында көрінеді…')}
        />
        <button
          className="btn-primary mt-2"
          disabled={busy || !reply.trim()}
          onClick={() => {
            onReply(report, reply.trim());
            setReply('');
          }}
        >
          <MessageSquare size={16} /> {tr('Отправить', 'Жіберу')}
        </button>
      </div>

      {/* Quick update — select a status, then confirm below */}
      <div className="mt-4">
        <p className="label">{tr('Выберите новый статус', 'Жаңа статусты таңдаңыз')}</p>
        <div className="flex flex-wrap gap-2">
          {QUICK_UPDATES.map((u) => {
            const active = staged?.stage === u.stage;
            return (
              <button
                key={u.stage}
                disabled={busy}
                onClick={() => setStaged(active ? null : u)}
                className={`rounded-full border px-3 py-1.5 text-xs font-semibold transition disabled:opacity-50 ${
                  active
                    ? 'border-primary bg-greentint text-primary'
                    : 'border-line text-ink2 hover:border-primary hover:text-primary'
                }`}
              >
                {tr(u.label, u.labelKk)}
              </button>
            );
          })}
        </div>
        {staged && (
          <p className="mt-2 text-xs text-ink3">
            {tr('Изменение применится после нажатия «Подтвердить».', '«Растау» батырмасын басқаннан кейін өзгеріс қолданылады.')}
          </p>
        )}
      </div>

      {/* Timeline */}
      <div className="mt-5">
        <p className="mb-2 text-sm font-semibold">{tr('Хронология', 'Хронология')}</p>
        {report.timeline.length === 0 ? (
          <p className="text-sm text-ink3">{tr('Пока нет обновлений.', 'Әзірге жаңартулар жоқ.')}</p>
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
        <p className="label">{tr('Внутренняя заметка (видна только администрации)', 'Ішкі ескертпе (тек әкімшілікке көрінеді)')}</p>
        <textarea
          className="input min-h-[64px] resize-y"
          defaultValue={report.internalNote ?? ''}
          onChange={(e) => setNote(e.target.value)}
          onBlur={() => onNote(report, note || report.internalNote || '')}
          placeholder={tr('Например: ждём доступности подрядчика…', 'Мысалы: мердігердің босауын күтудеміз…')}
        />
      </div>

      {/* Confirm staged status + direct resolve */}
      <div className="mt-4 flex gap-2">
        <button
          onClick={() => {
            if (staged) {
              onCommit(report, staged);
              setStaged(null);
            }
          }}
          className="btn-primary flex-1"
          disabled={busy || !staged}
        >
          <ThumbsUp size={16} /> {tr('Подтвердить', 'Растау')}
        </button>
        <button
          onClick={() => onResolve(report)}
          className="btn-ghost flex-1"
          disabled={busy || report.status === 'resolved'}
        >
          <CheckCircle2 size={16} /> {tr('Отметить решённой', 'Шешілді деп белгілеу')}
        </button>
      </div>

      {/* Delete (e.g. spam) */}
      <button
        onClick={() => onDelete(report)}
        disabled={busy}
        className="mt-3 flex w-full items-center justify-center gap-1.5 text-sm font-semibold text-[#C0492E] hover:underline disabled:opacity-50"
      >
        <Trash2 size={15} /> {tr('Удалить заявку (спам)', 'Өтінішті жою (спам)')}
      </button>
    </Modal>
  );
}
