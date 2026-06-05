import { useEffect, useState } from 'react';
import { Plus, Trash2, Users, Clock, Home, Lock, Globe } from 'lucide-react';
import { PageHeader } from '../components/ui/PageHeader';
import { Badge } from '../components/ui/Badge';
import { Modal } from '../components/ui/Modal';
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

  const [category, setCategory] = useState<PollCategory | null>(null);
  const [question, setQuestion] = useState('');
  const [questionKk, setQuestionKk] = useState('');
  const [optionsRu, setOptionsRu] = useState<string[]>(['Да, поддерживаю', 'Не сейчас']);
  const [optionsKk, setOptionsKk] = useState<string[]>(['Иә, қолдаймын', 'Әзірге жоқ']);
  const [duration, setDuration] = useState(7);
  const [audience, setAudience] = useState<'all' | 'street'>('all');
  const [confidential, setConfidential] = useState(true);

  useEffect(() => {
    if (data) setItems(data);
  }, [data]);

  const reset = () => {
    setCategory(null);
    setQuestion('');
    setQuestionKk('');
    setOptionsRu(['Да, поддерживаю', 'Не сейчас']);
    setOptionsKk(['Иә, қолдаймын', 'Әзірге жоқ']);
    setDuration(7);
    setAudience('all');
    setConfidential(true);
  };

  const setOpt = (i: number, lang: 'ru' | 'kk', v: string) => {
    if (lang === 'ru') setOptionsRu((p) => p.map((x, j) => (j === i ? v : x)));
    else setOptionsKk((p) => p.map((x, j) => (j === i ? v : x)));
  };
  const addOpt = () => {
    setOptionsRu((p) => [...p, '']);
    setOptionsKk((p) => [...p, '']);
  };
  const removeOpt = (i: number) => {
    setOptionsRu((p) => p.filter((_, j) => j !== i));
    setOptionsKk((p) => p.filter((_, j) => j !== i));
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
    const validRu = optionsRu.map((o) => o.trim());
    if (busy || !question.trim() || validRu.filter(Boolean).length < 2) return;
    setBusy(true);
    try {
      await createPoll({
        category: category ?? undefined,
        question,
        questionKk: questionKk.trim() || question,
        options: optionsRu,
        optionsKk: optionsKk.map((o, i) => o.trim() || optionsRu[i] || ''),
        durationDays: duration,
        audienceLabel: audience === 'all' ? 'Весь район' : 'Улица',
        confidential,
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
          const optLabel = (id: number) => p.options.find((o) => o.id === id)?.label ?? '—';
          return (
            <div key={p.id} className="card p-5">
              <div className="mb-2 flex items-center gap-2">
                <Badge label={st.label} bg={st.bg} fg={st.fg} />
                {cm && (
                  <span className="inline-flex items-center gap-1 text-xs font-medium" style={{ color: cm.color }}>
                    <cm.icon size={13} /> {cm.label}
                  </span>
                )}
                <span
                  className="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium"
                  style={
                    p.confidential
                      ? { background: '#F1F0EA', color: '#6E6E73' }
                      : { background: '#E2F0E8', color: '#1E6B4F' }
                  }
                >
                  {p.confidential ? <Lock size={11} /> : <Globe size={11} />}
                  {p.confidential ? 'Конфиденциально' : 'Открытый'}
                </span>
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

              {!p.confidential && p.voters.length > 0 && (
                <div className="mt-3 rounded-xl bg-muted/60 p-3">
                  <p className="mb-1 text-xs font-semibold text-ink2">Как проголосовали:</p>
                  <div className="space-y-0.5 text-xs text-ink3">
                    {p.voters.map((v, i) => (
                      <p key={i}>
                        <span className="font-medium text-ink">{v.name}</span> — {optLabel(v.optionId)}
                      </p>
                    ))}
                  </div>
                </div>
              )}

              <div className="mt-4 flex items-center justify-between border-t border-line/60 pt-3 text-xs text-ink3">
                <span className="flex items-center gap-1.5"><Users size={14} /> {p.households} домохозяйств</span>
                <span className="flex items-center gap-1.5"><Clock size={14} /> до {p.endsAt}</span>
              </div>
            </div>
          );
        })}
        {items.length === 0 && (
          <div className="card p-10 text-center text-ink3 lg:col-span-2">Опросов пока нет</div>
        )}
      </div>

      <Modal open={open} title="Создать опрос" onClose={() => setOpen(false)} width={560}>
        <div className="space-y-5">
          {/* Category (optional, toggleable) */}
          <div>
            <p className="label">Категория (необязательно)</p>
            <div className="grid grid-cols-5 gap-2">
              {CATEGORIES.map((c) => {
                const m = pollCategoryMeta[c];
                const active = category === c;
                return (
                  <button
                    key={c}
                    onClick={() => setCategory(active ? null : c)}
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
            {category && (
              <button onClick={() => setCategory(null)} className="mt-2 text-xs font-medium text-ink3 hover:text-ink">
                Сбросить категорию
              </button>
            )}
          </div>

          {/* Question RU + KK */}
          <div>
            <p className="label">Вопрос</p>
            <textarea
              className="input min-h-[56px] resize-y"
              maxLength={200}
              value={question}
              onChange={(e) => setQuestion(e.target.value)}
              placeholder="Русский — напр.: Установить шлагбаум на въезде?"
            />
            <textarea
              className="input mt-2 min-h-[56px] resize-y"
              maxLength={200}
              value={questionKk}
              onChange={(e) => setQuestionKk(e.target.value)}
              placeholder="Қазақша — напр.: Кіреберіске шлагбаум орнату керек пе?"
            />
          </div>

          {/* Options RU + KK */}
          <div>
            <p className="label">Варианты ответа (рус / қаз)</p>
            <div className="space-y-2">
              {optionsRu.map((o, i) => (
                <div key={i} className="flex items-center gap-2">
                  <div className="flex flex-1 flex-col gap-1.5">
                    <input
                      className="input"
                      value={o}
                      onChange={(e) => setOpt(i, 'ru', e.target.value)}
                      placeholder={`Вариант ${i + 1} (рус)`}
                    />
                    <input
                      className="input"
                      value={optionsKk[i] ?? ''}
                      onChange={(e) => setOpt(i, 'kk', e.target.value)}
                      placeholder={`${i + 1}-нұсқа (қаз)`}
                    />
                  </div>
                  {optionsRu.length > 2 && (
                    <button
                      onClick={() => removeOpt(i)}
                      className="grid h-9 w-9 shrink-0 place-items-center rounded-lg text-ink3 hover:bg-muted"
                    >
                      <Trash2 size={16} />
                    </button>
                  )}
                </div>
              ))}
              <button
                onClick={addOpt}
                className="flex w-full items-center justify-center gap-2 rounded-xl border border-dashed border-line py-2.5 text-sm font-medium text-ink2 hover:border-primary hover:text-primary"
              >
                <Plus size={16} /> Добавить вариант
              </button>
            </div>
          </div>

          {/* Visibility */}
          <div>
            <p className="label">Видимость голосов</p>
            <div className="flex gap-2">
              <button
                onClick={() => setConfidential(true)}
                className={`flex flex-1 items-center justify-center gap-2 rounded-xl border py-2.5 text-sm font-medium ${
                  confidential ? 'border-primary bg-greentint text-primary' : 'border-line'
                }`}
              >
                <Lock size={15} /> Конфиденциально
              </button>
              <button
                onClick={() => setConfidential(false)}
                className={`flex flex-1 items-center justify-center gap-2 rounded-xl border py-2.5 text-sm font-medium ${
                  !confidential ? 'border-primary bg-greentint text-primary' : 'border-line'
                }`}
              >
                <Globe size={15} /> Открытый
              </button>
            </div>
            <p className="mt-1 text-xs text-ink3">
              {confidential
                ? 'Никто не видит, кто как проголосовал.'
                : 'Жители и администратор видят, кто за что проголосовал.'}
            </p>
          </div>

          {/* Duration + audience */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="label">Длительность</p>
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
              <p className="label">Аудитория</p>
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

          <div className="flex justify-end gap-2">
            <button className="btn-ghost" onClick={() => setOpen(false)}>Отмена</button>
            <button className="btn-primary" onClick={start} disabled={busy}>
              {busy ? 'Создаём…' : 'Запустить опрос'}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
