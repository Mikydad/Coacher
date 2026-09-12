import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_keys.dart';
import '../domain/progress_period.dart';

/// What the Progress page is looking at: a horizon, the period within it,
/// and (Day / Week / Month) the day whose detail is open. Session-scoped
/// (not autoDispose) so leaving and returning lands on the same view.
class ProgressSelection {
  const ProgressSelection({
    required this.period,
    required this.selectedDateKey,
    required this.anchorDateKey,
  });

  final ProgressPeriod period;

  /// The day the user is "near": the open day when there is one, else the
  /// day the view was anchored on when it was reached (today, or a paged
  /// period's last day). Zooming between horizons keeps it, so Month →
  /// Week → Day lands where the eye already was.
  final String anchorDateKey;

  /// Open day-detail. Always set for the Day horizon; toggled by ring taps
  /// for Week / Month; never set for Quarter / Year (cells are too small).
  final String? selectedDateKey;

  ProgressHorizon get horizon => period.horizon;

  bool get supportsDayDetail => switch (horizon) {
    ProgressHorizon.day ||
    ProgressHorizon.week ||
    ProgressHorizon.month => true,
    ProgressHorizon.quarter || ProgressHorizon.year => false,
  };

  ProgressSelection copyWith({
    ProgressPeriod? period,
    String? selectedDateKey,
    bool clearSelection = false,
  }) {
    final selected = clearSelection
        ? null
        : (selectedDateKey ?? this.selectedDateKey);
    return ProgressSelection(
      period: period ?? this.period,
      selectedDateKey: selected,
      anchorDateKey: selected ?? anchorDateKey,
    );
  }
}

class ProgressSelectionController extends StateNotifier<ProgressSelection> {
  ProgressSelectionController([DateTime? now])
    : _now = now,
      super(_initial(ProgressHorizon.day, now));

  final DateTime? _now;

  DateTime get _clock => _now ?? DateTime.now();

  static ProgressSelection _initial(ProgressHorizon h, DateTime? now) {
    final period = ProgressPeriod.current(h, now);
    return ProgressSelection(
      period: period,
      selectedDateKey: _defaultSelection(period, now),
      anchorDateKey: DateKeys.todayKey(now),
    );
  }

  /// Day: the day itself. Week / Month: today when inside the period,
  /// else nothing open. Quarter / Year: never.
  static String? _defaultSelection(ProgressPeriod period, DateTime? now) {
    switch (period.horizon) {
      case ProgressHorizon.day:
        return period.key;
      case ProgressHorizon.week:
      case ProgressHorizon.month:
        final today = DateKeys.todayKey(now);
        return period.contains(today) ? today : null;
      case ProgressHorizon.quarter:
      case ProgressHorizon.year:
        return null;
    }
  }

  void setHorizon(ProgressHorizon horizon) {
    if (horizon == state.horizon) return;
    final anchor = DateKeys.parseLocalDateKey(state.anchorDateKey);
    final period = ProgressPeriod.forDate(horizon, anchor);
    state = ProgressSelection(
      period: period,
      selectedDateKey: horizon == ProgressHorizon.day
          ? period.key
          : _defaultSelection(period, _now),
      anchorDateKey: state.anchorDateKey,
    );
  }

  /// A representative day of a paged-to period: today when it contains
  /// today, otherwise the period's last day.
  String _anchorFor(ProgressPeriod period) {
    final today = DateKeys.todayKey(_clock);
    return period.contains(today) ? today : period.endDateKey;
  }

  void previous() => _jump(state.period.previous);

  void next() {
    final n = state.period.next;
    if (n.startsAfterToday(_clock)) return;
    _jump(n);
  }

  void _jump(ProgressPeriod period) {
    final selected = period.horizon == ProgressHorizon.day
        ? period.key
        : _defaultSelection(period, _now);
    state = ProgressSelection(
      period: period,
      selectedDateKey: selected,
      anchorDateKey: selected ?? _anchorFor(period),
    );
  }

  /// Ring tap: open that day's detail; tapping the open day closes it.
  void toggleDay(String dateKey) {
    if (!state.supportsDayDetail) return;
    if (state.horizon == ProgressHorizon.day) return;
    if (!state.period.contains(dateKey)) return;
    if (state.selectedDateKey == dateKey) {
      state = state.copyWith(clearSelection: true);
    } else {
      state = state.copyWith(selectedDateKey: dateKey);
    }
  }
}

final progressSelectionProvider =
    StateNotifierProvider<ProgressSelectionController, ProgressSelection>(
      (ref) => ProgressSelectionController(),
    );
