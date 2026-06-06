import { useState } from 'react';
import { Plus, Phone, Pencil, Trash2, Star, Wrench } from 'lucide-react';
import { Modal } from './ui/Modal';
import { categoryMeta } from '../lib/meta';
import { useI18n } from '../lib/i18n';
import type { ContactRow, ContactInput, ContactCategory, ContactBadge, ContactKind } from '../lib/api';

const CATS: ContactCategory[] = ['water', 'roads', 'lights', 'garbage', 'safety', 'other'];

type Mode = 'important' | 'services';

interface Props {
  mode: Mode;
  items: ContactRow[];
  busy?: boolean;
  onCreate: (input: ContactInput) => Promise<void> | void;
  onUpdate: (id: string, input: Partial<ContactInput>) => Promise<void> | void;
  onDelete: (id: string) => Promise<void> | void;
}

const emptyForm = (mode: Mode): ContactInput => ({
  kind: mode === 'services' ? 'service' : 'important',
  name: '', role: '', subtitle: '', category: 'other', badge: null, phone: '',
});

export function ContactsEditor({ mode, items, busy, onCreate, onUpdate, onDelete }: Props) {
  const { t } = useI18n();
  const [open, setOpen] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState<ContactInput>(emptyForm(mode));

  const badgeLabel = (b: ContactBadge) =>
    b === 'chairman' ? t('Председатель', 'Төраға')
      : b === 'police' ? t('Участковый', 'Учаскелік')
      : b === 'emergency' ? t('Экстренный', 'Жедел')
      : '';

  const openCreate = () => { setEditId(null); setForm(emptyForm(mode)); setOpen(true); };
  const openEdit = (c: ContactRow) => {
    setEditId(c.id);
    setForm({ kind: c.kind, name: c.name, role: c.role, subtitle: c.subtitle ?? '', category: c.category, badge: c.badge, phone: c.phone });
    setOpen(true);
  };

  const submit = async () => {
    if (!form.name.trim() || busy) return;
    if (editId) await onUpdate(editId, form);
    else await onCreate(form);
    setOpen(false);
  };

  const card = (c: ContactRow) => {
    const m = categoryMeta[c.category] ?? categoryMeta.other;
    return (
      <div key={c.id} className="card flex items-center gap-3 p-4">
        <div className="grid h-11 w-11 shrink-0 place-items-center rounded-xl"
          style={{ backgroundColor: `${m.color}22`, color: m.color }}>
          <m.icon size={20} />
        </div>
        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-2">
            <p className="truncate font-semibold">{c.name}</p>
            {c.badge && (
              <span className="rounded-full bg-greentint px-2 py-0.5 text-[11px] font-semibold text-primary">
                {badgeLabel(c.badge)}
              </span>
            )}
          </div>
          <p className="truncate text-xs text-ink3">
            {[c.role, c.subtitle].filter(Boolean).join(' · ') || '—'}
          </p>
          {c.phone && (
            <p className="mt-0.5 flex items-center gap-1 text-xs text-ink2">
              <Phone size={12} /> {c.phone}
            </p>
          )}
        </div>
        <button onClick={() => openEdit(c)} title={t('Изменить', 'Өзгерту')}
          className="grid h-8 w-8 place-items-center rounded-lg text-ink3 hover:bg-muted hover:text-ink">
          <Pencil size={15} />
        </button>
        <button onClick={() => onDelete(c.id)} title={t('Удалить', 'Жою')}
          className="grid h-8 w-8 place-items-center rounded-lg text-ink3 hover:bg-[#FBE6E1] hover:text-[#C0492E]">
          <Trash2 size={15} />
        </button>
      </div>
    );
  };

  const services = items.filter((c) => c.kind === 'service');
  const partners = items.filter((c) => c.kind === 'partner');

  return (
    <div>
      <div className="mb-3 flex justify-end">
        <button className="btn-primary" onClick={openCreate}>
          <Plus size={16} /> {t('Добавить контакт', 'Контакт қосу')}
        </button>
      </div>

      {mode === 'important' ? (
        <div className="space-y-3">
          {items.map(card)}
          {items.length === 0 && (
            <div className="card p-8 text-center text-ink3">{t('Контактов пока нет', 'Әзірге контактілер жоқ')}</div>
          )}
        </div>
      ) : (
        <div className="space-y-6">
          <div>
            <p className="mb-2 flex items-center gap-2 text-sm font-semibold text-ink2">
              <Wrench size={15} /> {t('Местные услуги', 'Жергілікті қызметтер')}
            </p>
            <div className="space-y-3">
              {services.map(card)}
              {services.length === 0 && (
                <div className="card p-6 text-center text-ink3">{t('Услуг пока нет', 'Әзірге қызметтер жоқ')}</div>
              )}
            </div>
          </div>
          <div>
            <p className="mb-2 flex items-center gap-2 text-sm font-semibold text-ink2">
              <Star size={15} /> {t('Проверенные партнёры', 'Тексерілген серіктестер')}
            </p>
            <div className="space-y-3">
              {partners.map(card)}
              {partners.length === 0 && (
                <div className="card p-6 text-center text-ink3">{t('Партнёров пока нет', 'Әзірге серіктестер жоқ')}</div>
              )}
            </div>
          </div>
        </div>
      )}

      <Modal open={open} width={480}
        title={editId ? t('Изменить контакт', 'Контактіні өзгерту') : t('Новый контакт', 'Жаңа контакт')}
        onClose={() => setOpen(false)}>
        <div className="space-y-4">
          {mode === 'services' && (
            <div>
              <p className="label">{t('Тип', 'Түрі')}</p>
              <div className="flex gap-2">
                {(['service', 'partner'] as ContactKind[]).map((k) => (
                  <button key={k} onClick={() => setForm((f) => ({ ...f, kind: k }))}
                    className={`flex flex-1 items-center justify-center gap-2 rounded-xl border py-2.5 text-sm font-medium ${
                      form.kind === k ? 'border-primary bg-greentint text-primary' : 'border-line'
                    }`}>
                    {k === 'service' ? <Wrench size={15} /> : <Star size={15} />}
                    {k === 'service' ? t('Услуга', 'Қызмет') : t('Партнёр', 'Серіктес')}
                  </button>
                ))}
              </div>
            </div>
          )}

          <div>
            <label className="label">{t('Название / Имя', 'Атауы / Аты')} *</label>
            <input className="input" value={form.name}
              onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
              placeholder={mode === 'important' ? t('Напр.: Асхат С.', 'Мыс.: Асхат С.') : t('Напр.: GreenClean', 'Мыс.: GreenClean')} />
          </div>

          <div>
            <label className="label">{t('Роль / описание', 'Рөлі / сипаттамасы')}</label>
            <input className="input" value={form.role}
              onChange={(e) => setForm((f) => ({ ...f, role: e.target.value }))}
              placeholder={t('Напр.: Сантехник', 'Мыс.: Сантехник')} />
          </div>

          <div>
            <label className="label">{t('Подпись (под именем)', 'Жазба (аты астында)')}</label>
            <input className="input" value={form.subtitle}
              onChange={(e) => setForm((f) => ({ ...f, subtitle: e.target.value }))}
              placeholder={t('Напр.: Обычно отвечает быстро', 'Мыс.: Әдетте тез жауап береді')} />
          </div>

          {mode === 'important' && (
            <div>
              <p className="label">{t('Метка', 'Белгі')}</p>
              <div className="grid grid-cols-4 gap-2">
                {([null, 'chairman', 'police', 'emergency'] as ContactBadge[]).map((b) => (
                  <button key={String(b)} onClick={() => setForm((f) => ({ ...f, badge: b }))}
                    className={`rounded-xl border px-2 py-2 text-xs font-medium ${
                      form.badge === b ? 'border-primary bg-greentint text-primary' : 'border-line text-ink2'
                    }`}>
                    {b === null ? t('Нет', 'Жоқ') : badgeLabel(b)}
                  </button>
                ))}
              </div>
            </div>
          )}

          <div>
            <p className="label">{t('Категория (цвет иконки)', 'Санат (белгіше түсі)')}</p>
            <div className="grid grid-cols-6 gap-2">
              {CATS.map((c) => {
                const m = categoryMeta[c];
                const active = form.category === c;
                return (
                  <button key={c} onClick={() => setForm((f) => ({ ...f, category: c }))}
                    title={t(m.label, m.labelKk)}
                    className="grid place-items-center rounded-xl border p-2.5"
                    style={{ borderColor: active ? m.color : '#E6E5DF', backgroundColor: active ? `${m.color}14` : '#fff' }}>
                    <m.icon size={18} style={{ color: m.color }} />
                  </button>
                );
              })}
            </div>
          </div>

          <div>
            <label className="label">{t('Телефон', 'Телефон')}</label>
            <input className="input" value={form.phone}
              onChange={(e) => setForm((f) => ({ ...f, phone: e.target.value }))}
              placeholder="+7 701 000 00 00" />
          </div>

          <div className="flex justify-end gap-2">
            <button className="btn-ghost" onClick={() => setOpen(false)}>{t('Отмена', 'Болдырмау')}</button>
            <button className="btn-primary" onClick={submit} disabled={busy || !form.name.trim()}>
              {editId ? t('Сохранить', 'Сақтау') : t('Добавить', 'Қосу')}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
