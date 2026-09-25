import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/context_override_providers.dart';
import '../application/sleep_window_util.dart';
import '../domain/models/context_override.dart';
import '../domain/models/user_attention_state.dart';
import 'post_override_review_card.dart';
import '../../../core/presentation/app_colors.dart';

/// Settings section for managing context overrides and the sleep window —
/// "Status" and "Quiet hours" to the user (plain-language pass, 2026-09-25).
///
/// Designed to be embedded inside a settings screen or used as a standalone
/// screen. Provides:
///   - Current status + "End now" button
///   - Quiet hours (sleep window) configuration
///   - Recent override history (in-memory stub in Phase B)

/// "23:00" → "11:00 PM": the stored HH:mm strings shown the way the rest of
/// the app shows times. Falls back to the raw string if it does not parse.
String formatSleepWindowTime(BuildContext context, String hhmm) {
  final parts = hhmm.trim().split(':');
  if (parts.length != 2) return hhmm;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
    return hhmm;
  }
  return MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay(hour: h, minute: m), alwaysUse24HourFormat: false);
}
class OverrideSettingsSection extends ConsumerWidget {
  const OverrideSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(attentionStateProvider);
    final effective = ref.watch(effectiveOverrideProvider);

    return stateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(
        'Error loading override state',
        style: TextStyle(color: AppColors.danger),
      ),
      data: (state) {
        final s = state ?? UserAttentionState.empty();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel(context, 'STATUS'),
            const SizedBox(height: 8),
            _CurrentOverrideRow(state: s, effective: effective),
            const SizedBox(height: 20),
            _sectionLabel(context, 'QUIET HOURS'),
            const SizedBox(height: 8),
            _SleepWindowConfig(state: s),
          ],
        );
      },
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(letterSpacing: 2, fontSize: 11, color: AppColors.fg54),
    );
  }
}

// ─── Current override status row ─────────────────────────────────────────────

class _CurrentOverrideRow extends ConsumerWidget {
  const _CurrentOverrideRow({required this.state, required this.effective});

  final UserAttentionState state;
  final ContextOverride effective;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasOverride = effective != ContextOverride.none;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            hasOverride ? effective.icon : '✅',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasOverride ? effective.displayName : 'No status set',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (hasOverride && state.overrideExpiresAt != null)
                  Text(
                    _remainingLabel(state.overrideExpiresAt!),
                    style: TextStyle(fontSize: 12, color: AppColors.fg54),
                  ),
                if (hasOverride && state.overrideExpiresAt == null)
                  Text(
                    // The automatic quiet hours end at their wake time;
                    // "End now" pauses them until then (2026-09-15).
                    state.activeOverride == ContextOverride.none &&
                            effective == ContextOverride.sleep &&
                            (state.sleepWindowEnd?.isNotEmpty ?? false)
                        ? 'Quiet hours · until '
                              '${formatSleepWindowTime(context, state.sleepWindowEnd!)}'
                        : 'Until manually ended',
                    style: TextStyle(fontSize: 12, color: AppColors.fg54),
                  ),
              ],
            ),
          ),
          if (hasOverride)
            TextButton(
              onPressed: () => _end(context, ref),
              child: const Text('End now'),
            ),
        ],
      ),
    );
  }

  String _remainingLabel(DateTime expires) {
    final remaining = expires.difference(DateTime.now());
    if (remaining.isNegative) return 'Expiring…';
    if (remaining.inMinutes < 1) return 'Less than a minute left';
    if (remaining.inHours < 1) return '${remaining.inMinutes}m remaining';
    return '${remaining.inHours}h ${remaining.inMinutes % 60}m remaining';
  }

  Future<void> _end(BuildContext context, WidgetRef ref) async {
    final review = await ref.read(contextOverrideServiceProvider).endOverride();
    if (review.overrideType != ContextOverride.none) {
      ref.read(pendingRecoveryReviewProvider.notifier).state = review;
      await persistPendingReviewFlag(true);
    }
  }
}

// ─── Quiet hours (sleep window) configuration ────────────────────────────────

class _SleepWindowConfig extends ConsumerStatefulWidget {
  const _SleepWindowConfig({required this.state});

  final UserAttentionState state;

  @override
  ConsumerState<_SleepWindowConfig> createState() => _SleepWindowConfigState();
}

class _SleepWindowConfigState extends ConsumerState<_SleepWindowConfig> {
  bool _enabled = false;
  TimeOfDay _start = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 7, minute: 0);

  @override
  void initState() {
    super.initState();
    _enabled = widget.state.hasSleepWindow;
    if (widget.state.sleepWindowStart != null) {
      final parts = widget.state.sleepWindowStart!.split(':');
      if (parts.length == 2) {
        _start = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 23,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    if (widget.state.sleepWindowEnd != null) {
      final parts = widget.state.sleepWindowEnd!.split(':');
      if (parts.length == 2) {
        _end = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 7,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
  }

  /// Storage form (HH:mm) — what the service persists and compares.
  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Display form ("10:30 PM").
  String _fmt12(BuildContext context, TimeOfDay t) =>
      MaterialLocalizations.of(
        context,
      ).formatTimeOfDay(t, alwaysUse24HourFormat: false);

  @override
  Widget build(BuildContext context) {
    final service = ref.read(contextOverrideServiceProvider);
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Quiet hours'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pause non-urgent reminders while you sleep.',
                style: TextStyle(fontSize: 12, color: AppColors.fg54),
              ),
              const SizedBox(height: 2),
              Text(
                _enabled
                    ? 'Non-urgent reminders paused from '
                          '${_fmt12(context, _start)} to ${_fmt12(context, _end)}'
                    : 'Off — reminders active overnight',
                style: TextStyle(fontSize: 12, color: AppColors.fg54),
              ),
            ],
          ),
          value: _enabled,
          onChanged: (v) async {
            setState(() => _enabled = v);
            if (!v) {
              await service.clearSleepWindow();
            } else {
              await service.setSleepWindow(
                start: _fmt(_start),
                end: _fmt(_end),
              );
            }
          },
        ),
        if (_enabled) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TimePicker(
                  label: 'Starts at',
                  value: _start,
                  onChanged: (t) async {
                    setState(() => _start = t);
                    await service.setSleepWindow(
                      start: _fmt(t),
                      end: _fmt(_end),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimePicker(
                  label: 'Ends at',
                  value: _end,
                  onChanged: (t) async {
                    setState(() => _end = t);
                    await service.setSleepWindow(
                      start: _fmt(_start),
                      end: _fmt(t),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Builder(
            builder: (ctx) {
              final now = DateTime.now();
              final active = isWithinSleepWindow(now, _fmt(_start), _fmt(_end));
              if (!active) return const SizedBox.shrink();
              return Text(
                '🌙 Quiet hours are active now',
                style: TextStyle(fontSize: 12, color: AppColors.fg54),
              );
            },
          ),
        ],
      ],
    );
  }
}

// ─── Time picker tile ─────────────────────────────────────────────────────────

class _TimePicker extends StatelessWidget {
  const _TimePicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final TimeOfDay value;
  final void Function(TimeOfDay) onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        // Device format (12-hour on a US phone) so the dial matches the
        // "10:30 PM" the tile shows (2026-09-25).
        final picked = await showTimePicker(
          context: context,
          initialTime: value,
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: AppColors.fg54)),
            const SizedBox(height: 2),
            Text(
              MaterialLocalizations.of(
                context,
              ).formatTimeOfDay(value, alwaysUse24HourFormat: false),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
