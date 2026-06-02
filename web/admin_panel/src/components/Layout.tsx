import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard,
  ClipboardList,
  Megaphone,
  BarChart3,
  Users,
  LogOut,
  Search,
  Bell,
} from 'lucide-react';
import type { LucideIcon } from 'lucide-react';
import { useAuth } from '../auth';
import { NEIGHBORHOOD } from '../lib/meta';

interface NavItem {
  to: string;
  label: string;
  icon: LucideIcon;
}

const nav: NavItem[] = [
  { to: '/', label: 'Обзор', icon: LayoutDashboard },
  { to: '/reports', label: 'Заявки', icon: ClipboardList },
  { to: '/announcements', label: 'Объявления', icon: Megaphone },
  { to: '/polls', label: 'Опросы', icon: BarChart3 },
  { to: '/residents', label: 'Жители', icon: Users },
];

export function Layout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  return (
    <div className="flex h-full">
      {/* Sidebar */}
      <aside className="flex w-64 shrink-0 flex-col border-r border-line bg-surface">
        <div className="flex items-center gap-2 px-6 py-5">
          <img src="/leaf.svg" className="h-7 w-7" alt="" />
          <div className="leading-tight">
            <p className="font-serif text-xl font-semibold">Korshi</p>
            <p className="text-xs text-ink3">Админ-панель</p>
          </div>
        </div>

        <nav className="flex-1 space-y-1 px-3 py-2">
          {nav.map(({ to, label, icon: Icon }) => (
            <NavLink
              key={to}
              to={to}
              end={to === '/'}
              className={({ isActive }) =>
                `flex items-center gap-3 rounded-xl px-3.5 py-2.5 text-sm font-medium transition ${
                  isActive
                    ? 'bg-primary text-white'
                    : 'text-ink2 hover:bg-muted hover:text-ink'
                }`
              }
            >
              <Icon size={18} />
              {label}
            </NavLink>
          ))}
        </nav>

        <button
          onClick={() => {
            logout();
            navigate('/login');
          }}
          className="m-3 flex items-center gap-3 rounded-xl px-3.5 py-2.5 text-sm font-medium text-[#D64A3A] transition hover:bg-[#FBE6E1]"
        >
          <LogOut size={18} />
          Выйти
        </button>
      </aside>

      {/* Main */}
      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex items-center justify-between border-b border-line bg-surface px-8 py-3.5">
          <div className="flex items-center gap-4">
            <span className="inline-flex items-center gap-2 rounded-full bg-greentint px-3 py-1.5 text-sm font-semibold text-primary">
              <img src="/leaf.svg" className="h-4 w-4" alt="" />
              {NEIGHBORHOOD}
            </span>
            <div className="relative w-72">
              <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink3" />
              <input className="input pl-9" placeholder="Поиск по заявкам, жителям…" />
            </div>
          </div>
          <div className="flex items-center gap-4">
            <button className="grid h-10 w-10 place-items-center rounded-full hover:bg-muted">
              <Bell size={18} className="text-ink2" />
            </button>
            <div className="flex items-center gap-3">
              <div className="grid h-9 w-9 place-items-center rounded-full bg-greentint text-sm font-semibold text-primary">
                {(user ?? 'A')[0].toUpperCase()}
              </div>
              <div className="leading-tight">
                <p className="text-sm font-semibold">Администратор</p>
                <p className="text-xs text-ink3">{user}</p>
              </div>
            </div>
          </div>
        </header>

        <main className="flex-1 overflow-y-auto p-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
