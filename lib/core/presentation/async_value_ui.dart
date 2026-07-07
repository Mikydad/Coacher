import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Builds from [AsyncValue] without replacing content with loaders on reload.
///
/// Uses Riverpod's [AsyncValue.when] with [skipLoadingOnReload] so cached data
/// stays visible while dependencies refresh (e.g. after cloud sync).
Widget asyncWhenStale<T>(
  AsyncValue<T> value, {
  required Widget Function(T data) data,
  Widget? loading,
  Widget Function(Object error, StackTrace stackTrace)? error,
  bool skipLoadingOnReload = true,
}) {
  return value.when(
    skipLoadingOnReload: skipLoadingOnReload,
    data: data,
    loading: () => loading ?? const SizedBox.shrink(),
    error: error != null
        ? (e, st) => error(e, st)
        : (_, __) => const SizedBox.shrink(),
  );
}

/// Logs an error that a UI error-handler would otherwise swallow silently,
/// then returns the fallback. Silent handlers hid real outages (errors.md
/// #18: a failed query showed only "Could not load…" with no diagnosable
/// cause). Keep the log; keep the calm UI.
T swallowedAsyncError<T>(String where, Object error, T fallback) {
  debugPrint('$where: swallowed error: $error');
  return fallback;
}
