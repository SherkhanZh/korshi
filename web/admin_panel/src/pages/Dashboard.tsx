import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  FileText,
  Wrench,
  Megaphone,
  BarChart3,
  CheckCircle2,
  MessageSquare,
  Users,
  Image as ImageIcon,
} from 'lucide-react';
import { useAuth } from '../auth';
import { categoryMeta } from '../lib/meta';
import { CoverUploadModal } from '../components/CoverUploadModal';
import { fetchStats, fetchReports } from '../lib/api';
import { useAsync } from '../lib/useAsync';
import { useI18n } from '../lib/i18n';

export function Dashboard() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { t } = useI18n();
  const [coverOpen, setCoverOpen] = useState(false);
  const name = (user?.split('@')[0] ?? 'Админ').replace(/^./, (c) => c.toUpperCase());

  const { data, loading } = useAsync(async () => {
    const [stats, reports] = await Promise.all([fetchStats(), fetchReports()]);
    return { stats, reports };
  }, []);
  const stats = data?.stats;
  const reports = data?.reports ?? [];
  const newReports = reports.filter((r) => r.status === 'new');

  const chips = [
    { label: t('Новые заявки', 'Жаңа өтініштер'), value: stats?.reportsNew ?? 0, icon: FileText, tint: '#C9881C' },
    { label: t('В работе', 'Жұмыста'), value: stats?.reportsInProgress ?? 0, icon: Wrench, tint: '#1E6B4F' },
    { label: t('Объявления', 'Хабарландырулар'), value: stats?.announcements ?? 0, icon: Megaphone, tint: '#3B9BE0' },
    { label: t('Активные опросы', 'Белсенді сауалнамалар'), value: stats?.activePolls ?? 0, icon: BarChart3, tint: '#6C63C7' },
  ];

  const quickActions = [
    { label: t('Новое объявление', 'Жаңа хабарландыру'), icon: Megaphone, onClick: () => navigate('/announcements') },
    { label: t('Создать опрос', 'Сауалнама құру'), icon: BarChart3, onClick: () => navigate('/polls') },
    { label: t('Жители', 'Тұрғындар'), icon: Users, onClick: () => navigate('/residents') },
    { label: t('Обновить обложку', 'Мұқабаны жаңарту'), icon: ImageIcon, onClick: () => setCoverOpen(true) },
  ];

  const summary = [
    { value: stats?.residents ?? 0, label: t('Жителей в районе', 'Аудан тұрғындары'), icon: Users },
    { value: stats?.reportsResolved ?? 0, label: t('Заявок решено', 'Шешілген өтініштер'), icon: CheckCircle2 },
    { value: stats?.reportsTotal ?? 0, label: t('Всего заявок', 'Барлық өтініштер'), icon: FileText },
  ];

  if (loading) return <div className="p-10 text-center text-ink3">{t('Загрузка…', 'Жүктелуде…')}</div>;

  return (
    <div>
      <div className="mb-6 flex items-end justify-between gap-4">
        <div>
          <p className="text-ink2">{t('Добро пожаловать,', 'Қош келдіңіз,')}</p>
          <h1 className="font-serif text-3xl font-semibold">{name}</h1>
        </div>
        <button className="btn-primary" onClick={() => setCoverOpen(true)}>
          <ImageIcon size={16} /> {t('Обновить обложку района', 'Аудан мұқабасын жаңарту')}
        </button>
      </div>

      {/* Stat chips */}
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        {chips.map((s) => (
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

      {/* New reports */}
      <div className="mb-3 mt-8 flex items-center justify-between">
        <h2 className="text-lg font-bold">{t('Новые заявки', 'Жаңа өтініштер')}</h2>
        <button className="text-sm font-semibold text-primary" onClick={() => navigate('/reports')}>
          {t('Смотреть все', 'Барлығын көру')}
        </button>
      </div>
      <div className="space-y-3">
        {newReports.slice(0, 3).map((r) => {
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
              <button className="btn-ghost !py-2 text-xs" onClick={() => navigate('/reports')}>
                <MessageSquare size={14} /> {t('Открыть', 'Ашу')}
              </button>
            </div>
          );
        })}
        {newReports.length === 0 && (
          <div className="card p-8 text-center text-ink3">{t('Новых заявок нет', 'Жаңа өтініштер жоқ')}</div>
        )}
      </div>

      {/* Quick actions */}
      <h2 className="mb-3 mt-8 text-lg font-bold">{t('Быстрые действия', 'Жылдам әрекеттер')}</h2>
      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        {quickActions.map((a) => (
          <button
            key={a.label}
            onClick={a.onClick}
            className="flex items-center gap-3 rounded-xl border border-line bg-surface p-4 text-left text-sm font-medium transition hover:bg-muted"
          >
            <a.icon size={18} className="text-primary" />
            {a.label}
          </button>
        ))}
      </div>

      {/* Summary (real numbers) */}
      <h2 className="mb-3 mt-8 text-lg font-bold">{t('Сводка района', 'Аудан қорытындысы')}</h2>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        {summary.map((i) => (
          <div key={i.label} className="card p-5">
            <div className="flex items-center gap-2 text-ink3">
              <i.icon size={16} />
              <span className="text-xs">{i.label}</span>
            </div>
            <p className="mt-2 text-3xl font-bold">{i.value}</p>
          </div>
        ))}
      </div>

      {coverOpen && <CoverUploadModal onClose={() => setCoverOpen(false)} />}
    </div>
  );
}
