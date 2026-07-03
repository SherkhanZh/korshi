import { useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../auth';
import { ApiError } from '../lib/api';
import { useI18n } from '../lib/i18n';

export function Login() {
  const { login } = useAuth();
  const { t } = useI18n();
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (!email.trim() || !password.trim()) return;
    setBusy(true);
    setError('');
    try {
      await login(email.trim(), password);
      navigate('/');
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Ошибка входа');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="flex h-full items-center justify-center bg-cream p-4">
      <div className="card w-full max-w-md p-8">
        <div className="mb-6 flex items-center gap-2">
          <img src="/leaf.svg" className="h-8 w-8" alt="" />
          <div className="leading-tight">
            <p className="font-serif text-2xl font-semibold">Korshi</p>
            <p className="text-xs text-ink3">{t('Админ-панель', 'Әкімші панелі')}</p>
          </div>
        </div>

        <h1 className="text-xl font-bold">{t('Вход в систему', 'Жүйеге кіру')}</h1>
        <p className="mt-1 text-sm text-ink2">
          {t('Управление районом, заявками и жителями.', 'Ауданды, өтініштер мен тұрғындарды басқару.')}
        </p>

        <form onSubmit={submit} className="mt-6 space-y-4">
          <div>
            <label className="label">{t('Эл. почта', 'Эл. пошта')}</label>
            <input
              className="input"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@korshi.kz"
            />
          </div>
          <div>
            <label className="label">{t('Пароль', 'Құпиясөз')}</label>
            <input
              className="input"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
            />
          </div>
          {error && (
            <p className="rounded-lg bg-[#FBE6E1] px-3 py-2 text-sm text-[#C0492E]">{error}</p>
          )}
          <button type="submit" className="btn-primary w-full" disabled={busy}>
            {busy ? t('Вход…', 'Кіру…') : t('Войти', 'Кіру')}
          </button>
        </form>
      </div>
    </div>
  );
}
