import 'package:flutter/material.dart';

import '../domain/models/flow_transition_event.dart';

/// The "why are plans changing?" dialog.
///
/// Extracted from `home_screen.dart` so the Recovery Card can demand the same
/// thing Extreme mode has always demanded elsewhere (FR-R-42). One dialog
/// means one definition of what counts as a reason — the note is validated by
/// [FlowTransitionEvent.validateReasonNote], so "ok" does not pass here and
/// silently pass there.

Future<({OverrideReasonCategory reason, String note})?> promptOverrideReason(
  BuildContext context,
) async {
  final reasons = OverrideReasonCategory.values;
  OverrideReasonCategory selectedReason = reasons.first;
  final noteCtrl = TextEditingController();
  String? errorText;
  final choice =
      await showDialog<({OverrideReasonCategory reason, String note})>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Why are plans changing?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<OverrideReasonCategory>(
                  initialValue: selectedReason,
                  items: [
                    for (final r in reasons)
                      DropdownMenuItem(value: r, child: Text(r.label)),
                  ],
                  onChanged: (v) =>
                      setState(() => selectedReason = v ?? reasons.first),
                  decoration: const InputDecoration(
                    labelText: 'Reason category',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Logical reason (1-2 sentences)',
                    hintText: 'Explain clearly why this is the best move now.',
                  ),
                ),
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      errorText!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final note = noteCtrl.text.trim();
                  try {
                    FlowTransitionEvent.validateReasonNote(note);
                  } catch (_) {
                    setState(
                      () => errorText = 'Give a clear reason in 1-2 sentences.',
                    );
                    return;
                  }
                  Navigator.pop(ctx, (reason: selectedReason, note: note));
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      );
  noteCtrl.dispose();
  return choice;
}
