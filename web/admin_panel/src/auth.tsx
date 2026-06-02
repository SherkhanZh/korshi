import { createContext, useContext, useState, type ReactNode } from 'react';

interface AuthState {
  authed: boolean;
  user: string | null;
  login: (email: string) => void;
  logout: () => void;
}

const AuthContext = createContext<AuthState | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<string | null>(
    () => localStorage.getItem('korshi_admin_user'),
  );

  const login = (email: string) => {
    localStorage.setItem('korshi_admin_user', email);
    setUser(email);
  };
  const logout = () => {
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
