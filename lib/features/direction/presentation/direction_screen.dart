import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/page_headers.dart';
import '../../education/presentation/help_dot.dart';
import '../../goals/presentation/widgets/goal_editor_widgets.dart';
import '../../settings/presentation/settings_page_scaffold.dart';
import '../application/direction_closeout.dart';
import '../application/direction_providers.dart';
import '../data/direction_repository.dart';
import '../domain/direction_context_lines.dart';
import '../domain/direction_periods.dart';
import '../domain/models/direction_entry.dart';

/// The Direction page (PRD/Direction, 2026-09-11; entry interaction revised
/// 2026-09-12 after Miko's device test).
///
/// Direction is not something SidePal asks the user to accomplish. It is
/// something SidePal remembers while helping them. So this page is three
/// statements — year, quarter, month — and nothing else: no deadline, no
/// progress, no history.
///
/// Interaction (decision 8, revised):
///  - Empty horizon → the question and a quiet `+ Add` row. Tapping opens
///    an editor (field + Save / Cancel), focused.
///  - Set horizon → the text as a plain statement; tapping it reopens the
///    editor with the current text.
///  - `Keep` under an empty horizon carries the previous period's text in
///    one tap (the only way history enters a new period).
///  - Safety net, invisible: backing out or backgrounding with an open,
///    dirty editor still saves — text is never lost. Otherwise nothing
///    writes until Save. The repository no-ops on unchanged text.
class DirectionScreen extends ConsumerStatefulWidget {
  const DirectionScreen({super.key});

  static const routeName = '/direction';

  @override
  ConsumerState<DirectionScreen> createState() => _DirectionScreenState();
}

