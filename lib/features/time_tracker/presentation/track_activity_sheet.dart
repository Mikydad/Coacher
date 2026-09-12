import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../application/time_tracker_providers.dart';
import '../domain/models/activity_category_rule.dart';
import '../domain/models/activity_event.dart';
import '../domain/recent_activities.dart';
import 'time_screen.dart';

/// The capture sheet (PRD/Time_Tracker §4) — the common path, so it must
/// be two taps and done:
///
/// ```
/// 10:03 PM             Today's timeline →   ← time tappable; link top-right
/// What are you doing?
/// [ Scrolling                ]
/// RECENT   (Gym) (Scrolling) …   ← the user's own, tap fills the field
/// DURATION · OPTIONAL  (15m) (30m) (45m) (1h) (Custom…)
/// [        TRACK ▸        ]
/// ```
///
/// Edit mode (`edit != null`) is the same sheet with an End row and a
/// Delete action. The timestamp is captured ONCE, when the sheet opens —
/// "the moment they opened the tracker" — never re-read at Track time.
///
/// SidePal doesn't track your time for you. It makes it effortless for you
/// to record your time, then helps you see what you actually did with it.
Future<void> showTrackActivitySheet(
  BuildContext context, {
  ActivityEvent? edit,
  int? presetStartMs,
}) {
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
    routeSettings: const RouteSettings(name: TrackActivitySheet.routeName),
    builder: (_) => TrackActivitySheet(edit: edit, presetStartMs: presetStartMs),
  );
}

/// Intended-duration chip choices (minutes).
const List<int> kIntendedDurationChips = [15, 30, 45, 60];

class TrackActivitySheet extends ConsumerStatefulWidget {
  const TrackActivitySheet({super.key, this.edit, this.presetStartMs});

  /// Named for the feedback route tracker, like Add Task.
  static const routeName = '/track';

  final ActivityEvent? edit;
  final int? presetStartMs;

  bool get isEdit => edit != null;

  @override
  ConsumerState<TrackActivitySheet> createState() => _TrackActivitySheetState();
}

class _TrackActivitySheetState extends ConsumerState<TrackActivitySheet> {
  late final TextEditingController _text;
  late int _startMs;
  int? _endMs;
  int? _intended;
  bool _saving = false;
  String? _note;

