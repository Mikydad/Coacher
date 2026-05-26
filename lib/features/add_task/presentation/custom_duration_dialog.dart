import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../planning/domain/add_task_duration.dart';
import 'add_task_ui.dart';

/// Lets the user set any duration between 1 minute and 12 hours.
Future<int?> showCustomDurationDialog(
  BuildContext context, {
  required int initialMinutes,
}) {
  return showDialog<int>(
    context: context,
    builder: (ctx) => _CustomDurationDialog(initialMinutes: initialMinutes),
  );
}

class _CustomDurationDialog extends StatefulWidget {
  const _CustomDurationDialog({required this.initialMinutes});

  final int initialMinutes;

  @override
  State<_CustomDurationDialog> createState() => _CustomDurationDialogState();
}

class _CustomDurationDialogState extends State<_CustomDurationDialog> {
  late final TextEditingController _hoursController;
  late final TextEditingController _minutesController;
  String? _error;

  @override
  void initState() {
    super.initState();
    final clamped = widget.initialMinutes.clamp(
      kAddTaskMinCustomMinutes,
      kAddTaskMaxCustomMinutes,
    );
    _hoursController = TextEditingController(text: '${clamped ~/ 60}');
    _minutesController = TextEditingController(text: '${clamped % 60}');
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  void _submit() {
    final h = int.tryParse(_hoursController.text.trim()) ?? 0;
    final m = int.tryParse(_minutesController.text.trim()) ?? 0;
    if (h < 0 || m < 0) {
      setState(() => _error = 'Enter valid numbers');
      return;
    }
    final total = h * 60 + m;
    if (total < kAddTaskMinCustomMinutes) {
      setState(() => _error = 'Duration must be at least 1 minute');
      return;
    }
    if (total > kAddTaskMaxCustomMinutes) {
      setState(() => _error = 'Maximum duration is 12 hours');
      return;
    }
    Navigator.pop(context, total);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AddTaskColors.card,
      title: const Text(
        'Custom duration',
        style: TextStyle(color: AddTaskColors.onSurface),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _hoursController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  style: const TextStyle(color: AddTaskColors.onSurface),
                  decoration: const InputDecoration(
                    labelText: 'Hours',
                    filled: true,
                    fillColor: AddTaskColors.cardElevated,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: (_) => _submit(),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  style: const TextStyle(color: AddTaskColors.onSurface),
                  decoration: const InputDecoration(
                    labelText: 'Minutes',
                    filled: true,
                    fillColor: AddTaskColors.cardElevated,
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AddTaskColors.accent,
            foregroundColor: Colors.black,
          ),
          child: const Text('Set duration'),
        ),
      ],
    );
  }
}
