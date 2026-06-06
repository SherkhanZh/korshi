import { Navigate, Route, Routes } from 'react-router-dom';
import { AuthProvider, useAuth } from './auth';
import { I18nProvider } from './lib/i18n';
import { Layout } from './components/Layout';
import { Login } from './pages/Login';
import { Dashboard } from './pages/Dashboard';
import { Reports } from './pages/Reports';
import { Announcements } from './pages/Announcements';
import { Polls } from './pages/Polls';
import { Residents } from './pages/Residents';
import { Contacts } from './pages/Contacts';
import { Neighborhoods } from './pages/Neighborhoods';
import type { ReactNode } from 'react';

function RequireAuth({ children }: { children: ReactNode }) {
  const { authed } = useAuth();
  return authed ? <>{children}</> : <Navigate to="/login" replace />;
}

function Router() {
  const { role } = useAuth();
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route
        element={
          <RequireAuth>
            <Layout />
          </RequireAuth>
        }
      >
        {role === 'super' ? (
          <Route path="/" element={<Neighborhoods />} />
        ) : (
          <>
            <Route path="/" element={<Dashboard />} />
            <Route path="/reports" element={<Reports />} />
            <Route path="/announcements" element={<Announcements />} />
            <Route path="/polls" element={<Polls />} />
            <Route path="/residents" element={<Residents />} />
            <Route path="/contacts" element={<Contacts />} />
          </>
        )}
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

export default function App() {
  return (
    <I18nProvider>
      <AuthProvider>
        <Router />
      </AuthProvider>
    </I18nProvider>
  );
}
