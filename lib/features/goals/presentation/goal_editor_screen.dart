import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/stable_id.dart';
import '../application/goal_intensity_mode.dart';
import '../application/goal_period_helpers.dart';
import '../application/goals_providers.dart';
import '../domain/models/goal_action.dart';
import '../domain/models/goal_categories.dart';
import '../domain/models/goal_enums.dart';
import '../domain/models/user_goal.dart';

class GoalEditorArgs {
  const GoalEditorArgs({this.goalId});
  final String? goalId;
}

class GoalEditorScreen extends ConsumerStatefulWidget {
  const GoalEditorScreen({super.key, this.goalId});

  final String? goalId;

  static const routeName = '/goals/edit';

  @override
  ConsumerState<GoalEditorScreen> createState() => _GoalEditorScreenState();
}

class _GoalEditorScreenState extends ConsumerState<GoalEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _target = TextEditingController();
  final _customLabel = TextEditingController();
  final _durationDays = TextEditingController(text: '30');
  final _actionControllers = <TextEditingController>[TextEditingController()];

  String _categoryId = GoalCategories.study;
  GoalHorizon _horizon = GoalHorizon.monthly;
  GoalPeriodMode _periodMode = GoalPeriodMode.calendar;
  MeasurementKind _measurement = MeasurementKind.minutes;
  double _intensity = 3;
  DateTime _monthAnchor = DateTime.now();
  DateTime _rangeStart = DateTime.now();
  DateTime _rangeEnd = DateTime.now().add(const Duration(days: 6));
  DateTime _durationStart = DateTime.now();
  bool _reminderEnabled = false;
  int _reminderMinutesFromMidnight = 9 * 60;
  bool _seeded = false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    _customLabel.dispose();
    _durationDays.dispose();
    for (final c in _actionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _monthAnchor,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) setState(() => _monthAnchor = DateTime(picked.year, picked.month, 1));
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rangeStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _rangeStart = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rangeEnd,
      firstDate: _rangeStart,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _rangeEnd = picked);
  }

  String _formatReminderTime(BuildContext context) {
    final t = TimeOfDay(
      hour: _reminderMinutesFromMidnight ~/ 60,
      minute: _reminderMinutesFromMidnight % 60,
    );
    return t.format(context);
  }

  Future<void> _pickReminderTime() async {
    final initial = TimeOfDay(
      hour: _reminderMinutesFromMidnight ~/ 60,
      minute: _reminderMinutesFromMidnight % 60,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() => _reminderMinutesFromMidnight = picked.hour * 60 + picked.minute);
    }
  }

  Future<void> _pickDurationStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _durationStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _durationStart = picked);
  }

  ({int startMs, int endMs}) _periodBounds({required int? durationDayCount}) {
    if (_periodMode == GoalPeriodMode.durationDays) {
      final n = durationDayCount ?? int.tryParse(_durationDays.text.trim()) ?? 1;
      return GoalPeriodHelpers.localDurationDayCount(_durationStart, n);
    }
    switch (_horizon) {
      case GoalHorizon.monthly:
        return GoalPeriodHelpers.localCalendarMonthBounds(_monthAnchor.year, _monthAnchor.month);
      case GoalHorizon.daily:
      case GoalHorizon.weekly:
        return GoalPeriodHelpers.localDayRangeBounds(_rangeStart, _rangeEnd);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    int? durationDayCount;
    if (_periodMode == GoalPeriodMode.durationDays) {
      durationDayCount = int.tryParse(_durationDays.text.trim());
      if (durationDayCount == null || durationDayCount < 1 || durationDayCount > 3650) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter number of days (1–3650)')),
        );
        return;
      }
    } else if (_horizon != GoalHorizon.monthly) {
      final rs = DateTime(_rangeStart.year, _rangeStart.month, _rangeStart.day);
      final re = DateTime(_rangeEnd.year, _rangeEnd.month, _rangeEnd.day);
      if (re.isBefore(rs)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End date must be on or after start date')));
        return;
      }
    }
    final target = double.tryParse(_target.text.trim());
    if (target == null || target < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid target number')));
      return;
    }
    final actions = _actionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    if (actions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one action')));
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(goalsRepositoryProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    final bounds = _periodBounds(durationDayCount: durationDayCount);
    final goalId = widget.goalId ?? StableId.generate('goal');

    try {
      final existing = widget.goalId != null ? await repo.getGoal(goalId) : null;
      final goal = UserGoal(
        id: goalId,
        title: _title.text.trim(),
        categoryId: _categoryId,
        horizon: _horizon,
        status: existing?.status ?? GoalStatus.active,
        measurementKind: _measurement,
        targetValue: target,
        customLabel: _measurement == MeasurementKind.custom ? _customLabel.text.trim().isEmpty ? null : _customLabel.text.trim() : null,
        intensity: _intensity.round().clamp(1, 5),
        periodStartMs: bounds.startMs,
        periodEndMs: bounds.endMs,
        periodMode: _periodMode,
        durationDays: _periodMode == GoalPeriodMode.durationDays ? durationDayCount : null,
        reminderEnabled: _reminderEnabled,
        reminderMinutesFromMidnight: _reminderEnabled ? _reminderMinutesFromMidnight : null,
        reminderStyle: existing?.reminderStyle ?? GoalReminderStyle.dailyOnce,
        createdAtMs: existing?.createdAtMs ?? now,
        updatedAtMs: now,
      );
      await repo.upsertGoal(goal);

      if (widget.goalId != null) {
        final oldActions = await repo.getActions(goalId);
        for (final a in oldActions) {
          await repo.deleteAction(goalId: goalId, actionId: a.id);
        }
      }
      var idx = 0;
      for (final title in actions) {
        await repo.upsertAction(
          GoalAction(
            id: StableId.generate('gaction'),
            goalId: goalId,
            title: title,
            orderIndex: idx++,
          ),
        );
      }

      if (!mounted) return;
      invalidateGoals(ref, goalId: goalId);
      await ref.read(goalReminderSyncServiceProvider).applyForGoal(goal);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _seedFromBundle(GoalDetailBundle bundle) {
    if (_seeded) return;
    _seeded = true;
    final g = bundle.goal;
    _title.text = g.title;
    _categoryId = g.categoryId;
    _horizon = g.horizon;
    _measurement = g.measurementKind;
    _target.text = g.targetValue == g.targetValue.roundToDouble() ? '${g.targetValue.toInt()}' : '${g.targetValue}';
    if (g.customLabel != null) _customLabel.text = g.customLabel!;
    _intensity = g.intensity.toDouble();
    _periodMode = g.periodMode;
    _monthAnchor = DateTime.fromMillisecondsSinceEpoch(g.periodStartMs);
    _rangeStart = DateTime.fromMillisecondsSinceEpoch(g.periodStartMs);
    _rangeEnd = DateTime.fromMillisecondsSinceEpoch(g.periodEndMs);
    _durationStart = DateTime.fromMillisecondsSinceEpoch(g.periodStartMs);
    _durationDays.text = '${g.durationDays ?? GoalPeriodHelpers.totalCalendarDaysInPeriod(g)}';
    _reminderEnabled = g.reminderEnabled;
    _reminderMinutesFromMidnight = g.reminderMinutesFromMidnight ?? 9 * 60;
    for (final c in _actionControllers) {
      c.dispose();
    }
    _actionControllers.clear();
    if (bundle.actions.isEmpty) {
      _actionControllers.add(TextEditingController());
    } else {
      for (final a in bundle.actions) {
        _actionControllers.add(TextEditingController(text: a.title));
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.goalId != null) {
      final async = ref.watch(goalDetailProvider(widget.goalId!));
      async.whenData((b) {
        if (b != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _seedFromBundle(b);
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goalId == null ? 'New goal' : 'Edit goal'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Learn Chinese'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            const Text('Category', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in GoalCategories.all)
                  ChoiceChip(
                    label: Text(GoalCategories.label(id)),
                    selected: _categoryId == id,
                    onSelected: (_) => setState(() => _categoryId = id),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<GoalHorizon>(
              segments: const [
                ButtonSegment(value: GoalHorizon.daily, label: Text('Daily')),
                ButtonSegment(value: GoalHorizon.weekly, label: Text('Weekly')),
                ButtonSegment(value: GoalHorizon.monthly, label: Text('Monthly')),
              ],
              selected: {_horizon},
              onSelectionChanged: (s) => setState(() => _horizon = s.first),
            ),
            const SizedBox(height: 12),
            const Text('How long', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            SegmentedButton<GoalPeriodMode>(
              segments: const [
                ButtonSegment(
                  value: GoalPeriodMode.calendar,
                  label: Text('Calendar'),
                  icon: Icon(Icons.calendar_today, size: 18),
                ),
                ButtonSegment(
                  value: GoalPeriodMode.durationDays,
                  label: Text('Day count'),
                  icon: Icon(Icons.timelapse, size: 18),
                ),
              ],
              selected: {_periodMode},
              onSelectionChanged: (s) => setState(() => _periodMode = s.first),
            ),
            const SizedBox(height: 4),
            Text(
              _periodMode == GoalPeriodMode.calendar
                  ? 'Pick a calendar month or start/end dates.'
                  : 'Pick a start date and how many days the goal runs (e.g. 30-day sprint).',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            if (_periodMode == GoalPeriodMode.calendar) ...[
              if (_horizon == GoalHorizon.monthly)
                ListTile(
                  title: Text(
                    'Month: ${_monthAnchor.year}-${_monthAnchor.month.toString().padLeft(2, '0')}',
                  ),
                  subtitle: const Text('Whole calendar month (local)'),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: _pickMonth,
                )
              else ...[
                ListTile(
                  title: Text('Start: ${_rangeStart.year}-${_rangeStart.month}-${_rangeStart.day}'),
                  subtitle: const Text('First day'),
                  onTap: _pickStart,
                ),
                ListTile(
                  title: Text('End: ${_rangeEnd.year}-${_rangeEnd.month}-${_rangeEnd.day}'),
                  subtitle: const Text('Last day'),
                  onTap: _pickEnd,
                ),
              ],
            ] else ...[
              ListTile(
                title: Text(
                  'Starts: ${_durationStart.year}-${_durationStart.month.toString().padLeft(2, '0')}-${_durationStart.day.toString().padLeft(2, '0')}',
                ),
                subtitle: const Text('First day of the run'),
                trailing: const Icon(Icons.event),
                onTap: _pickDurationStart,
              ),
              TextFormField(
                controller: _durationDays,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of days',
                  hintText: 'e.g. 30',
                  helperText: 'Inclusive: day 1 through this many days',
                ),
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<MeasurementKind>(
              // Controlled field; `initialValue` does not follow selection changes.
              // ignore: deprecated_member_use
              value: _measurement,
              decoration: const InputDecoration(labelText: 'Measure progress with'),
              items: [
                for (final k in MeasurementKind.values)
                  DropdownMenuItem(value: k, child: Text(k.displayLabel())),
              ],
              onChanged: (v) => setState(() => _measurement = v ?? MeasurementKind.minutes),
            ),
            if (_measurement == MeasurementKind.custom)
              TextFormField(
                controller: _customLabel,
                decoration: const InputDecoration(labelText: 'Custom unit label'),
              ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _target,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: switch ((_periodMode, _horizon)) {
                  (GoalPeriodMode.durationDays, _) => 'Target (per day in this run)',
                  (_, GoalHorizon.weekly) => 'Target (this week)',
                  (_, GoalHorizon.monthly) => 'Target (per day in that month)',
                  (_, GoalHorizon.daily) => 'Target (per day)',
                },
                hintText: 'e.g. 30',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            const Text(
              'Intensity (discipline level)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${_intensity.round()} / 5 · ${GoalIntensityMode.displayLabelForIntensity(_intensity.round())}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            const Text(
              '1–2 flexible · 3–4 disciplined · 5 extreme',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            Slider(
              value: _intensity,
              min: 1,
              max: 5,
              divisions: 4,
              label: '${_intensity.round()}',
              onChanged: (v) => setState(() => _intensity = v),
            ),
            const SizedBox(height: 16),
            const Text('Reminder', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Daily reminder'),
              subtitle: Text(
                _reminderEnabled
                    ? 'At ${_formatReminderTime(context)} (local), while this goal is active'
                    : 'Off',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              value: _reminderEnabled,
              onChanged: (v) async {
                if (v) {
                  final ok = await ref.read(localNotificationsServiceProvider).requestPermissionsIfNeeded();
                  if (!context.mounted) return;
                  if (!ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Allow notifications to get goal reminders.')),
                    );
                  }
                }
                if (!context.mounted) return;
                setState(() => _reminderEnabled = v);
              },
            ),
            if (_reminderEnabled)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reminder time'),
                subtitle: Text(_formatReminderTime(context)),
                trailing: const Icon(Icons.schedule),
                onTap: _pickReminderTime,
              ),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Uses one notification per day at this time. Other patterns (several pings, “until you start”) can extend this later.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Actions (what you actually do)', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            for (var i = 0; i < _actionControllers.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _actionControllers[i],
                        decoration: InputDecoration(hintText: 'Action ${i + 1}'),
                      ),
                    ),
                    if (_actionControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          setState(() {
                            _actionControllers[i].dispose();
                            _actionControllers.removeAt(i);
                          });
                        },
                      ),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed: () => setState(() => _actionControllers.add(TextEditingController())),
              icon: const Icon(Icons.add),
              label: const Text('Add action'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: const Color(0xFFB7FF00),
                foregroundColor: Colors.black,
              ),
              child: _saving ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save goal'),
            ),
          ],
        ),
      ),
    );
  }
}
