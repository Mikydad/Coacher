import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/providers.dart';
import '../../../core/firebase/firestore_paths.dart';
import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/keyboard_dismiss.dart';
import '../../../core/presentation/page_headers.dart';
import '../../../core/tier/tier_providers.dart';
import '../../../core/tier/upgrade_prompt.dart';
import '../../../core/utils/stable_id.dart';
import '../../community/application/circle_providers.dart';
import '../../goals/application/goal_period_helpers.dart';
import '../../goals/application/goals_providers.dart';
import '../../goals/domain/models/goal_categories.dart';
import '../../goals/domain/models/goal_enums.dart';
import '../../goals/domain/models/user_goal.dart';
import '../../goals/presentation/widgets/goal_editor_widgets.dart';
import '../application/points_providers.dart';
import '../application/stake_functions.dart';
import '../application/stakes_providers.dart';
import '../domain/models/points.dart';
import '../domain/models/stake_challenge.dart';
import 'stake_challenge_detail_screen.dart';
import 'stake_photo_cache.dart';

/// The unified accountability creation flow (PRD 1.4). All three entry
/// points land here:
///  - goal/task editor → [prefilledTitle]
///  - Accountability hub → nothing prefilled
///  - circle → [prefilledCircleId]
///
/// Steps: category → commitment → details (skipped for practice) →
/// consent (photo/money) → pledge → review. Category comes FIRST
/// (decision log 2026-07-17): the flow opens on what's at stake, then
/// the commitment, then type-specific setup.
/// Multi-step back is intercepted (PopScope steps back, never exits
/// mid-flow); step changes animate (~260 ms).
Future<void> openAccountabilityCreateFlow(
  BuildContext context, {
  String? prefilledTitle,
  String? prefilledCircleId,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AccountabilityCreateFlow(
        prefilledTitle: prefilledTitle,
        prefilledCircleId: prefilledCircleId,
      ),
    ),
  );
}

class AccountabilityCreateFlow extends ConsumerStatefulWidget {
  const AccountabilityCreateFlow({
    super.key,
    this.prefilledTitle,
    this.prefilledCircleId,
  });

  final String? prefilledTitle;
  final String? prefilledCircleId;

  @override
  ConsumerState<AccountabilityCreateFlow> createState() =>
      _AccountabilityCreateFlowState();
}

/// 3-page flow (2026-07-22, supersedes the 6-step order): choose &
/// configure everything → promise (why + consent + hold) → review.
enum _Step { configure, promise, review }

/// What's on the line: photo (P1), h2h points (P2), money ($ — SIMULATED
/// until Stripe activates; debug builds only), practice.
enum _StakeChoice { photo, h2h, money, practice }

