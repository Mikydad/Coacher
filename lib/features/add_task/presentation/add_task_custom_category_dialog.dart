import 'package:flutter/material.dart';

/// Prompts for a custom category name; resolves to the trimmed name or null
/// when cancelled. (Same show-function shape as `showCustomDurationDialog`.)
Future<String?> showCustomCategoryDialog(BuildContext context) {
  return showDialog<String?>(
    context: context,
    builder: (_) => const _CustomCategoryDialog(),
  );
}

/// Owns its [TextEditingController] so it is disposed only after the dialog
/// route finishes (same pattern as the goal milestone dialog).
class _CustomCategoryDialog extends StatefulWidget {
  const _CustomCategoryDialog();

  @override
  State<_CustomCategoryDialog> createState() => _CustomCategoryDialogState();
}

class _CustomCategoryDialogState extends State<_CustomCategoryDialog> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    Navigator.pop<String?>(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom category'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'e.g. Music'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop<String?>(context, null),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Use')),
      ],
    );
  }
}
