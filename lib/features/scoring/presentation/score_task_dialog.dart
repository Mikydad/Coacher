import 'package:flutter/material.dart';

class ScoreTaskDialogResult {
  const ScoreTaskDialogResult({
    required this.completionPercent,
    required this.reason,
  });

  final int completionPercent;
  final String? reason;
}

class ScoreTaskDialog extends StatefulWidget {
  const ScoreTaskDialog({
    super.key,
    required this.taskTitle,
    this.requireSubmit = false,
    this.requireReasonAlways = false,
    this.initialPercent = 100,
    this.reasonThresholdPercent = 100,
  });

  final String taskTitle;

  /// When true (disciplined / extreme) the Cancel button is hidden — Save is
  /// the only way out. Keep in sync with the PopScope/barrier in [show].
  final bool requireSubmit;

  /// When true (extreme mode) a reason is required at any score, not only
  /// below the threshold.
  final bool requireReasonAlways;

  /// Where the slider starts. The timer flow passes the computed
  /// elapsed-vs-planned percent (2026-08-25) so the user adjusts a
  /// pre-filled honest number instead of rating from scratch; checkbox
  /// flows keep the old default of 100.
  final int initialPercent;

  /// The mode's "good enough" bar: at or above it the reason field never
  /// appears; below it a reason is shown and required. Mirrors
  /// [reasonThresholdForMode] / `EnforcementModePolicy.streakDayThreshold`.
  final int reasonThresholdPercent;

  /// The per-mode bar for "good enough" — the same numbers the streak
  /// engine judges days by (`EnforcementModePolicy.streakDayThreshold`),
  /// so the rating card and the analytics never disagree about what
  /// counts.
  static int reasonThresholdForMode(String modeRefId) =>
      switch (modeRefId.trim().toLowerCase()) {
        'extreme' => 100,
        'disciplined' => 90,
        _ => 80,
      };

  /// Dismissability is the task's discipline-mode contract:
  ///
  /// - [requireSubmit] false (flexible): tapping outside / back returns null.
  ///   What null means is the caller's choice — the home checkbox flow treats
  ///   it as "accept the default, done at 100%"; the timer flow treats it as
  ///   "leave without rating".
  /// - [requireSubmit] true (disciplined / extreme): no outside-tap, no back —
  ///   the user must press Save. `show` never returns null in this case.
  /// - [requireReasonAlways] (extreme): reason mandatory at any score.
  static Future<ScoreTaskDialogResult?> show(
    BuildContext context, {
    required String taskTitle,
    bool requireSubmit = false,
    bool requireReasonAlways = false,
    int initialPercent = 100,
    int reasonThresholdPercent = 100,
  }) {
    return showDialog<ScoreTaskDialogResult>(
      context: context,
      barrierDismissible: !requireSubmit,
      builder: (_) => PopScope(
        canPop: !requireSubmit,
        child: ScoreTaskDialog(
          taskTitle: taskTitle,
          requireSubmit: requireSubmit,
          requireReasonAlways: requireReasonAlways,
          initialPercent: initialPercent,
          reasonThresholdPercent: reasonThresholdPercent,
        ),
      ),
    );
  }

  @override
  State<ScoreTaskDialog> createState() => _ScoreTaskDialogState();
}

class _ScoreTaskDialogState extends State<ScoreTaskDialog> {
  late double _percent = widget.initialPercent.clamp(0, 100).toDouble();
  final _reasonCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  /// The reason field exists only below the mode's bar (or always, in
  /// extreme): a good-enough session needs no explanation.
  bool get _reasonNeeded =>
      widget.requireReasonAlways ||
      _percent.round() < widget.reasonThresholdPercent;

  void _submit() {
    final value = _percent.round();
    final reason = _reasonCtrl.text.trim();
    if (_reasonNeeded && reason.isEmpty) {
      setState(
        () => _error = widget.requireReasonAlways
            ? 'A reason is required in extreme mode.'
            : 'Reason is required below '
                  '${widget.reasonThresholdPercent}%.',
      );
      return;
    }
    Navigator.pop(
      context,
      ScoreTaskDialogResult(
        completionPercent: value,
        // A reason typed and then slid out of relevance doesn't ship.
        reason: _reasonNeeded && reason.isNotEmpty ? reason : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Score Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.taskTitle,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text('Completion: ${_percent.round()}%'),
            Slider(
              min: 0,
              max: 100,
              divisions: 20,
              value: _percent,
              onChanged: (v) => setState(() {
                _percent = v;
                if (!_reasonNeeded) _error = null;
              }),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.topCenter,
              child: _reasonNeeded
                  ? TextField(
                      textCapitalization: TextCapitalization.sentences,
                      controller: _reasonCtrl,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: widget.requireReasonAlways
                            ? 'Reason (required)'
                            : 'Reason (required below '
                                  '${widget.reasonThresholdPercent}%)',
                        hintText: widget.requireReasonAlways
                            ? 'How did this session go?'
                            : 'Add context for partial completion',
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
      actions: [
        if (!widget.requireSubmit)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        FilledButton(onPressed: _submit, child: const Text('Save Score')),
      ],
    );
  }
}
