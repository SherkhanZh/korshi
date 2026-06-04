import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  FileText,
  Wrench,
  Megaphone,
  BarChart3,
  AlertTriangle,
  CheckCircle2,
  MessageSquare,
  Users,
  Image as ImageIcon,
  TrendingUp,
  Eye,
  Calendar,
} from 'lucide-react';
import { useAuth } from '../auth';
import { categoryMeta } from '../lib/meta';
import { CoverUploadModal } from '../components/CoverUploadModal';
import { fetchReports, fetchAnnouncements, fetchPolls } from '../lib/api';
import { useAsync } from '../lib/useAsync';

export function Dashboard() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [coverOpen, setCoverOpen] = useState(false);
  const name = (user?.split('@')[0] ?? 'Админ').replace(/^./, (c) => c.toUpperCase());

  const { data } = useAsync(async () => {
    const [reports, announcements, polls] = await Promise.all([
      fetchReports(),
      fetchAnnouncements(),
      fetchPolls(),
    ]);
    return { reports, announcements, polls };
  }, []);
  const reports = data?.reports ?? [];
  const announcements = data?.announcements ?? [];
  const polls = data?.polls ?? [];

  const newReports = reports.filter((r) => r.status === 'new');
  const inProgress = reports.filter((r) => r.status === 'inProgress').length;
  const activePolls = polls.filter((p) => p.status === 'active').length;
  const urgent = reports.find((r) => r.urgent);

  const stats = [
    { label: 'Новые заявки', value: newReports.length, icon: FileText, tint: '#C9881C' },
    { label: 'В работе', value: inProgress, icon: Wrench, tint: '#1E6B4F' },
    { label: 'Объявления', value: announcements.length, icon: Megaphone, tint: '#3B9BE0' },
    { label: 'Активные опросы', value: activePolls, icon: BarChart3, tint: '#6C63C7' },
  ];

  const quickActions = [
    { label: 'Новое объявление', icon: Megaphone, onClick: () => navigate('/announcements') },
    { label: 'Создать опрос', icon: BarChart3, onClick: () => navigate('/polls') },
    { label: 'Жители', icon: Users, onClick: () => navigate('/residents') },
    { label: 'Обновить обложку', icon: ImageIcon, onClick: () => setCoverOpen(true) },
  ];

  const insights = [
    { value: '78%', label: 'Активных жителей', delta: '+6% за неделю', icon: Users },
    { value: '64', label: 'Видели объявление', delta: '+12% за неделю', icon: Eye },
    { value: '12', label: 'Решено за неделю', delta: '+20% за неделю', icon: CheckCircle2 },
  ];

  return (
    <div>
      <div className="mb-6 flex items-end justify-between gap-4">
        <div>
          <p className="text-ink2">Доброе утро,</p>
          <h1 className="font-serif text-3xl font-semibold">{name}</h1>
        </div>
        <button className="btn-primary" onClick={() => setCoverOpen(true)}>
          <ImageIcon size={16} /> Обновить обложку района
        </button>
      </div>

      {/* Stat chips */}
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        {stats.map((s) => (
          <div key={s.label} className="card flex items-center gap-3 p-4">
            <div
              className="grid h-11 w-11 place-items-center rounded-xl"
              style={{ backgroundColor: `${s.tint}22`, color: s.tint }}
            >
              <s.icon size={20} />
            </div>
            <div>
              <p className="text-2xl font-bold leading-none">{s.value}</p>
              <p className="mt-1 text-xs text-ink2">{s.label}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Requires attention */}
      {urgent && (
        <>
          <h2 className="mb-3 mt-8 text-lg font-bold">Требует внимания</h2>
          <div className="rounded-2xl border border-[#F3DDD3] bg-[#FBEFE9] p-5">
            <div className="flex items-start gap-4">
              <div className="grid h-14 w-14 shrink-0 place-items-center rounded-xl bg-[#FBE6E1] text-[#C0492E]">
                <AlertTriangle size={24} />
              </div>
              <div className="min-w-0 flex-1">
                <span className="inline-flex items-center gap-1 rounded-full bg-[#C0492E] px-2 py-0.5 text-xs font-bold text-white">
                  СРОЧНО
                </span>
                <h3 className="mt-1.5 text-xl font-bold">{urgent.title}</h3>
                <p className="text-sm text-ink2">
                  {urgent.location} · {urgent.resident} · {urgent.ago}
                </p>
              </div>
              <div className="flex shrink-0 gap-2">
                <button className="btn-ghost" onClick={() => navigate('/reports')}>
                  Открыть
                </button>
                <button
                  className="btn-primary !bg-[#C0492E] hover:!bg-[#a83e26]"
                  onClick={() => navigate('/reports')}
                >
                  Ответить
                </button>
              </div>
            </div>
          </div>
        </>
      )}

      {/* New reports */}
      <div className="mb-3 mt-8 flex items-center justify-between">
        <h2 className="text-lg font-bold">Новые заявки</h2>
        <button className="text-sm font-semibold text-primary" onClick={() => navigate('/reports')}>
          Смотреть все
        </button>
      </div>
      <div className="space-y-3">
        {newReports.slice(0, 2).map((r) => {
          const cat = categoryMeta[r.category];
          const Icon = cat.icon;
          return (
            <div key={r.id} className="card flex items-center gap-4 p-4">
              <div
                className="grid h-12 w-12 place-items-center rounded-xl"
                style={{ backgroundColor: `${cat.color}22`, color: cat.color }}
              >
                <Icon size={20} />
              </div>
              <div className="min-w-0 flex-1">
                <p className="font-semibold">{r.title}</p>
                <p className="text-xs text-ink3">
                  {r.location} · {r.resident} · {r.ago}
                </p>
              </div>
              <div className="flex shrink-0 gap-2">
                <button className="btn-ghost !py-2 text-xs" onClick={() => navigate('/reports')}>
                  <CheckCircle2 size={14} /> В работу
                </button>
                <button className="btn-ghost !py-2 text-xs" onClick={() => navigate('/reports')}>
                  <MessageSquare size={14} /> Ответить
                </button>
              </div>
            </div>
          );
        })}
      </div>

      <div className="mt-8 grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Today */}
        <div className="card p-5">
          <h3 className="mb-3 font-semibold">Сегодня</h3>
          <div className="space-y-3 text-sm">
            {[
              { icon: Calendar, color: '#1E6B4F', t: 'Ремонт дороги на ул. Абая', s: 'Сегодня, 14:00' },
              { icon: BarChart3, color: '#6C63C7', t: 'Опрос «Детская площадка»', s: 'Завершается завтра' },
              { icon: Wrench, color: '#3B9BE0', t: 'Обслуживание воды', s: 'Завтра, 10:00' },
            ].map((it) => (
              <div key={it.t} className="flex items-center gap-3">
                <div
                  className="grid h-9 w-9 place-items-center rounded-lg"
                  style={{ backgroundColor: `${it.color}22`, color: it.color }}
                >
                  <it.icon size={16} />
                </div>
                <div>
                  <p className="font-medium">{it.t}</p>
                  <p className="text-xs text-ink3">{it.s}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Quick actions */}
        <div className="card p-5">
          <h3 className="mb-3 font-semibold">Быстрые действия</h3>
          <div className="grid grid-cols-2 gap-3">
            {quickActions.map((a) => (
              <button
                key={a.label}
                onClick={a.onClick}
                className="flex items-center gap-3 rounded-xl border border-line bg-surface p-3 text-left text-sm font-medium transition hover:bg-muted"
              >
                <a.icon size={18} className="text-primary" />
                {a.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Insights */}
      <h2 className="mb-3 mt-8 text-lg font-bold">Аналитика района</h2>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        {insights.map((i) => (
          <div key={i.label} className="card p-5">
            <div className="flex items-center gap-2 text-ink3">
              <i.icon size={16} />
              <span className="text-xs">{i.label}</span>
            </div>
            <p className="mt-2 text-3xl font-bold">{i.value}</p>
            <p className="mt-1 flex items-center gap-1 text-xs font-medium text-primary">
              <TrendingUp size={13} /> {i.delta}
            </p>
          </div>
        ))}
      </div>

      {coverOpen && <CoverUploadModal onClose={() => setCoverOpen(false)} />}
    </div>
  );
}
