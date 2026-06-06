import { createContext, useContext, useState, type ReactNode } from 'react';

export type Lang = 'ru' | 'kk';

interface I18nState {
  lang: Lang;
  setLang: (l: Lang) => void;
  /** Returns the Kazakh string when the panel is in Kazakh, else Russian. */
  t: (ru: string, kk: string) => string;
}

const Ctx = createContext<I18nState | undefined>(undefined);
const KEY = 'korshi_admin_lang';

export function I18nProvider({ children }: { children: ReactNode }) {
  const [lang, setLangState] = useState<Lang>(
    () => (localStorage.getItem(KEY) as Lang) || 'ru',
  );
  const setLang = (l: Lang) => {
    localStorage.setItem(KEY, l);
    setLangState(l);
  };
  const t = (ru: string, kk: string) => (lang === 'kk' && kk ? kk : ru);
  return <Ctx.Provider value={{ lang, setLang, t }}>{children}</Ctx.Provider>;
}

export function useI18n() {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error('useI18n must be used within I18nProvider');
  return ctx;
}

/** KZ / RU toggle pill for the header. */
export function LangToggle() {
  const { lang, setLang } = useI18n();
  return (
    <div className="inline-flex overflow-hidden rounded-lg border border-line text-xs font-semibold">
      {(['kk', 'ru'] as Lang[]).map((l) => (
        <button
          key={l}
          onClick={() => setLang(l)}
          className={`px-2.5 py-1.5 transition ${
            lang === l ? 'bg-primary text-white' : 'bg-surface text-ink2 hover:bg-muted'
          }`}
        >
          {l === 'ru' ? 'RU' : 'KZ'}
        </button>
      ))}
    </div>
  );
}
