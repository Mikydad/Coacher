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
  });

  final String taskTitle;

  /// When true (disciplined / extreme) the Cancel button is hidden — Save is
  /// the only way out. Keep in sync with the PopScope/barrier in [show].
  final bool requireSubmit;

  /// When true (extreme mode) a reason is required at any score, not only
  /// below 100%.
  final bool requireReasonAlways;

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
        ),
      ),
    );
  }

  @override
  State<ScoreTaskDialog> createState() => _ScoreTaskDialogState();
}

class _ScoreTaskDialogState extends State<ScoreTaskDialog> {
  double _percent = 100;
  final _reasonCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _percent.round();
    final reason = _reasonCtrl.text.trim();
    if ((value < 100 || widget.requireReasonAlways) && reason.isEmpty) {
      setState(
        () => _error = widget.requireReasonAlways
            ? 'A reason is required in extreme mode.'
            : 'Reason is required when completion is below 100%.',
      );
      return;
    }
    Navigator.pop(
      context,
      ScoreTaskDialogResult(
        completionPercent: value,
        reason: reason.isEmpty ? null : reason,
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
              onChanged: (v) => setState(() => _percent = v),
            ),
            TextField(
              controller: _reasonCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: widget.requireReasonAlways
                    ? 'Reason (required)'
                    : 'Reason (required if < 100%)',
                hintText: widget.requireReasonAlways
                    ? 'How did this session go?'
                    : 'Add context for partial completion',
              ),
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
