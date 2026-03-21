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
  const ScoreTaskDialog({super.key, required this.taskTitle});

  final String taskTitle;

  static Future<ScoreTaskDialogResult?> show(BuildContext context, {required String taskTitle}) {
    return showDialog<ScoreTaskDialogResult>(
      context: context,
      builder: (_) => ScoreTaskDialog(taskTitle: taskTitle),
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
    if (value < 100 && reason.isEmpty) {
      setState(() => _error = 'Reason is required when completion is below 100%.');
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
            Text(widget.taskTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
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
              decoration: const InputDecoration(
                labelText: 'Reason (required if < 100%)',
                hintText: 'Add context for partial completion',
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save Score')),
      ],
    );
  }
}
