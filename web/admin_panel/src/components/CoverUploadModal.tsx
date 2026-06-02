import { useRef, useState } from 'react';
import { ImageUp, Check } from 'lucide-react';
import { Modal } from './ui/Modal';

export function CoverUploadModal({ onClose }: { onClose: () => void }) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [file, setFile] = useState<File | null>(null);
  const [busy, setBusy] = useState(false);
  const [done, setDone] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const pick = (f: File | null) => {
    if (!f) return;
    setFile(f);
    setPreview(URL.createObjectURL(f));
    setDone(false);
    setError(null);
  };

  const save = async () => {
    if (!file) return;
    setBusy(true);
    setError(null);
    try {
      const body = new FormData();
      body.append('image', file);
      const res = await fetch('/api/neighborhood/cover', { method: 'POST', body });
      if (!res.ok) {
        if (res.status === 404) {
          throw new Error('Сервер не обновлён (нет эндпоинта загрузки). Передеплойте бэкенд.');
        }
        if (res.status === 413) {
          throw new Error('Файл слишком большой.');
        }
        throw new Error(`Ошибка сервера (${res.status}).`);
      }
      setDone(true);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Не удалось загрузить.');
    } finally {
      setBusy(false);
    }
  };

  return (
    <Modal open title="Обновить обложку района" onClose={onClose} width={480}>
      <p className="text-sm text-ink2">
        Это изображение увидят жители в шапке приложения.
      </p>

      <div className="mt-4 aspect-[16/9] w-full overflow-hidden rounded-2xl border border-line bg-muted">
        {preview ? (
          <img src={preview} alt="" className="block h-full w-full object-cover" />
        ) : (
          <img
            src="/api/neighborhood/cover"
            alt=""
            className="block h-full w-full object-cover"
            onError={(e) => {
              (e.currentTarget as HTMLImageElement).style.visibility = 'hidden';
            }}
          />
        )}
      </div>

      <input
        ref={inputRef}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={(e) => pick(e.target.files?.[0] ?? null)}
      />

      <button className="btn-ghost mt-4 w-full" onClick={() => inputRef.current?.click()}>
        <ImageUp size={16} /> {file ? 'Выбрать другое фото' : 'Выбрать фото'}
      </button>

      {error && <p className="mt-3 text-sm text-[#C0492E]">{error}</p>}
      {done && (
        <p className="mt-3 flex items-center gap-1.5 text-sm font-medium text-primary">
          <Check size={16} /> Обложка обновлена
        </p>
      )}

      <div className="mt-5 flex justify-end gap-2">
        <button className="btn-ghost" onClick={onClose}>
          {done ? 'Закрыть' : 'Отмена'}
        </button>
        <button className="btn-primary" onClick={save} disabled={!file || busy}>
          {busy ? 'Загрузка…' : 'Сохранить'}
        </button>
      </div>
    </Modal>
  );
}
