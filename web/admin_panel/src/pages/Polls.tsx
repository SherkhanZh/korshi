import { useEffect, useState } from 'react';
import { Plus, Trash2, Users, Clock, Home } from 'lucide-react';
import { PageHeader } from '../components/ui/PageHeader';
import { Badge } from '../components/ui/Badge';
import { Modal } from '../components/ui/Modal';
import { quickPollTemplates } from '../data/mockData';
import { pollStatusMeta, pollCategoryMeta } from '../lib/meta';
import type { Poll, PollCategory } from '../types';
import { fetchPolls, createPoll, deletePoll } from '../lib/api';
import { useAsync } from '../lib/useAsync';

const CATEGORIES = Object.keys(pollCategoryMeta) as PollCategory[];
const DURATIONS = [3, 7, 14];

export function Polls() {
  const { data, loading, error, reload } = useAsync(fetchPolls, []);
  const [items, setItems] = useState<Poll[]>([]);
  const [open, setOpen] = useState(false);
  const [busy, setBusy] = useState(false);

  const [category, setCategory] = useState<PollCategory>('infrastructure');
  const [question, setQuestion] = useState('');
  const [options, setOptions] = useState<string[]>(['Да, поддерживаю', 'Не сейчас']);
  const [duration, setDuration] = useState(7);
  const [audience, setAudience] = useState<'all' | 'street'>('all');

  useEffect(() => {
    if (data) setItems(data);
  }, [data]);

  const reset = () => {
    setCategory('infrastructure');
    setQuestion('');
    setOptions(['Да, поддерживаю', 'Не сейчас']);
    setDuration(7);
    setAudience('all');
  };

  const remove = async (id: string) => {
    if (!confirm('Удалить этот опрос?')) return;
    setItems((prev) => prev.filter((p) => p.id !== id));
    try {
      await deletePoll(id);
    } catch {
      reload();
    }
  };

  const start = async () => {
    if (busy || !question.trim() || options.filter((o) => o.trim()).length < 2) return;
    setBusy(true);
    try {
      await createPoll({
        category,
        question,
        options: options.filter((o) => o.trim()),
        durationDays: duration,
        audienceLabel: audience === 'all' ? 'Весь район' : 'Улица',
      });
      reset();
      setOpen(false);
      reload();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Не удалось создать опрос');
    } finally {
      setBusy(false);
    }
  };

  if (loading) return <div className="p-10 text-center text-ink3">Загрузка…</div>;
  if (error) return <div className="p-10 text-center text-[#C0492E]">{error}</div>;

  return (
    <div>
      <PageHeader
        title="Опросы"
        subtitle="Спросите мнение жителей"
        action={
          <button className="btn-primary" onClick={() => { reset(); setOpen(true); }}>
            <Plus size={16} /> Создать опрос
          </button>
        }
      />

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        {items.map((p) => {
          const st = pollStatusMeta[p.status];
          const total = p.options.reduce((s, o) => s + o.votes, 0);
          const cm = p.category ? pollCategoryMeta[p.category] : null;
          return (
            <div key={p.id} className="card p-5">
              <div className="mb-2 flex items-center gap-2">
                <Badge label={st.label} bg={st.bg} fg={st.fg} />
                {cm && (
                  <span className="inline-flex items-center gap-1 text-xs font-medium" style={{ color: cm.color }}>
                    <cm.icon size={13} /> {cm.label}
                  </span>
                )}
                <button
                  onClick={() => remove(p.id)}
                  title="Удалить опрос"
                  className="ml-auto grid h-8 w-8 place-items-center rounded-lg text-ink3 hover:bg-[#FBE6E1] hover:text-[#C0492E]"
                >
                  <Trash2 size={16} />
                </button>
              </div>
              <h3 className="font-bold">{p.question}</h3>
              <div className="mt-3 space-y-2.5">
                {p.options.map((o) => {
                  const pct = total ? Math.round((o.votes / total) * 100) : 0;
                  return (
                    <div key={o.label}>
                      <div className="mb-1 flex justify-between text-sm">
                        <span className="font-medium">{o.label}</span>
                        <span className="text-ink2">{pct}% · {o.votes}</span>
                      </div>
                      <div className="h-2 overflow-hidden rounded-full bg-line">
                        <div className="h-full rounded-full bg-primary" style={{ width: `${pct}%` }} />
                      </div>
                    </div>
                  );
                })}
              </div>
              <div className="mt-4 flex items-center justify-between border-t border-line/60 pt-3 text-xs text-ink3">
                <span className="flex items-center gap-1.5"><Users size={14} /> {p.households} домохозяйств</span>
                <span className="flex items-center gap-1.5"><Clock size={14} /> до {p.endsAt}</span>
              </div>
            </div>
          );
        })}
      </div>

      <Modal open={open} title="Создать опрос" onClose={() => setOpen(false)} width={560}>
        <div className="space-y-5">
          {/* Category */}
          <div>
            <p className="label">1. Категория (необязательно)</p>
            <div className="grid grid-cols-5 gap-2">
              {CATEGORIES.map((c) => {
                const m = pollCategoryMeta[c];
                const active = category === c;
                return (
                  <button
                    key={c}
                    onClick={() => setCategory(c)}
                    className="flex flex-col items-center gap-1 rounded-xl border p-2.5 text-center text-[11px] font-medium transition"
                    style={{
                      borderColor: active ? m.color : '#E6E5DF',
                      backgroundColor: active ? `${m.color}12` : '#fff',
                      color: active ? m.color : '#1C1C1E',
                    }}
                  >
                    <m.icon size={18} style={{ color: m.color }} />
                    {m.label}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Question */}
          <div>
            <p className="label">2. Ваш вопрос</p>
            <textarea
              className="input min-h-[64px] resize-y"
              maxLength={200}
              value={question}
              onChange={(e) => setQuestion(e.target.value)}
              placeholder="Например: Установить шлагбаум на въезде?"
            />
            <p className="mt-1 text-right text-xs text-ink3">{question.length}/200</p>
          </div>

          {/* Templates */}
          <div>
            <p className="label">3. Шаблоны (нажмите, чтобы использовать)</p>
            <div className="flex flex-wrap gap-2">
              {quickPollTemplates.map((t) => (
                <button
                  key={t.label}
                  onClick={() => setQuestion(t.question)}
                  className="rounded-full bg-muted px-3 py-1.5 text-xs font-medium hover:bg-line"
                >
                  {t.label}
                </button>
              ))}
            </div>
          </div>

          {/* Options */}
          <div>
            <p className="label">4. Варианты ответа</p>
            <div className="space-y-2">
              {options.map((o, i) => (
                <div key={i} className="flex items-center gap-2">
                  <input
                    className="input"
                    value={o}
                    onChange={(e) =>
                      setOptions((prev) => prev.map((x, j) => (j === i ? e.target.value : x)))
                    }
                    placeholder={`Вариант ${i + 1}`}
                  />
                  {options.length > 2 && (
                    <button
                      onClick={() => setOptions((prev) => prev.filter((_, j) => j !== i))}
                      className="grid h-9 w-9 shrink-0 place-items-center rounded-lg text-ink3 hover:bg-muted"
                    >
                      <Trash2 size={16} />
                    </button>
                  )}
                </div>
              ))}
              <button
                onClick={() => setOptions((prev) => [...prev, ''])}
                className="flex w-full items-center justify-center gap-2 rounded-xl border border-dashed border-line py-2.5 text-sm font-medium text-ink2 hover:border-primary hover:text-primary"
              >
                <Plus size={16} /> Добавить вариант
              </button>
            </div>
          </div>

          {/* Duration + audience */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="label">5. Длительность</p>
              <div className="flex gap-2">
                {DURATIONS.map((d) => (
                  <button
                    key={d}
                    onClick={() => setDuration(d)}
                    className={`flex-1 rounded-xl border py-2 text-sm font-medium ${
                      duration === d ? 'border-primary bg-greentint text-primary' : 'border-line'
                    }`}
                  >
                    {d} дн.
                  </button>
                ))}
              </div>
            </div>
            <div>
              <p className="label">6. Аудитория</p>
              <div className="flex gap-2">
                <button
                  onClick={() => setAudience('all')}
                  className={`flex flex-1 items-center justify-center gap-1.5 rounded-xl border py-2 text-sm font-medium ${
                    audience === 'all' ? 'border-primary bg-greentint text-primary' : 'border-line'
                  }`}
                >
                  <Users size={15} /> Весь район
                </button>
                <button
                  onClick={() => setAudience('street')}
                  className={`flex flex-1 items-center justify-center gap-1.5 rounded-xl border py-2 text-sm font-medium ${
                    audience === 'street' ? 'border-primary bg-greentint text-primary' : 'border-line'
                  }`}
                >
                  <Home size={15} /> Улица
                </button>
              </div>
            </div>
          </div>

          {/* Preview */}
          <div>
            <p className="label">Предпросмотр</p>
            <div className="card p-3">
              <h4 className="font-bold">{question || 'Текст вопроса'}</h4>
              <div className="mt-2 space-y-1.5">
                {options.filter((o) => o.trim()).map((o) => (
                  <div key={o} className="flex items-center justify-between text-sm">
                    <span>{o}</span>
                    <span className="text-ink3">0 голосов</span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          <div className="flex justify-end gap-2">
            <button className="btn-ghost" onClick={() => setOpen(false)}>Отмена</button>
            <button className="btn-primary" onClick={start}>Запустить опрос</button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
