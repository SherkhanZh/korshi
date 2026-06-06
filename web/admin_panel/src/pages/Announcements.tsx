import { useEffect, useState } from 'react';
import { Plus, Pin, Eye, Zap, CalendarClock, Users, Home, MapPin, Trash2, Pencil } from 'lucide-react';
import { PageHeader } from '../components/ui/PageHeader';
import { Modal } from '../components/ui/Modal';
import { announcementTypeMeta } from '../lib/meta';
import type { Announcement, AnnouncementType, Audience } from '../types';
import {
  fetchAnnouncements,
  createAnnouncement,
  updateAnnouncement,
  pinAnnouncement,
  deleteAnnouncement,
} from '../lib/api';
import { useAsync } from '../lib/useAsync';
import { useI18n } from '../lib/i18n';

const TYPES = Object.keys(announcementTypeMeta) as AnnouncementType[];

const AUDIENCES: { key: Audience; label: string; labelKk: string; sub: string; subKk: string; icon: typeof Users }[] = [
  { key: 'all', label: 'Весь район', labelKk: 'Бүкіл аудан', sub: 'Все 98 домов', subKk: 'Барлық 98 үй', icon: Users },
  { key: 'street', label: 'Улица', labelKk: 'Көше', sub: 'Выбрать улицу', subKk: 'Көшені таңдау', icon: Home },
  { key: 'zone', label: 'Зона', labelKk: 'Аймақ', sub: 'Выбрать зону', subKk: 'Аймақты таңдау', icon: MapPin },
];

