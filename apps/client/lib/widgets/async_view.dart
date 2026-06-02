import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Wraps a Future with loading / error (retry) / data states.
/// Use a key bumped on retry, or pass a `futureBuilder` to re-create the future.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({
    super.key,
    required this.create,
    required this.builder,
    this.padding = const EdgeInsets.all(24),
    this.refresh,
  });

  final Future<T> Function() create;
  final Widget Function(BuildContext context, T data) builder;
  final EdgeInsetsGeometry padding;

  /// When this fires, the data is re-fetched (e.g. after a new report).
  final Listenable? refresh;

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.create();
    widget.refresh?.addListener(_retry);
  }

  @override
  void dispose() {
    widget.refresh?.removeListener(_retry);
    super.dispose();
  }

  void _retry() {
    if (mounted) setState(() => _future = widget.create());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        if (snap.hasError || !snap.hasData) {
          return Center(
            child: Padding(
              padding: widget.padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      size: 40, color: AppColors.textTertiary),
                  const SizedBox(height: 12),
                  const Text('Не удалось загрузить данные',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('Проверьте подключение к интернету',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _retry,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          );
        }
        return widget.builder(context, snap.data as T);
      },
    );
  }
}
