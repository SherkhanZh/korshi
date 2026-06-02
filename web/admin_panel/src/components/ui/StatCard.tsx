import type { LucideIcon } from 'lucide-react';

interface StatCardProps {
  label: string;
  value: string | number;
  icon: LucideIcon;
  tint?: string;
  hint?: string;
}

export function StatCard({ label, value, icon: Icon, tint = '#1E6B4F', hint }: StatCardProps) {
  return (
    <div className="card p-5">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm text-ink2">{label}</p>
          <p className="mt-2 text-3xl font-bold tracking-tight">{value}</p>
          {hint && <p className="mt-1 text-xs text-ink3">{hint}</p>}
        </div>
        <div
          className="grid h-11 w-11 place-items-center rounded-xl"
          style={{ backgroundColor: `${tint}22`, color: tint }}
        >
          <Icon size={22} />
        </div>
      </div>
    </div>
  );
}
