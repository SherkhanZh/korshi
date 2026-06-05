import { useState } from 'react';
import { Plus, Building2, Users, ClipboardList, Trash2, KeyRound, Copy, Check, Pencil } from 'lucide-react';
import { PageHeader } from '../components/ui/PageHeader';
import { Modal } from '../components/ui/Modal';
import {
  listNeighborhoods,
  createNeighborhood,
  updateNeighborhood,
  deleteNeighborhood,
  type NeighborhoodRow,
} from '../lib/api';
import { useAsync } from '../lib/useAsync';

export function Neighborhoods() {
  const { data, loading, error, reload } = useAsync(listNeighborhoods, []);
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<NeighborhoodRow | null>(null);
  const items: NeighborhoodRow[] = data ?? [];

  const remove = async (n: NeighborhoodRow) => {
    if (!confirm(`Удалить район «${n.name}»? Все его заявки, жители, опросы и админ будут удалены безвозвратно.`)) return;
    try {
      await deleteNeighborhood(n.id);
      reload();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Не удалось удалить район');
    }
  };

  if (loading) return <div className="p-10 text-center text-ink3">Загрузка…</div>;
  if (error) return <div className="p-10 text-center text-[#C0492E]">{error}</div>;

  return (
    <div>
      <PageHeader
        title="Районы"
        subtitle="Создавайте районы и назначайте их администраторов"
        action={
          <button className="btn-primary" onClick={() => setOpen(true)}>
            <Plus size={16} /> Добавить район
          </button>
        }
      />

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        {items.map((n) => (
          <div key={n.id} className="card p-5">
            <div className="flex items-start gap-3">
              <div className="grid h-11 w-11 shrink-0 place-items-center rounded-xl bg-greentint text-primary">
                <Building2 size={20} />
              </div>
              <div className="min-w-0 flex-1">
                <h3 className="font-bold">{n.name}</h3>
                <p className="truncate text-xs text-ink3">{n.adminEmail ?? 'без администратора'}</p>
              </div>
              <button
                onClick={() => setEditing(n)}
                title="Изменить район"
                className="grid h-8 w-8 shrink-0 place-items-center rounded-lg text-ink3 hover:bg-muted hover:text-ink"
              >
                <Pencil size={16} />
              </button>
              <button
                onClick={() => remove(n)}
                title="Удалить район"
                className="grid h-8 w-8 shrink-0 place-items-center rounded-lg text-ink3 hover:bg-[#FBE6E1] hover:text-[#C0492E]"
              >
                <Trash2 size={16} />
              </button>
            </div>
            <div className="mt-4 flex gap-5 border-t border-line/60 pt-3 text-sm text-ink2">
              <span className="flex items-center gap-1.5"><Users size={15} /> {n.residents} жителей</span>
              <span className="flex items-center gap-1.5"><ClipboardList size={15} /> {n.reports} заявок</span>
            </div>
          </div>
        ))}
        {items.length === 0 && (
          <div className="card p-10 text-center text-ink3">Районов пока нет</div>
        )}
      </div>

      {open && <CreateModal onClose={() => setOpen(false)} onCreated={reload} />}
      {editing && (
        <EditModal
          row={editing}
          onClose={() => setEditing(null)}
          onSaved={reload}
        />
      )}
    </div>
  );
}

