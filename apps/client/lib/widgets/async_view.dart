import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

  /// Last successfully loaded value. Kept so a refresh keeps showing the current
  /// content while new data loads (stale-while-revalidate) instead of blanking.
  T? _data;

  /// Consecutive failures — drives a short auto-retry so a flaky first request
  /// recovers on its own instead of stranding the user on the error screen.
  int _fails = 0;

  @override
  void initState() {
    super.initState();
    _future = _track(widget.create());
    widget.refresh?.addListener(_retry);
  }

  @override
  void dispose() {
    widget.refresh?.removeListener(_retry);
    super.dispose();
  }

  /// Remembers the resolved value of [f] for stale-while-revalidate, and
  /// auto-retries a few times on failure.
  Future<T> _track(Future<T> f) {
    f.then((v) {
      _fails = 0;
      if (mounted) setState(() => _data = v);
    }).catchError((_) {
      if (mounted && _fails < 3) {
        _fails++;
        Future<void>.delayed(const Duration(milliseconds: 1200), _retry);
      }
    });
    return f;
  }

  void _retry() {
    if (!mounted) return;
    // If a refresh fires while the framework is mid-build/layout (e.g. on
    // app-resume), defer the setState to the next frame to avoid the
    // "setState() called during build" crash.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() { _future = _track(widget.create()); });
      });
    } else {
      setState(() { _future = _track(widget.create()); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          // Keep prior content visible while revalidating.
          if (_data != null) return widget.builder(context, _data as T);
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        if (snap.hasError || !snap.hasData) {
          // Prefer stale data over an error screen when we have something.
          if (_data != null) return widget.builder(context, _data as T);
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
