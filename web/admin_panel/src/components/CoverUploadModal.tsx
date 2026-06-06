import { useEffect, useMemo, useRef, useState } from 'react';
import { ImageUp, Check } from 'lucide-react';
import { Modal } from './ui/Modal';
import { uploadCover, ApiError } from '../lib/api';

export function CoverUploadModal({ onClose }: { onClose: () => void }) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [file, setFile] = useState<File | null>(null);
  const [previewError, setPreviewError] = useState(false);
  const [existingError, setExistingError] = useState(false);
  const [busy, setBusy] = useState(false);
  const [done, setDone] = useState(false);
  const [error, setError] = useState<string | null>(null);
  // Current cover is per-neighborhood; bust the cache after a successful upload.
  const nid = localStorage.getItem('korshi_admin_nid') ?? '';
  const [coverVersion, setCoverVersion] = useState(0);
  const existingCoverUrl = `/api/neighborhood/cover?nid=${nid}&v=${coverVersion}`;

  // Derive the preview URL synchronously from the selected file, so the <img>
  // has a src on the very same render the file is chosen (no async timing).
  const previewUrl = useMemo(() => (file ? URL.createObjectURL(file) : null), [file]);
  useEffect(() => {
    return () => {
      if (previewUrl) URL.revokeObjectURL(previewUrl);
    };
  }, [previewUrl]);

  // Browsers (Chrome especially) can't render HEIC/HEIF and may not even fire an
  // <img> error event for them, so gate on the file type up front.
  const canPreview =
    !!file && /^image\/(jpe?g|png|webp|gif|avif|bmp|svg\+xml)$/i.test(file.type);
  const showImage = !!previewUrl && canPreview && !previewError;
  const showUnsupported = !!file && (!canPreview || previewError);

  const pick = (f: File | null) => {
    if (!f) return;
    setFile(f);
    setDone(false);
    setError(null);
    setPreviewError(false);
  };

  const save = async () => {
    if (!file) return;
    setBusy(true);
    setError(null);
    try {
      await uploadCover(file);
      setDone(true);
      setFile(null);
      setCoverVersion((v) => v + 1);
    } catch (e) {
      if (e instanceof ApiError && e.status === 413) setError('Файл слишком большой.');
      else setError(e instanceof Error ? e.message : 'Не удалось загрузить.');
    } finally {
      setBusy(false);
    }
  };

  return (
    <Modal open title="Обновить обложку района" onClose={onClose} width={480}>
      <p className="text-sm text-ink2">
        Это изображение увидят жители в шапке приложения.
      </p>

      <div className="mt-4 flex h-48 w-full items-center justify-center overflow-hidden rounded-2xl border border-line bg-muted">
        {showImage ? (
          <img
            key="preview"
            src={previewUrl!}
            alt=""
            className="block h-48 w-full object-cover"
            onError={() => setPreviewError(true)}
          />
        ) : showUnsupported ? (
          <p className="px-6 text-center text-sm text-ink3">
            Браузер не может показать этот формат{file?.type ? ` (${file.type})` : ''} — например
            HEIC с iPhone. Файл всё равно загрузится при сохранении, или выберите JPG / PNG.
          </p>
        ) : !existingError ? (
          <img
            key="existing"
            src={existingCoverUrl}
            alt=""
            className="block h-48 w-full object-cover"
            onError={() => setExistingError(true)}
          />
        ) : (
          <p className="px-6 text-center text-sm text-ink3">Обложка ещё не загружена</p>
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
