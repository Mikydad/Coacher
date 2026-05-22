import 'package:flutter/material.dart';

class QuickDirective {
  const QuickDirective({required this.label, required this.startingText});

  final String label;
  final String startingText;
}

const List<QuickDirective> kDefaultDirectives = [
  QuickDirective(label: 'Add task', startingText: 'Add a task '),
  QuickDirective(label: 'Create goal', startingText: 'Create a goal '),
  QuickDirective(label: 'Move schedule', startingText: 'Move my '),
  QuickDirective(label: 'Focus mode', startingText: 'Enable focus mode '),
];

class QuickDirectivesRow extends StatelessWidget {
  const QuickDirectivesRow({
    super.key,
    required this.onSelected,
    this.directives = kDefaultDirectives,
  });

  final void Function(String startingText) onSelected;
  final List<QuickDirective> directives;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: directives.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = directives[i];
          return _DirectiveChip(
            label: d.label,
            onTap: () => onSelected(d.startingText),
          );
        },
      ),
    );
  }
}

class _DirectiveChip extends StatelessWidget {
  const _DirectiveChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.20),
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFFADAAAA),
          ),
        ),
      ),
    );
  }
}
