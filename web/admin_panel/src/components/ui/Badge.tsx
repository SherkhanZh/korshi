interface BadgeProps {
  label: string;
  bg: string;
  fg: string;
}

export function Badge({ label, bg, fg }: BadgeProps) {
  return (
    <span
      className="inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold whitespace-nowrap"
      style={{ backgroundColor: bg, color: fg }}
    >
      {label}
    </span>
  );
}
