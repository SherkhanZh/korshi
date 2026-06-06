import {
  Droplet,
  TrafficCone,
  Lightbulb,
  Trash2,
  ShieldCheck,
  Home,
  Construction,
  Zap,
  Megaphone,
  PartyPopper,
  Siren,
  Building2,
  Coins,
  Users,
  CalendarDays,
  type LucideIcon,
} from 'lucide-react';
import type {
  Category,
  ReportStatus,
  AnnouncementType,
  PollStatus,
  PollCategory,
} from '../types';

/** The single neighborhood this panel manages (multi-neighborhood comes later). */
export const NEIGHBORHOOD = 'мкр Кок-Тобе';

export const categoryMeta: Record<
  Category,
  { label: string; labelKk: string; color: string; icon: LucideIcon }
> = {
  water: { label: 'Вода', labelKk: 'Су', color: '#3B9BE0', icon: Droplet },
  roads: { label: 'Дороги', labelKk: 'Жолдар', color: '#4A4A4F', icon: TrafficCone },
  lights: { label: 'Освещение', labelKk: 'Жарық', color: '#F5B81E', icon: Lightbulb },
  garbage: { label: 'Мусор', labelKk: 'Қоқыс', color: '#3FA45F', icon: Trash2 },
  safety: { label: 'Безопасность', labelKk: 'Қауіпсіздік', color: '#6C63C7', icon: ShieldCheck },
  other: { label: 'Другое', labelKk: 'Басқа', color: '#B07A4A', icon: Home },
};

export const reportStatusMeta: Record<
  ReportStatus,
  { label: string; labelKk: string; bg: string; fg: string }
> = {
  new: { label: 'Новая', labelKk: 'Жаңа', bg: '#E3ECF8', fg: '#3A6FB0' },
  inProgress: { label: 'В работе', labelKk: 'Жұмыста', bg: '#FBEFD6', fg: '#C9881C' },
  waitingCity: { label: 'Ожидает город', labelKk: 'Қаланы күтуде', bg: '#ECE7F7', fg: '#6C63C7' },
  resolved: { label: 'Решено', labelKk: 'Шешілді', bg: '#E2F0E8', fg: '#1E6B4F' },
};

export const announcementTypeMeta: Record<
  AnnouncementType,
  { label: string; labelKk: string; color: string; icon: LucideIcon }
> = {
  maintenance: { label: 'Ремонт', labelKk: 'Жөндеу', color: '#C9881C', icon: Construction },
  water: { label: 'Вода', labelKk: 'Су', color: '#3B9BE0', icon: Droplet },
  electricity: { label: 'Электричество', labelKk: 'Электр', color: '#F5B81E', icon: Zap },
  community: { label: 'Сообщество', labelKk: 'Қауымдастық', color: '#1E6B4F', icon: Megaphone },
  important: { label: 'Важное', labelKk: 'Маңызды', color: '#C0492E', icon: Siren },
  event: { label: 'Событие', labelKk: 'Іс-шара', color: '#6C63C7', icon: PartyPopper },
};

export const pollCategoryMeta: Record<
  PollCategory,
  { label: string; labelKk: string; color: string; icon: LucideIcon }
> = {
  infrastructure: { label: 'Инфраструктура', labelKk: 'Инфрақұрылым', color: '#1E6B4F', icon: Building2 },
  safety: { label: 'Безопасность', labelKk: 'Қауіпсіздік', color: '#6C63C7', icon: ShieldCheck },
  budget: { label: 'Бюджет', labelKk: 'Бюджет', color: '#F5B81E', icon: Coins },
  community: { label: 'Сообщество', labelKk: 'Қауымдастық', color: '#3FA45F', icon: Users },
  event: { label: 'Событие', labelKk: 'Іс-шара', color: '#6C63C7', icon: CalendarDays },
};

export const pollStatusMeta: Record<
  PollStatus,
  { label: string; labelKk: string; bg: string; fg: string }
> = {
  active: { label: 'Активный', labelKk: 'Белсенді', bg: '#E2F0E8', fg: '#1E6B4F' },
  upcoming: { label: 'Скоро', labelKk: 'Жақында', bg: '#FBEFD6', fg: '#C9881C' },
  closed: { label: 'Завершён', labelKk: 'Аяқталды', bg: '#F1F0EA', fg: '#6E6E73' },
};
