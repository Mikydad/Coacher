import 'package:flutter/material.dart';

import '../application/goal_templates.dart';
import '../domain/models/goal_categories.dart';
import '../domain/models/goal_enums.dart';
import '../domain/models/goal_template.dart';
import 'goal_editor_screen.dart';
import 'widgets/goal_editor_widgets.dart';
import '../../../core/presentation/app_colors.dart';

/// Entry point for creating a goal — pick a template or start blank.
class GoalTemplatePickerScreen extends StatelessWidget {
  const GoalTemplatePickerScreen({super.key});

  static const routeName = '/goals/templates';

  void _openEditor(BuildContext context, GoalTemplate template) {
    Navigator.pushReplacementNamed(
      context,
      GoalEditorScreen.routeName,
      arguments: GoalEditorArgs(template: template),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.fg70),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'NEW GOAL',
          style: TextStyle(
            color: AppColors.fg,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Popular goals',
            style: TextStyle(
              color: AppColors.fg,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pick a starting point — you can change anything on the next screen.',
            style: TextStyle(color: AppColors.fg54, height: 1.4),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemCount: goalTemplates.length,
            itemBuilder: (context, i) {
              final template = goalTemplates[i];
              final isCustom = template.isBlank;
              return _TemplateCard(
                template: template,
                isCustom: isCustom,
                onTap: () => _openEditor(context, template),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.isCustom,
    required this.onTap,
  });

  final GoalTemplate template;
  final bool isCustom;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: isCustom ? Colors.transparent : GoalEditorColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCustom ? AppColors.fg24 : GoalEditorColors.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(template.emoji, style: const TextStyle(fontSize: 28)),
                const Spacer(),
                Text(
                  template.label,
                  style: TextStyle(
                    color: isCustom ? GoalEditorColors.lime : AppColors.fg,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                if (!isCustom && template.measurement != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _subtitle(template),
                    style: TextStyle(color: AppColors.fg38, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle(GoalTemplate t) {
    final target = t.targetValue?.round() ?? 0;
    final unit = switch (t.measurement) {
      MeasurementKind.minutes => 'min',
      MeasurementKind.sessions => 'sessions',
      MeasurementKind.count => t.customLabel ?? 'count',
      MeasurementKind.distance => 'km',
      MeasurementKind.custom => t.customLabel ?? 'units',
      null => '',
    };
    return '$target $unit · ${GoalCategories.label(t.categoryId ?? '')}';
  }
}
