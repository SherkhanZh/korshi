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
  { label: string; color: string; icon: LucideIcon }
> = {
  water: { label: 'Вода', color: '#3B9BE0', icon: Droplet },
  roads: { label: 'Дороги', color: '#4A4A4F', icon: TrafficCone },
  lights: { label: 'Освещение', color: '#F5B81E', icon: Lightbulb },
  garbage: { label: 'Мусор', color: '#3FA45F', icon: Trash2 },
  safety: { label: 'Безопасность', color: '#6C63C7', icon: ShieldCheck },
  other: { label: 'Другое', color: '#B07A4A', icon: Home },
};

export const reportStatusMeta: Record<
  ReportStatus,
  { label: string; bg: string; fg: string }
> = {
  new: { label: 'Новая', bg: '#E3ECF8', fg: '#3A6FB0' },
  inProgress: { label: 'В работе', bg: '#FBEFD6', fg: '#C9881C' },
  waitingCity: { label: 'Ожидает город', bg: '#ECE7F7', fg: '#6C63C7' },
  resolved: { label: 'Решено', bg: '#E2F0E8', fg: '#1E6B4F' },
};

export const announcementTypeMeta: Record<
  AnnouncementType,
  { label: string; color: string; icon: LucideIcon }
> = {
  maintenance: { label: 'Ремонт', color: '#C9881C', icon: Construction },
  water: { label: 'Вода', color: '#3B9BE0', icon: Droplet },
  electricity: { label: 'Электричество', color: '#F5B81E', icon: Zap },
  community: { label: 'Сообщество', color: '#1E6B4F', icon: Megaphone },
  important: { label: 'Важное', color: '#C0492E', icon: Siren },
  event: { label: 'Событие', color: '#6C63C7', icon: PartyPopper },
};

export const pollCategoryMeta: Record<
  PollCategory,
  { label: string; color: string; icon: LucideIcon }
> = {
  infrastructure: { label: 'Инфраструктура', color: '#1E6B4F', icon: Building2 },
  safety: { label: 'Безопасность', color: '#6C63C7', icon: ShieldCheck },
  budget: { label: 'Бюджет', color: '#F5B81E', icon: Coins },
  community: { label: 'Сообщество', color: '#3FA45F', icon: Users },
  event: { label: 'Событие', color: '#6C63C7', icon: CalendarDays },
};

export const pollStatusMeta: Record<
  PollStatus,
  { label: string; bg: string; fg: string }
> = {
  active: { label: 'Активный', bg: '#E2F0E8', fg: '#1E6B4F' },
  upcoming: { label: 'Скоро', bg: '#FBEFD6', fg: '#C9881C' },
  closed: { label: 'Завершён', bg: '#F1F0EA', fg: '#6E6E73' },
};
