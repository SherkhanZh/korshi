import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/models.dart';
import '../services/launchers.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class UpdateDetailScreen extends StatefulWidget {
  const UpdateDetailScreen({
    super.key,
    required this.title,
    required this.date,
    required this.body,
    required this.category,
    required this.status,
  });

  final String title;
  final String date;
  final String body;
  final IssueCategory category;
  final AppStatus status;

  @override
  State<UpdateDetailScreen> createState() => _UpdateDetailScreenState();
}

class _UpdateDetailScreenState extends State<UpdateDetailScreen> {
  bool _helpful = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text('Подробнее', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconChip(
                      icon: widget.category.icon,
                      color: Colors.white,
                      bgOpacity: 0.2,
                      size: 40,
                    ),
                    const Spacer(),
                    StatusBadge(status: widget.status),
                  ],
                ),
                const SizedBox(height: 12),
                Text(widget.title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Text(widget.date,
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Text(widget.body, style: AppTheme.body.copyWith(fontSize: 15, height: 1.5)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _helpful = !_helpful),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: _helpful ? Colors.white : AppColors.primary,
                    backgroundColor: _helpful ? AppColors.primary : Colors.transparent,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  icon: Icon(_helpful ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                      size: 18),
                  label: const Text('Полезно'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => callNumber(context, kChairmanPhone),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  icon: const Icon(Icons.call_rounded, size: 18),
                  label: const Text('Председатель'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