class _AccountabilityCreateFlowState
    extends ConsumerState<AccountabilityCreateFlow> {
  _Step _step = _Step.configure;

  /// Which way the last navigation went — drives the slide direction.
  bool _navForward = true;

  // Scroll targets for continue-walks-you-to-the-next-missing-field
  // (2026-07-22). One key per requirement site, in page order.
  final _keyPhotoCircle = GlobalKey();
  final _keyPhotoUpload = GlobalKey();
  final _keyH2hCircle = GlobalKey();
  final _keyOpponent = GlobalKey();
  final _keyYourCause = GlobalKey();
  final _keyBothLose = GlobalKey();
  final _keyAntiCharity = GlobalKey();
  final _keyTitle = GlobalKey();
  final _keyTarget = GlobalKey();
  final _keySchedule = GlobalKey();
  final _keyWhy = GlobalKey();
  final _keyConsent = GlobalKey();

  /// First missing requirement's scroll key, in PAGE order (stake config →
  /// commitment → photo tile). Null when nothing is missing or the miss
  /// is already at the top (stake not chosen).
  GlobalKey? _firstMissingKey() {
    final commitment = <(GlobalKey, bool)>[
      (_keyTitle, _title.text.trim().isNotEmpty),
      (_keyTarget, _unitTarget > 0),
      (
        _keySchedule,
        _totalUnits > 0 &&
            _totalUnits <= 90 &&
            (_cadence != GoalRepeatCadence.weekly || _weekdays.isNotEmpty) &&
            (_cadence != GoalRepeatCadence.monthly || _monthDays.isNotEmpty),
      ),
    ];
    final ordered = switch (_step) {
      _Step.configure =>
        !_stakeChosen
            ? <(GlobalKey, bool)>[]
            : switch (_stake) {
                _StakeChoice.photo => [
                  (_keyPhotoCircle, _circleId != null),
                  ...commitment,
                  (_keyPhotoUpload, _photo != null),
                ],
                _StakeChoice.h2h => [
                  (_keyH2hCircle, _circleId != null),
                  (_keyOpponent, _opponentUid != null),
                  (_keyYourCause, _charityId != null),
                  (_keyBothLose, _bothLoseCharityId != null),
                  ...commitment,
                ],
                _StakeChoice.money => [
                  (_keyAntiCharity, _antiCharityId != null),
                  ...commitment,
                ],
                _StakeChoice.practice => commitment,
              },
      _Step.promise => [
        (_keyWhy, _why.text.trim().isNotEmpty),
        if (_needsConsent) (_keyConsent, _consentValid),
      ],
      _Step.review => <(GlobalKey, bool)>[],
    };
    for (final (key, ok) in ordered) {
      if (!ok) return key;
    }
    return null;
  }

  /// Reveal the checklist and glide to the first missing field.
  void _revealMissing() {
    setState(() => _showChecklist = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _firstMissingKey()?.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    });
  }

  /// No card pre-selected: choosing WHAT'S on the line is the first act.
  bool _stakeChosen = false;

  /// Strictness selector: collapsed tile by default (Add-Task pattern);
  /// tap expands to the three mode cards.
  bool _modeExpanded = false;

  /// Stake picker after a choice: only the selected card shows; tapping
  /// it expands to all four (same pattern as strictness).
  bool _stakePickerExpanded = false;

  /// Requirements checklist (A+C combo, 2026-07-22): hidden until the
  /// user taps Continue while incomplete; then live-updates (green when
  /// satisfied) and disappears once everything is met. Reset per step.
  bool _showChecklist = false;

  // Commitment — goal-style sections (2026-07-22): the challenge mints a
  // real linked Goal, so it collects the same shape the goal editor does.
  late final TextEditingController _title = TextEditingController(
    text: widget.prefilledTitle ?? '',
  );
  late final TextEditingController _target = TextEditingController(text: '60');
  MeasurementKind _measurement = MeasurementKind.minutes;
  late DateTime _rangeStart = _todayDate();
  late DateTime _rangeEnd = _todayDate().add(const Duration(days: 6));
  GoalRepeatCadence _cadence = GoalRepeatCadence.daily;
  int _interval = 1;
  final Set<int> _weekdays = <int>{};
  final Set<int> _monthDays = <int>{};
  bool _reminderEnabled = false;
  int _reminderMinutesFromMidnight = 7 * 60;
  String _mode = 'disciplined';

  static DateTime _todayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String get _unitKind =>
      _measurement == MeasurementKind.minutes ? 'minutes' : 'count';
  int get _unitTarget => int.tryParse(_target.text.trim()) ?? 0;

  String get _cadenceStorage => switch (_cadence) {
    GoalRepeatCadence.weekly => 'weekly',
    GoalRepeatCadence.monthly => 'monthly',
    _ => 'daily',
  };

  /// Action days in the picked range — the challenge's unit space.
  int get _totalUnits => countChallengeActionDays(
    start: _rangeStart,
    end: _rangeEnd,
    cadence: _cadenceStorage,
    interval: _interval,
    scheduledWeekdays: _weekdays,
    repeatDaysOfMonth: _monthDays,
  );

  // Stake
  _StakeChoice _stake = _StakeChoice.photo;
  String? _circleId;
  XFile? _photo;
  int _revealWindowMins = 60;
  // h2h (D5/D6, M-4)
  String? _opponentUid;
  int _h2hStake = 100;
  String? _charityId;
  String? _bothLoseCharityId;
  // solo money ($-1) — SIMULATED provider until Stripe is live
  int _moneyCents = 2000;
  String? _antiCharityId;

  bool get _isPractice => _stake == _StakeChoice.practice;
  bool get _isH2h => _stake == _StakeChoice.h2h;
  bool get _isMoney => _stake == _StakeChoice.money;

  // Consent + pledge
  bool _consentIsMe = false;
  bool _consentPosting = false;
  bool _consentAdult = false;
  late final TextEditingController _why = TextEditingController();

  // Create
  bool _creating = false;
  String? _createError;

  @override
  void initState() {
    super.initState();
    _circleId = widget.prefilledCircleId;
    // Next-button validity depends on these fields; rebuild as they type.
    _title.addListener(_onFormChanged);
    _target.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    _why.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  /// Focused when the commitment fields first appear (Add-Task pattern:
  /// title ready to type, keyboard up).
  final FocusNode _titleFocus = FocusNode();

  // Category still leads (2026-07-17) — but it now absorbs ALL
  // configuration (2026-07-22): the chosen card expands into stake setup
  // + the full commitment. Consent lives on the promise page.
  List<_Step> get _steps => const [
    _Step.configure,
    _Step.promise,
    _Step.review,
  ];

  void _goBack() {
    final order = _steps;
    final i = order.indexOf(_step);
    if (i > 0) {
      setState(() {
        _step = order[i - 1];
        _showChecklist = false;
        _navForward = false;
      });
    }
  }

  void _goNext() {
    final order = _steps;
    final i = order.indexOf(_step);
    if (i < order.length - 1) {
      setState(() {
        _step = order[i + 1];
        _showChecklist = false;
        _navForward = true;
      });
    }
  }

  /// (label, satisfied) rows for the requirements checklist.
  List<(String, bool)> get _requirementItems => switch (_step) {
    _Step.configure => [
      if (!_stakeChosen)
        ('What\'s on the line', false)
      else ...[
        ...switch (_stake) {
          _StakeChoice.photo => [
            ('Circle', _circleId != null),
            ('The photo', _photo != null),
          ],
          _StakeChoice.h2h => [
            ('Circle', _circleId != null),
            ('Opponent', _opponentUid != null),
            ('Your cause', _charityId != null),
            ('Both-lose cause', _bothLoseCharityId != null),
          ],
          _StakeChoice.money => [('Anti-charity', _antiCharityId != null)],
          _StakeChoice.practice => <(String, bool)>[],
        },
        ('Title', _title.text.trim().isNotEmpty),
        ('Target', _unitTarget > 0),
        (
          'Action days',
          _totalUnits > 0 &&
              _totalUnits <= 90 &&
              (_cadence != GoalRepeatCadence.weekly || _weekdays.isNotEmpty) &&
              (_cadence != GoalRepeatCadence.monthly || _monthDays.isNotEmpty),
        ),
      ],
    ],
    _Step.promise => [
      ('Your why', _why.text.trim().isNotEmpty),
      if (_needsConsent) ('Consent boxes', _consentValid),
    ],
    _Step.review => const [],
  };

  /// Red-only (2026-07-22): satisfied items say nothing; only what still
  /// blocks Continue shows.
  Widget _requirementChecklist() {
    final missing = _requirementItems.where((item) => !item.$2).toList();
    if (missing.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          for (final (label, _) in missing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.coral.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _reqBadge(),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.coral,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Small circled '!' — sits next to a missing field's label once the
  /// user has tapped Continue (2026-07-22).
  Widget _reqBadge() {
    return Container(
      width: 15,
      height: 15,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.coral, width: 1.3),
      ),
      child: Text(
        '!',
        style: TextStyle(
          color: AppColors.coral,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }

  /// Badge for a section label's `trailing` slot; null while hidden.
  Widget? _reqTrailing(bool ok) => (_showChecklist && !ok) ? _reqBadge() : null;

  /// Micro label + optional requirement badge.
  Widget _microLabelReq(String text, bool ok) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _microLabel(text),
        if (_showChecklist && !ok) ...[const SizedBox(width: 6), _reqBadge()],
      ],
    );
  }

  int get _requiredUnits {
    final pct = switch (_mode) {
      'flexible' => 70,
      'extreme' => 100,
      _ => 85,
    };
    return ((_totalUnits * pct) + 99) ~/ 100;
  }

  int get _mercyTarget => (_unitTarget * 3 + 3) ~/ 4;

  bool get _commitmentValid =>
      _title.text.trim().isNotEmpty &&
      _unitTarget > 0 &&
      _totalUnits > 0 &&
      _totalUnits <= 90 &&
      (_cadence != GoalRepeatCadence.weekly || _weekdays.isNotEmpty) &&
      (_cadence != GoalRepeatCadence.monthly || _monthDays.isNotEmpty);

  bool get _stakeDetailsValid => switch (_stake) {
    _StakeChoice.practice => true,
    _StakeChoice.photo => _circleId != null && _photo != null,
    _StakeChoice.h2h =>
      _circleId != null &&
          _opponentUid != null &&
          _charityId != null &&
          _bothLoseCharityId != null,
    _StakeChoice.money => _antiCharityId != null,
  };

  bool get _needsConsent => _stake == _StakeChoice.photo || _isMoney;

  bool get _consentValid => !_needsConsent
      ? true
      : _isMoney
      ? _consentPosting && _consentAdult
      : _consentIsMe && _consentPosting && _consentAdult;

  bool get _stepValid => switch (_step) {
    _Step.configure => _stakeChosen && _stakeDetailsValid && _commitmentValid,
    _Step.promise => _why.text.trim().isNotEmpty && _consentValid,
    _Step.review => !_creating,
  };

  @override
  Widget build(BuildContext context) {
    final atFirstStep = _steps.indexOf(_step) == 0;
    return PopScope(
      canPop: atFirstStep,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const PageTitle('New Challenge'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (atFirstStep) {
                Navigator.of(context).pop();
              } else {
                _goBack();
              }
            },
          ),
        ),
        // Tap anywhere outside an input to drop the keyboard — same
        // shared affordance as the goal editor.
        body: KeyboardDismissOnTap(
          child: Column(
            children: [
              _StepDots(current: _steps.indexOf(_step), total: _steps.length),
              Expanded(
                child: ClipRect(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    // Pages slide horizontally in the direction of travel
                    // (2026-07-22): forward = new page in from the right.
                    transitionBuilder: (child, animation) {
                      final isIncoming = child.key == ValueKey(_step);
                      final fromRight = Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      );
                      final fromLeft = Tween<Offset>(
                        begin: const Offset(-1, 0),
                        end: Offset.zero,
                      );
                      final tween = _navForward
                          ? (isIncoming ? fromRight : fromLeft)
                          : (isIncoming ? fromLeft : fromRight);
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                    child: SingleChildScrollView(
                      key: ValueKey(_step),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: _buildStep(),
                    ),
                  ),
                ),
              ),
              SafeArea(
                minimum: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_showChecklist && !_stepValid) _requirementChecklist(),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: _step == _Step.promise
                          ? _HoldToCommitButton(
                              enabled: _stepValid,
                              onCommitted: () {
                                setState(_goNext);
                              },
                              onDisabledTap: _revealMissing,
                            )
                          : FilledButton(
                              // A+C combo: the button always answers a tap —
                              // incomplete taps reveal the checklist instead of
                              // silently doing nothing.
                              onPressed: _creating
                                  ? null
                                  : () {
                                      if (!_stepValid) {
                                        _revealMissing();
                                        return;
                                      }
                                      if (_step == _Step.review) {
                                        _create();
                                      } else {
                                        _goNext();
                                      }
                                    },
                              child: _creating
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _step == _Step.review
                                              ? 'Start the challenge'
                                              : 'Continue',
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          _step == _Step.review
                                              ? Icons.bolt_rounded
                                              : Icons.arrow_forward_rounded,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() => switch (_step) {
    _Step.configure => _configureStep(),
    _Step.promise => _promiseStep(),
    _Step.review => _reviewStep(),
  };

  // ─── Step: commitment ──────────────────────────────────────────────────────

  List<Widget> _commitmentFields() {
    return [
      KeyedSubtree(
        key: _keyTitle,
        child: GoalEditorSectionLabel(
          'Title',
          trailing: _reqTrailing(_title.text.trim().isNotEmpty),
        ),
      ),
      GoalEditorTextField(
        controller: _title,
        focusNode: _titleFocus,
        hintText: 'Read for my exams',
      ),
      const SizedBox(height: 16),
      KeyedSubtree(
        key: _keyTarget,
        child: GoalEditorSectionLabel(
          'Target',
          trailing: _reqTrailing(_unitTarget > 0),
        ),
      ),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: GoalEditorTextField(
                controller: _target,
                hintText: '60',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GoalEditorMeasurementDropdown(
                value: _measurement,
                onChanged: (m) => setState(() => _measurement = m),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Target (per action day)',
        style: TextStyle(color: AppColors.fg38, fontSize: 12),
      ),
      const SizedBox(height: 16),
      const GoalEditorSectionLabel('Duration'),
      GoalEditorDateCard(
        title:
            '${_formatRangeDay(_rangeStart)}  →  ${_formatRangeDay(_rangeEnd)}',
        subtitle: 'First day → last day · tap to change',
        onTap: _pickRange,
      ),
      const SizedBox(height: 16),
      KeyedSubtree(key: _keySchedule, child: const SizedBox.shrink()),
      GoalEditorSectionLabel(
        'Schedule',
        trailing: Text(
          'REPEATS',
          style: TextStyle(
            color: GoalEditorColors.lime,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ),
      GoalEditorRepeatToggle(
        selected: _cadence,
        onChanged: (c) {
          if (c == GoalRepeatCadence.off) {
            // A stake needs a rhythm to hold you to; Off is a passive
            // accumulate-whenever goal with nothing to measure daily.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Challenges need a rhythm — pick Daily, Weekly or '
                  'Monthly.',
                ),
              ),
            );
            return;
          }
          setState(() => _cadence = c);
        },
      ),
      const SizedBox(height: 8),
      if (_cadence == GoalRepeatCadence.weekly) ...[
        GoalEditorWeekdayPicker(
          selected: _weekdays,
          onDayToggled: (day) => setState(() {
            if (!_weekdays.remove(day)) _weekdays.add(day);
          }),
        ),
        const SizedBox(height: 12),
      ],
      if (_cadence == GoalRepeatCadence.monthly) ...[
        GoalEditorMonthDayPicker(
          selected: _monthDays,
          onChanged: (days) => setState(() {
            _monthDays
              ..clear()
              ..addAll(days);
          }),
        ),
        const SizedBox(height: 12),
      ],
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_cadence == GoalRepeatCadence.daily) ...[
            GoalEditorIntervalWheel(
              value: _interval,
              maxValue: 30,
              onChanged: (v) => setState(() => _interval = v),
              unitSingular: 'day',
              unitPlural: 'days',
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: GoalEditorReminderCard(
              compact: true,
              enabled: _reminderEnabled,
              timeLabel: _formatReminderTime(context),
              onToggle: (v) async {
                if (v) {
                  final ok = await ref
                      .read(localNotificationsServiceProvider)
                      .requestPermissionsIfNeeded();
                  if (!mounted) return;
                  if (!ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Allow notifications to get goal reminders.',
                        ),
                      ),
                    );
                  }
                }
                if (!mounted) return;
                setState(() => _reminderEnabled = v);
              },
              onPickTime: _pickReminderTime,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      ..._modeSection(),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.fg12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'You pass by hitting $_requiredUnits of $_totalUnits action '
          'days. A day counts from $_mercyTarget '
          '${_unitKind == 'minutes' ? 'min' : ''} — '
          'a 25% mercy for timer slips.',
          style: TextStyle(
            color: AppColors.textSoft,
            fontSize: 12.5,
            height: 1.45,
          ),
        ),
      ),
    ];
  }

  static const _modeSpecs = [
    ('flexible', 'Flexible', 'Pass 70% of action days'),
    ('disciplined', 'Disciplined', 'Pass 85% of action days'),
    ('extreme', 'Extreme', 'Every action day. No excuses'),
  ];

  /// Strictness as a collapsed tile (Add-Task pattern, 2026-07-22):
  /// shows the current pick + its pass-rule; tap to expand into the three
  /// compact mode cards, picking collapses back.
  List<Widget> _modeSection() {
    final current = _modeSpecs.firstWhere((s) => s.$1 == _mode);
    return [
      _microLabel('STRICTNESS'),
      const SizedBox(height: 8),
      if (!_modeExpanded)
        Material(
          color: AppColors.inkCard,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _modeExpanded = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.fg12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          current.$2,
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          current.$3,
                          style: TextStyle(
                            color: AppColors.textSoft,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    color: AppColors.textSoft,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        )
      else
        for (final (id, title, sub) in _modeSpecs)
          _modeCard(id, title, sub, compact: true),
    ];
  }

  String _formatRangeDay(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _pickRange() async {
    final today = _todayDate();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 150)),
      initialDateRange: DateTimeRange(start: _rangeStart, end: _rangeEnd),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _rangeStart = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
      );
      _rangeEnd = DateTime(picked.end.year, picked.end.month, picked.end.day);
    });
  }

  String _formatReminderTime(BuildContext context) {
    final t = TimeOfDay(
      hour: _reminderMinutesFromMidnight ~/ 60,
      minute: _reminderMinutesFromMidnight % 60,
    );
    return t.format(context);
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _reminderMinutesFromMidnight ~/ 60,
        minute: _reminderMinutesFromMidnight % 60,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _reminderMinutesFromMidnight = picked.hour * 60 + picked.minute;
      _reminderEnabled = true;
    });
  }

  // ─── Step: stake ───────────────────────────────────────────────────────────

  /// (icon, color, title, subtitle) per stake — one source for the full
  /// cards, the docked header, and the compact switch pills.
  (IconData, Color, String, String) _cardSpec(_StakeChoice c) => switch (c) {
    _StakeChoice.photo => (
      Icons.photo_camera_rounded,
      AppColors.coral,
      'Photo stake',
      'An embarrassing photo of you. Fail and it posts to your circle.',
    ),
    _StakeChoice.h2h => (
      Icons.sports_kabaddi_rounded,
      AppColors.amber,
      'Challenge a friend',
      'Both stake points. The loser\'s points fund the winner\'s cause.',
    ),
    _StakeChoice.money => (
      Icons.attach_money_rounded,
      AppColors.statusGreen,
      'Money stake (simulated)',
      'Fail and it\'s donated to a cause you can\'t stand. No real '
          'money until Stripe is live.',
    ),
    _StakeChoice.practice => (
      Icons.school_rounded,
      AppColors.textSoft,
      'Practice run',
      'No stake — learn the loop first.',
    ),
  };

  // $ — money is debug-only until Stripe activates (Phase 3 runbook);
  // the server rail is the SIMULATED provider either way.
  List<_StakeChoice> get _availableStakes => [
    _StakeChoice.photo,
    _StakeChoice.h2h,
    if (kDebugMode) _StakeChoice.money,
    _StakeChoice.practice,
  ];

  void _pickStake(_StakeChoice c) {
    setState(() {
      _stake = c;
      _stakeChosen = true;
      _stakePickerExpanded = false;
    });
    // Title ready to type the moment the fields land (Add-Task pattern) —
    // but never steal focus over text the user already entered.
    if (_title.text.trim().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _titleFocus.requestFocus();
      });
    }
  }

  /// Page 1 of 3 (2026-07-22): pick WHAT'S on the line; the chosen card
  /// animates to the top (others collapse away) and its configuration
  /// slides in beneath. Switching cards preserves typed state.
  ///
  /// Structure note: only the STAKE-SPECIFIC config lives inside the
  /// cross-fade switcher — the commitment block holds GlobalKey scroll
  /// targets, and a switcher briefly mounts old+new children, which would
  /// duplicate those keys and crash.
  Widget _configureStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Choose your accountability'),
        const SizedBox(height: 12),
        // All four cards stay in the tree; hiding via AnimatedSize makes
        // the chosen card glide up as the ones above it collapse.
        for (final c in _availableStakes)
          Builder(
            builder: (_) {
              final visible =
                  !_stakeChosen || _stakePickerExpanded || c == _stake;
              final (icon, color, title, subtitle) = _cardSpec(c);
              return AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: !visible
                    ? const SizedBox(width: double.infinity)
                    : _stakeChoiceCard(
                        selected: _stakeChosen && c == _stake,
                        icon: icon,
                        iconColor: color,
                        title: title,
                        subtitle: subtitle,
                        onTap: () {
                          if (!_stakeChosen || _stakePickerExpanded) {
                            _pickStake(c);
                          } else {
                            setState(() => _stakePickerExpanded = true);
                          }
                        },
                        trailing:
                            (_stakeChosen &&
                                !_stakePickerExpanded &&
                                c == _stake)
                            ? Icon(
                                Icons.expand_more_rounded,
                                color: AppColors.textSoft,
                                size: 20,
                              )
                            : null,
                      ),
              );
            },
          ),
        // Stake-specific config cross-fades per stake (per-stake keys only).
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0, 0.04), end: Offset.zero),
              ),
              child: child,
            ),
          ),
          child: !_stakeChosen
              ? const SizedBox.shrink()
              : Column(
                  key: ValueKey(_stake),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 22),
                    ..._stakeConfigFields(),
                  ],
                ),
        ),
        // Commitment block appears once (stable subtree — GlobalKeys
        // inside must never be duplicated by a switcher).
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !_stakeChosen
              ? const SizedBox(width: double.infinity)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 22),
                    const SectionHeader('The commitment'),
                    const SizedBox(height: 12),
                    ..._commitmentFields(),
                  ],
                ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !(_stakeChosen && _stake == _StakeChoice.photo)
              ? const SizedBox(width: double.infinity)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 22),
                    KeyedSubtree(
                      key: _keyPhotoUpload,
                      child: _photoUploadTile(),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  /// Type-specific setup, now that the category and commitment are known.
  /// Per-stake configuration inside the expanded card (2026-07-22):
  /// dropdown-first, compact. Practice needs nothing.
  List<Widget> _stakeConfigFields() {
    return switch (_stake) {
      _StakeChoice.practice => const [],
      _StakeChoice.photo => _photoConfigFields(),
      _StakeChoice.h2h => _h2hFields(),
      _StakeChoice.money => _moneyFields(),
    };
  }

  List<Widget> _photoConfigFields() {
    final circlesAsync = ref.watch(myCirclesProvider);
    final circles = circlesAsync.value ?? const [];
    final revealDropdown = _dropdown<int>(
      hint: 'Window',
      value: _revealWindowMins,
      items: const [
        (5, '5 min'),
        (30, '30 min'),
        (60, '1 hour'),
        (180, '3 hours'),
        (720, '12 hours'),
        (1440, '24 hours'),
      ],
      onChanged: (v) => setState(() => _revealWindowMins = v ?? 60),
    );
    final autoDeleteTag = Align(
      alignment: Alignment.centerRight,
      child: Text(
        'THEN IT AUTO-DELETES',
        style: TextStyle(
          color: AppColors.cyan,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
    if (circlesAsync.isLoading) {
      return [const LinearProgressIndicator()];
    }
    if (circles.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'A photo stake needs a circle to post to. Join one in '
            'Community first — or start with a practice run.',
            style: TextStyle(color: AppColors.textSoft, fontSize: 12.5),
          ),
        ),
        const SizedBox(height: 16),
        _microLabel('REVEAL WINDOW'),
        const SizedBox(height: 8),
        revealDropdown,
        const SizedBox(height: 6),
        autoDeleteTag,
      ];
    }
    // POSTS TO and REVEAL side by side, ~65/35 (2026-07-22).
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 65,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KeyedSubtree(
                  key: _keyPhotoCircle,
                  child: _microLabelReq('POSTS TO', _circleId != null),
                ),
                const SizedBox(height: 8),
                _dropdown<String>(
                  hint: 'Pick a circle',
                  value: _circleId,
                  items: [for (final c in circles) (c.id, c.name)],
                  onChanged: (v) => setState(() => _circleId = v),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 35,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _microLabel('REVEAL'),
                const SizedBox(height: 8),
                revealDropdown,
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      autoDeleteTag,
    ];
  }

  /// Goal-editor-styled dropdown, shared by every picker on the
  /// configure page (2026-07-22).
  Widget _dropdown<T>({
    required String hint,
    required T? value,
    required List<(T, String)> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: AppColors.inkCard,
      borderRadius: BorderRadius.circular(16),
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
      icon: Icon(Icons.expand_more_rounded, color: AppColors.textSoft),
      decoration: goalEditorInputDecoration(hintText: hint),
      items: [
        for (final (v, label) in items)
          DropdownMenuItem(
            value: v,
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }

  /// The collateral, last (2026-07-22): a compact coral tile that only
  /// grows once a photo is attached.
  Widget _photoUploadTile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'THE PHOTO',
              style: TextStyle(
                color: AppColors.coral,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '— HIGH RISK',
              style: TextStyle(
                color: AppColors.coral.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
              ),
            ),
            if (_showChecklist && _photo == null) ...[
              const SizedBox(width: 6),
              _reqBadge(),
            ],
            const Spacer(),
            Icon(Icons.priority_high_rounded, color: AppColors.coral, size: 14),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.coral.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.coral.withValues(alpha: 0.45),
                width: 1.4,
              ),
            ),
            child: _photo == null
                ? InkWell(
                    onTap: _pickPhoto,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            color: AppColors.textSoft,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Choose the photo you\'d hate them to see',
                              style: TextStyle(
                                color: AppColors.textSoft,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textFaint,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: _pickPhoto,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_photo!.path),
                                width: double.infinity,
                                height: 140,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => _photo = null),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.coral,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.black,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This photo posts to your selected circle '
                        'automatically if you fail.',
                        style: TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  /// h2h fields (D5/D6): opponent, stake size, and the two charity picks.
  List<Widget> _h2hFields() {
    final circlesAsync = ref.watch(myCirclesProvider);
    final circles = circlesAsync.value ?? const [];
    final charitiesAsync = ref.watch(charitiesProvider);
    final balance = ref.watch(pointsBalanceProvider).valueOrNull ?? 0;
    final myUid = FirestorePaths.activeUid;

    return [
      if (circlesAsync.isLoading)
        const LinearProgressIndicator()
      else if (circles.isEmpty)
        Text(
          'Join a circle first — challenges live inside one.',
          style: TextStyle(color: AppColors.textSoft, fontSize: 12.5),
        )
      else
        // CIRCLE and POINTS side by side, ~65/35 (2026-07-22).
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 65,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KeyedSubtree(
                    key: _keyH2hCircle,
                    child: _microLabelReq('CIRCLE', _circleId != null),
                  ),
                  const SizedBox(height: 8),
                  _dropdown<String>(
                    hint: 'Pick a circle',
                    value: _circleId,
                    items: [for (final c in circles) (c.id, c.name)],
                    onChanged: (v) => setState(() {
                      _circleId = v;
                      _opponentUid = null; // circle changed, re-pick
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 35,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _microLabel('POINTS EACH'),
                  const SizedBox(height: 8),
                  _dropdown<int>(
                    hint: 'Points',
                    value: _h2hStake,
                    items: const [
                      (100, '100'),
                      (200, '200'),
                      (300, '300'),
                      (500, '500'),
                    ],
                    onChanged: (v) => setState(() => _h2hStake = v ?? 100),
                  ),
                ],
              ),
            ),
          ],
        ),
      if (balance < _h2hStake)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'You have $balance points — earn more before staking $_h2hStake.',
            style: TextStyle(color: AppColors.amber, fontSize: 12),
          ),
        ),
      if (_circleId != null) ...[
        const SizedBox(height: 16),
        KeyedSubtree(
          key: _keyOpponent,
          child: _microLabelReq('OPPONENT', _opponentUid != null),
        ),
        const SizedBox(height: 8),
        ref
            .watch(circleMembersProvider(_circleId!))
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(
                'Could not load members',
                style: TextStyle(color: AppColors.danger),
              ),
              data: (members) {
                final others = members.where((m) => m.userId != myUid).toList();
                if (others.isEmpty) {
                  return Text(
                    'Nobody else in this circle yet.',
                    style: TextStyle(color: AppColors.textSoft, fontSize: 12.5),
                  );
                }
                return _dropdown<String>(
                  hint: 'Pick your opponent',
                  value: _opponentUid,
                  items: [
                    for (final m in others)
                      (
                        m.userId,
                        m.displayName.isEmpty ? 'Member' : m.displayName,
                      ),
                  ],
                  onChanged: (v) => setState(() => _opponentUid = v),
                );
              },
            ),
      ],
      const SizedBox(height: 16),
      KeyedSubtree(
        key: _keyYourCause,
        child: _microLabelReq(
          'IF YOU WIN, THEIR POINTS FUND',
          _charityId != null,
        ),
      ),
      const SizedBox(height: 8),
      _charityDropdown(
        charitiesAsync,
        hint: 'Pick your cause',
        value: _charityId,
        onPick: (id) => setState(() => _charityId = id),
      ),
      const SizedBox(height: 16),
      KeyedSubtree(
        key: _keyBothLose,
        child: _microLabelReq(
          'IF YOU BOTH LOSE, EVERYTHING GOES TO',
          _bothLoseCharityId != null,
        ),
      ),
      const SizedBox(height: 8),
      _charityDropdown(
        charitiesAsync,
        hint: 'Neutral ground',
        value: _bothLoseCharityId,
        onPick: (id) => setState(() => _bothLoseCharityId = id),
      ),
    ];
  }

  List<Widget> _moneyFields() {
    final charitiesAsync = ref.watch(charitiesProvider);
    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.amber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
        ),
        child: Text(
          'SIMULATED — no card is charged and no real money moves. The full '
          'flow runs so it\'s real the day Stripe goes live.',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const SizedBox(height: 16),
      _microLabel('ON THE LINE'),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (label, cents) in const [
            ('\$5', 500),
            ('\$10', 1000),
            ('\$20', 2000),
            ('\$50', 5000),
          ])
            _choiceChip(
              label,
              _moneyCents == cents,
              () => setState(() => _moneyCents = cents),
            ),
        ],
      ),
      const SizedBox(height: 16),
      KeyedSubtree(
        key: _keyAntiCharity,
        child: _microLabelReq('IF YOU FAIL, IT FUNDS', _antiCharityId != null),
      ),
      const SizedBox(height: 8),
      Text(
        'Pick the one that hurts — that\'s the point.',
        style: TextStyle(color: AppColors.textSoft, fontSize: 12),
      ),
      const SizedBox(height: 8),
      _charityDropdown(
        charitiesAsync,
        hint: 'Pick your anti-charity',
        value: _antiCharityId,
        onPick: (id) => setState(() => _antiCharityId = id),
      ),
    ];
  }

  Widget _charityDropdown(
    AsyncValue<List<Charity>> charitiesAsync, {
    required String hint,
    required String? value,
    required ValueChanged<String?> onPick,
  }) {
    return charitiesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text(
        'Could not load charities',
        style: TextStyle(color: AppColors.danger),
      ),
      data: (charities) => charities.isEmpty
          ? Text(
              'The charity list hasn\'t synced yet — check your connection.',
              style: TextStyle(color: AppColors.textSoft, fontSize: 12.5),
            )
          : _dropdown<String>(
              hint: hint,
              value: value,
              items: [for (final c in charities) (c.id, c.name)],
              onChanged: onPick,
            ),
    );
  }

  bool _pickingPhoto = false;

  Future<void> _pickPhoto() async {
    // Double-tapping the tile before iOS presents the picker fires a
    // second request that cancels the first with
    // PlatformException(multiple_request) — guard + swallow that case.
    if (_pickingPhoto) return;
    _pickingPhoto = true;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked != null && mounted) setState(() => _photo = picked);
    } on PlatformException catch (e) {
      if (e.code != 'multiple_request') rethrow;
    } finally {
      _pickingPhoto = false;
    }
  }

  // ─── Step: consent (P-1 — explicit, in-flow, not ToS) ─────────────────────

  /// Consent lives on the promise page (2026-07-22, photo/money only).
  /// "Before you commit" is the human framing; the card keeps its full
  /// severity — it is the P-1 consent artifact.
  List<Widget> _consentBlock() {
    if (!_needsConsent) return const [];
    if (_isMoney) {
      final charities = ref.watch(charitiesProvider).valueOrNull ?? const [];
      final charity = charities
          .where((c) => c.id == _antiCharityId)
          .firstOrNull;
      final amount = '\$${(_moneyCents / 100).toStringAsFixed(0)}';
      return [
        KeyedSubtree(
          key: _keyConsent,
          child: const SectionHeader('Before you commit'),
        ),
        const SizedBox(height: 12),
        _consentWarningCard(
          headerLabel: 'MONEY — NO MERCY',
          body: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'If you fail '),
                _consentStrong(_title.text.trim()),
                const TextSpan(text: ' by the deadline, '),
                _consentStrong(amount),
                const TextSpan(text: ' will be donated to '),
                _consentStrong(charity?.name ?? 'your chosen recipient'),
                const TextSpan(
                  text:
                      '. There is NO mercy veto on money — if you lose, '
                      'you lose.\n\nKeep your word and every cent comes back '
                      'to you.\n\n(Simulated build: no card is charged yet.)',
                ),
              ],
            ),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15.5,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _bigCheck(
          'I understand the money is donated if I fail — no undo',
          _consentPosting,
          (v) => setState(() => _consentPosting = v),
        ),
        _bigCheck(
          'I am 18 or older',
          _consentAdult,
          (v) => setState(() => _consentAdult = v),
        ),
      ];
    }
    final circles = ref.watch(myCirclesProvider).value ?? const [];
    final circle = circles.where((c) => c.id == _circleId).firstOrNull;
    final circleName = circle?.name ?? 'your circle';
    final members = circle?.memberCount ?? 0;
    final window = _revealWindowLabel(_revealWindowMins);
    return [
      KeyedSubtree(
        key: _keyConsent,
        child: const SectionHeader('Before you commit'),
      ),
      const SizedBox(height: 12),
      _consentWarningCard(
        headerLabel: 'STAKE — NO UNDO',
        body: Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'If you fail '),
              _consentStrong(_title.text.trim()),
              const TextSpan(
                text: ' by the deadline, this photo will be posted to ',
              ),
              _consentStrong(circleName),
              const TextSpan(text: ' and visible to its '),
              _consentStrong('$members members'),
              const TextSpan(text: ' for '),
              _consentStrong(window),
              const TextSpan(text: '.'),
            ],
          ),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15.5,
            height: 1.55,
          ),
        ),
      ),
      const SizedBox(height: 20),
      _bigCheck(
        'This is a photo of me',
        _consentIsMe,
        (v) => setState(() => _consentIsMe = v),
      ),
      _bigCheck(
        'I understand it will be posted if I fail',
        _consentPosting,
        (v) => setState(() => _consentPosting = v),
      ),
      // P-9 — photo stakes are 18+ (17+ App Store rating is the other
      // layer; this is the in-flow attestation).
      _bigCheck(
        'I am 18 or older',
        _consentAdult,
        (v) => setState(() => _consentAdult = v),
      ),
    ];
  }

  /// Review summary card: tonal, rounded-24; [tint] adds the risk framing
  /// (Stitch redesign 2026-07-22).
  Widget _reviewCard({
    required String label,
    required Widget child,
    Color? tint,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint != null ? tint.withValues(alpha: 0.07) : AppColors.inkCard,
        borderRadius: BorderRadius.circular(24),
        border: tint != null
            ? Border.all(color: tint.withValues(alpha: 0.35))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: tint ?? AppColors.textFaint,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  TextSpan _consentStrong(String text) => TextSpan(
    text: text,
    style: const TextStyle(
      fontWeight: FontWeight.w800,
      decoration: TextDecoration.underline,
    ),
  );

  /// The coral disclosure card with the icon chip and the nested
  /// "server decides" sub-card (Stitch redesign 2026-07-22).
  Widget _consentWarningCard({
    required String headerLabel,
    required Widget body,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.coral.withValues(alpha: 0.08),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.coral.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.coral,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                headerLabel,
                style: TextStyle(
                  color: AppColors.coral,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          body,
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.inkCard.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THE SERVER DECIDES — ALWAYS',
                  style: TextStyle(
                    color: AppColors.coral,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Going offline, deleting the app, or missing the moment '
                  'does not stop it.',
                  style: TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step: pledge (PSY-1) ──────────────────────────────────────────────────

  /// Page 2 of 3 (2026-07-22): write WHY → read the consequences →
  /// check the boxes → hold. The strongest screen in the flow.
  Widget _promiseStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        Center(
          child: Text(
            'THE PLEDGE',
            style: TextStyle(
              color: AppColors.cyan,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _stepHeadline(
          lead: 'WHY DOES THIS',
          emphasis: 'MATTER?',
          emphasisColor: AppColors.accent,
          centered: true,
        ),
        const SizedBox(height: 14),
        Text(
          'You\'ll see these words every time you log a day.\n'
          'Make them yours.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 14.5,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          key: _keyWhy,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          decoration: BoxDecoration(
            color: AppColors.inkCard,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.fg12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _why,
                maxLength: 280,
                maxLines: 5,
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.5,
                ),
                decoration: const InputDecoration(
                  hintText: 'So I stop failing exams I could pass…',
                  counterText: '',
                  border: InputBorder.none,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.textFaint,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'YOUR WHY',
                    style: TextStyle(
                      color: AppColors.textFaint,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                  if (_showChecklist && _why.text.trim().isEmpty) ...[
                    const SizedBox(width: 6),
                    _reqBadge(),
                  ],
                  const Spacer(),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${_why.text.length}',
                          style: TextStyle(
                            color: _why.text.isEmpty
                                ? AppColors.textFaint
                                : AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(text: ' / 280'),
                      ],
                    ),
                    style: TextStyle(color: AppColors.textFaint, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_needsConsent) ...[
          const SizedBox(height: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _consentBlock(),
          ),
        ],
        const SizedBox(height: 14),
        Center(
          child: Text(
            'Hold the button to give your word.',
            style: TextStyle(color: AppColors.textSoft, fontSize: 12.5),
          ),
        ),
      ],
    );
  }

  // ─── Step: review + create ─────────────────────────────────────────────────

  Widget _reviewStep() {
    // Stake card content per type: (header label, headline, sub-line, tint).
    final (stakeLabel, stakeHeadline, stakeSub, stakeTint) = switch (_stake) {
      _StakeChoice.photo => (
        'STAKE — CRITICAL RISK',
        'Embarrassing photo',
        '${_revealWindowLabel(_revealWindowMins).toUpperCase()} PUBLIC '
            'REVEAL',
        AppColors.coral,
      ),
      _StakeChoice.h2h => (
        'STAKE — POINTS DUEL',
        '$_h2hStake points each',
        'LOCKED WHEN THEY ACCEPT · THEY SEE "${_mode.toUpperCase()}" FIRST',
        AppColors.amber,
      ),
      _StakeChoice.money => (
        'STAKE — REAL MONEY (SIMULATED)',
        '\$${(_moneyCents / 100).toStringAsFixed(0)} on the line',
        'CHARGED AT START · REFUNDED IF YOU PASS',
        AppColors.coral,
      ),
      _StakeChoice.practice => (
        'PRACTICE RUN',
        'Nothing on the line',
        'LEARN THE LOOP SAFELY',
        AppColors.textFaint,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeadline(
          lead: 'LOOK IT IN',
          emphasis: 'THE EYE',
          emphasisColor: AppColors.textPrimary,
          subline: 'Final check of what you\'re signing',
        ),
        const SizedBox(height: 18),
        _reviewCard(
          label: 'COMMITMENT',
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _title.text.trim(),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
              Icon(Icons.bolt_rounded, color: AppColors.accent, size: 22),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _reviewCard(
          label: 'TARGET',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$_unitTarget${_unitKind == 'minutes' ? ' min' : '×'} '
                      'a day, $_totalUnits action days',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _mode.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.textSoft,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Required threshold: pass $_requiredUnits',
                    style: TextStyle(color: AppColors.textSoft, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _reviewCard(
          label: stakeLabel,
          tint: stakeTint,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      stakeHeadline,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (_stake == _StakeChoice.photo ||
                      _stake == _StakeChoice.money)
                    Icon(
                      Icons.warning_amber_rounded,
                      color: stakeTint.withValues(alpha: 0.7),
                      size: 26,
                    ),
                ],
              ),
              // Look THIS in the eye: the actual photo on the line.
              if (_stake == _StakeChoice.photo && _photo != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(_photo!.path),
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                stakeSub,
                style: TextStyle(
                  color: stakeTint,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _reviewCard(
          label: 'YOUR WORD',
          child: Text(
            '"${_why.text.trim()}"',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.5,
              fontStyle: FontStyle.italic,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_createError != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _createError!,
              style: TextStyle(color: AppColors.danger, fontSize: 12.5),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _create() async {
    setState(() {
      _creating = true;
      _createError = null;
    });

    final functions = ref.read(stakeFunctionsProvider);
    final repository = ref.read(stakesRepositoryProvider);
    final uid = FirestorePaths.activeUid;
    final now = DateTime.now();

    // Free-tier monthly photo-stake quota — polite pre-check against the
    // local mirror; stakeCreateChallenge enforces the same rule
    // authoritatively server-side. Only activated challenges count
    // (draft/cancelled don't consume an allowance).
    if (_stake == _StakeChoice.photo) {
      final tierGate = ref.read(tierGateProvider);
      if (!tierGate.isBypassed) {
        final challenges =
            ref.read(stakeChallengesStreamProvider).value ??
            const <StakeChallenge>[];
        final monthStartMs = DateTime(
          now.year,
          now.month,
        ).millisecondsSinceEpoch;
        final usedThisMonth = challenges
            .where(
              (c) =>
                  c.type == StakeChallengeType.soloPhoto &&
                  c.createdAtMs >= monthStartMs &&
                  c.status != StakeChallengeStatus.draft &&
                  c.status != StakeChallengeStatus.cancelled,
            )
            .length;
        if (!tierGate.canCreatePhotoStakeThisMonth(usedThisMonth)) {
          setState(() {
            _creating = false;
            _createError =
                'The free plan includes '
                '${tierGate.limits.freePhotoStakesPerMonth} photo stakes per '
                'month — the counter resets on the 1st. SidePal Pro removes '
                'the limit.';
          });
          return;
        }
      }
    }
    // Free-tier goal cap: the commitment mints a real Goal, so the same
    // creation gate the goal editor enforces applies here.
    final goalGate = ref.read(tierGateProvider);
    if (!goalGate.isBypassed) {
      final goals = await ref.read(goalsRepositoryProvider).fetchGoalsOnce();
      final activeCount = goals
          .where((g) => g.status == GoalStatus.active)
          .length;
      if (!goalGate.canCreateGoal(activeCount)) {
        setState(() => _creating = false);
        if (mounted) {
          await showTierLimitSheet(
            context,
            title: 'Goal limit reached',
            message:
                'This challenge creates a goal, and the free plan includes '
                '${goalGate.limits.freeGoals} active goals. Finish or '
                'archive one, or let SidePal Pro remove the limit.',
          );
        }
        return;
      }
    }

    // Day 0 = the picked start date (may be in the future, 2026-07-22);
    // deadline = end of the picked last day.
    final startDateMs = _rangeStart.millisecondsSinceEpoch;
    var deadline = DateTime(
      _rangeEnd.year,
      _rangeEnd.month,
      _rangeEnd.day + 1,
    ).millisecondsSinceEpoch;
    // Server requires deadline ≥ now + 1h; a 1-day challenge started late
    // at night still gets a real runway.
    final minDeadline = now
        .add(const Duration(hours: 2))
        .millisecondsSinceEpoch;
    if (deadline < minDeadline) deadline = minDeadline;

    final id = StableId.generate('stk');
    final goalId = StableId.generate('goal');
    final type = switch (_stake) {
      _StakeChoice.photo => 'solo_photo',
      _StakeChoice.h2h => 'h2h_points',
      _StakeChoice.money => 'solo_money',
      _StakeChoice.practice => 'practice',
    };

    try {
      Map<String, dynamic>? photoPayload;
      if (_stake == _StakeChoice.photo) {
        final storagePath = 'stake_photos/$id/$uid.jpg';
        // Owner-only path (storage.rules); the server verifies this exact
        // layout in stakeCreateChallenge.
        await FirebaseStorage.instance
            .ref(storagePath)
            .putFile(
              File(_photo!.path),
              SettableMetadata(contentType: 'image/jpeg'),
            );
        photoPayload = {
          'storagePath': storagePath,
          'revealWindowMins': _revealWindowMins,
        };
      }

      await functions.createChallenge(
        challengeId: id,
        type: type,
        circleId: _isPractice ? '' : (_circleId ?? ''),
        goal: {
          'title': _title.text.trim(),
          'unitKind': _unitKind,
          'unitTarget': _unitTarget,
          'totalUnits': _totalUnits,
          'cadence': _cadenceStorage,
          if (_cadence == GoalRepeatCadence.daily) 'interval': _interval,
          if (_cadence == GoalRepeatCadence.weekly)
            'scheduledWeekdays': (_weekdays.toList()..sort()),
          if (_cadence == GoalRepeatCadence.monthly)
            'repeatDaysOfMonth': (_monthDays.toList()..sort()),
          'startDateMs': startDateMs,
          'linkedGoalId': goalId,
        },
        mode: _mode,
        deadlineMs: deadline,
        photo: photoPayload,
        opponentUid: _isH2h ? _opponentUid : null,
        stakeAmount: _isH2h ? _h2hStake : null,
        charityId: _isH2h ? _charityId : null,
        bothLoseCharityId: _isH2h ? _bothLoseCharityId : null,
        amountCents: _isMoney ? _moneyCents : null,
        antiCharityId: _isMoney ? _antiCharityId : null,
        pledgeWhy: _why.text.trim(),
      );

      // The commitment IS a real goal (2026-07-22): it lands in the Goals
      // hub with the staked badge, its reminders ride the goal reminder
      // machinery, and the challenge above froze its snapshot. Local-first
      // write, after the callable so a failed create leaves no stray goal.
      final bounds = GoalPeriodHelpers.localDayRangeBounds(
        _rangeStart,
        _rangeEnd,
      );
      final goalNowMs = DateTime.now().millisecondsSinceEpoch;
      final linkedGoal = UserGoal(
        id: goalId,
        title: _title.text.trim(),
        categoryId: GoalCategories.habits,
        status: GoalStatus.active,
        measurementKind: _measurement,
        targetValue: _unitTarget.toDouble(),
        // Strictness maps to intensity so analytics weighting follows it.
        intensity: switch (_mode) {
          'flexible' => 2,
          'extreme' => 5,
          _ => 3,
        },
        periodStartMs: bounds.startMs,
        periodEndMs: bounds.endMs,
        periodMode: GoalPeriodMode.calendar,
        repeatCadence: _cadence,
        repeatInterval: _cadence == GoalRepeatCadence.daily ? _interval : 1,
        scheduledWeekdays: _cadence == GoalRepeatCadence.weekly
            ? (_weekdays.toList()..sort())
            : null,
        repeatDaysOfMonth: _cadence == GoalRepeatCadence.monthly
            ? (_monthDays.toList()..sort())
            : null,
        reminderEnabled: _reminderEnabled,
        reminderMinutesFromMidnight: _reminderEnabled
            ? _reminderMinutesFromMidnight
            : null,
        createdAtMs: goalNowMs,
        updatedAtMs: goalNowMs,
      );
      await ref.read(goalsRepositoryProvider).upsertGoal(linkedGoal);
      await ref.read(goalReminderSyncServiceProvider).applyForGoal(linkedGoal);

      // Optimistic local mirror so the challenge renders before the next
      // background pull (which LWW-overwrites with server truth).
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await repository.upsertLocalMirror(
        StakeChallenge(
          id: id,
          type: switch (_stake) {
            _StakeChoice.photo => StakeChallengeType.soloPhoto,
            _StakeChoice.h2h => StakeChallengeType.h2hPoints,
            _StakeChoice.money => StakeChallengeType.soloMoney,
            _StakeChoice.practice => StakeChallengeType.practice,
          },
          status: switch (_stake) {
            _StakeChoice.photo => StakeChallengeStatus.draft,
            _StakeChoice.h2h => StakeChallengeStatus.pendingAccept,
            _StakeChoice.money ||
            _StakeChoice.practice => StakeChallengeStatus.active,
          },
          creatorUid: uid,
          circleId: (_isPractice || _isMoney) ? '' : (_circleId ?? ''),
          participants: [
            StakeParticipant(
              uid: uid,
              teamId: uid,
              stakeKind: switch (_stake) {
                _StakeChoice.photo => 'photo',
                _StakeChoice.money => 'money',
                _ => 'points',
              },
              stakeAmount: _isH2h
                  ? _h2hStake
                  : _isMoney
                  ? _moneyCents
                  : null,
              photoStoragePath: _stake == _StakeChoice.photo
                  ? 'stake_photos/$id/$uid.jpg'
                  : null,
              revealWindowMins: _stake == _StakeChoice.photo
                  ? _revealWindowMins
                  : null,
              accepted: true,
            ),
            if (_isH2h && _opponentUid != null)
              StakeParticipant(
                uid: _opponentUid!,
                teamId: _opponentUid!,
                stakeKind: 'points',
                stakeAmount: _h2hStake,
                accepted: false,
              ),
          ],
          frozenGoal: StakeFrozenGoal(
            title: _title.text.trim(),
            unitKind: _unitKind,
            unitTarget: _unitTarget,
            totalUnits: _totalUnits,
            cadence: _cadenceStorage,
            interval: _interval,
            scheduledWeekdays: _cadence == GoalRepeatCadence.weekly
                ? (_weekdays.toList()..sort())
                : null,
            repeatDaysOfMonth: _cadence == GoalRepeatCadence.monthly
                ? (_monthDays.toList()..sort())
                : null,
            startDateMs: startDateMs,
            linkedGoalId: goalId,
          ),
          mode: _mode,
          sideCharities: _isH2h && _charityId != null
              ? {uid: _charityId!}
              : const {},
          bothLoseCharityId: _isH2h ? _bothLoseCharityId : null,
          antiCharityId: _isMoney ? _antiCharityId : null,
          deadlineMs: deadline,
          photoState: _stake == _StakeChoice.photo
              ? StakePhotoState.pendingScreen
              : null,
          createdAtMs: nowMs,
          // NOT the client clock: a phone running seconds ahead of the
          // server would make this optimistic row "newer" than the real
          // server writes, and LWW would reject every later flip (the
          // photo-screen result only appeared after a logout wipe).
          // 0 = "placeholder, first server echo replaces me".
          updatedAtMs: 0,
        ),
      );

      if (!mounted) return;
      final nav = Navigator.of(context);
      nav.pop();
      if (_stake == _StakeChoice.photo && _photo != null) {
        // Seed the owner's preview cache — the detail screen then shows
        // the photo instantly instead of re-downloading it (slow links
        // made the preview take minutes).
        unawaited(StakePhotoCache.seed(id, File(_photo!.path)));
      }
      nav.push(
        MaterialPageRoute(
          builder: (_) => StakeChallengeDetailScreen(challengeId: id),
        ),
      );
    } on StakeActionException catch (e) {
      final photoRejected =
          e.code == 'failed-precondition' &&
          e.message.toLowerCase().contains('rejected');
      setState(() {
        _creating = false;
        if (photoRejected) {
          // Content screening said no. Re-pressing the button would just
          // re-upload the same doomed photo under a new id and sit at
          // "checking" until it gets rejected again — bounce back to the
          // configure page (photo tile) and demand a different one.
          _photo = null;
          _step = _Step.configure;
          _createError =
              'That photo was rejected by content screening — pick a '
              'different one.';
        } else {
          _createError = e.isRetryable
              ? 'Couldn\'t reach the server. Check your connection and try again.'
              : e.message;
        }
      });
    } catch (e) {
      setState(() {
        _creating = false;
        _createError = 'Something went wrong: $e';
      });
    }
  }

  // ─── Small shared widgets ──────────────────────────────────────────────────

  Widget _microLabel(String text) => Text(
    text,
    style: TextStyle(
      color: AppColors.textFaint,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
    ),
  );

  Widget _choiceChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.18)
              : AppColors.inkCard,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.fg12,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.28),
                    blurRadius: 14,
                  ),
                ]
              : const [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.accent : AppColors.textSoft,
            fontSize: 13.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Editorial two-tone step headline (Stitch redesign 2026-07-22):
  /// "READ THIS **CAREFULLY**" — display-weight lead with a colored
  /// emphasis word, optional spaced-caps subline.
  Widget _stepHeadline({
    required String lead,
    required String emphasis,
    required Color emphasisColor,
    String? subline,
    bool centered = false,
  }) {
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$lead\n'),
              TextSpan(
                text: emphasis,
                style: TextStyle(color: emphasisColor),
              ),
            ],
          ),
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1.02,
            letterSpacing: -1.2,
          ),
        ),
        if (subline != null) ...[
          const SizedBox(height: 10),
          Text(
            subline.toUpperCase(),
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              color: AppColors.textFaint,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.8,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  /// Big rounded-square checkbox row (Stitch redesign 2026-07-22) —
  /// same consent semantics, louder affordance.
  Widget _bigCheck(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () => onChanged(!value),
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: value ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: value ? AppColors.accent : AppColors.fg24,
                  width: 1.4,
                ),
              ),
              child: value
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.black,
                      size: 24,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  height: 1.4,
                ),
              ),
            ),
            if (_showChecklist && !value) ...[
              const SizedBox(width: 8),
              _reqBadge(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stakeChoiceCard({
    required bool selected,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppColors.accent.withValues(alpha: 0.12)
            : AppColors.inkCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.fg12,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing
                else if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeCard(
    String mode,
    String title,
    String subtitle, {
    bool compact = false,
  }) {
    final selected = _mode == mode;
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 6 : 8),
      child: Material(
        color: selected
            ? AppColors.accent.withValues(alpha: 0.12)
            : AppColors.inkCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() {
            _mode = mode;
            // Picking from the expanded list folds it back (Add-Task
            // pattern).
            if (compact) _modeExpanded = false;
          }),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 14,
              vertical: compact ? 10 : 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.fg12,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: compact ? 13.5 : 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.textSoft,
                          fontSize: compact ? 11.5 : 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.accent,
                    size: compact ? 18 : 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _revealWindowLabel(int mins) {
    if (mins < 60) return '$mins minutes';
    if (mins == 60) return '1 hour';
    if (mins < 1440) return '${mins ~/ 60} hours';
    return '24 hours';
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == current ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i <= current ? AppColors.accent : AppColors.fg24,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }
}

/// PSY-1 — the pledge is an active gesture: hold 1.5s to commit.
class _HoldToCommitButton extends StatefulWidget {
  const _HoldToCommitButton({
    required this.enabled,
    required this.onCommitted,
    this.onDisabledTap,
  });

  final bool enabled;
  final VoidCallback onCommitted;

  /// Tap while disabled — used to reveal the requirements checklist.
  final VoidCallback? onDisabledTap;

  @override
  State<_HoldToCommitButton> createState() => _HoldToCommitButtonState();
}

class _HoldToCommitButtonState extends State<_HoldToCommitButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    _progress.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onCommitted();
    });
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? null : widget.onDisabledTap,
      onTapDown: widget.enabled ? (_) => _progress.forward() : null,
      onTapUp: (_) => _progress.reverse(),
      onTapCancel: () => _progress.reverse(),
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              color: widget.enabled ? AppColors.accent : AppColors.fg12,
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progress.value,
                  child: Container(color: AppColors.accentDeep),
                ),
                Center(
                  child: Text(
                    _progress.value > 0
                        ? 'Keep holding…'
                        : 'Hold to give your word',
                    style: TextStyle(
                      color: widget.enabled
                          ? AppColors.onAccent
                          : AppColors.textFaint,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
