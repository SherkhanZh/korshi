import { createContext, useContext, useState, type ReactNode } from 'react';
import { adminLogin, getToken, setToken } from './lib/api';

interface AuthState {
  authed: boolean;
  user: string | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthState | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  // Restore session only if a token is present.
  const [user, setUser] = useState<string | null>(() =>
    getToken() ? localStorage.getItem('korshi_admin_user') : null,
  );

  const login = async (email: string, password: string) => {
    const r = await adminLogin(email, password);
    localStorage.setItem('korshi_admin_user', r.email);
    setUser(r.email);
  };
  const logout = () => {
    setToken(null);
    localStorage.removeItem('korshi_admin_user');
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ authed: !!user, user, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
