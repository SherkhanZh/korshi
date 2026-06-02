import { useState } from 'react';
import { Plus, Pin, Eye, Zap, CalendarClock, Users, Home, MapPin } from 'lucide-react';
import { PageHeader } from '../components/ui/PageHeader';
import { Modal } from '../components/ui/Modal';
import { announcements as seed } from '../data/mockData';
import { announcementTypeMeta } from '../lib/meta';
import type { Announcement, AnnouncementType, Audience } from '../types';

const TYPES = Object.keys(announcementTypeMeta) as AnnouncementType[];

const AUDIENCES: { key: Audience; label: string; sub: string; icon: typeof Users }[] = [
  { key: 'all', label: 'Весь район', sub: 'Все 98 домов', icon: Users },
  { key: 'street', label: 'Улица', sub: 'Выбрать улицу', icon: Home },
  { key: 'zone', label: 'Зона', sub: 'Выбрать зону', icon: MapPin },
];

export function Announcements() {
  const [items, setItems] = useState<Announcement[]>(seed);
  const [open, setOpen] = useState(false);

  const [type, setType] = useState<AnnouncementType>('maintenance');
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [publishNow, setPublishNow] = useState(true);
  const [audience, setAudience] = useState<Audience>('all');

  const reset = () => {
    setType('maintenance');
    setTitle('');
    setMessage('');
    setPublishNow(true);
    setAudience('all');
  };

  const publish = () => {
    if (!title.trim()) return;
    const audLabel = AUDIENCES.find((a) => a.key === audience)!.label;
    setItems((prev) => [
      {
        id: `a${Date.now()}`,
        type,
        title,
        message,
        publishNow,
        audience,
        audienceLabel: audLabel,
        date: publishNow ? 'только что' : 'запланировано',
        seenBy: 0,
        pinned: false,
      },
      ...prev,
    ]);
    reset();
    setOpen(false);
  };

  const togglePin = (id: string) =>
    setItems((prev) => prev.map((a) => (a.id === id ? { ...a, pinned: !a.pinned } : a)));

  return (
    <div>
      <PageHeader
        title="Объявления"
        subtitle="Информируйте жителей района"
        action={
          <button className="btn-primary" onClick={() => { reset(); setOpen(true); }}>
            <Plus size={16} /> Создать объявление
          </button>
        }
      />

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        {items.map((a) => {
          const t = announcementTypeMeta[a.type];
          return (
            <div key={a.id} className="card p-5">
              <div className="mb-2 flex items-center gap-2">
                <span
                  className="inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-semibold"
                  style={{ backgroundColor: `${t.color}1A`, color: t.color }}
                >
                  <t.icon size={13} /> {t.label}
                </span>
                {a.pinned && (
                  <span className="inline-flex items-center gap-1 text-xs font-semibold text-[#C0492E]">
                    <Pin size={12} /> Закреплено
                  </span>
                )}
                <span className="ml-auto text-xs text-ink3">{a.audienceLabel}</span>
              </div>
              <h3 className="font-bold">{a.title}</h3>
              <p className="mt-0.5 text-xs text-ink3">{a.date}</p>
              <p className="mt-2 line-clamp-3 text-sm text-ink2">{a.message}</p>
              <div className="mt-4 flex items-center justify-between border-t border-line/60 pt-3">
                <span className="flex items-center gap-1.5 text-xs text-ink3">
                  <Eye size={14} /> {a.seenBy} просмотров
                </span>
                <button
                  onClick={() => togglePin(a.id)}
                  className="text-xs font-semibold text-primary hover:underline"
                >
                  {a.pinned ? 'Открепить' : 'Закрепить'}
                </button>
              </div>
            </div>
          );
        })}
      </div>

      <Modal open={open} title="Создать объявление" onClose={() => setOpen(false)} width={560}>
        <div className="space-y-5">
          {/* Type */}
          <div>
            <p className="label">1. Тип объявления</p>
            <div className="grid grid-cols-3 gap-2">
              {TYPES.map((tp) => {
                const m = announcementTypeMeta[tp];
                const active = type === tp;
                return (
                  <button
                    key={tp}
                    onClick={() => setType(tp)}
                    className="flex flex-col items-center gap-1.5 rounded-xl border p-3 text-xs font-medium transition"
                    style={{
                      borderColor: active ? m.color : '#E6E5DF',
                      backgroundColor: active ? `${m.color}12` : '#fff',
                      color: active ? m.color : '#1C1C1E',
                    }}
                  >
                    <m.icon size={20} style={{ color: m.color }} />
                    {m.label}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Title */}
          <div>
            <p className="label">2. Заголовок</p>
            <input
              className="input"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Например: Отключение воды в субботу"
            />
          </div>

          {/* Message */}
          <div>
            <p className="label">3. Сообщение</p>
            <textarea
              className="input min-h-[110px] resize-y"
              maxLength={500}
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="Текст для жителей…"
            />
            <p className="mt-1 text-right text-xs text-ink3">{message.length}/500</p>
          </div>

          {/* Schedule */}
          <div>
            <p className="label">4. Публикация</p>
            <div className="flex gap-2">
              <button
                onClick={() => setPublishNow(true)}
                className={`flex flex-1 items-center justify-center gap-2 rounded-xl border px-3 py-2.5 text-sm font-medium ${
                  publishNow ? 'border-primary bg-greentint text-primary' : 'border-line'
                }`}
              >
                <Zap size={16} /> Опубликовать сейчас
              </button>
              <button
                onClick={() => setPublishNow(false)}
                className={`flex flex-1 items-center justify-center gap-2 rounded-xl border px-3 py-2.5 text-sm font-medium ${
                  !publishNow ? 'border-primary bg-greentint text-primary' : 'border-line'
                }`}
              >
                <CalendarClock size={16} /> Запланировать
              </button>
            </div>
          </div>

          {/* Audience */}
          <div>
            <p className="label">5. Аудитория</p>
            <div className="grid grid-cols-3 gap-2">
              {AUDIENCES.map((a) => {
                const active = audience === a.key;
                return (
                  <button
                    key={a.key}
                    onClick={() => setAudience(a.key)}
                    className={`rounded-xl border p-3 text-left transition ${
                      active ? 'border-primary bg-greentint' : 'border-line'
                    }`}
                  >
                    <a.icon size={16} className={active ? 'text-primary' : 'text-ink2'} />
                    <p className="mt-1 text-sm font-medium">{a.label}</p>
                    <p className="text-xs text-ink3">{a.sub}</p>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Live preview */}
          <div>
            <p className="label">Предпросмотр</p>
            <div className="card p-3">
              <span
                className="inline-flex items-center gap-1.5 text-xs font-semibold"
                style={{ color: announcementTypeMeta[type].color }}
              >
                {(() => {
                  const I = announcementTypeMeta[type].icon;
                  return <I size={13} />;
                })()}
                {announcementTypeMeta[type].label}
              </span>
              <h4 className="mt-1 font-bold">{title || 'Заголовок объявления'}</h4>
              <p className="mt-0.5 line-clamp-2 text-sm text-ink2">
                {message || 'Текст объявления появится здесь…'}
              </p>
            </div>
          </div>

          <div className="flex justify-end gap-2">
            <button className="btn-ghost" onClick={() => setOpen(false)}>Отмена</button>
            <button className="btn-primary" onClick={publish}>Опубликовать</button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
