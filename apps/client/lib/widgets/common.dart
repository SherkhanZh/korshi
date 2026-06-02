import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/launchers.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A white rounded card with soft shadow — the base surface across the app.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.surface,
    this.radius = 18,
    this.onTap,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final VoidCallback? onTap;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// Small pill badge used for statuses (Resolved, Upcoming, Event...).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final AppStatus status;

  @override
  Widget build(BuildContext context) {
    return Pill(
      text: context.l10n.t(status.labelKey),
      bg: status.bg,
      fg: status.fg,
    );
  }
}

/// Generic colored pill.
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.text,
    required this.bg,
    required this.fg,
    this.fontSize = 12.5,
    this.fontWeight = FontWeight.w600,
  });

  final String text;
  final Color bg;
  final Color fg;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: fontSize, fontWeight: fontWeight),
      ),
    );
  }
}

/// Rounded square icon tile (the colored glyph chips on list rows).
class IconChip extends StatelessWidget {
  const IconChip({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.iconSize = 22,
    this.bgOpacity = 0.14,
    this.radius = 12,
    this.filled = false,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final double bgOpacity;
  final double radius;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(bgOpacity),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: filled ? Colors.white : color, size: iconSize),
    );
  }
}

/// "Section title  ........  See all" header row.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.style,
  });

  final String title;
  final VoidCallback? onSeeAll;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(title, style: style ?? AppTheme.sectionTitle)),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(context.l10n.seeAll, style: AppTheme.seeAll),
          ),
      ],
    );
  }
}

/// Small uppercase section label (e.g. "IMPORTANT CONTACTS").
class MiniSectionLabel extends StatelessWidget {
  const MiniSectionLabel({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
        ],
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

/// Call + WhatsApp circular action buttons used on contact cards.
class CallWhatsAppRow extends StatelessWidget {
  const CallWhatsAppRow({
    super.key,
    this.compact = false,
    this.labelled = false,
    this.phone = '',
  });

  final bool compact;
  final bool labelled;
  final String phone;

  void _call(BuildContext context) {
    if (phone.isNotEmpty) callNumber(context, phone);
  }

  void _whatsapp(BuildContext context) {
    if (phone.isNotEmpty) openWhatsApp(context, phone);
  }

  @override
  Widget build(BuildContext context) {
    if (labelled) {
      return Row(
        children: [
          Expanded(
            child: _labelledBtn(
                Icons.call_rounded, context.l10n.call, () => _call(context)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _labelledBtn(
                Icons.chat_rounded, context.l10n.whatsApp, () => _whatsapp(context)),
          ),
        ],
      );
    }
    final s = compact ? 36.0 : 42.0;
    return Row(
      children: [
        _circleBtn(Icons.call_rounded, s, () => _call(context)),
        const SizedBox(width: 10),
        _circleBtn(Icons.chat_rounded, s, () => _whatsapp(context)),
      ],
    );
  }

  Widget _circleBtn(IconData icon, double size, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.surfaceGreenTint,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: size * 0.45, color: AppColors.primary),
      ),
    );
  }

  Widget _labelledBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surfaceGreenTint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Standard page header: leaf glyph + serif title + subtitle, optional action.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailingIcon,
    this.onTrailing,
  });

  final String title;
  final String? subtitle;
  final IconData? trailingIcon;
  final VoidCallback? onTrailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.eco, color: AppColors.primaryLight, size: 22),
                    const SizedBox(width: 8),
                    Flexible(child: Text(title, style: AppTheme.displayTitle)),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(subtitle!, style: AppTheme.subtle),
                ],
              ],
            ),
          ),
          if (trailingIcon != null)
            GestureDetector(
              onTap: onTrailing,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 10,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: Icon(trailingIcon, color: AppColors.textPrimary, size: 22),
              ),
            ),
        ],
      ),
    );
  }
}

/// Horizontal segmented filter chips (All / Important / ...).
class FilterChips extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final active = i == selected;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  color: active ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Star rating + review count line used on partner cards.
class RatingLine extends StatelessWidget {
  const RatingLine({super.key, this.rating = '4.9', this.reviews = '128'});

  final String rating;
  final String reviews;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: AppColors.star, size: 18),
        const SizedBox(width: 4),
        Text(
          rating,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(width: 4),
        Text('($reviews отзывов)', style: AppTheme.subtle),
      ],
    );
  }
}
