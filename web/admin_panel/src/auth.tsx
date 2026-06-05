import { createContext, useContext, useState, type ReactNode } from 'react';
import { adminLogin, getToken, setToken, type AdminRole } from './lib/api';

interface AuthState {
  authed: boolean;
  user: string | null;
  role: AdminRole | null;
  neighborhood: string | null;
  login: (email: string, password: string) => Promise<AdminRole>;
  logout: () => void;
}

const AuthContext = createContext<AuthState | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const restored = !!getToken();
  const [user, setUser] = useState<string | null>(() =>
    restored ? localStorage.getItem('korshi_admin_user') : null,
  );
  const [role, setRole] = useState<AdminRole | null>(() =>
    restored ? (localStorage.getItem('korshi_admin_role') as AdminRole | null) : null,
  );
  const [neighborhood, setNeighborhood] = useState<string | null>(() =>
    restored ? localStorage.getItem('korshi_admin_nbhd') : null,
  );

  const login = async (email: string, password: string) => {
    const r = await adminLogin(email, password);
    localStorage.setItem('korshi_admin_user', r.email);
    localStorage.setItem('korshi_admin_role', r.role);
    localStorage.setItem('korshi_admin_nbhd', r.neighborhood?.name ?? '');
    setUser(r.email);
    setRole(r.role);
    setNeighborhood(r.neighborhood?.name ?? null);
    return r.role;
  };
  const logout = () => {
    setToken(null);
    localStorage.removeItem('korshi_admin_user');
    localStorage.removeItem('korshi_admin_role');
    localStorage.removeItem('korshi_admin_nbhd');
    setUser(null);
    setRole(null);
    setNeighborhood(null);
  };

  return (
    <AuthContext.Provider value={{ authed: !!user, user, role, neighborhood, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
