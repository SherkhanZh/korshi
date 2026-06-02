import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, this.initialCategory});

  final IssueCategory? initialCategory;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late IssueCategory _selected = widget.initialCategory ?? IssueCategory.roads;
  final _controller = TextEditingController();
  bool _hasPhoto = false;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await repository.submitReport(
        category: _selected.code,
        description: _controller.text.trim(),
        location: 'ул. Мереке, 12',
      );
      dataVersion.value++; // refresh open lists (Home / Updates / My reports)
      messenger.showSnackBar(
        const SnackBar(content: Text('Заявка отправлена')),
      );
      navigator.maybePop();
    } catch (_) {
      setState(() => _sending = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Не удалось отправить. Попробуйте ещё раз.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  _topBar(context, l),
                  const SizedBox(height: 24),
                  _label(l.selectCategory),
                  const SizedBox(height: 12),
                  _categoryGrid(l),
                  const SizedBox(height: 24),
                  _label(l.addPhotoOptional),
                  const SizedBox(height: 12),
                  _photoRow(l),
                  const SizedBox(height: 24),
                  _label(l.location),
                  const SizedBox(height: 12),
                  _locationCard(l),
                  const SizedBox(height: 24),
                  _label(l.describeIssue),
                  const SizedBox(height: 12),
                  _descriptionField(l),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: FilledButton(
                onPressed: _sending ? null : _send,
                child: _sending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(l.sendReport),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(l.chairmanNotified, style: AppTheme.subtle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, AppLocalizations l) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: Container(
            width: 180,
            height: 110,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8FB6A6), Color(0xFFCBD9C5)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.landscape_rounded,
                color: Colors.white70, size: 36),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: Offset(0, 3)),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
            ),
            const SizedBox(height: 16),
            Text(l.reportAnIssue, style: AppTheme.displayTitle.copyWith(fontSize: 34)),
            const SizedBox(height: 6),
            Text(l.reportSubtitle, style: AppTheme.subtle.copyWith(fontSize: 15)),
          ],
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primary),
      );

  Widget _categoryGrid(AppLocalizations l) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.02,
      children: [
        for (final c in IssueCategory.values) _categoryTile(l, c),
      ],
    );
  }

  Widget _categoryTile(AppLocalizations l, IssueCategory c) {
    final selected = c == _selected;
    return GestureDetector(
      onTap: () => setState(() => _selected = c),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(c.icon, color: c.color, size: 32),
                  const SizedBox(height: 10),
                  Text(
                    l.t(c.labelKey),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.check_rounded, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _photoRow(AppLocalizations l) {
    return SizedBox(
      height: 120,
      child: Row(
        children: [
          if (_hasPhoto)
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.image_rounded,
                        color: AppColors.textTertiary, size: 36),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => setState(() => _hasPhoto = false),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.close_rounded,
                            size: 16, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_hasPhoto) const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _hasPhoto = true),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.border,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceGreenTint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.photo_camera_rounded,
                          color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(l.addPhoto,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(l.cameraOrGallery, style: AppTheme.subtle),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationCard(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const IconChip(
            icon: Icons.location_on_rounded,
            color: AppColors.primary,
            size: 40,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ул. Мереке, 12',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text('Алматы', style: AppTheme.subtle),
              ],
            ),
          ),
          const Icon(Icons.edit_rounded,
              color: AppColors.textSecondary, size: 20),
        ],
      ),
    );
  }

  Widget _descriptionField(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _controller,
            maxLines: 4,
            maxLength: 200,
            buildCounter: (_, {required currentLength, maxLength, required isFocused}) =>
                null,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration.collapsed(hintText: l.describeHint),
          ),
          Text('${_controller.text.length}/200', style: AppTheme.subtle),
        ],
      ),
    );
  }
}