  @override
  void initState() {
    super.initState();
    final edit = widget.edit;
    _text = TextEditingController(text: edit?.text ?? '');
    _startMs =
        edit?.startedAtMs ??
        widget.presetStartMs ??
        DateTime.now().millisecondsSinceEpoch;
    _endMs = edit?.endedAtMs;
    _intended = edit?.intendedMinutes;
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _canSubmit => _text.text.trim().isNotEmpty && !_saving;

  /// The calendar day this sheet edits — today for new entries, the
  /// event's own day in edit mode (edits are today-only, so the same).
  DateTime get _day {
    final d = DateTime.fromMillisecondsSinceEpoch(_startMs);
    return DateTime(d.year, d.month, d.day);
  }

  Future<void> _pickStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateTime.fromMillisecondsSinceEpoch(_startMs),
      ),
    );
    if (picked == null || !mounted) return;
    var candidate = DateTime(
      _day.year,
      _day.month,
      _day.day,
      picked.hour,
      picked.minute,
    ).millisecondsSinceEpoch;
    final now = DateTime.now().millisecondsSinceEpoch;
    String? note;
    if (candidate > now) {
      candidate = now;
      note = "Can't log the future yet — set to now.";
    }
    final end = _endMs;
    if (end != null && end <= candidate) {
      _endMs = null;
      note = 'End cleared — it was before the new start.';
    }
    setState(() {
      _startMs = candidate;
      _note = note;
    });
  }

  Future<void> _pickEnd() async {
    final initial = _endMs ?? DateTime.now().millisecondsSinceEpoch;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateTime.fromMillisecondsSinceEpoch(initial),
      ),
    );
    if (picked == null || !mounted) return;
    var candidate = DateTime(
      _day.year,
      _day.month,
      _day.day,
      picked.hour,
      picked.minute,
    ).millisecondsSinceEpoch;
    final now = DateTime.now().millisecondsSinceEpoch;
    String? note;
    if (candidate > now) {
      candidate = now;
      note = "Can't end in the future — set to now.";
    }
    if (candidate <= _startMs) {
      setState(() => _note = 'End must be after the start.');
      return;
    }
    setState(() {
      _endMs = candidate;
      _note = note;
    });
  }

  Future<void> _pickCustomDuration() async {
    final minutes = await showDialog<int>(
      context: context,
      builder: (_) => _CustomDurationDialog(
        initial: _intended != null && !kIntendedDurationChips.contains(_intended)
            ? _intended
            : null,
      ),
    );
    if (minutes == null || !mounted) return;
    if (minutes < 1 || minutes > kActivityIntendedMaxMinutes) {
      setState(
        () => _note = 'Duration must be 1–$kActivityIntendedMaxMinutes minutes.',
      );
      return;
    }
    setState(() {
      _intended = minutes;
      _note = null;
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _saving = true);
    final actions = ref.read(timeTrackerActionsProvider);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final edit = widget.edit;
    try {
      final event = edit == null
          ? ActivityEvent.create(
              text: _text.text,
              startedAtMs: _startMs,
              nowMs: nowMs,
              endedAtMs: _endMs,
              intendedMinutes: _intended,
            )
          : edit.copyWith(
              text: _text.text.trim(),
              startedAtMs: _startMs,
              endedAtMs: _endMs,
              clearEnd: _endMs == null,
              intendedMinutes: _intended,
              clearIntended: _intended == null,
            );
      if (edit == null) {
        await actions.log(event);
      } else {
        await actions.update(event);
      }
    } catch (e) {
      debugPrint('[TrackActivitySheet] save failed: $e');
      if (mounted) {
        setState(() {
          _saving = false;
          _note = "Couldn't save that — check the entry.";
        });
      }
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final edit = widget.edit;
    if (edit == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: Text(edit.text),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            key: const ValueKey('track_delete_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.coral),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(timeTrackerActionsProvider).delete(edit.id);
    if (mounted) Navigator.of(context).pop();
  }

  void _openTimeline() {
    final nav = Navigator.of(context);
    nav.pop();
    nav.pushNamed(TimeScreen.routeName);
  }

  String _clock(BuildContext context, int ms) {
    final loc = MaterialLocalizations.of(context);
    return loc.formatTimeOfDay(
      TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(ms)),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = recentActivitySuggestions(
      ref.watch(recentActivityEventsProvider).valueOrNull ?? const [],
      query: _text.text,
    );
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isEdit = widget.isEdit;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timestamp + timeline link ────────────────────────────────
          // The link sits up here (Miko, device test 2026-09-12): at the
          // foot of the sheet it was easy to miss under the keyboard.
          Row(
            children: [
              InkWell(
                key: const ValueKey('track_time'),
                borderRadius: BorderRadius.circular(10),
                onTap: _pickStart,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _clock(context, _startMs),
                        style: TextStyle(
                          color: AppColors.fg,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.edit_outlined,
                        size: 15,
                        color: AppColors.textSoft,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                key: const ValueKey('track_timeline_link'),
                onPressed: _openTimeline,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.timeline_outlined, size: 16),
                label: const Text(
                  "Today's timeline",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (isEdit) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                InkWell(
                  key: const ValueKey('track_end'),
                  borderRadius: BorderRadius.circular(10),
                  onTap: _pickEnd,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      _endMs == null
                          ? 'Set an end time'
                          : 'Ended at ${_clock(context, _endMs!)}',
                      style: TextStyle(
                        color: _endMs == null ? AppColors.textSoft : AppColors.fg,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (_endMs != null)
                  IconButton(
                    key: const ValueKey('track_end_clear'),
                    tooltip: 'Clear end',
                    icon: Icon(Icons.close, size: 16, color: AppColors.textSoft),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _endMs = null),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),

          // ── Activity ─────────────────────────────────────────────────
          Text(
            'What are you doing?',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('track_text'),
            controller: _text,
            autofocus: !isEdit,
            maxLength: kActivityTextMaxChars,
            buildCounter:
                (context, {required currentLength, required isFocused, maxLength}) =>
                    null,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Scrolling, Gym, Working on SidePal…',
              hintStyle: TextStyle(color: AppColors.fg54),
              filled: true,
              fillColor: AppColors.fg12.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),

          // ── Recent ───────────────────────────────────────────────────
          // A fixed five-row list, not chips (Miko, 2026-09-12): entries
          // like "going to the clinic with my mom" never fit a pill.
          // Repeats first, then recency; typing filters the list.
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 14),
            const _MicroLabel('Recent'),
            const SizedBox(height: 4),
            for (final s in suggestions)
              InkWell(
                key: ValueKey('track_recent_${s.text}'),
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  _text.text = s.text;
                  _text.selection = TextSelection.collapsed(
                    offset: s.text.length,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 15,
                        color: AppColors.textSoft.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.fg,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (s.count > 1) ...[
                        const SizedBox(width: 8),
                        Text(
                          '×${s.count}',
                          style: TextStyle(
                            color: AppColors.fg38,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],

          // ── Duration ─────────────────────────────────────────────────
          const SizedBox(height: 14),
          const _MicroLabel('Duration · optional'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in kIntendedDurationChips)
                ChoiceChip(
                  key: ValueKey('track_duration_$m'),
                  label: Text(m == 60 ? '1h' : '${m}m'),
                  selected: _intended == m,
                  onSelected: (_) =>
                      setState(() => _intended = _intended == m ? null : m),
                ),
              ChoiceChip(
                key: const ValueKey('track_duration_custom'),
                label: Text(
                  _intended != null && !kIntendedDurationChips.contains(_intended)
                      ? '${_intended}m'
                      : 'Custom…',
                ),
                selected:
                    _intended != null && !kIntendedDurationChips.contains(_intended),
                onSelected: (_) => _pickCustomDuration(),
              ),
            ],
          ),

          // V1.2: category override — edit mode only, capture stays free.
          // Writes a USER rule for every event with this text.
          if (isEdit) ...[
            const SizedBox(height: 14),
            const _MicroLabel('Category'),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, _) {
                final rules =
                    ref.watch(activityCategoryRulesProvider).valueOrNull ??
                    const <ActivityCategoryRule>[];
                final key = normalizeActivityText(_text.text);
                ActivityCategoryRule? current;
                for (final r in rules) {
                  if (r.normalizedText == key) {
                    current = r;
                    break;
                  }
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in ActivityCategories.all)
                          ChoiceChip(
                            key: ValueKey('track_category_$c'),
                            label: Text(ActivityCategories.label(c)),
                            selected: current?.category == c,
                            onSelected: (_) async {
                              await ref
                                  .read(activityCategoryRuleRepositoryProvider)
                                  .setCategory(
                                    _text.text,
                                    category: c,
                                    source: CategoryRuleSource.user,
                                  );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      current == null
                          ? "Applies to every '${_text.text.trim()}'."
                          : current.isUserSet
                          ? "Applies to every '${_text.text.trim()}' · set by you"
                          : "Applies to every '${_text.text.trim()}' · suggested by SidePal",
                      style: TextStyle(color: AppColors.fg38, fontSize: 11),
                    ),
                  ],
                );
              },
            ),
          ],

          if (_note != null) ...[
            const SizedBox(height: 10),
            Text(
              _note!,
              key: const ValueKey('track_note'),
              style: TextStyle(color: AppColors.textSoft, fontSize: 12),
            ),
          ],

          // ── Primary action ───────────────────────────────────────────
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              key: const ValueKey('track_submit'),
              onPressed: _canSubmit ? _submit : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.onAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: Text(
                isEdit ? 'SAVE' : 'TRACK  ▸',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          // ── Footer (edit mode only) ──────────────────────────────────
          if (isEdit) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey('track_delete'),
                onPressed: _delete,
                style: TextButton.styleFrom(foregroundColor: AppColors.coral),
                child: const Text(
                  'Delete',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MicroLabel extends StatelessWidget {
  const _MicroLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: AppColors.textSoft,
      ),
    );
  }
}

/// Owns its controller so the dialog's exit animation never touches a
/// disposed controller.
class _CustomDurationDialog extends StatefulWidget {
  const _CustomDurationDialog({this.initial});

  final int? initial;

  @override
  State<_CustomDurationDialog> createState() => _CustomDurationDialogState();
}

class _CustomDurationDialogState extends State<_CustomDurationDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial?.toString() ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Intended minutes'),
      content: TextField(
        key: const ValueKey('track_custom_duration_field'),
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(hintText: 'e.g. 90'),
        onSubmitted: (v) => Navigator.of(context).pop(int.tryParse(v)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('track_custom_duration_ok'),
          onPressed: () =>
              Navigator.of(context).pop(int.tryParse(_controller.text)),
          child: const Text('Set'),
        ),
      ],
    );
  }
}
