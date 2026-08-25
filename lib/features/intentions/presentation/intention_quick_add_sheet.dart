import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../application/intention_capture.dart';
import '../application/intentions_providers.dart';
import 'geofence_opt_in_flow.dart';

/// 3-field quick-add for promises (PRD §4.2): what / when-ish / kind.
/// No clock time anywhere — SidePal picks the moment. Works fully offline;
/// the local write IS the update.
Future<void> showIntentionQuickAddSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.surfacePanel,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _IntentionQuickAddSheet(),
  );
}

class _IntentionQuickAddSheet extends ConsumerStatefulWidget {
  const _IntentionQuickAddSheet();

  @override
  ConsumerState<_IntentionQuickAddSheet> createState() =>
      _IntentionQuickAddSheetState();
}

class _IntentionQuickAddSheetState
    extends ConsumerState<_IntentionQuickAddSheet> {
  final _titleController = TextEditingController();
  IntentionWindowKind _window = IntentionWindowKind.tomorrow;
  _IntentionKind _kind = _IntentionKind.other;
  bool _headOutReminder = false;
  bool _saving = false;

  /// The per-intention location ask (Phase 6b) only exists where the
  /// geofence can — iOS with the in-house channel.
  bool get _geofenceEligible => !kIsWeb && Platform.isIOS;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _saving) return;
    setState(() => _saving = true);

    final now = DateTime.now();
    final window = resolveIntentionWindow(_window, now);
    final intention = buildIntention(
      IntentionDraft(
        title: title,
        rawUtterance: title,
        windowStart: window.start,
        windowEnd: window.end,
        estimatedMinutes: _kind.estimatedMinutes,
        activityTags: _kind.tags,
      ),
      now: now,
    );
    await ref.read(intentionsRepositoryProvider).upsertIntention(intention);
    // Plan the nudge ladder right away — Isar-only, airplane-safe.
    try {
      await ref
          .read(intentionNudgeSyncServiceProvider)
          .applyForIntention(intention);
    } catch (_) {}
    // Per-intention location opt-in (Phase 6b): remembered even when the
    // enable/home ladder isn't finished yet — arming starts once it is.
    // The time-based ladder above stays the correctness floor either way.
    if (_headOutReminder && _geofenceEligible) {
      final arming = ref.read(geofenceArmingServiceProvider);
      await arming.optIn(intention.id);
      try {
        if (mounted && await ensureGeofenceReady(context, ref)) {
          final all = await ref
              .read(intentionsRepositoryProvider)
              .fetchIntentionsOnce();
          await arming.syncArmed(all);
        }
      } catch (_) {}
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROMISE',
            style: TextStyle(
              color: AppColors.fg54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Call cousin Sara…',
              hintStyle: TextStyle(color: AppColors.fg54),
              filled: true,
              fillColor: AppColors.fg12.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 16),
          _MicroLabel('WHEN-ISH'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final w in IntentionWindowKind.values)
                ChoiceChip(
                  label: Text(_windowLabel(w)),
                  selected: _window == w,
                  onSelected: (_) => setState(() => _window = w),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _MicroLabel('KIND'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final k in _IntentionKind.values)
                ChoiceChip(
                  label: Text(k.label),
                  selected: _kind == k,
                  onSelected: (_) => setState(() => _kind = k),
                ),
            ],
          ),
          // The per-intention location ask (PRD §9: "Want me to use your
          // location for this one?") — errands are the shape that benefits
          // ("buy flowers on the way"). Quiet inline row, not a dialog.
          if (_geofenceEligible && _kind == _IntentionKind.errand) ...[
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () =>
                  setState(() => _headOutReminder = !_headOutReminder),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.near_me_outlined,
                      size: 18,
                      color: _headOutReminder
                          ? AppColors.cyan
                          : AppColors.fg54,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Remind me when I head out',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Switch(
                      value: _headOutReminder,
                      onChanged: (v) => setState(() => _headOutReminder = v),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text('Find me a good time'),
            ),
          ),
        ],
      ),
    );
  }

  String _windowLabel(IntentionWindowKind w) => switch (w) {
    IntentionWindowKind.today => 'Today',
    IntentionWindowKind.tomorrow => 'Tomorrow',
    IntentionWindowKind.thisWeek => 'This week',
    IntentionWindowKind.weekend => 'Weekend',
  };
}

class _MicroLabel extends StatelessWidget {
  const _MicroLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.fg54,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

enum _IntentionKind {
  call('Call', ['call'], 15),
  message('Message', ['message', 'quick'], 10),
  errand('Errand', ['errand'], 30),
  other('Other', [], 20);

  const _IntentionKind(this.label, this.tags, this.estimatedMinutes);
  final String label;
  final List<String> tags;
  final int estimatedMinutes;
}