class _DirectionScreenState extends ConsumerState<DirectionScreen>
    with WidgetsBindingObserver {
  // Cached so the save path never touches `ref` — the safety net runs from
  // dispose() and after an await, where a ConsumerState's ref is invalid.
  late final DirectionRepository _repo;
  DirectionCloseoutScheduler? _scheduler;
  Map<DirectionHorizon, DirectionSlot> _slots = const {};

  /// Open editors only; a horizon without one is in view mode.
  final Map<DirectionHorizon, _Editor> _editors = {};

  @override
  void initState() {
    super.initState();
    _repo = ref.read(directionRepositoryProvider);
    try {
      _scheduler = ref.read(directionCloseoutSchedulerProvider);
    } catch (e) {
      // Tests without the notifications plugin: the page still works.
      debugPrint('[DirectionScreen] close-out scheduler unavailable: $e');
    }
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _flushDirtyEditors(close: false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flushDirtyEditors(close: true);
    super.dispose();
  }

  /// Safety net: persist any open editor whose text changed. Reads the
  /// texts BEFORE disposing controllers; the writes finish in the
  /// background (Isar txn — milliseconds, no network).
  void _flushDirtyEditors({required bool close}) {
    for (final entry in _editors.entries.toList()) {
      final horizon = entry.key;
      final editor = entry.value;
      final text = editor.controller.text.trim();
      final slot = _slots[horizon];
      if (slot != null && text != editor.original) {
        unawaited(_write(slot, text));
      }
      if (close) {
        editor.dispose();
        _editors.remove(horizon);
      }
    }
  }

  Future<void> _write(DirectionSlot slot, String text) async {
    try {
      await _repo.setText(slot.period, text);
      await _rearmCloseouts();
    } catch (e) {
      debugPrint('[DirectionScreen] save failed for ${slot.period.key}: $e');
    }
  }

  /// The close-out answer for the previous period (2026-09-19).
  Future<void> _setOutcome(DirectionEntry entry, DirectionOutcome o) async {
    try {
      await _repo.setOutcome(entry, o);
      await _rearmCloseouts();
    } catch (e) {
      debugPrint('[DirectionScreen] outcome failed for ${entry.id}: $e');
    }
  }

  /// Keeps the end-of-period notices in step with what was just written.
  /// Cached scheduler: this runs after awaits and from dispose paths.
  Future<void> _rearmCloseouts() async {
    final scheduler = _scheduler;
    if (scheduler == null) return;
    await scheduler.rearm(await _repo.fetchAllOnce());
  }

  void _openEditor(DirectionHorizon horizon) {
    if (_editors.containsKey(horizon)) return;
    final current = _slots[horizon]?.text ?? '';
    setState(() => _editors[horizon] = _Editor(current));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _editors[horizon]?.focusNode.requestFocus();
    });
  }

  void _cancel(DirectionHorizon horizon) {
    final editor = _editors.remove(horizon);
    editor?.dispose();
    setState(() {});
  }

  Future<void> _save(DirectionHorizon horizon) async {
    final editor = _editors[horizon];
    final slot = _slots[horizon];
    if (editor == null || slot == null) return;
    final text = editor.controller.text.trim();
    _editors.remove(horizon);
    editor.dispose();
    setState(() {});
    if (text == editor.original) return; // nothing changed — just close
    await _write(slot, text);
  }

  Future<void> _keep(DirectionHorizon horizon, String text) async {
    final slot = _slots[horizon];
    if (slot == null) return;
    // Keep from inside an open editor closes it — the statement is the
    // confirmation.
    _editors.remove(horizon)?.dispose();
    setState(() {});
    await _write(slot, text);
  }

  @override
  Widget build(BuildContext context) {
    final slots = ref.watch(currentDirectionProvider);
    _slots = slots;

    return SettingsPageScaffold(
      title: 'Direction',
      children: [
        const SectionHeader(
          'Your Direction',
          subtitle:
              'Set what you want to focus on this year, quarter, and month. '
              'SidePal uses it to help guide your plans and suggestions.',
          trailing: HelpDot('direction'),
        ),
        const SizedBox(height: 28),
        for (final horizon in kDirectionHorizonOrder) ...[
          _HorizonSection(
            horizon: horizon,
            slot: slots[horizon]!,
            editor: _editors[horizon],
            onAdd: () => _openEditor(horizon),
            onSave: () => _save(horizon),
            onCancel: () => _cancel(horizon),
            onKeep: (text) => _keep(horizon, text),
            onOutcome: (entry, o) => _setOutcome(entry, o),
          ),
          const SizedBox(height: 30),
        ],
        Text(
          "Direction isn't a task or a goal. It simply helps SidePal "
          'understand what matters to you.',
          style: TextStyle(color: AppColors.fg38, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }
}

class _Editor {
  _Editor(this.original) : controller = TextEditingController(text: original);

  /// Trimmed text when the editor opened — Save with no change is a close.
  final String original;
  final TextEditingController controller;
  final FocusNode focusNode = FocusNode();

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}

class _HorizonSection extends StatelessWidget {
  const _HorizonSection({
    required this.horizon,
    required this.slot,
    required this.editor,
    required this.onAdd,
    required this.onSave,
    required this.onCancel,
    required this.onKeep,
    required this.onOutcome,
  });

  final DirectionHorizon horizon;
  final DirectionSlot slot;
  final _Editor? editor;
  final VoidCallback onAdd;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final ValueChanged<String> onKeep;
  final void Function(DirectionEntry entry, DirectionOutcome outcome) onOutcome;

  String get _label => switch (horizon) {
    DirectionHorizon.year => 'This year',
    DirectionHorizon.quarter => 'This quarter',
    DirectionHorizon.month => 'This month',
  };

  String get _question => switch (horizon) {
    DirectionHorizon.year => 'What do you want this year to be about?',
    DirectionHorizon.quarter => 'What are you focused on right now?',
    DirectionHorizon.month => 'What matters most this month?',
  };

  String get _previousLabel => switch (horizon) {
    DirectionHorizon.year => 'Last year',
    DirectionHorizon.quarter => 'Last quarter',
    DirectionHorizon.month => 'Last month',
  };

  @override
  Widget build(BuildContext context) {
    final e = editor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MicroLabel('$_label · ${slot.period.label}'),
        const SizedBox(height: 10),
        if (e != null)
          _EditorView(
            horizon: horizon,
            editor: e,
            hint: _question,
            onSave: onSave,
            onCancel: onCancel,
          )
        else if (slot.hasText)
          _StatementView(horizon: horizon, text: slot.text, onTap: onAdd)
        else
          _EmptyView(horizon: horizon, question: _question, onAdd: onAdd),
        if (slot.suggestion != null)
          _SuggestionRow(
            horizon: horizon,
            label: slot.previous?.outcome == null
                ? _previousLabel
                : '$_previousLabel (${slot.previous!.outcome!.label.toLowerCase()})',
            text: slot.suggestion!,
            onKeep: () => onKeep(slot.suggestion!),
            // Inside an open editor, hide once the user types their own words.
            listenable: e?.controller,
          ),
        // The previous period's close-out waits here until answered
        // (2026-09-19) — the notification only points at it. Sits under
        // the suggestion line, which already carries the text; it repeats
        // the text only when that line is absent.
        if (slot.closeout != null)
          _CloseoutRow(
            horizon: horizon,
            label: _previousLabel,
            entry: slot.closeout!,
            showText: slot.suggestion == null,
            onOutcome: (o) => onOutcome(slot.closeout!, o),
          ),
      ],
    );
  }
}

/// Set horizon: the text as a statement, not an input. Tap to edit.
class _StatementView extends StatelessWidget {
  const _StatementView({
    required this.horizon,
    required this.text,
    required this.onTap,
  });

  final DirectionHorizon horizon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('direction_statement_${horizon.name}'),
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: AppColors.fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(
                Icons.edit_outlined,
                size: 15,
                color: AppColors.textSoft.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty horizon: the question and a quiet `+ Add` row.
class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.horizon,
    required this.question,
    required this.onAdd,
  });

  final DirectionHorizon horizon;
  final String question;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            question,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 6),
        TextButton.icon(
          key: ValueKey('direction_add_${horizon.name}'),
          onPressed: onAdd,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            alignment: Alignment.centerLeft,
          ),
          icon: const Icon(Icons.add, size: 16),
          label: const Text(
            'Add',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// Open editor: field + Cancel / Save.
class _EditorView extends StatelessWidget {
  const _EditorView({
    required this.horizon,
    required this.editor,
    required this.hint,
    required this.onSave,
    required this.onCancel,
  });

  final DirectionHorizon horizon;
  final _Editor editor;
  final String hint;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: ValueKey('direction_field_${horizon.name}'),
          controller: editor.controller,
          focusNode: editor.focusNode,
          maxLength: kDirectionMaxChars,
          maxLines: null,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSave(),
          style: TextStyle(
            color: AppColors.fg,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          buildCounter:
              (
                context, {
                required currentLength,
                required isFocused,
                maxLength,
              }) {
                // Statement, not essay: the counter appears only near the cap.
                if (currentLength < kDirectionMaxChars - 40) return null;
                return Text(
                  '$currentLength/$maxLength',
                  style: TextStyle(color: AppColors.fg38, fontSize: 11),
                );
              },
          decoration: goalEditorInputDecoration(hintText: hint),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              key: ValueKey('direction_cancel_${horizon.name}'),
              onPressed: onCancel,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSoft,
                minimumSize: const Size(0, 36),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 6),
            FilledButton(
              key: ValueKey('direction_save_${horizon.name}'),
              onPressed: onSave,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.onAccent,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.horizon,
    required this.label,
    required this.text,
    required this.onKeep,
    required this.listenable,
  });

  final DirectionHorizon horizon;
  final String label;
  final String text;
  final VoidCallback onKeep;

  /// Present while an editor is open: the row hides once it has text.
  final TextEditingController? listenable;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label: $text',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textSoft, fontSize: 12),
            ),
          ),
          TextButton(
            key: ValueKey('direction_keep_${horizon.name}'),
            onPressed: onKeep,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Keep',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    final l = listenable;
    if (l == null) return row;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: l,
      builder: (context, value, _) =>
          value.text.trim().isNotEmpty ? const SizedBox.shrink() : row,
    );
  }
}

