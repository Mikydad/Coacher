import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/context_override_providers.dart';
import '../application/sleep_window_util.dart';
import '../domain/models/context_override.dart';
import '../domain/models/user_attention_state.dart';
import 'post_override_review_card.dart';
import '../../../core/presentation/app_colors.dart';

/// Settings section for managing context overrides and sleep window.
///
/// Designed to be embedded inside a settings screen or used as a standalone
/// screen. Provides:
///   - Current override status + "End now" button
///   - Sleep window configuration
///   - Recent override history (in-memory stub in Phase B)
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
        style: TextStyle(color: Colors.red.shade300),
      ),
      data: (state) {
        final s = state ?? UserAttentionState.empty();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel(context, 'ATTENTION MODE'),
            const SizedBox(height: 8),
            _CurrentOverrideRow(state: s, effective: effective),
            const SizedBox(height: 20),
            _sectionLabel(context, 'SLEEP WINDOW'),
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
        color: AppColors.fg.withAlpha(10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.fg12),
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
                  hasOverride
                      ? '${effective.displayName} mode active'
                      : 'No active override',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (hasOverride && state.overrideExpiresAt != null)
                  Text(
                    _remainingLabel(state.overrideExpiresAt!),
                    style: TextStyle(fontSize: 12, color: AppColors.fg54),
                  ),
                if (hasOverride && state.overrideExpiresAt == null)
                  Text(
                    'Until manually ended',
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

// ─── Sleep window configuration ───────────────────────────────────────────────

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

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final service = ref.read(contextOverrideServiceProvider);
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Daily sleep window'),
          subtitle: Text(
            _enabled
                ? 'Reminders suppressed from ${_fmt(_start)} to ${_fmt(_end)}'
                : 'Off — all reminders active overnight',
            style: TextStyle(fontSize: 12, color: AppColors.fg54),
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
                '🌙 Sleep window is currently active',
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
        final picked = await showTimePicker(
          context: context,
          initialTime: value,
          builder: (ctx, child) => MediaQuery(
            data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.fg.withAlpha(10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.fg12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: AppColors.fg54)),
            const SizedBox(height: 2),
            Text(
              '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
