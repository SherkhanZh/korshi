import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'api.dart';
import 'theme.dart';

/// Async-loading wrapper with loading / error (retry) / pull-to-refresh.
class Loader<T> extends StatefulWidget {
  const Loader({super.key, required this.load, required this.builder, this.refresh});
  final Future<T> Function() load;
  final Widget Function(BuildContext, T, VoidCallback reload) builder;
  final Listenable? refresh;
  @override
  State<Loader<T>> createState() => _LoaderState<T>();
}

class _LoaderState<T> extends State<Loader<T>> {
  late Future<T> _future;
  int _fails = 0; // consecutive failures → short auto-retry

  @override
  void initState() {
    super.initState();
    _future = _track(widget.load());
    widget.refresh?.addListener(_reload);
  }

  @override
  void dispose() {
    widget.refresh?.removeListener(_reload);
    super.dispose();
  }

  Future<T> _track(Future<T> f) {
    f.then((_) => _fails = 0).catchError((_) {
      if (mounted && _fails < 3) {
        _fails++;
        Future<void>.delayed(const Duration(milliseconds: 1200), _reload);
      }
    });
    return f;
  }

  void _reload() {
    if (!mounted) return;
    // Defer if a refresh fires mid-build (e.g. on app-resume) to avoid the
    // "setState() called during build" crash.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() { _future = _track(widget.load()); });
      });
    } else {
      setState(() { _future = _track(widget.load()); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: C.primary)));
        }
        if (snap.hasError || !snap.hasData) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 40, color: C.ink3),
                const SizedBox(height: 10),
                Text(snap.error is ApiException ? (snap.error as ApiException).message : loc('Ошибка загрузки', 'Жүктеу қатесі'),
                    style: const TextStyle(color: C.ink2)),
                const SizedBox(height: 12),
                OutlinedButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: Text(loc('Повторить', 'Қайталау'))),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: C.primary,
          onRefresh: () async {
            _reload();
            await Future<void>.delayed(const Duration(milliseconds: 400));
          },
          child: widget.builder(context, snap.data as T, _reload),
        );
      },
    );
  }
}

/// Standard page header with title + optional action.
class Header extends StatelessWidget {
  const Header({super.key, required this.title, this.subtitle, this.action});
  final String title;
  final String? subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                if (subtitle != null) Text(subtitle!, style: const TextStyle(color: C.ink2, fontSize: 14)),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