/// "Last month: <text> — did you get there?" with the three answers.
/// Stays until answered; answering is one tap and the row leaves.
class _CloseoutRow extends StatelessWidget {
  const _CloseoutRow({
    required this.horizon,
    required this.label,
    required this.entry,
    required this.showText,
    required this.onOutcome,
  });

  final DirectionHorizon horizon;
  final String label;
  final DirectionEntry entry;

  /// False when the suggestion line above already shows the text.
  final bool showText;
  final ValueChanged<DirectionOutcome> onOutcome;

  @override
  Widget build(BuildContext context) {
    // The period by name ("August"), never "Last month": that wording is
    // the suggestion line's, and the two must read as different things.
    final periodLabel = entry.period?.label ?? label;
    return Container(
      key: ValueKey('direction_closeout_${horizon.name}'),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.fg.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showText) ...[
            Text(
              '$periodLabel: ${entry.text}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.fg,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            showText
                ? 'Did you get there?'
                : '$periodLabel — did you get there?',
            style: TextStyle(color: AppColors.textSoft, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final o in DirectionOutcome.values)
                ActionChip(
                  key: ValueKey(
                    'direction_outcome_${horizon.name}_${o.storageValue}',
                  ),
                  label: Text(o.label, style: const TextStyle(fontSize: 12)),
                  onPressed: () => onOutcome(o),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 11px uppercase tracked micro-label — tier 3 of the header hierarchy.
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