function EditModal({
  row,
  onClose,
  onSaved,
}: {
  row: NeighborhoodRow;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [name, setName] = useState(row.name);
  const [email, setEmail] = useState(row.adminEmail ?? '');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState('');

  const gen = () => {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789';
    let p = '';
    for (let i = 0; i < 10; i++) p += chars[Math.floor(Math.random() * chars.length)];
    setPassword(p);
  };

  const save = async () => {
    if (busy) return;
    const body: { name?: string; adminEmail?: string; adminPassword?: string } = {};
    if (name.trim() && name.trim() !== row.name) body.name = name.trim();
    if (email.trim() && email.trim() !== row.adminEmail) body.adminEmail = email.trim();
    if (password) {
      if (password.length < 6) {
        setErr('Пароль должен быть от 6 символов');
        return;
      }
      body.adminPassword = password;
    }
    if (Object.keys(body).length === 0) {
      onClose();
      return;
    }
    setBusy(true);
    setErr('');
    try {
      await updateNeighborhood(row.id, body);
      onSaved();
      onClose();
    } catch (e) {
      setErr(e instanceof Error ? e.message : 'Не удалось сохранить');
    } finally {
      setBusy(false);
    }
  };

  return (
    <Modal open title="Изменить район" onClose={onClose} width={480}>
      <div className="space-y-4">
        <div>
          <label className="label">Название района</label>
          <input className="input" value={name} onChange={(e) => setName(e.target.value)} />
        </div>
        <div>
          <label className="label">Email администратора</label>
          <input className="input" type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
        </div>
        <div>
          <label className="label">Новый пароль (необязательно)</label>
          <div className="flex gap-2">
            <input
              className="input"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="оставьте пустым, чтобы не менять"
            />
            <button onClick={gen} className="btn-ghost shrink-0" type="button">
              <KeyRound size={16} /> Сгенерировать
            </button>
          </div>
        </div>
        {err && <p className="rounded-lg bg-[#FBE6E1] px-3 py-2 text-sm text-[#C0492E]">{err}</p>}
        <div className="flex justify-end gap-2">
          <button className="btn-ghost" onClick={onClose}>Отмена</button>
          <button className="btn-primary" onClick={save} disabled={busy}>
            {busy ? 'Сохраняем…' : 'Сохранить'}
          </button>
        </div>
      </div>
    </Modal>
  );
}

function CreateModal({ onClose, onCreated }: { onClose: () => void; onCreated: () => void }) {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState('');
  const [done, setDone] = useState(false);
  const [copied, setCopied] = useState(false);

  const gen = () => {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789';
    let p = '';
    for (let i = 0; i < 10; i++) p += chars[Math.floor(Math.random() * chars.length)];
    setPassword(p);
  };

  const submit = async () => {
    if (busy) return;
    if (!name.trim() || !email.trim() || password.length < 6) {
      setErr('Заполните название, email и пароль (от 6 символов)');
      return;
    }
    setBusy(true);
    setErr('');
    try {
      await createNeighborhood({ name: name.trim(), adminEmail: email.trim(), adminPassword: password });
      onCreated();
      setDone(true);
    } catch (e) {
      setErr(e instanceof Error ? e.message : 'Не удалось создать район');
    } finally {
      setBusy(false);
    }
  };

  return (
    <Modal open title="Новый район" onClose={onClose} width={480}>
      {done ? (
        <div className="space-y-4">
          <div className="flex items-center gap-2 rounded-xl bg-greentint p-3 text-primary">
            <Check size={18} /> <span className="font-semibold">Район «{name}» создан</span>
          </div>
          <p className="text-sm text-ink2">Передайте администратору данные для входа:</p>
          <div className="rounded-xl border border-line p-4 text-sm">
            <p><span className="text-ink3">Район:</span> <b>{name}</b></p>
            <p className="mt-1"><span className="text-ink3">Логин:</span> <b>{email}</b></p>
            <p className="mt-1"><span className="text-ink3">Пароль:</span> <b className="font-mono">{password}</b></p>
          </div>
          <button
            onClick={() => {
              navigator.clipboard?.writeText(`Район: ${name}\nЛогин: ${email}\nПароль: ${password}`);
              setCopied(true);
              setTimeout(() => setCopied(false), 1500);
            }}
            className="btn-ghost w-full"
          >
            <Copy size={16} /> {copied ? 'Скопировано' : 'Скопировать данные'}
          </button>
          <button onClick={onClose} className="btn-primary w-full">Готово</button>
        </div>
      ) : (
        <div className="space-y-4">
          <div>
            <label className="label">Название района *</label>
            <input className="input" value={name} onChange={(e) => setName(e.target.value)} placeholder="мкр Самал" />
          </div>
          <div>
            <label className="label">Email администратора *</label>
            <input className="input" type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="admin@samal.kz" />
          </div>
          <div>
            <label className="label">Пароль администратора *</label>
            <div className="flex gap-2">
              <input className="input" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="не короче 6 символов" />
              <button onClick={gen} className="btn-ghost shrink-0" type="button">
                <KeyRound size={16} /> Сгенерировать
              </button>
            </div>
          </div>
          {err && <p className="rounded-lg bg-[#FBE6E1] px-3 py-2 text-sm text-[#C0492E]">{err}</p>}
          <div className="flex justify-end gap-2">
            <button className="btn-ghost" onClick={onClose}>Отмена</button>
            <button className="btn-primary" onClick={submit} disabled={busy}>
              {busy ? 'Создаём…' : 'Создать район'}
            </button>
          </div>
        </div>
      )}
    </Modal>
  );
}
