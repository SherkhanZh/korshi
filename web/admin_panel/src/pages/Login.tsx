import { useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../auth';

export function Login() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState('admin@korshi.kz');
  const [password, setPassword] = useState('');

  const submit = (e: FormEvent) => {
    e.preventDefault();
    // Mock auth — accepts any non-empty credentials.
    if (email.trim() && password.trim()) {
      login(email.trim());
      navigate('/');
    }
  };

  return (
    <div className="flex h-full items-center justify-center bg-cream p-4">
      <div className="card w-full max-w-md p-8">
        <div className="mb-6 flex items-center gap-2">
          <img src="/leaf.svg" className="h-8 w-8" alt="" />
          <div className="leading-tight">
            <p className="font-serif text-2xl font-semibold">Korshi</p>
            <p className="text-xs text-ink3">Админ-панель</p>
          </div>
        </div>

        <h1 className="text-xl font-bold">Вход в систему</h1>
        <p className="mt-1 text-sm text-ink2">
          Управление районами, заявками и жителями.
        </p>

        <form onSubmit={submit} className="mt-6 space-y-4">
          <div>
            <label className="label">Эл. почта</label>
            <input
              className="input"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@korshi.kz"
            />
          </div>
          <div>
            <label className="label">Пароль</label>
            <input
              className="input"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
            />
          </div>
          <button type="submit" className="btn-primary w-full">
            Войти
          </button>
        </form>

        <p className="mt-4 text-center text-xs text-ink3">
          Демо-режим: подойдут любые данные.
        </p>
      </div>
    </div>
  );
}