export function Announcements() {
  const { t: tr } = useI18n();
  const { data, loading, error, reload } = useAsync(fetchAnnouncements, []);
  const [items, setItems] = useState<Announcement[]>([]);
  const [open, setOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const [type, setType] = useState<AnnouncementType>('maintenance');
  const [title, setTitle] = useState('');
  const [titleKk, setTitleKk] = useState('');
  const [message, setMessage] = useState('');
  const [messageKk, setMessageKk] = useState('');
  const [publishNow, setPublishNow] = useState(true);
  const [audience, setAudience] = useState<Audience>('all');

  useEffect(() => {
    if (data) setItems(data);
  }, [data]);

  const reset = () => {
    setEditingId(null);
    setType('maintenance');
    setTitle('');
    setTitleKk('');
    setMessage('');
    setMessageKk('');
    setPublishNow(true);
    setAudience('all');
  };

  const openCreate = () => {
    reset();
    setOpen(true);
  };

  const openEdit = (a: Announcement) => {
    setEditingId(a.id);
    setType(a.type);
    setTitle(a.title);
    setTitleKk(a.titleKk);
    setMessage(a.message);
    setMessageKk(a.messageKk);
    setAudience(a.audience);
    setPublishNow(true);
    setOpen(true);
  };

  const publish = async () => {
    if (!title.trim() || busy) return;
    const audLabel = AUDIENCES.find((a) => a.key === audience)!.label;
    setBusy(true);
    try {
      if (editingId) {
        await updateAnnouncement(editingId, {
          type, title, titleKk: titleKk.trim() || title, message, messageKk: messageKk.trim() || message,
        });
      } else {
        await createAnnouncement({
          type, title, titleKk: titleKk.trim() || title, message,
          messageKk: messageKk.trim() || message, audience, audienceLabel: audLabel, publishNow,
        });
      }
      reset();
      setOpen(false);
      reload();
    } catch (e) {
      alert(e instanceof Error ? e.message : tr('Не удалось сохранить', 'Сақтау мүмкін болмады'));
    } finally {
      setBusy(false);
    }
  };

  const togglePin = async (a: Announcement) => {
    setItems((prev) => prev.map((x) => (x.id === a.id ? { ...x, pinned: !x.pinned } : x)));
    try {
      await pinAnnouncement(a.id, !a.pinned);
    } catch {
      reload();
    }
  };

  const remove = async (id: string) => {
    if (!confirm(tr('Удалить это объявление?', 'Бұл хабарландыруды жою керек пе?'))) return;
    setItems((prev) => prev.filter((a) => a.id !== id));
    try {
      await deleteAnnouncement(id);
    } catch {
      reload();
    }
  };

  if (loading) return <div className="p-10 text-center text-ink3">{tr('Загрузка…', 'Жүктелуде…')}</div>;
  if (error) return <div className="p-10 text-center text-[#C0492E]">{error}</div>;

  return (
    <div>
      <PageHeader
        title={tr('Объявления', 'Хабарландырулар')}
        subtitle={tr('Информируйте жителей района', 'Аудан тұрғындарын хабардар етіңіз')}
        action={
          <button className="btn-primary" onClick={openCreate}>
            <Plus size={16} /> {tr('Создать объявление', 'Хабарландыру құру')}
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
                  <t.icon size={13} /> {tr(t.label, t.labelKk)}
                </span>
                {a.pinned && (
                  <span className="inline-flex items-center gap-1 text-xs font-semibold text-[#C0492E]">
                    <Pin size={12} /> {tr('Закреплено', 'Бекітілген')}
                  </span>
                )}
                <span className="ml-auto text-xs text-ink3">{a.audienceLabel}</span>
              </div>
              <h3 className="font-bold">{a.title}</h3>
              <p className="mt-0.5 text-xs text-ink3">{a.date}</p>
              <p className="mt-2 line-clamp-3 text-sm text-ink2">{a.message}</p>
              <div className="mt-4 flex items-center justify-between border-t border-line/60 pt-3">
                <span className="flex items-center gap-1.5 text-xs text-ink3">
                  <Eye size={14} /> {a.seenBy} {tr('просмотров', 'қаралым')}
                </span>
                <div className="flex items-center gap-3">
                  <button
                    onClick={() => togglePin(a)}
                    className="text-xs font-semibold text-primary hover:underline"
                  >
                    {a.pinned ? tr('Открепить', 'Босату') : tr('Закрепить', 'Бекіту')}
                  </button>
                  <button
                    onClick={() => openEdit(a)}
                    className="inline-flex items-center gap-1 text-xs font-semibold text-ink2 hover:underline"
                  >
                    <Pencil size={13} /> {tr('Изменить', 'Өзгерту')}
                  </button>
                  <button
                    onClick={() => remove(a.id)}
                    className="inline-flex items-center gap-1 text-xs font-semibold text-[#C0492E] hover:underline"
                  >
                    <Trash2 size={13} /> {tr('Удалить', 'Жою')}
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <Modal open={open} title={editingId ? tr('Изменить объявление', 'Хабарландыруды өзгерту') : tr('Создать объявление', 'Хабарландыру құру')} onClose={() => setOpen(false)} width={560}>
        <div className="space-y-5">
          {/* Type */}
          <div>
            <p className="label">{tr('1. Тип объявления', '1. Хабарландыру түрі')}</p>
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
                    {tr(m.label, m.labelKk)}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Title — KK + RU (Kazakh first) */}
          <div>
            <p className="label">{tr('2. Заголовок', '2. Тақырып')}</p>
            <input
              className="input"
              value={titleKk}
              onChange={(e) => setTitleKk(e.target.value)}
              placeholder="Қазақша — мыс.: Сенбіде су өшіріледі"
            />
            <input
              className="input mt-2"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Русский — напр.: Отключение воды в субботу"
            />
            <p className="mt-1 text-xs text-ink3">{tr('Если поле пустое — покажется текст из другого языка.', 'Өріс бос болса — басқа тілдегі мәтін көрсетіледі.')}</p>
          </div>

          {/* Message — KK + RU (Kazakh first) */}
          <div>
            <p className="label">{tr('3. Сообщение', '3. Хабарлама')}</p>
            <textarea
              className="input min-h-[90px] resize-y"
              maxLength={500}
              value={messageKk}
              onChange={(e) => setMessageKk(e.target.value)}
              placeholder="Тұрғындарға арналған мәтін (қаз)…"
            />
            <textarea
              className="input mt-2 min-h-[90px] resize-y"
              maxLength={500}
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="Текст для жителей (рус)…"
            />
          </div>

          {/* Schedule */}
          {/* Schedule + audience — only when creating a new announcement */}
          {!editingId && (
            <>
              <div>
                <p className="label">{tr('4. Публикация', '4. Жариялау')}</p>
                <div className="flex gap-2">
                  <button
                    onClick={() => setPublishNow(true)}
                    className={`flex flex-1 items-center justify-center gap-2 rounded-xl border px-3 py-2.5 text-sm font-medium ${
                      publishNow ? 'border-primary bg-greentint text-primary' : 'border-line'
                    }`}
                  >
                    <Zap size={16} /> {tr('Опубликовать сейчас', 'Қазір жариялау')}
                  </button>
                  <button
                    onClick={() => setPublishNow(false)}
                    className={`flex flex-1 items-center justify-center gap-2 rounded-xl border px-3 py-2.5 text-sm font-medium ${
                      !publishNow ? 'border-primary bg-greentint text-primary' : 'border-line'
                    }`}
                  >
                    <CalendarClock size={16} /> {tr('Запланировать', 'Жоспарлау')}
                  </button>
                </div>
              </div>

              <div>
                <p className="label">{tr('5. Аудитория', '5. Аудитория')}</p>
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
                        <p className="mt-1 text-sm font-medium">{tr(a.label, a.labelKk)}</p>
                        <p className="text-xs text-ink3">{tr(a.sub, a.subKk)}</p>
                      </button>
                    );
                  })}
                </div>
              </div>
            </>
          )}

          {/* Live preview */}
          <div>
            <p className="label">{tr('Предпросмотр', 'Алдын ала қарау')}</p>
            <div className="card p-3">
              <span
                className="inline-flex items-center gap-1.5 text-xs font-semibold"
                style={{ color: announcementTypeMeta[type].color }}
              >
                {(() => {
                  const I = announcementTypeMeta[type].icon;
                  return <I size={13} />;
                })()}
                {tr(announcementTypeMeta[type].label, announcementTypeMeta[type].labelKk)}
              </span>
              <h4 className="mt-1 font-bold">{title || tr('Заголовок объявления', 'Хабарландыру тақырыбы')}</h4>
              <p className="mt-0.5 line-clamp-2 text-sm text-ink2">
                {message || tr('Текст объявления появится здесь…', 'Хабарландыру мәтіні осында көрінеді…')}
              </p>
            </div>
          </div>

          <div className="flex justify-end gap-2">
            <button className="btn-ghost" onClick={() => setOpen(false)}>{tr('Отмена', 'Болдырмау')}</button>
            <button className="btn-primary" onClick={publish} disabled={busy}>
              {editingId ? tr('Сохранить', 'Сақтау') : tr('Опубликовать', 'Жариялау')}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
